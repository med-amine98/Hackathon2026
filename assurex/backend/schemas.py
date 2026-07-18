from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

# Claim Schemas
class ClaimBase(BaseModel):
    vehicle: str
    vehicle_type: str
    gravity: str
    risk: int
    agent_initials: Optional[str] = "AX"
    time_left: Optional[str] = "3h left"

class ClaimCreate(ClaimBase):
    pass

class ClaimResponse(ClaimBase):
    id: int
    status: str
    created_at: datetime
    updated_at: Optional[datetime]
    
    class Config:
        from_attributes = True

class ClaimUpdateStatus(BaseModel):
    status: str

# User Schemas
class UserBase(BaseModel):
    email: EmailStr
    username: str
    full_name: Optional[str] = None

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(UserBase):
    id: int
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse

class TokenData(BaseModel):
    email: Optional[str] = None

# Note Schema
class NoteCreate(BaseModel):
    text: str
    author: Optional[str] = "Alex (Agent)"