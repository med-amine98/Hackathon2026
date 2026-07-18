"""
Recommendation Schemas — Pydantic models for recommendation responses.
"""
from pydantic import BaseModel


class RecommendationResponse(BaseModel):
    """Schema for a saved recommendation with product details."""
    id: int
    user_id: int
    product_id: int
    match_score: float
    is_accepted: bool
    product_name: str
    product_provider: str
    monthly_premium: float

    class Config:
        from_attributes = True
