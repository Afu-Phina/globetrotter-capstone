"""
JSON file storage layer, scoped to this service's own data directory
(itineraries.json + visits.json only -- no other service's collections
are reachable from here).
"""

import json
import os
import threading

DATA_DIR = os.environ.get("GLOBETROTTER_DATA_DIR") or os.path.join(
    os.path.dirname(os.path.dirname(__file__)), "data"
)

_lock = threading.Lock()


def _path_for(collection: str) -> str:
    return os.path.join(DATA_DIR, f"{collection}.json")


def read_all(collection: str) -> list:
    path = _path_for(collection)
    if not os.path.exists(path):
        return []
    with open(path, "r", encoding="utf-8") as f:
        content = f.read().strip()
        return json.loads(content) if content else []


def write_all(collection: str, records: list) -> None:
    path = _path_for(collection)
    with _lock:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(records, f, indent=2, ensure_ascii=False)


def find_by_id(collection: str, record_id: str) -> dict | None:
    records = read_all(collection)
    return next((r for r in records if r.get("id") == record_id), None)
