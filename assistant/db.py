"""
Direct Postgres persistence for the chat app — every message, per-vehicle
client profile, and (once a fault result exists) a real Claim record.

Reuses the platform backend's SQLAlchemy models and session factory
(../platform/backend/app/{database,models}.py) instead of keeping a second
schema — the same "one source of truth" pattern accident_analysis.py
already uses for fault_engine.py. Works with no docker-compose running too:
app/config.py's DATABASE_URL defaults to sqlite:///./local_dev.db when the
env var isn't set, so this still persists locally with zero setup.

Every function opens and closes its own short-lived session rather than
holding one long-lived SQLAlchemy session across a whole conversation —
each turn is its own independent FastAPI request (see
platform/backend/app/routers/chat.py), so there's no single long-running
process session to attach one to anyway, and a connection held open across
many turns is a real way to exhaust a connection pool over a long
conversation.

All functions are best-effort: a database hiccup should degrade the app
(lose an audit record) rather than break the conversation the client is in
the middle of. Callers in app/routers/chat.py wrap these in try/except
accordingly.
"""
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from . import geocoding

_BACKEND_APP_DIR = Path(__file__).resolve().parent.parent / "platform" / "backend"
if str(_BACKEND_APP_DIR) not in sys.path:
    sys.path.insert(0, str(_BACKEND_APP_DIR))

from app.database import Base, SessionLocal, engine  # noqa: E402
from app.models import (  # noqa: E402
    Claim,
    ClientProfile,
    Conversation,
    FaultDetermination,
    Message,
    VehicleDeclaration,
)


def init_db() -> None:
    """Create any tables that don't exist yet. Safe to call every startup — no-op if already there."""
    Base.metadata.create_all(bind=engine)


def create_conversation(base_url: str, model: str) -> str:
    with SessionLocal() as db:
        convo = Conversation(llm_base_url=base_url, llm_model=model)
        db.add(convo)
        db.commit()
        db.refresh(convo)
        return convo.id


def mark_conversation_completed(conversation_id: str) -> None:
    with SessionLocal() as db:
        convo = db.get(Conversation, conversation_id)
        if convo:
            convo.status = "completed"
            convo.ended_at = datetime.now(timezone.utc)
            db.commit()


def log_message(conversation_id: str, role: str, content: str, language: Optional[str] = None) -> None:
    if not content:
        return
    with SessionLocal() as db:
        db.add(Message(conversation_id=conversation_id, role=role, content=content, language=language))
        db.commit()


def upsert_client_profile(conversation_id: str, vehicle_label: str, **fields) -> None:
    """fields: any subset of ClientProfile's columns (first_name, phone, plate_number, ...). Empty values are skipped, not overwritten with blanks."""
    with SessionLocal() as db:
        profile = (
            db.query(ClientProfile)
            .filter_by(conversation_id=conversation_id, vehicle_label=vehicle_label)
            .first()
        )
        if profile is None:
            profile = ClientProfile(conversation_id=conversation_id, vehicle_label=vehicle_label)
            db.add(profile)
        for key, value in fields.items():
            if value:
                setattr(profile, key, value)
        db.commit()


def update_conversation_escalation(conversation_id: str, flag: bool, reasons: list) -> None:
    with SessionLocal() as db:
        convo = db.get(Conversation, conversation_id)
        if convo:
            convo.escalation_flag = flag
            convo.escalation_reasons = list(reasons)
            db.commit()


def update_conversation_llm_config(conversation_id: str, base_url: str, model: str) -> None:
    """
    create_conversation() records whatever base_url/model were the *code*
    defaults at the moment the conversation row was created — but the
    sidebar widgets that hold the real, current values only render after
    that, and the user is free to switch provider mid-session. Without
    this, the persisted audit record would keep claiming a conversation
    used Gemini/gemini-3.5-flash even after someone switched to Groq
    partway through. Called on every turn so the record always reflects
    whatever was actually used for that turn.
    """
    with SessionLocal() as db:
        convo = db.get(Conversation, conversation_id)
        if convo:
            convo.llm_base_url = base_url
            convo.llm_model = model
            db.commit()


_CONSTAT_STORAGE_DIR = _BACKEND_APP_DIR / "generated_constats"


def save_generated_constat(conversation_id: str, pdf_bytes: bytes) -> str:
    """
    Writes the just-generated constat PDF to disk and records where (plus
    when) on the Conversation row, so the exact document a client saw/
    downloaded is retrievable later — not just the underlying vehicle/claim
    data it was built from. Called every time the sidebar (re)generates a
    constat (draft or complete); overwrites the same conversation's file
    each time rather than keeping a version history, since the point is
    "the current constat is saved," not an audit trail of every draft.

    In a real deployment this would go to object storage (S3/MinIO — same
    idea as Photo.s3_key elsewhere in this schema) rather than local disk;
    kept local here to match this app's zero-setup local-dev story (see the
    module docstring above). Raises on a hard disk failure rather than
    swallowing it — callers already go through _db_call in app.py, which is
    the actual best-effort boundary.
    """
    _CONSTAT_STORAGE_DIR.mkdir(parents=True, exist_ok=True)
    path = _CONSTAT_STORAGE_DIR / f"{conversation_id}.pdf"
    path.write_bytes(pdf_bytes)
    with SessionLocal() as db:
        convo = db.get(Conversation, conversation_id)
        if convo:
            convo.constat_pdf_path = str(path)
            convo.constat_pdf_generated_at = datetime.now(timezone.utc)
            db.commit()
    return str(path)


