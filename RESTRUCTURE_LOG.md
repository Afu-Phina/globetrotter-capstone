# Restructure Log

This file records non-destructive changes made to support phase-oriented structure.

Changes so far:
- Added `backend/phases/phase_app.py` — adapter to create phase-limited Flask apps.
- Added `backend/phases/check_phase_health.py` — helper to verify phase apps via Flask test_client.
- Added `scripts/run_phase.py` — convenience script to run phase apps (`phase1` -> port 5002, `full` -> port 5000).
- Added `scripts/integration_smoke_test.py` — end-to-end smoke test hitting the running monolith API.
- Added `backend/refactor/README.md` — instructions for non-destructive refactor.

Next steps:
- Create frontend scaffolding notes under `frontend/refactor/` and optionally small adapters.
- Add CI workflow to run smoke tests on push.
