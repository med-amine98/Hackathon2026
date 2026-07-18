# Smart Constat — Platform

Backend platform for the Tunisian smart-constat app: digitized constat data model, a deterministic fault-determination engine, and the scaffolding (storage + async worker) that damage-assessment CV and fraud-detection jobs will plug into next. See `../ARCHITECTURE.md` for the full technical plan and legal context (FTUSA Convention IDA).

## What's here

This directory's own `docker-compose.yml` is superseded by the one at `/home/saoussen/insurance/docker-compose.yml` — that root one adds a sixth service (`mobile-api`, the separate mobile-app backend in `../backend/`, sharing this same Postgres database in its own schema — see the root README) and is the one to actually run. This file is kept only as a reference for the platform-only service definitions. Six services in the root compose: Postgres (claims + chat data), Redis (job queue), MinIO (S3-compatible photo storage), the FastAPI `api` (claims/fault endpoints AND the agent's conversational accident-intake chat at `POST /chat/message`), a Celery `worker` for async jobs, and `mobile-api`. `backend/app/fault_engine.py` is the rules engine — deterministic, not ML, per the IDA convention's requirement that fault be decided strictly from direction/position/impact-point data. `backend/app/main.py` wires up the API; `backend/app/models.py` has the data model (Claim, VehicleDeclaration, Photo, FaultDetermination, Conversation, Message).

The agent's chat has no standalone UI of its own anymore — it's reached through `POST /chat/message` directly, and in practice through the Flutter app's floating chat bubble (`frontend/flutter_app`), which calls that same endpoint.

## Running it

```
cd /home/saoussen/insurance
cp .env.example .env        # then edit passwords, add LLM_API_KEY (free at aistudio.google.com/apikey) for the agent chat
docker compose up --build
```

API comes up on `http://localhost:8000` (interactive docs at `/docs`), MinIO console on `http://localhost:9001`, the mobile backend on `http://localhost:8001`.

## Trying it end-to-end

```bash
# 1. create a claim
curl -X POST localhost:8000/claims -H 'content-type: application/json' \
  -d '{"location_text": "Avenue Habib Bourguiba, Tunis"}'
# → {"id": "<claim_id>", "status": "draft", ...}

# 2. both drivers declare their circumstances (letters match the constat checkboxes)
curl -X POST localhost:8000/claims/<claim_id>/vehicles -H 'content-type: application/json' \
  -d '{"vehicle_label": "A", "circumstances": ["h"], "impact_zones": ["front"]}'
curl -X POST localhost:8000/claims/<claim_id>/vehicles -H 'content-type: application/json' \
  -d '{"vehicle_label": "B", "circumstances": ["a"], "impact_zones": ["rear"]}'

# 3. run the fault engine
curl -X POST localhost:8000/claims/<claim_id>/determine-fault
# → {"fault_a_pct": 100, "fault_b_pct": 0, "rule_id": "rear_end", ...}

# 4. upload a photo (camera-only capture is a client-side rule; this endpoint
#    just accepts whatever bytes it's given and computes forensic metadata)
curl -X POST localhost:8000/claims/<claim_id>/photos \
  -F "vehicle_label=A" -F "file=@/path/to/photo.jpg"
```

## What's tested vs. what isn't yet

The claims/vehicles/fault-determination flow was smoke-tested directly (in-process, sqlite) covering: claim creation, both-parties-declared status transition, the rear-end rule firing 100/0, the unmatched-scenario fallback correctly flagging `needs_manual_review`, 404s on unknown claims, and the 409 guard when fault is requested before both parties have declared. Docker Compose itself (the actual multi-container startup, Postgres/MinIO connectivity, the Celery worker) has **not** been run — this build environment doesn't have a Docker daemon. Run `docker compose up --build` on your machine and hit `/health` and `/docs` as the first check.

## What's stubbed, on purpose

`backend/app/worker.py` has two Celery task placeholders — `run_damage_assessment` and `run_fraud_scan` — that return `"not_implemented"`. They exist so the async plumbing (queue, worker container, task routing) is already in place; wiring in a real CV model and the photo-forensics checks (perceptual-hash duplicate detection is already implemented in `exif_utils.py`, just not yet called from a task) is the next phase per `ARCHITECTURE.md`.

## Before this handles real claims

Replace the placeholder percentages in `fault_engine.py` with the actual FTUSA barème (see the caveat at the top of that file — it's flagged deliberately). Swap `Base.metadata.create_all()` in `main.py` for real Alembic migrations. Tighten CORS (`main.py` currently allows `*`). Move secrets out of `.env` into a real secrets manager before deploying anywhere but your laptop.
