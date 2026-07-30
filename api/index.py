"""
Vercel entrypoint.

Vercel's Python functions run against a read-only deployment bundle --
only /tmp is writable, and it isn't guaranteed to survive between cold
starts. backend/app/utils/storage.py writes JSON files directly, so it
can't run against the bundled backend/app/data path as-is.

This points storage at /tmp instead, and seeds it from the bundled seed
data once per cold start. Data still won't survive a cold start or be
shared across concurrent instances -- there's no way around that without
a real external database -- but requests won't 500 on every write, which
is the difference between a working demo and a broken one.
"""

import os
import shutil
import sys

_HERE = os.path.dirname(os.path.abspath(__file__))
_BACKEND_DIR = os.path.join(_HERE, "..", "backend")
sys.path.insert(0, _BACKEND_DIR)

_SEED_DATA_DIR = os.path.join(_BACKEND_DIR, "app", "data")
_RUNTIME_DATA_DIR = "/tmp/globetrotter_data"

if not os.path.isdir(_RUNTIME_DATA_DIR) or not os.listdir(_RUNTIME_DATA_DIR):
    shutil.copytree(_SEED_DATA_DIR, _RUNTIME_DATA_DIR, dirs_exist_ok=True)

os.environ["GLOBETROTTER_DATA_DIR"] = _RUNTIME_DATA_DIR

from app import create_app  # noqa: E402

app = create_app()
