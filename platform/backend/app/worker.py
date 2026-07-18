"""
Celery worker skeleton for the async jobs the architecture plan calls for:
damage assessment (CV) and photo forensics / fraud scoring. Both tasks are
deliberately stubbed — wiring them up to real models is the next phase
(see ARCHITECTURE.md, "Suggested build order", steps 4-5). What matters for
the platform right now is that claims/photos flow through a queue instead
of blocking the request thread, so swapping in real logic later doesn't
require touching the API layer.
"""
from celery import Celery

from app.config import REDIS_URL

celery_app = Celery("constat_worker", broker=REDIS_URL, backend=REDIS_URL)


@celery_app.task(name="run_damage_assessment")
def run_damage_assessment(claim_id: str, photo_id: str) -> dict:
    # TODO: load photo from MinIO, run damage-detection model, persist results.
    return {"claim_id": claim_id, "photo_id": photo_id, "status": "not_implemented"}


@celery_app.task(name="run_fraud_scan")
def run_fraud_scan(claim_id: str, photo_id: str) -> dict:
    # TODO: ELA / noise-residual analysis, synthetic-image detection,
    # weather-API cross-check against claimed time/location.
    return {"claim_id": claim_id, "photo_id": photo_id, "status": "not_implemented"}
