"""
Profile Schemas — Pydantic models for user profile requests/responses.
"""
from pydantic import BaseModel
from typing import Optional, List


class ProfileSchema(BaseModel):
    """Schema for updating a user profile."""
    age: Optional[int] = None
    city: Optional[str] = None
    occupation: Optional[str] = None
    marital_status: Optional[str] = None

    # Vehicle info
    vehicle_make: Optional[str] = None
    vehicle_model: Optional[str] = None
    vehicle_year: Optional[int] = None
    vehicle_usage: Optional[str] = None  # daily, weekend, occasional

    # Driving info
    annual_km: Optional[int] = None
    driving_experience_years: Optional[int] = None
    parking_type: Optional[str] = None  # garage, street, private

    # Insurance preferences
    budget_monthly: Optional[float] = None
    preferred_coverage: Optional[List[str]] = None
    has_previous_insurance: Optional[bool] = None
    previous_insurer: Optional[str] = None


class ProfileResponse(ProfileSchema):
    """Schema for profile data returned to client (includes computed fields)."""
    id: int
    user_id: int
    risk_score: Optional[float] = None
    risk_factors: Optional[List[str]] = None

    class Config:
        from_attributes = True
