"""
JSON file storage layer.

This is the single most important file in Phase 1. Every route talks to
data through these functions instead of touching files directly. When
Phase 2/3 replaces JSON files with a real database, only this file changes
-- routes stay untouched. This is the core lesson of the monolith phase:
isolate your data access behind a stable interface.
"""

import json
import os
import threading

# All JSON "tables" live here.
DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data")

# A simple lock so two requests writing at once don't corrupt a file.
# (In-memory only -- fine for a single-process dev server in Phase 1.)
_lock = threading.Lock()


def _path_for(collection: str) -> str:
    return os.path.join(DATA_DIR, f"{collection}.json")


def read_all(collection: str) -> list:
    """Read every record from a collection (e.g. 'users', 'destinations')."""
    path = _path_for(collection)
    if not os.path.exists(path):
        return []
    with open(path, "r", encoding="utf-8") as f:
        content = f.read().strip()
        return json.loads(content) if content else []


def write_all(collection: str, records: list) -> None:
    """Overwrite a collection with a new list of records."""
    path = _path_for(collection)
    with _lock:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(records, f, indent=2, ensure_ascii=False)


def find_by_id(collection: str, record_id: str) -> dict | None:
    records = read_all(collection)
    return next((r for r in records if r.get("id") == record_id), None)


def insert(collection: str, record: dict) -> dict:
    records = read_all(collection)
    records.append(record)
    write_all(collection, records)
    return record


def update_by_id(collection: str, record_id: str, updates: dict) -> dict | None:
    records = read_all(collection)
    for r in records:
        if r.get("id") == record_id:
            r.update(updates)
            write_all(collection, records)
            return r
    return None


def delete_by_id(collection: str, record_id: str) -> bool:
    records = read_all(collection)
    filtered = [r for r in records if r.get("id") != record_id]
    if len(filtered) == len(records):
        return False
    write_all(collection, filtered)
    return True
