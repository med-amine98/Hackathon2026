from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta  # <-- Add timedelta here
from sqlalchemy.orm import Session
from database import engine, get_db, ensure_schema, SessionLocal, DB_SCHEMA
from models import Base, Claim, Client, DashboardStat, User
from schemas import (
    UserCreate, UserLogin, UserResponse, Token,
    ClaimCreate, ClaimUpdateStatus, NoteCreate
)
from auth import (
    authenticate_user, create_access_token, get_current_user,
    get_password_hash, ACCESS_TOKEN_EXPIRE_MINUTES
)
from seed import seed_if_empty, DEFAULT_ESTIMATION_IMAGE, DEFAULT_ESTIMATION_INSIGHTS
from migrate import run_migrations
import platform_claims
import mobile_clients
import analytics

app = FastAPI(title="AssureX Agency Portal API")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create assurex's own Postgres schema first, then non-destructively add
# any columns an older `claims` table is missing
# (see migrate.py - never drops/touches existing rows or other tables),
# then create any tables that don't exist yet at all.
ensure_schema()
run_migrations(engine, DB_SCHEMA)
Base.metadata.create_all(bind=engine)

# Claims/clients/dashboard stats live as real rows in the database (see
# models.py) - seed_if_empty inserts demo content once, on first startup,
# so the app isn't empty out of the box. Every request below reads/writes
# the DB directly.
_seed_db = SessionLocal()
try:
    seed_if_empty(_seed_db)
finally:
    _seed_db.close()


# ============ SERIALIZATION HELPERS ============

def _claim_summary(c: Claim) -> Dict[str, Any]:
    data = {
        "id": c.id,
        "type": c.type,
        "gravity": c.gravity,
        "gravity_color": c.gravity_color,
        "risk": c.risk,
        "risk_text": c.risk_text,
        "risk_color": c.risk_color,
        "status": c.status,
        "vehicle": c.vehicle,
        "vehicle_type": c.vehicle_type,
        "agent_initials": c.agent_initials,
        "time_left": c.time_left,
        "photos_count": c.photos_count,
    }
    # Only present for the few claims that have a quick inline AI estimate
    # (Claims.jsx's `selectedClaim.ai_estimate &&` check), same as before.
    if c.ai_estimate is not None:
        data["ai_estimate"] = c.ai_estimate
    if c.ai_progress is not None:
        data["ai_progress"] = c.ai_progress
    return data


def _claim_estimation(c: Claim) -> Dict[str, Any]:
    return {
        "claim_id": c.id,
        "vehicle": c.vehicle,
        "status": c.estimation_status,
        "image_url": c.image_url,
        "thumbnails": c.thumbnails or [],
        "hotspots": c.hotspots or [],
        "subtotal": c.subtotal,
        "total": c.total,
        "insights": c.insights,
    }


def _client_summary(cl: Client) -> Dict[str, Any]:
    return {
        "id": cl.id,
        "name": cl.name,
        "type": cl.type,
        "score": cl.score,
        "risk": cl.risk,
        "risk_text": cl.risk_text,
        "risk_color": cl.risk_color,
        "last_contact": cl.last_contact,
        "initials": cl.initials,
        "claims_count": len(cl.claims_history or []),
        "email": cl.email,
        "phone": cl.phone,
        "address": cl.address,
        "joined": cl.joined,
        "policies": cl.policies or [],
        "claims_history": cl.claims_history or [],
        "notes": cl.notes or [],
        "cin": cl.cin,
        "plate_number": cl.plate_number,
        "car_category": cl.car_category,
        "insurance_date": cl.insurance_date.strftime("%d/%m/%Y") if cl.insurance_date else None,
        "payment_status": cl.payment_status,
    }


# ============ AUTH ROUTES ============

