from sqlalchemy import Column, Integer, String, DateTime, Boolean, Float, JSON, Text
from sqlalchemy.sql import func
from database import Base

class Claim(Base):
    __tablename__ = "claims"

    # Business id used throughout the app/UI (e.g. "CLM-8291"), not an
    # autoincrement surrogate - the frontend already treats it as the
    # lookup key everywhere (/api/claims/{claim_id}, etc.).
    id = Column(String, primary_key=True, index=True)
    type = Column(String)
    gravity = Column(String)
    gravity_color = Column(String)
    risk = Column(Integer)
    risk_text = Column(String)
    risk_color = Column(String)
    status = Column(String, default="new")
    vehicle = Column(String)
    vehicle_type = Column(String)
    agent_initials = Column(String, default="AX")
    time_left = Column(String, default="3h left")
    photos_count = Column(Integer, default=0)

    # Optional quick AI estimate shown inline in the claims list/detail
    # modal (Claims.jsx) - only a couple of demo claims have this set.
    ai_estimate = Column(Float, nullable=True)
    ai_progress = Column(Integer, nullable=True)

    # Full AI estimation, 1:1 with the claim (AIEstimation.jsx / GET
    # /api/claims/{claim_id}). image_url/thumbnails are the car photos -
    # left exactly as seeded, never generated or replaced here.
    estimation_status = Column(String, default="AI Verification Required")
    image_url = Column(String, nullable=True)
    thumbnails = Column(JSON, default=list)
    hotspots = Column(JSON, default=list)
    subtotal = Column(Float, default=0.0)
    total = Column(Float, default=0.0)
    insights = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


class Client(Base):
    __tablename__ = "clients"

    id = Column(String, primary_key=True, index=True)  # e.g. "c-1"
    name = Column(String)
    type = Column(String)
    score = Column(Integer)
    risk = Column(Integer)
    risk_text = Column(String)
    risk_color = Column(String)
    last_contact = Column(String)
    initials = Column(String)
    email = Column(String)
    phone = Column(String)
    address = Column(String)
    joined = Column(String)

    # Nested/list data (policies, claim history, notes) - kept as JSON
    # rather than separate tables since the UI only ever reads/writes them
    # as whole lists scoped to one client (Clients.jsx).
    policies = Column(JSON, default=list)
    claims_history = Column(JSON, default=list)
    notes = Column(JSON, default=list)

    # Same fields requested for real mobile-app clients (see
    # mobile_clients.py / backend/app/models/user.py) - added here too so
    # assurex's own demo/manually-created clients can carry them as well,
    # instead of only ever showing null for these fields.
    cin = Column(String, nullable=True)
    plate_number = Column(String, nullable=True)  # immatriculation
    car_category = Column(String, nullable=True)
    insurance_date = Column(DateTime(timezone=True), nullable=True)
    payment_status = Column(String, default="unpaid")  # "paid" / "unpaid"

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


class DashboardStat(Base):
    """
    Singleton row (id=1) holding the dashboard KPI tiles (Dashboard.jsx's
    GET /api/dashboard/stats). One JSON blob rather than a column per
    metric since it's a small, UI-shaped config object, not relational
    data.
    """
    __tablename__ = "dashboard_stats"

    id = Column(Integer, primary_key=True, default=1)
    data = Column(JSON, default=dict)


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
