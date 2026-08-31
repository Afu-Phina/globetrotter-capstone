"""Phase-based adapters for the monolith backend.

This package provides a small, non-destructive adapter to run the
backend with a subset of blueprints corresponding to design phases.

Usage (example):
    from backend.phases.phase_app import create_phase_app
    app = create_phase_app("phase1")
    app.run(port=5002)

We keep this separate so the original `app.create_app()` is unchanged.
"""
