"""
Recommendation routes — list and accept AI-generated product recommendations.
Uses schemas from app.schemas.recommendation (clean separation of concerns).
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.database.connection import get_db
from app.api.dependencies import get_current_user
from app.schemas.recommendation import RecommendationResponse
from app.models.user import User
from app.models.recommendation import Recommendation
from app.models.product import InsuranceProduct

router = APIRouter(prefix="/recommendations", tags=["Recommendations"])


def _build_response(rec: Recommendation, db: Session) -> dict:
    """Helper: join recommendation with its product and build response dict."""
    prod = db.query(InsuranceProduct).filter(InsuranceProduct.id == rec.product_id).first()
    return {
        "id": rec.id,
        "user_id": rec.user_id,
        "product_id": rec.product_id,
        "match_score": rec.match_score,
        "is_accepted": rec.is_accepted,
        "product_name": prod.name if prod else "Unknown Product",
        "product_provider": prod.provider if prod else "Unknown Provider",
        "monthly_premium": prod.monthly_premium if prod else 0.0,
    }


@router.get("", response_model=List[RecommendationResponse])
def get_user_recommendations(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List all AI-generated recommendations for the authenticated user."""
    recs = db.query(Recommendation).filter(Recommendation.user_id == current_user.id).all()
    return [_build_response(r, db) for r in recs]


@router.post("/{rec_id}/accept", response_model=RecommendationResponse)
def accept_recommendation(
    rec_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Mark a recommendation as accepted by the user."""
    rec = db.query(Recommendation).filter(
        Recommendation.id == rec_id,
        Recommendation.user_id == current_user.id,
    ).first()

    if not rec:
        raise HTTPException(status_code=404, detail="Recommendation not found")

    rec.is_accepted = True
    db.commit()
    db.refresh(rec)

    return _build_response(rec, db)
