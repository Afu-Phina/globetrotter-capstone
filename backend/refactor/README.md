# Backend Refactor (Non-destructive)

This folder contains non-destructive scaffolding and notes for reorganizing the backend around the design phases.

What this contains:
- Guidance for moving blueprints into phase-aligned packages.
- Examples of adapter modules that register existing blueprints without moving original files.

How to use:
1. Use `backend/phases/phase_app.py` to run a subset of the backend for a phase.
2. Add adapter modules here that import existing `app.routes.*` blueprints and expose a `create_app()` if you want a standalone small service.

This folder is intentionally small — prefer adapters and wrappers instead of moving stable code until tests exist.
