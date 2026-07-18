from sqlalchemy import Column, Integer, String, Float, Boolean, JSON, DateTime
from sqlalchemy.sql import func
from app.database.connection import Base

class InsuranceProduct(Base):
    __tablename__ = "insurance_products"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    provider = Column(String, nullable=False)
    category = Column(String, nullable=False)  # auto, home, health, life
    
    # Coverage details
    coverage_amount = Column(Float)
    deductible = Column(Float)
    monthly_premium = Column(Float)
    
    # Features
    features = Column(JSON)  # ["theft", "collision", "legal_help"]
    coverage_details = Column(JSON)  # Detailed coverage info
    
    # Eligibility
    min_age = Column(Integer)
    max_age = Column(Integer)
    vehicle_requirements = Column(JSON)  # {"max_age": 10, "usage": "daily"}
    
    # Rating
    rating = Column(Float)
    reviews_count = Column(Integer)
    
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
