from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import fault_engine, models, schemas
from app.database import get_db

router = APIRouter(prefix="/claims", tags=["fault"])


def _to_engine_declaration(row: models.VehicleDeclaration) -> fault_engine.VehicleDeclaration:
    circumstances = set()
    for code in row.circumstances or []:
        try:
            circumstances.add(fault_engine.Circumstance(code))
        except ValueError:
            continue  # unknown/legacy code — ignore rather than crash the engine

    impact_zones = set()
    for code in row.impact_zones or []:
        try:
            impact_zones.add(fault_engine.ImpactZone(code))
        except ValueError:
            continue

    return fault_engine.VehicleDeclaration(
        vehicle_id=row.vehicle_label,
        circumstances=circumstances,
        impact_zones=impact_zones,
    )


@router.post("/{claim_id}/determine-fault", response_model=schemas.FaultOut)
def determine_fault(claim_id: str, db: Session = Depends(get_db)):
    claim = db.get(models.Claim, claim_id)
    if not claim:
        raise HTTPException(404, "Claim not found")

    declarations = {
        v.vehicle_label: v
        for v in db.query(models.VehicleDeclaration).filter_by(claim_id=claim_id).all()
    }
    if "A" not in declarations or "B" not in declarations:
        raise HTTPException(409, "Both vehicle A and B declarations are required before fault can be determined")

    vehicle_a = _to_engine_declaration(declarations["A"])
    vehicle_b = _to_engine_declaration(declarations["B"])
    result = fault_engine.determine_fault(vehicle_a, vehicle_b)

    existing = db.query(models.FaultDetermination).filter_by(claim_id=claim_id).first()
    if existing:
        existing.fault_a_pct = result.fault_a_pct
        existing.fault_b_pct = result.fault_b_pct
        existing.rule_id = result.rule_id
        existing.explanation = result.explanation
        existing.needs_manual_review = result.needs_manual_review
        record = existing
    else:
        record = models.FaultDetermination(
            claim_id=claim_id,
            fault_a_pct=result.fault_a_pct,
            fault_b_pct=result.fault_b_pct,
            rule_id=result.rule_id,
            explanation=result.explanation,
            needs_manual_review=result.needs_manual_review,
        )
        db.add(record)

    claim.status = "needs_review" if result.needs_manual_review else "fault_determined"
    db.commit()
    db.refresh(record)
    return record


@router.get("/{claim_id}/fault", response_model=schemas.FaultOut)
def get_fault(claim_id: str, db: Session = Depends(get_db)):
    record = db.query(models.FaultDetermination).filter_by(claim_id=claim_id).first()
    if not record:
        raise HTTPException(404, "Fault has not been determined for this claim yet")
    return record
