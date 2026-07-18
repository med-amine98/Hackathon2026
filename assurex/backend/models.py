from sqlalchemy import Column, Integer, String, DateTime, Boolean, Float, JSON
from sqlalchemy.sql import func
from database import Base

class Claim(Base):
    __tablename__ = "claims"
    
    id = Column(Integer, primary_key=True, index=True)
    vehicle = Column(String)
    vehicle_type = Column(String)
    gravity = Column(String)
    risk = Column(Integer)
    status = Column(String, default="new")
    agent_initials = Column(String, default="AX")
    time_left = Column(String, default="3h left")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())