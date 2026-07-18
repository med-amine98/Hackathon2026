"""
Authentication Service — user creation and authentication logic.

Note: UserCreateSchema is now defined in app.schemas.auth.
This module imports it from there; the local alias is kept for backward-compat.
"""
from sqlalchemy.orm import Session
from typing import Optional

from app.models.user import User
from app.core.security import get_password_hash, verify_password
from app.schemas.auth import UserCreate

# Backward-compatible alias
UserCreateSchema = UserCreate


class AuthService:
    """Handles user registration and authentication."""

    def __init__(self, db: Session):
        self.db = db

    def create_user(self, user_in: UserCreate) -> User:
        """Create a new user with a hashed password."""
        hashed_password = get_password_hash(user_in.password)
        db_user = User(
            email=user_in.email,
            hashed_password=hashed_password,
            first_name=user_in.first_name,
            last_name=user_in.last_name,
            phone=user_in.phone,
            is_active=True,
            is_verified=False,
        )
        self.db.add(db_user)
        self.db.commit()
        self.db.refresh(db_user)
        return db_user

    def authenticate_user(self, email: str, password: str) -> Optional[User]:
        """Verify credentials and return user if valid, else None."""
        user = self.db.query(User).filter(User.email == email).first()
        if not user:
            return None
        if not verify_password(password, user.hashed_password):
            return None
        return user
