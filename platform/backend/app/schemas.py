from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict


class ClaimCreate(BaseModel):
    accident_datetime: Optional[datetime] = None
    location_lat: Optional[float] = None
    location_lng: Optional[float] = None
    location_text: Optional[str] = None


class ClaimOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    created_at: datetime
    accident_datetime: Optional[datetime]
    location_lat: Optional[float]
    location_lng: Optional[float]
    location_text: Optional[str]
    status: str
    damages_exceed_cap: bool


class VehicleDeclarationIn(BaseModel):
    vehicle_label: str  # "A" or "B"
    plate_number: Optional[str] = None
    insurer_name: Optional[str] = None
    policy_number: Optional[str] = None
    driver_name: Optional[str] = None
    circumstances: list[str] = []
    impact_zones: list[str] = []
    signature_hash: Optional[str] = None


class VehicleDeclarationOut(VehicleDeclarationIn):
    model_config = ConfigDict(from_attributes=True)

    id: str
    claim_id: str
    signed_at: Optional[datetime] = None


class PhotoOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    claim_id: str
    vehicle_label: Optional[str]
    s3_key: str
    content_hash: Optional[str]
    exif_datetime: Optional[datetime]
    exif_gps_lat: Optional[float]
    exif_gps_lng: Optional[float]
    has_metadata: bool
    duplicate_of_photo_id: Optional[str]
    uploaded_at: datetime


class FaultOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    claim_id: str
    fault_a_pct: float
    fault_b_pct: float
    rule_id: str
    explanation: str
    needs_manual_review: bool
    determined_at: datetime


class ChatMessageIn(BaseModel):
    message: str
    # None on the first turn — the server creates a new conversation and
    # returns its id, which the client then sends back on every later turn.
    conversation_id: Optional[str] = None
    # Identity of the logged-in mobile-app user, sent by the Flutter chat
    # bubble (which only shows once someone is authenticated — see
    # AgentChatBubble). Optional because the assistant package is reusable
    # outside the mobile app too (CLI, tests). When present, the first turn
    # of a new conversation prefills Vehicle A's driver/insured identity
    # with this instead of asking the user to type their own name and phone
    # number again — see send_message's "known identity" handling below.
    user_id: Optional[int] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None


class ChatMessageOut(BaseModel):
    conversation_id: str
    message: str
    # Set once analyze_accident has actually run for this conversation (a
    # fault result exists) — the client can use this to, say, stop showing
    # a "still collecting info" indicator.
    claim_id: Optional[str] = None
    escalation_flag: bool = False
    # Relative path (GET it against the same agent base URL) to the current
    # draft/final constat PDF for this conversation — set on every turn once
    # either vehicle has at least some real data, None before that. This is
    # what lets the Flutter chat bubble show a "view constat" link inline.
    constat_pdf_url: Optional[str] = None
