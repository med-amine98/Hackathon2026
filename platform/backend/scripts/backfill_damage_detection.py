"""
Batch job: walks every Photo row already in the database, downloads its
bytes from MinIO, and runs it through the exact same detection pipeline as
the live per-upload flow (app/worker.py's run_damage_assessment) — the
CarDD-trained YOLO11 checkpoint (app/weights/car_damage_yolo11.pt) when
present, the OpenCV heuristic fallback otherwise (see
app/damage_detection.py's module docstring). Nothing here duplicates the
detection/estimation logic; it just drives run_damage_assessment (in-process,
synchronously — Celery task objects are plain callables, no broker needed)
over every stored photo instead of only new uploads.

Use this to:
  - backfill DamageEstimate rows for every photo that was uploaded before
    the trained checkpoint (best.pt) was dropped into app/weights/, so
    every existing claim/photo in the database + MinIO gets a real,
    model-derived estimate instead of staying empty forever;
  - re-run every photo through a newly retrained/updated checkpoint.

Usage (from platform/backend/, with the same env as the api/worker
containers so DATABASE_URL/MINIO_* resolve to the real Postgres/MinIO):

    python -m scripts.backfill_damage_detection
        Only claims that don't have a DamageEstimate yet (first-time backfill).

    python -m scripts.backfill_damage_detection --force
        Re-run every claim's photos from scratch (deletes and rebuilds each
        claim's DamageEstimate), e.g. after retraining the model.

    python -m scripts.backfill_damage_detection --claim-id CLM-123
        Limit to one claim (useful for spot-checking after a model update).
"""
import argparse

from app import models
from app.database import SessionLocal
from app.worker import run_damage_assessment


def _claims_to_process(db, claim_id: str | None):
    query = db.query(models.Claim)
    if claim_id:
        query = query.filter_by(id=claim_id)
    return query.order_by(models.Claim.created_at).all()


def main(force: bool, claim_id: str | None) -> None:
    with SessionLocal() as db:
        claims = _claims_to_process(db, claim_id)
        if not claims:
            print("No matching claim(s) found.")
            return

        total_claims = len(claims)
        processed_photos = 0
        failed_photos = 0
        skipped_claims = 0
        claims_with_no_photos = 0

        for i, claim in enumerate(claims, 1):
            photos = (
                db.query(models.Photo)
                .filter_by(claim_id=claim.id)
                .order_by(models.Photo.uploaded_at)
                .all()
            )
            if not photos:
                claims_with_no_photos += 1
                continue

            existing = db.query(models.DamageEstimate).filter_by(claim_id=claim.id).first()
            if existing and not force:
                skipped_claims += 1
                continue

            if existing and force:
                db.delete(existing)
                db.commit()

            print(f"[{i}/{total_claims}] Claim {claim.id} — analyse de {len(photos)} photo(s)...")
            for photo in photos:
                result = run_damage_assessment(claim.id, photo.id)
                status = result.get("status")
                if status == "ok":
                    processed_photos += 1
                    print(f"    photo {photo.id}: ok — {result.get('detections', 0)} detection(s)")
                else:
                    failed_photos += 1
                    print(f"    photo {photo.id}: {status}")

        print(
            f"\nTermine. {processed_photos} photo(s) analysee(s) avec succes, "
            f"{failed_photos} echec(s) (MinIO/telechargement), sur "
            f"{total_claims - skipped_claims - claims_with_no_photos} claim(s) traite(s). "
            f"{skipped_claims} claim(s) avaient deja une estimation et ont ete ignores "
            f"(utilisez --force pour les refaire) ; {claims_with_no_photos} claim(s) sans photo."
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        "--force",
        action="store_true",
        help="Re-run detection for claims that already have a DamageEstimate (deletes and rebuilds it).",
    )
    parser.add_argument(
        "--claim-id",
        default=None,
        help="Only process this one claim id, instead of every claim in the database.",
    )
    args = parser.parse_args()
    main(force=args.force, claim_id=args.claim_id)
