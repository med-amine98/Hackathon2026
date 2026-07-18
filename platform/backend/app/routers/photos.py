import io
import uuid

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from app import exif_utils, models, schemas, storage
from app.config import PHASH_DUPLICATE_THRESHOLD
from app.database import get_db

router = APIRouter(prefix="/claims", tags=["photos"])


@router.post("/{claim_id}/photos", response_model=schemas.PhotoOut, status_code=201)
async def upload_photo(
    claim_id: str,
    vehicle_label: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    claim = db.get(models.Claim, claim_id)
    if not claim:
        raise HTTPException(404, "Claim not found")

    content = await file.read()
    if not content:
        raise HTTPException(422, "Empty file")

    meta = exif_utils.extract_datetime_and_gps(content)
    phash = exif_utils.compute_phash(content)

    # Duplicate/reuse check against every previously stored photo's hash.
    # Fine at MVP scale (linear scan); move to a proper nearest-neighbor
    # index (e.g. an LSH table) once claim volume makes this slow.
    duplicate_of_id = None
    if phash:
        for existing in db.query(models.Photo).filter(models.Photo.content_hash.isnot(None)).all():
            if exif_utils.hamming_distance(phash, existing.content_hash) <= PHASH_DUPLICATE_THRESHOLD:
                duplicate_of_id = existing.id
                break

    key = f"{claim_id}/{vehicle_label}/{uuid.uuid4()}.jpg"
    storage.ensure_bucket()
    storage.upload_bytes(key, content, content_type=file.content_type or "image/jpeg")

    photo = models.Photo(
        claim_id=claim_id,
        vehicle_label=vehicle_label,
        s3_key=key,
        content_hash=phash,
        exif_datetime=meta["datetime"],
        exif_gps_lat=meta["lat"],
        exif_gps_lng=meta["lng"],
        has_metadata=meta["has_metadata"],
        duplicate_of_photo_id=duplicate_of_id,
    )
    db.add(photo)
    db.commit()
    db.refresh(photo)

    # Kick off real YOLOv8 damage detection on this photo (app/worker.py) -
    # runs async on the Celery worker so the upload response doesn't wait on
    # model inference. Best-effort: if Redis/the worker isn't reachable, the
    # photo upload itself must still succeed - the AI Estimation panel just
    # stays empty for this claim until a retry, same failure mode every
    # other best-effort call site in this codebase already accepts.
    try:
        from app.worker import run_damage_assessment

        run_damage_assessment.delay(claim_id, photo.id)
    except Exception:
        pass

    return photo


@router.get("/{claim_id}/photos", response_model=list[schemas.PhotoOut])
def list_photos(claim_id: str, db: Session = Depends(get_db)):
    return db.query(models.Photo).filter_by(claim_id=claim_id).all()


@router.get("/{claim_id}/photos/{photo_id}/file")
def get_photo_file(claim_id: str, photo_id: str, db: Session = Depends(get_db)):
    """
    Serves the actual image bytes for one uploaded damage photo. Every
    photo up to now was write-only (upload_photo saves to MinIO, list_photos
    only returns metadata/s3_key, never the pixels) - nothing could ever
    display what a client actually photographed. This is what lets the
    AssureX agency portal (or anything else) put a real <img src=...> on a
    real damage photo instead of a placeholder - see assurex/backend/
    platform_claims.py, the only current caller.
    """
    photo = db.get(models.Photo, photo_id)
    if not photo or photo.claim_id != claim_id:
        raise HTTPException(404, "Photo not found")
    try:
        data, content_type = storage.download_bytes(photo.s3_key)
    except Exception:
        raise HTTPException(502, "Could not retrieve photo from storage")
    return StreamingResponse(io.BytesIO(data), media_type=content_type)
