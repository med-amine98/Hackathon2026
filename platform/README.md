# Smart Constat — Platform

Backend platform for the Tunisian smart-constat app: digitized constat data model, a deterministic fault-determination engine, and the scaffolding (storage + async worker) that damage-assessment CV and fraud-detection jobs will plug into next. Legal context: FTUSA Convention IDA (direct-indemnification agreement between Tunisian insurers).

## What's here

This directory's own `docker-compose.yml` is deprecated — the one at the repo root (`Hackathon2026/docker-compose.yml`) is the single source of truth for the whole stack (Postgres, Redis, MinIO, this service's `api`/`worker`, the mobile backend `mobile-api`, and the AssureX agency portal `assurex-api`/`assurex-frontend`), all sharing one Postgres instance in separate schemas. This file is kept only as a reference for the platform-only service definitions. `backend/app/fault_engine.py` is the rules engine — deterministic, not ML, per the IDA convention's requirement that fault be decided strictly from direction/position/impact-point data. `backend/app/main.py` wires up the API; `backend/app/models.py` has the data model (Claim, VehicleDeclaration, Photo, FaultDetermination, Conversation, Message).

The agent's chat has no standalone UI of its own anymore — it's reached through `POST /chat/message` directly, and in practice through the Flutter app's floating chat bubble (`frontend/flutter_app`), which calls that same endpoint.

## Running it

Run it as part of the full stack from the repo root — see the root [README.md](../README.md) for the `.env` variables and the `docker compose up --build` command. This service comes up on `http://localhost:8010` (interactive docs at `/docs`), MinIO console on `http://localhost:9003`, the mobile backend on `http://localhost:8001`.

To run this service alone, outside Docker, see "Option B" in the root README — create a `.env` in this directory with the Postgres/Redis/MinIO/LLM variables documented there (pointing at `localhost` instead of Docker service names), then `uvicorn app.main:app --reload --port 8000`.

## Trying it end-to-end

```bash
# 1. create a claim
curl -X POST localhost:8010/claims -H 'content-type: application/json' \
  -d '{"location_text": "Avenue Habib Bourguiba, Tunis"}'
# → {"id": "<claim_id>", "status": "draft", ...}

# 2. both drivers declare their circumstances (letters match the constat checkboxes)
curl -X POST localhost:8010/claims/<claim_id>/vehicles -H 'content-type: application/json' \
  -d '{"vehicle_label": "A", "circumstances": ["h"], "impact_zones": ["front"]}'
curl -X POST localhost:8010/claims/<claim_id>/vehicles -H 'content-type: application/json' \
  -d '{"vehicle_label": "B", "circumstances": ["a"], "impact_zones": ["rear"]}'

# 3. run the fault engine
curl -X POST localhost:8010/claims/<claim_id>/determine-fault
# → {"fault_a_pct": 100, "fault_b_pct": 0, "rule_id": "rear_end", ...}

# 4. upload a photo (camera-only capture is a client-side rule; this endpoint
#    just accepts whatever bytes it's given and computes forensic metadata)
curl -X POST localhost:8010/claims/<claim_id>/photos \
  -F "vehicle_label=A" -F "file=@/path/to/photo.jpg"
```

(Running the service standalone on port 8000 instead of through the root Docker stack? Swap `8010` for `8000` in the calls above.)

## What's tested vs. what isn't yet

The claims/vehicles/fault-determination flow was smoke-tested directly (in-process, sqlite) covering: claim creation, both-parties-declared status transition, the rear-end rule firing 100/0, the unmatched-scenario fallback correctly flagging `needs_manual_review`, 404s on unknown claims, and the 409 guard when fault is requested before both parties have declared. Docker Compose itself (the actual multi-container startup, Postgres/MinIO connectivity, the Celery worker) has **not** been run — this build environment doesn't have a Docker daemon. Run `docker compose up --build` on your machine and hit `/health` and `/docs` as the first check.

## What's stubbed, on purpose

`backend/app/worker.py` has two Celery task placeholders — `run_damage_assessment` and `run_fraud_scan` — that return `"not_implemented"`. They exist so the async plumbing (queue, worker container, task routing) is already in place; wiring in a real CV model and the photo-forensics checks (perceptual-hash duplicate detection is already implemented in `exif_utils.py`, just not yet called from a task) is the next phase. Note the trained YOLO11/CarDD damage-detection checkpoint is already wired in separately via `CAR_DAMAGE_MODEL_PATH` (see root README) — it's the fraud/duplicate-detection side that's still stubbed here.

## Before this handles real claims

Replace the placeholder percentages in `fault_engine.py` with the actual FTUSA barème (see the caveat at the top of that file — it's flagged deliberately). Swap `Base.metadata.create_all()` in `main.py` for real Alembic migrations. Tighten CORS (`main.py` currently allows `*`). Move secrets out of `.env` into a real secrets manager before deploying anywhere but your laptop.
