"""
Celery worker for the async jobs the architecture plan calls for: damage
assessment (CV) and photo forensics / fraud scoring. Claims/photos flow
through a queue instead of blocking the upload request thread, so this can
take a couple of seconds (YOLOv8 inference) without the client waiting on it
— see app/routers/photos.py's upload_photo, which enqueues
run_damage_assessment right after a photo is saved to MinIO.

run_fraud_scan is still a stub (see ARCHITECTURE.md, "Suggested build
order", step 5) — out of scope for the damage-estimation pass.
"""
from celery import Celery

from app.config import REDIS_URL
from app.damage_detection import detect_damage, estimate_repair
from app.database import SessionLocal
from app import models, storage

celery_app = Celery("constat_worker", broker=REDIS_URL, backend=REDIS_URL)


def _vehicle_make_model_for_claim(db, claim_id: str, vehicle_label: str | None) -> str | None:
    """
    Best-effort lookup of what the client actually declared as their car's
    make/model (ClientProfile.vehicle_make_model), via whichever conversation
    is linked to this claim. Used to pick a cost tier (economique/standard/
    premium) in damage_detection.estimate_repair — falls back to "standard"
    pricing if nothing was ever collected (e.g. photo uploaded before the
    vehicle make/model question was answered).
    """
    convo = db.query(models.Conversation).filter_by(claim_id=claim_id).first()
    if not convo:
        return None
    query = db.query(models.ClientProfile).filter_by(conversation_id=convo.id)
    if vehicle_label:
        query = query.filter_by(vehicle_label=vehicle_label)
    profile = query.first()
    return profile.vehicle_make_model if profile else None


@celery_app.task(name="run_damage_assessment")
def run_damage_assessment(claim_id: str, photo_id: str) -> dict:
    """
    Downloads one uploaded photo, runs YOLOv8 (or the OpenCV fallback — see
    app/damage_detection.py) damage detection on it, and merges the result
    into this claim's single DamageEstimate row: new hotspots from this
    photo are appended to whatever earlier photos already contributed,
    subtotal/total/damage_percent are recomputed over the combined set, and
    photos_analyzed is incremented — so opening the AI Estimation panel
    after 3 photos shows all 3 photos' findings together, not just the last
    one's.
    """
    with SessionLocal() as db:
        photo = db.get(models.Photo, photo_id)
        claim = db.get(models.Claim, claim_id)
        if not photo or not claim:
            return {"claim_id": claim_id, "photo_id": photo_id, "status": "not_found"}

        try:
            image_bytes, _content_type = storage.download_bytes(photo.s3_key)
        except Exception as exc:
            return {"claim_id": claim_id, "photo_id": photo_id, "status": f"download_failed: {exc}"}

        vehicle_make_model = _vehicle_make_model_for_claim(db, claim_id, photo.vehicle_label)
        detections = detect_damage(image_bytes)
        result = estimate_repair(detections, vehicle_make_model=vehicle_make_model)

        estimate = db.query(models.DamageEstimate).filter_by(claim_id=claim_id).first()
        if estimate is None:
            estimate = models.DamageEstimate(claim_id=claim_id)
            db.add(estimate)
            existing_hotspots = []
        else:
            existing_hotspots = list(estimate.hotspots or [])

        # Re-number this photo's new hotspot ids so they don't collide with
        # ones already recorded from earlier photos on the same claim.
        offset = len(existing_hotspots)
        for i, h in enumerate(result["hotspots"]):
            h["id"] = f"hs-{offset + i + 1}"
        combined_hotspots = existing_hotspots + result["hotspots"]

        estimate.hotspots = combined_hotspots
        estimate.subtotal = round(sum(h["cost"] for h in combined_hotspots), 2)
        labor = 60.0 if combined_hotspots else 0.0
        estimate.total = round(estimate.subtotal + labor, 2)
        # Take the worst (highest) damage_percent reading seen across all
        # photos analyzed so far for this claim, rather than averaging —
        # one photo clearly showing severe damage shouldn't get diluted
        # just because another photo was a calmer angle of the same car.
        estimate.damage_percent = max(estimate.damage_percent or 0, result["damage_percent"])
        estimate.insights = result["insights"]
        estimate.vehicle_make_model = vehicle_make_model or estimate.vehicle_make_model
        estimate.vehicle_tier = result["vehicle_tier"]
        estimate.photos_analyzed = (estimate.photos_analyzed or 0) + 1

        db.commit()

        return {
            "claim_id": claim_id,
            "photo_id": photo_id,
            "status": "ok",
            "detections": len(result["hotspots"]),
        }


@celery_app.task(name="run_fraud_scan")
def run_fraud_scan(claim_id: str, photo_id: str) -> dict:
    # TODO: ELA / noise-residual analysis, synthetic-image detection,
    # weather-API cross-check against claimed time/location.
    return {"claim_id": claim_id, "photo_id": photo_id, "status": "not_implemented"}
