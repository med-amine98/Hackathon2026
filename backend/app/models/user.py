from sqlalchemy import Column, Integer, String, DateTime, Boolean
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database.connection import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    first_name = Column(String)
    last_name = Column(String)
    phone = Column(String)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)

    # Client identity/vehicle/policy info, requested for the AssureX agency
    # portal's client list (see assurex/backend/mobile_clients.py — that's
    # the only current reader of these). None of this existed anywhere in
    # the database before; these are real new columns, not a bridge to
    # pre-existing data. See app/database/migrate.py for why a fresh
    # ADD COLUMN is needed even on an already-deployed `users` table.
    cin = Column(String(20), index=True, nullable=True)  # Tunisian national ID card number
    plate_number = Column(String(20), nullable=True)  # immatriculation
    car_category = Column(String(50), nullable=True)  # e.g. Citadine, Berline, SUV, Utilitaire
    insurance_date = Column(DateTime(timezone=True), nullable=True)  # policy start/renewal date
    payment_status = Column(String(20), default="unpaid")  # "paid" / "unpaid"

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # ✅ Relations
    declarations = relationship("Declaration", back_populates="user", lazy="dynamic")
    conseils = relationship("Conseil", back_populates="user", lazy="dynamic")
    preventions = relationship("Prevention", back_populates="user", lazy="dynamic")

    def to_dict(self):
        return {
            "id": self.id,
            "email": self.email,
            "first_name": self.first_name,
            "last_name": self.last_name,
            "phone": self.phone,
            "is_active": self.is_active,
            "is_verified": self.is_verified,
            "cin": self.cin,
            "plate_number": self.plate_number,
            "car_category": self.car_category,
            "insurance_date": self.insurance_date.isoformat() if self.insurance_date else None,
            "payment_status": self.payment_status,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }