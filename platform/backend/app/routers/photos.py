import uuid

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
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
    return photo


@router.get("/{claim_id}/photos", response_model=list[schemas.PhotoOut])
def list_photos(claim_id: str, db: Session = Depends(get_db)):
    return db.query(models.Photo).filter_by(claim_id=claim_id).all()
