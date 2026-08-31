# Frontend Refactor (Non-destructive)

This folder contains notes and small adapters to align the Flutter frontend with the design phases without modifying the main app.

Recommendations:
- Keep the existing Flutter project at `frontend/globetrotter/` intact.
- Use feature flags or environment variables to enable/disable UI sections by phase.
- For quick phase previews, run `flutter run -d web-server --web-port=5001` and open the pages matching the phase (Destinations, Details, Itineraries).

Files to add later (optional):
- Small Dart wrappers in `lib/phases/` that expose only the screens needed per phase.
- A build-time script that compiles a phase-specific web build using `--dart-define` flags.
