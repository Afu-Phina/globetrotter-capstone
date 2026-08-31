# Design Phases Mapping

This document maps the visual/design phases from the provided prompt to the repository structure and implementation notes so each phase is preserved, discoverable, and actionable.

## Phase 1 — Dashboard / Explore (Home)
- Goal: Show curated destinations grid, category filters, search, and pagination.
- Frontend: frontend/globetrotter/lib/screens/destinations_screen.dart implements the main UI and categories.
- Backend: services/recommendation-service/app/routes/destinations.py (`GET /api/destinations`) provides search, filtering, pagination, and popularity-based sorting.
- Data: services/recommendation-service/data/destinations.json (seed catalogue).
- Notes / Next steps: tune the category list and icons in the frontend to match design; add analytics hook if desired.

## Phase 2 — Place Details Page
- Goal: Large cover image, description, tags, rating summary, reviews, nearby suggestions, and actions (open in maps, add to itinerary, book visit).
- Frontend: frontend/globetrotter/lib/widgets/destination_detail_sheet.dart, ask_question_widget.dart, guided_visit_form.dart, destination_image.dart.
- Backend: services/recommendation-service/app/routes/destinations.py (GET /<id>, reviews endpoints) and services/itinerary-service/app/routes/itineraries.py for adding to itineraries. Booking uses services/itinerary-service/app/routes/visits.py (POST /api/visits).
- Data: services/recommendation-service/data/reviews.json, services/itinerary-service/data/itineraries.json and visits.json.

## Phase 3 — Ask-a-Question Chat Widget
- Goal: Inline chat for free-form Q&A about a place, powered by an LLM with grounded context and a graceful fallback.
- Frontend: frontend/globetrotter/lib/widgets/ask_question_widget.dart.
- Backend (monolith): backend/app/utils/ai_assistant.py (Google Gemini integration, fallback rule-based answers) used by `/api/destinations/<id>/ask` in the monolith.
- Backend (microservice): services/recommendation-service/app/utils/ai.py (Anthropic/Claude integration) used by services/recommendation-service/app/routes/destinations.py `ask` endpoint.
- Notes: Both providers are supported — keep API keys in env (`GEMINI_API_KEY`, `ANTHROPIC_API_KEY` / `ANTHROPIC_AUTH_TOKEN`). Test fallback behavior and the response parsing logic.

## Phase 4 — Booking / Guided Visit Flow
- Goal: User selects date/time/people and books a guided visit; confirmation and My Bookings view.
- Frontend: frontend/globetrotter/lib/widgets/guided_visit_form.dart, bookings screen at frontend/globetrotter/lib/screens/my_bookings_screen.dart.
- Backend: services/itinerary-service/app/routes/visits.py (POST /api/visits, GET /api/visits, DELETE /api/visits/<id>).
- Notes: Ensure `require_auth` header flows through gateway when using the microservices architecture.

## Phase 5 — Itineraries & Sharing
- Goal: Create itineraries, add/remove destinations, share by email with other users.
- Frontend: frontend/globetrotter/lib/screens/itineraries_screen.dart, itinerary_form_screen.dart, itinerary_detail_screen.dart.
- Backend: services/itinerary-service/app/routes/itineraries.py (create/list/get/update/delete/share) and services/user-service for resolving user-by-email.

## Phase 6 — Profile, Auth, and JWT
- Goal: Register/login, persistent auth token, profile view, secure endpoints with JWT.
- Frontend: frontend/globetrotter/lib/services/auth_service.dart, login/register screens.
- Backend: services/user-service implements /api/auth/register and /api/auth/login and user lookups. Shared `GLOBETROTTER_SECRET` is used across services for token verification.

## Phase 7 — Static Images & Media
- Goal: Serve destination photos at `/static/...`.
- Backend (gateway): services/gateway/app.py forwards `/static` to recommendation-service static asset root. services/recommendation-service serves static files from its `static/` folder.

## Phase 8 — Responsive Design & UX polish
- Goal: Desktop + tablet + mobile friendly UI, animations, transitions, and consistent branding.
- Frontend: theme files under frontend/globetrotter/lib/theme/ and multiple screens already wired for responsive constraints.

## Cross-cutting concerns and deployment phases
- Local / Monolith (Phase 1 demo): backend/ top-level monolith app (easy to run locally or from Vercel via `api/index.py`).
- Microservices (Phase 2+): services/ contains gateway, user-service, itinerary-service, recommendation-service — each with its own app/ package and data/ folder.
- Orchestration: docker-compose.yml at repo root and services/*/Dockerfile for multi-container local testing; k8s/ contains Kubernetes manifests for later deployment.

## Suggested repo restructuring to reflect phases (non-destructive)
- Add a docs/ directory and keep this file at docs/PHASES.md for future reference. This file is intentionally placed at the repo root for quick discovery.
- Consider adding small helpers in `scripts/` to seed and run per-phase smoke tests: `scripts/seed_data.py`, `scripts/run-local.sh`, `scripts/integration_smoke_test.py`.
- Avoid risky, large refactors now: prefer adapters and small scaffolding until automated tests exist.

## Quick verification checklist (one-liners)
- Phase 1: open `Destinations` in the Flutter app and verify categories + pagination.
- Phase 2: open a destination and verify description, reviews, nearby, and add-to-itinerary.
- Phase 3: Try the Ask widget with and without AI keys to confirm fallback.
- Phase 4: Book a guided visit and check `My Bookings`.

---
If you'd like, I can (pick one):
- scaffold `docs/architecture.md` and `scripts/` helpers, or
- create the `scripts/integration_smoke_test.py` that runs through register/login/create-itinerary/add-review/ask flows, or
- perform the refactor to move monolith AI helper into the recommendation-service and consolidate prompts.

Please tell me which follow-up you prefer and I'll implement it next.
