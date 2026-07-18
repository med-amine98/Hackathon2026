from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, JSON, Boolean
from sqlalchemy.sql import func
from app.database.connection import Base

class UserProfile(Base):
    __tablename__ = "user_profiles"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Personal info
    age = Column(Integer)
    city = Column(String)
    occupation = Column(String)
    marital_status = Column(String)
    
    # Vehicle info
    vehicle_make = Column(String)
    vehicle_model = Column(String)
    vehicle_year = Column(Integer)
    vehicle_usage = Column(String)  # daily, weekend, occasional
    
    # Driving info
    annual_km = Column(Integer)
    driving_experience_years = Column(Integer)
    parking_type = Column(String)  # garage, street, private
    
    # Insurance preferences
    budget_monthly = Column(Float)
    preferred_coverage = Column(JSON)  # ["theft", "collision", "liability"]
    has_previous_insurance = Column(Boolean, default=False)
    previous_insurer = Column(String)
    
    # Risk assessment
    risk_score = Column(Float)
    risk_factors = Column(JSON)  # List of risk factors
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