def find_claims_by_identifier(plate_number: Optional[str] = None, phone: Optional[str] = None) -> list:
    """
    Look up real claims this person has been involved in, matched by an
    exact plate number (on VehicleDeclaration) and/or an exact phone number
    (on ClientProfile, joined back to the Conversation that produced the
    claim). Deliberately exact-match only, no fuzzy/partial matching — a
    wrong match here would tell a client about someone else's accident,
    which is a worse outcome than an honest "nothing found." This is what
    the `lookup_constats` tool calls so the assistant answers "how many
    constats have I filed" / "what's the status of my claim" from real data
    instead of guessing. Returns claims newest-first.
    """
    if not plate_number and not phone:
        return []
    with SessionLocal() as db:
        claim_ids = set()
        if plate_number:
            rows = (
                db.query(VehicleDeclaration.claim_id)
                .filter(VehicleDeclaration.plate_number == plate_number)
                .all()
            )
            claim_ids.update(r[0] for r in rows)
        if phone:
            rows = (
                db.query(Conversation.claim_id)
                .join(ClientProfile, ClientProfile.conversation_id == Conversation.id)
                .filter(ClientProfile.phone == phone, Conversation.claim_id.isnot(None))
                .all()
            )
            claim_ids.update(r[0] for r in rows if r[0])
        if not claim_ids:
            return []
        claims = (
            db.query(Claim)
            .filter(Claim.id.in_(claim_ids))
            .order_by(Claim.created_at.desc())
            .all()
        )
        return [_claim_summary(c) for c in claims]


def get_claim_status(claim_id: str) -> Optional[dict]:
    """Status/result of one specific claim by id, or None if it doesn't exist — used for a direct 'what's the status of claim X' lookup."""
    with SessionLocal() as db:
        c = db.get(Claim, claim_id)
        return _claim_summary(c) if c else None


def _claim_summary(c: Claim) -> dict:
    fault = c.fault_determination
    return {
        "claim_id": c.id,
        "created_at": c.created_at.isoformat() if c.created_at else None,
        "status": c.status,
        "location": c.location_text,
        "fault_a_pct": fault.fault_a_pct if fault else None,
        "fault_b_pct": fault.fault_b_pct if fault else None,
        "rule_id": fault.rule_id if fault else None,
        "needs_manual_review": fault.needs_manual_review if fault else None,
    }


def _full_name(first: Optional[str], last: Optional[str]) -> Optional[str]:
    parts = [p for p in (first, last) if p]
    return " ".join(parts) or None


def persist_claim_and_fault(conversation_id: str, claim_info, vehicle_a, vehicle_b, fault_result: dict) -> str:
    """
    Creates a real Claim + two VehicleDeclarations + a FaultDetermination
    once analyze_accident actually runs, reusing the platform's own schema
    rather than a shadow copy of it. Returns the new claim's id.

    Deliberately does NOT try to parse claim_info.accident_date/accident_time
    into Claim.accident_datetime — those are free text exactly as the client
    said them ("hier vers 15h", "yesterday afternoon"), and guessing a
    concrete timestamp out of that would risk silently storing a wrong one,
    which is worse than leaving it null. location_lat/location_lng ARE
    geocoded here, same as each vehicle's route already is elsewhere —
    that's a real lookup against a real address, not a guess.
    """
    location_coords = geocoding.geocode(claim_info.location) if claim_info.location else None
    with SessionLocal() as db:
        claim = Claim(
            location_text=claim_info.location,
            location_lat=location_coords["lat"] if location_coords else None,
            location_lng=location_coords["lng"] if location_coords else None,
            status="needs_review" if fault_result["needs_manual_review"] else "fault_determined",
        )
        db.add(claim)
        db.flush()  # populate claim.id before creating rows that reference it

        for label, v in (("A", vehicle_a), ("B", vehicle_b)):
            db.add(
                VehicleDeclaration(
                    claim_id=claim.id,
                    vehicle_label=label,
                    plate_number=v.plate_number,
                    insurer_name=v.insurance_company,
                    policy_number=v.policy_number,
                    driver_name=_full_name(v.driver_first_name, v.driver_last_name),
                    circumstances=list(v.circumstances),
                    impact_zones=list(v.impact_zones),
                )
            )

        db.add(
            FaultDetermination(
                claim_id=claim.id,
                fault_a_pct=fault_result["fault_a_pct"],
                fault_b_pct=fault_result["fault_b_pct"],
                rule_id=fault_result["rule_id"],
                explanation=fault_result["explanation"],
                needs_manual_review=fault_result["needs_manual_review"],
            )
        )

        convo = db.get(Conversation, conversation_id)
        if convo:
            convo.claim_id = claim.id

        db.commit()
        return claim.id
