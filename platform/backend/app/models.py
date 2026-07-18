import uuid
from datetime import datetime, timezone

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    JSON,
    String,
)
from sqlalchemy.orm import relationship

from app.database import Base


def _uuid() -> str:
    return str(uuid.uuid4())


def _now() -> datetime:
    return datetime.now(timezone.utc)


class Claim(Base):
    """One 'constat amiable' — the accident report shared by both drivers."""
    __tablename__ = "claims"

    id = Column(String, primary_key=True, default=_uuid)
    created_at = Column(DateTime, default=_now)
    accident_datetime = Column(DateTime, nullable=True)
    location_lat = Column(Float, nullable=True)
    location_lng = Column(Float, nullable=True)
    location_text = Column(String, nullable=True)
    # draft -> both_declared -> fault_determined -> needs_review -> closed
    status = Column(String, default="draft")
    damages_exceed_cap = Column(Boolean, default=False)

    vehicles = relationship("VehicleDeclaration", back_populates="claim", cascade="all, delete-orphan")
    photos = relationship("Photo", back_populates="claim", cascade="all, delete-orphan")
    fault_determination = relationship(
        "FaultDetermination", back_populates="claim", uselist=False, cascade="all, delete-orphan"
    )


class VehicleDeclaration(Base):
    """What one driver (A or B) declared on the constat."""
    __tablename__ = "vehicle_declarations"

    id = Column(String, primary_key=True, default=_uuid)
    claim_id = Column(String, ForeignKey("claims.id"), nullable=False, index=True)
    vehicle_label = Column(String, nullable=False)  # "A" or "B"

    # Indexed: find_claims_by_identifier (assistant/db.py) does an exact
    # lookup on this column for the lookup_constats tool.
    plate_number = Column(String, nullable=True, index=True)
    insurer_name = Column(String, nullable=True)
    policy_number = Column(String, nullable=True)
    driver_name = Column(String, nullable=True)

    circumstances = Column(JSON, default=list)  # list[str] of Circumstance codes
    impact_zones = Column(JSON, default=list)   # list[str] of ImpactZone codes

    signature_hash = Column(String, nullable=True)  # sha256 of the captured signature blob
    signed_at = Column(DateTime, nullable=True)

    claim = relationship("Claim", back_populates="vehicles")


class Photo(Base):
    """A camera-captured photo attached to a claim, with forensic metadata."""
    __tablename__ = "photos"

    id = Column(String, primary_key=True, default=_uuid)
    claim_id = Column(String, ForeignKey("claims.id"), nullable=False)
    vehicle_label = Column(String, nullable=True)

    s3_key = Column(String, nullable=False)
    content_hash = Column(String, nullable=True)  # perceptual hash (hex string)

    # Set by app/worker.py's run_damage_assessment once damage detection has
    # run on this specific photo: the same photo, re-saved to MinIO with
    # each detected damage's bounding box + "class conf%" label drawn on it
    # (app/damage_detection.py's annotate_image), so an agent can actually
    # see what the model found instead of just reading a cost line. Stays
    # NULL until the worker has processed this photo at least once.
    annotated_s3_key = Column(String, nullable=True)

    exif_datetime = Column(DateTime, nullable=True)
    exif_gps_lat = Column(Float, nullable=True)
    exif_gps_lng = Column(Float, nullable=True)
    has_metadata = Column(Boolean, default=False)

    duplicate_of_photo_id = Column(String, ForeignKey("photos.id"), nullable=True)
    uploaded_at = Column(DateTime, default=_now)

    claim = relationship("Claim", back_populates="photos")


class FaultDetermination(Base):
    """Output of the fault engine for a claim, one per claim."""
    __tablename__ = "fault_determinations"

    id = Column(String, primary_key=True, default=_uuid)
    claim_id = Column(String, ForeignKey("claims.id"), nullable=False, unique=True)

    fault_a_pct = Column(Float, nullable=False)
    fault_b_pct = Column(Float, nullable=False)
    rule_id = Column(String, nullable=False)
    explanation = Column(String, nullable=False)
    needs_manual_review = Column(Boolean, default=False)
    determined_at = Column(DateTime, default=_now)

    claim = relationship("Claim", back_populates="fault_determination")


class DamageEstimate(Base):
    """
    Output of the YOLO11 damage-detection pipeline (app/damage_detection.py),
    one row per claim - aggregated across every photo uploaded for it so far
    (see app/worker.py's run_damage_assessment, triggered on every photo
    upload in app/routers/photos.py). Read by assurex/backend's
    platform_claims.py to populate the AI Damage Estimation panel with real
    hotspots/costs instead of the empty-list placeholder it used to fall
    back to for every real (non-demo) constat.
    """
    __tablename__ = "damage_estimates"

    id = Column(String, primary_key=True, default=_uuid)
    claim_id = Column(String, ForeignKey("claims.id"), nullable=False, unique=True)

    hotspots = Column(JSON, default=list)  # list[dict] — see damage_detection.estimate_repair
    subtotal = Column(Float, default=0.0)
    total = Column(Float, default=0.0)
    damage_percent = Column(Integer, default=0)
    insights = Column(String, nullable=True)
    vehicle_make_model = Column(String, nullable=True)
    vehicle_tier = Column(String, nullable=True)  # "economique" / "standard" / "premium"
    photos_analyzed = Column(Integer, default=0)
    updated_at = Column(DateTime, default=_now, onupdate=_now)

    claim = relationship("Claim")


