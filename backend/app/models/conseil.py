from sqlalchemy import Column, Integer, String, DateTime, Float, JSON, ForeignKey, Text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database.connection import Base

class Conseil(Base):
    __tablename__ = "conseils"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    
    # Profil utilisateur
    age = Column(Integer)
    experience_years = Column(Integer)
    city = Column(String(50))
    
    # Véhicule
    vehicle_make = Column(String(50))
    vehicle_model = Column(String(50))
    vehicle_year = Column(Integer)
    annual_km = Column(Integer)
    usage = Column(String(20))
    
    # Analyse
    risk_score = Column(Float)
    risk_analysis = Column(Text)
    ia_advice = Column(Text)
    garanties = Column(JSON, default=list)
    
    # Dates
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # ✅ Relations - CORRIGÉ
    user = relationship("User", back_populates="conseils")

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "age": self.age,
            "experience_years": self.experience_years,
            "city": self.city,
            "vehicle_make": self.vehicle_make,
            "vehicle_model": self.vehicle_model,
            "vehicle_year": self.vehicle_year,
            "annual_km": self.annual_km,
            "usage": self.usage,
            "risk_score": self.risk_score,
            "risk_analysis": self.risk_analysis,
            "ia_advice": self.ia_advice,
            "garanties": self.garanties,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }