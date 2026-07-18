from sqlalchemy import Column, Integer, String, DateTime, Text, JSON, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database.connection import Base

class Declaration(Base):
    __tablename__ = "declarations"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Informations du véhicule
    vehicle_make = Column(String(50), nullable=False)
    vehicle_model = Column(String(50), nullable=False)
    vehicle_year = Column(Integer)
    license_plate = Column(String(20))
    
    # Informations du conducteur
    driver_name = Column(String(100), nullable=False)
    driver_email = Column(String(100))
    driver_phone = Column(String(20))
    driver_age = Column(Integer)
    
    # Détails de l'accident
    accident_date = Column(String(20), nullable=False)
    accident_time = Column(String(10), nullable=False)
    accident_location = Column(String(200), nullable=False)
    accident_description = Column(Text, nullable=False)
    
    # Images (stockées comme URLs)
    images = Column(JSON, default=[])
    
    # Analyse IA
    analysis = Column(JSON, default={})
    
    # Statut
    status = Column(String(20), default="en_attente")
    
    # Dates
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # ✅ Relations - CORRIGÉ
    user = relationship("User", back_populates="declarations")

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "vehicle_make": self.vehicle_make,
            "vehicle_model": self.vehicle_model,
            "vehicle_year": self.vehicle_year,
            "license_plate": self.license_plate,
            "driver_name": self.driver_name,
            "driver_email": self.driver_email,
            "driver_phone": self.driver_phone,
            "driver_age": self.driver_age,
            "accident_date": self.accident_date,
            "accident_time": self.accident_time,
            "accident_location": self.accident_location,
            "accident_description": self.accident_description,
            "images": self.images,
            "analysis": self.analysis,
            "status": self.status,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }