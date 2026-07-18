from sqlalchemy import Column, Integer, String, DateTime, JSON, ForeignKey, Text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database.connection import Base

class Prevention(Base):
    __tablename__ = "preventions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)

    # Données météo
    weather_data = Column(JSON, default=dict)

    # Données trafic
    traffic_data = Column(JSON, default=list)

    # Rappels maintenance
    maintenances = Column(JSON, default=list)

    # Conseils sécurité
    safety_tips = Column(JSON, default=list)

    # Alertes
    alerts = Column(JSON, default=list)
    
    # Dates
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # ✅ Relations - CORRIGÉ
    user = relationship("User", back_populates="preventions")

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "weather_data": self.weather_data,
            "traffic_data": self.traffic_data,
            "maintenances": self.maintenances,
            "safety_tips": self.safety_tips,
            "alerts": self.alerts,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }