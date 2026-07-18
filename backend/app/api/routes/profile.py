"""
Profile routes — retrieve and update the authenticated user's insurance profile.
Uses schemas from app.schemas.profile (clean separation of concerns).
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.api.dependencies import get_current_user
from app.schemas.profile import ProfileSchema, ProfileResponse
from app.services.profile_service import ProfileService
from app.models.user import User

router = APIRouter(prefix="/profile", tags=["Profile"])


@router.get("", response_model=ProfileResponse)
def get_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get the authenticated user's insurance profile."""
    profile_service = ProfileService(db)
    return profile_service.get_or_create_profile(current_user.id)


@router.put("", response_model=ProfileResponse)
def update_profile(
    profile_data: ProfileSchema,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Update the authenticated user's insurance profile."""
    profile_service = ProfileService(db)
    profile = profile_service.get_or_create_profile(current_user.id)

    # Apply only the provided fields
    for field, value in profile_data.model_dump(exclude_unset=True).items():
        setattr(profile, field, value)

    db.commit()
    db.refresh(profile)
    return profile
