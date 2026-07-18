"""
Product Schemas — Pydantic models for insurance product requests/responses.
"""
from pydantic import BaseModel
from typing import Optional, List, Dict, Any


class ProductSchema(BaseModel):
    """Schema for an insurance product."""
    id: int
    name: str
    provider: str
    category: str
    coverage_amount: float
    deductible: float
    monthly_premium: float
    features: Optional[List[str]] = []
    coverage_details: Optional[Dict[str, Any]] = None
    min_age: Optional[int] = None
    max_age: Optional[int] = None
    rating: Optional[float] = None
    reviews_count: Optional[int] = None
    is_active: bool = True

    class Config:
        from_attributes = True


class ProductListResponse(BaseModel):
    """Paginated list of products."""
    items: List[ProductSchema]
    total: int
