"""
Authentication Schemas — Pydantic models for auth requests/responses.
Moved here from auth_service.py to follow clean architecture separation.
"""
from pydantic import BaseModel, EmailStr, Field
from typing import Optional


# ─── Request Schemas ──────────────────────────────────────────────────────────

class UserCreate(BaseModel):
    """Schema for user registration request."""
    email: EmailStr
    password: str = Field(..., min_length=8, description="Minimum 8 characters")
    first_name: str = Field(..., min_length=1)
    last_name: str = Field(..., min_length=1)
    phone: Optional[str] = None


class LoginRequest(BaseModel):
    """Schema for standard JSON login (not OAuth2 form)."""
    email: EmailStr
    password: str


# ─── Response Schemas ─────────────────────────────────────────────────────────

class UserResponse(BaseModel):
    """Schema for user data returned to client."""
    id: int
    email: str
    first_name: str
    last_name: str
    phone: Optional[str] = None
    is_active: bool
    is_verified: bool

    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    """Schema for JWT token response."""
    access_token: str
    token_type: str = "bearer"
    user_id: int
    email: str


# Keep backward-compatible alias
UserCreateSchema = UserCreate
