"""Run a phase-specific backend app.

Usage:
    python scripts/run_phase.py phase1  # runs on port 5002
    python scripts/run_phase.py full    # runs the full app on port 5000
"""
import sys
from backend.phases.phase_app import create_phase_app


def main():
    phase = sys.argv[1] if len(sys.argv) > 1 else "phase1"
    port = 5002 if phase != "full" else 5000
    app = create_phase_app(phase)
    print(f"Starting backend for {phase} on port {port}")
    app.run(host="0.0.0.0", port=port)


if __name__ == "__main__":
    main()