@app.post("/api/auth/signup", response_model=UserResponse)
def signup(user_data: UserCreate, db: Session = Depends(get_db)):
    # Check if user exists
    existing_user = db.query(User).filter(
        (User.email == user_data.email) | (User.username == user_data.username)
    ).first()

    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email or username already registered"
        )

    # Create new user
    db_user = User(
        email=user_data.email,
        username=user_data.username,
        full_name=user_data.full_name,
        hashed_password=get_password_hash(user_data.password)
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    return db_user

@app.post("/api/auth/login", response_model=Token)
def login(user_data: UserLogin, db: Session = Depends(get_db)):
    user = authenticate_user(db, user_data.email, user_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    }

@app.get("/api/auth/me", response_model=UserResponse)
def get_current_user_info(current_user: User = Depends(get_current_user)):
    return current_user

# ============ ENDPOINTS (Protected) ============

@app.get("/api/analytics/overview")
async def get_analytics_overview(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Powers the "Analyse" page - stats merged across assurex's own data and the bridged mobile/platform data."""
    return analytics.build_overview(db)

@app.get("/api/dashboard/stats")
async def get_stats(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    stat = db.get(DashboardStat, 1)
    return stat.data if stat else {}

@app.get("/api/claims")
async def get_claims(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    claims = db.query(Claim).order_by(Claim.created_at).all()
    # Merge in real constats filed through the mobile app's agent chat -
    # see platform_claims.py's module docstring for why these otherwise
    # never showed up here even though they were correctly saved.
    return [_claim_summary(c) for c in claims] + platform_claims.fetch_platform_claims(db)

@app.get("/api/claims/{claim_id}")
async def get_claim_details(claim_id: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    claim = db.get(Claim, claim_id)
    if claim:
        return _claim_estimation(claim)

    platform_detail = platform_claims.fetch_platform_claim_detail(db, claim_id)
    if platform_detail:
        return platform_detail

    raise HTTPException(status_code=404, detail="Claim not found")

@app.post("/api/claims/{claim_id}/move")
async def update_claim_status(claim_id: str, payload: ClaimUpdateStatus, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    valid_statuses = ["new", "estimation", "review", "completed"]
    if payload.status not in valid_statuses:
        raise HTTPException(status_code=400, detail=f"Invalid status. Must be one of {valid_statuses}")

    claim = db.get(Claim, claim_id)
    if claim:
        claim.status = payload.status
        db.commit()
        db.refresh(claim)
        return {"message": "Status updated successfully", "claim": _claim_summary(claim)}

    if platform_claims.update_platform_claim_status(db, claim_id, payload.status):
        updated = platform_claims.fetch_platform_claim_detail(db, claim_id)
        return {"message": "Status updated successfully", "claim": updated}

    raise HTTPException(status_code=404, detail="Claim not found")

@app.post("/api/claims")
async def create_claim(payload: ClaimCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    new_id = f"CLM-{db.query(Claim).count() + 8292}"

    gravity_colors = {
        "Critical": "bg-error",
        "High": "bg-error",
        "Moderate": "bg-orange-500",
        "Minor": "bg-green-500",
        "Low": "bg-green-500"
    }

    risk_colors = {
        "Critical": "text-error",
        "High": "text-error",
        "Moderate": "text-orange-600",
        "Minor": "text-green-600",
        "Low": "text-green-600"
    }

    grav = payload.gravity
    grav_color = gravity_colors.get(grav, "bg-primary")
    risk_color = risk_colors.get(grav, "text-primary")

    new_claim = Claim(
        id=new_id,
        type="Property Damage" if "scratch" in payload.vehicle.lower() or "bumper" in payload.vehicle.lower() else "Vehicle Collision",
        gravity=grav,
        gravity_color=grav_color,
        risk=payload.risk,
        risk_text=f"{grav} ({payload.risk}%)",
        risk_color=risk_color,
        status="new",
        vehicle=payload.vehicle,
        vehicle_type=payload.vehicle_type,
        agent_initials=payload.agent_initials,
        time_left=payload.time_left,
        photos_count=0,
        # No AI processing has run yet for a brand-new claim - same
        # fallback estimation content the old dummy-record generator used.
        estimation_status="AI Verification Required",
        image_url=DEFAULT_ESTIMATION_IMAGE,
        thumbnails=[],
        hotspots=[],
        subtotal=0.0,
        total=0.0,
        insights=DEFAULT_ESTIMATION_INSIGHTS,
    )
    db.add(new_claim)

    # Update dashboard stats: active claims count
    stat = db.get(DashboardStat, 1)
    if stat:
        current_active = int(stat.data["active_claims"]["value"].replace(",", ""))
        # Reassign (don't mutate in place) so SQLAlchemy detects the JSON
        # column changed.
        stat.data = {
            **stat.data,
            "active_claims": {
                **stat.data["active_claims"],
                "value": f"{current_active + 1:,}",
            },
        }

    db.commit()
    db.refresh(new_claim)
    return _claim_summary(new_claim)

@app.get("/api/clients")
async def get_clients(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    clients = db.query(Client).all()
    # Merge in real mobile-app users - "users = clients" - see
    # mobile_clients.py's module docstring for why these otherwise never
    # showed up here even though the accounts genuinely exist.
    return [_client_summary(c) for c in clients] + mobile_clients.fetch_mobile_clients(db)

@app.post("/api/clients/{client_id}/notes")
async def add_client_note(client_id: str, note: NoteCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    client = db.get(Client, client_id)
    if not client:
        raise HTTPException(status_code=404, detail="Client not found")

    existing_notes = client.notes or []
    new_note = {
        "id": len(existing_notes) + 1,
        "date": datetime.now().strftime("%Y-%m-%d %H:%M"),
        "author": note.author,
        "text": note.text
    }

    # Reassign (don't mutate the list in place) so SQLAlchemy detects the
    # JSON column changed - prepend, same order as before.
    client.notes = [new_note] + existing_notes
    db.commit()
    return new_note

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