class Conversation(Base):
    """
    One agent chat session between the assistant and a client (see
    app/routers/chat.py). Linked to a Claim once analyze_accident actually
    runs and confirms one — before that, a conversation can exist on its
    own (someone who started chatting but hasn't finished the accident
    narrative yet).
    """
    __tablename__ = "conversations"

    id = Column(String, primary_key=True, default=_uuid)
    claim_id = Column(String, ForeignKey("claims.id"), nullable=True, index=True)
    started_at = Column(DateTime, default=_now)
    ended_at = Column(DateTime, nullable=True)
    llm_base_url = Column(String, nullable=True)
    llm_model = Column(String, nullable=True)
    escalation_flag = Column(Boolean, default=False)
    escalation_reasons = Column(JSON, default=list)  # list[str]
    # Granular emotion/mood tracking from the assistant's note_mood tool
    # (see assistant/prompts.py) — last_mood is the most recent
    # calm/concerned/stressed/distressed reading for this conversation;
    # injury_mentioned/dispute_mentioned are sticky flags (once true, stay
    # true) so the portal can see "this client mentioned an injury" even if
    # a later turn is calmer.
    last_mood = Column(String, nullable=True)  # "calm" / "concerned" / "stressed" / "distressed"
    injury_mentioned = Column(Boolean, default=False)
    dispute_mentioned = Column(Boolean, default=False)
    # in_progress -> completed. Deliberately not richer than this — this
    # table exists for message/profile persistence and audit, not as a
    # second claim-workflow state machine duplicating Claim.status.
    status = Column(String, default="in_progress")

    # Where the last-generated constat PDF for this conversation was saved on
    # disk (see assistant/db.py's save_generated_constat), and when. A
    # conversation can regenerate its constat many times as the client adds
    # data (draft -> more complete draft -> final) — this always points at
    # the latest one, not a version history, since the point is that the
    # actual document a client saw/downloaded is retrievable later, not just
    # the underlying data it was built from.
    constat_pdf_path = Column(String, nullable=True)
    constat_pdf_generated_at = Column(DateTime, nullable=True)

    messages = relationship("Message", back_populates="conversation", cascade="all, delete-orphan")
    client_profiles = relationship("ClientProfile", back_populates="conversation", cascade="all, delete-orphan")
    claim = relationship("Claim")


class Message(Base):
    """One chat turn, in the order it happened — the full audit trail of a conversation."""
    __tablename__ = "messages"

    id = Column(String, primary_key=True, default=_uuid)
    conversation_id = Column(String, ForeignKey("conversations.id"), nullable=False, index=True)
    role = Column(String, nullable=False)  # "user" / "assistant" / "tool"
    content = Column(String, nullable=False)
    language = Column(String, nullable=True)  # best-guess tag: "ar" / "fr" / "en"
    created_at = Column(DateTime, default=_now)

    conversation = relationship("Conversation", back_populates="messages")


class ClientProfile(Base):
    """
    Identity/insurance/contact info collected for one driver (A or B) within
    one conversation. Deliberately NOT deduplicated or linked across
    conversations — this is a per-conversation profile snapshot, not a
    persistent cross-visit customer record. Matching returning clients by
    phone number is a real feature to consider later, but wasn't wanted for
    this pass: keeping it out avoids the false-match risk of merging two
    different people who happen to share a phone number typo, or splitting
    one person across records because of a formatting difference.
    """
    __tablename__ = "client_profiles"

    id = Column(String, primary_key=True, default=_uuid)
    conversation_id = Column(String, ForeignKey("conversations.id"), nullable=False, index=True)
    vehicle_label = Column(String, nullable=False)  # "A" or "B"

    # Soft cross-reference to the mobile backend's users.id (separate
    # Postgres schema — see backend/app/database/connection.py — so this is
    # NOT a real ForeignKey, just a convention-based link) when this profile
    # belongs to a logged-in mobile-app user rather than an anonymous chat.
    # Set once, on the first turn of a conversation — see send_message's
    # "known identity" handling in routers/chat.py.
    mobile_user_id = Column(Integer, nullable=True, index=True)

    first_name = Column(String, nullable=True)
    last_name = Column(String, nullable=True)
    address = Column(String, nullable=True)
    # Indexed: find_claims_by_identifier (assistant/db.py) does an exact
    # lookup on this column for the lookup_constats tool.
    phone = Column(String, nullable=True, index=True)
    license_number = Column(String, nullable=True)
    insurance_company = Column(String, nullable=True)
    policy_number = Column(String, nullable=True)
    vehicle_make_model = Column(String, nullable=True)
    plate_number = Column(String, nullable=True)
    preferred_language = Column(String, nullable=True)  # "ar" / "fr" / "en" — best guess from their messages

    updated_at = Column(DateTime, default=_now, onupdate=_now)

    conversation = relationship("Conversation", back_populates="client_profiles")
