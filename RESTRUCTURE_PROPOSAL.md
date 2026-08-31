# Restructure & UI Scaffolding Proposal

This document proposes a conservative, non-destructive repo re-organization and a concrete UI scaffolding plan that preserves every design phase from `PHASES.md` while making future development and testing easier.

Principles
- Non-destructive: don't delete working files. Stage migrations behind small adapters so runtime behavior doesn't break.
- Phase-aligned: each step maps to one design phase in `PHASES.md`.
- Incremental: small commits + tests for each step so changes are reviewable.

High-level changes (no-code moves yet)
1. Add a `docs/` folder and move `PHASES.md` → `docs/PHASES.md`. Add `docs/architecture.md` to record decisions.
2. Add a `scripts/` folder with small helpers:
   - `scripts/seed_data.py` — copy seed JSON into a runtime dir or /tmp for Vercel/dev.
   - `scripts/run_services_locally.sh` — convenience runner for services using env vars.
   - `scripts/integration_smoke_test.py` — runs a sequence: register → login → create itinerary → add review → ask question → book visit.
3. Consolidate AI helpers (proposal only): create a new helper in `services/recommendation-service/app/utils/ai_helpers.py` that wraps both Gemini+Anthropic providers and exposes a stable `answer(destination, question)` interface. Keep current helpers as fallback wrappers until migration is complete.

Concrete file move suggestions (rename / logical placement; actual move should be done via small PRs):
- Move root monolith docs & examples into `backend/` to reduce confusion. Suggested moves:
  - `PHASES.md` → `docs/PHASES.md`
  - Add `docs/README_OVERVIEW.md` linking monolith vs services vs frontend.

Backend consolidation plan
- Step A: Add `services/recommendation-service/app/utils/ai_helpers.py` implementing an adapter that imports `backend/app/utils/ai_assistant.py` and `services/recommendation-service/app/utils/ai.py` behind one interface. This is read-only and adds no behavioural change.
- Step B: Update `services/recommendation-service/app/routes/destinations.py` to import the new adapter. Run smoke tests.
- Step C: Remove duplicate monolith helper once traffic has been validated (optional later).

Frontend UI scaffolding plan (Flutter)
- Create `frontend/globetrotter/lib/ui/` with subfolders:
  - `components/` (reusable widgets: `DestinationCard`, `RatingStars`, `AskQuestionWidget`) — many already exist; move copies or export them via barrel file `components.dart`.
  - `screens/` (keep existing `screens/`, but introduce `shells/` for higher-level shells e.g., `MainShell`).
  - `styles/` or `theme/` already exists; ensure `theme/` exports color & spacing tokens.
- Add a `ui/README.md` that documents component contracts (props, events) and the mapping to design assets in `docs/`.

Testing & CI
- Add `scripts/integration_smoke_test.py` that uses `requests` to talk to each API and asserts expected responses. Run locally via:
```
python scripts/integration_smoke_test.py --base-url http://127.0.0.1:5000/api
```
- Add a lightweight GitHub Actions workflow later to run the smoke test against the monolith or deployed preview.

Estimate & risk
- Small additions (docs + scripts): 1–2 hours. Low risk.
- AI helper consolidation adapter: 1–3 hours (including testing). Medium risk but reversible.
- Moving frontend files into `ui/components` barrels: 1–2 hours; ensure imports updated.

Next concrete step I can perform now (pick one):
- A. Create `docs/` and move `PHASES.md` there (non-destructive copy + README update). Recommended first step.
- B. Scaffold `scripts/integration_smoke_test.py` that runs the end-to-end flow against a running local instance.
- C. Implement the `ai_helpers.py` adapter and wire `services/recommendation-service` to use it (requires running tests).

Tell me which option to run next and I'll implement it.
