from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.config import IDA_DAMAGE_CAP_TND
from app.database import get_db

router = APIRouter(prefix="/claims", tags=["claims"])


@router.post("", response_model=schemas.ClaimOut, status_code=201)
def create_claim(payload: schemas.ClaimCreate, db: Session = Depends(get_db)):
    claim = models.Claim(**payload.model_dump())
    db.add(claim)
    db.commit()
    db.refresh(claim)
    return claim


@router.get("/{claim_id}", response_model=schemas.ClaimOut)
def get_claim(claim_id: str, db: Session = Depends(get_db)):
    claim = db.get(models.Claim, claim_id)
    if not claim:
        raise HTTPException(404, "Claim not found")
    return claim


@router.post("/{claim_id}/vehicles", response_model=schemas.VehicleDeclarationOut, status_code=201)
def upsert_vehicle_declaration(claim_id: str, payload: schemas.VehicleDeclarationIn, db: Session = Depends(get_db)):
    claim = db.get(models.Claim, claim_id)
    if not claim:
        raise HTTPException(404, "Claim not found")
    if payload.vehicle_label not in ("A", "B"):
        raise HTTPException(422, "vehicle_label must be 'A' or 'B'")

    existing = (
        db.query(models.VehicleDeclaration)
        .filter_by(claim_id=claim_id, vehicle_label=payload.vehicle_label)
        .first()
    )
    if existing:
        for field, value in payload.model_dump().items():
            setattr(existing, field, value)
        vehicle = existing
    else:
        vehicle = models.VehicleDeclaration(claim_id=claim_id, **payload.model_dump())
        db.add(vehicle)

    db.commit()
    db.refresh(vehicle)

    # Once both parties have declared, move the claim out of draft status.
    declared_labels = {
        v.vehicle_label
        for v in db.query(models.VehicleDeclaration).filter_by(claim_id=claim_id).all()
    }
    if {"A", "B"}.issubset(declared_labels) and claim.status == "draft":
        claim.status = "both_declared"
        db.commit()

    return vehicle


@router.get("/{claim_id}/vehicles", response_model=list[schemas.VehicleDeclarationOut])
def list_vehicle_declarations(claim_id: str, db: Session = Depends(get_db)):
    return db.query(models.VehicleDeclaration).filter_by(claim_id=claim_id).all()
