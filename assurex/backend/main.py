from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta  # <-- Add timedelta here
from sqlalchemy.orm import Session
from database import engine, get_db
from models import Base, Claim, User
from schemas import (
    UserCreate, UserLogin, UserResponse, Token, 
    ClaimCreate, ClaimUpdateStatus, NoteCreate
)
from auth import (
    authenticate_user, create_access_token, get_current_user,
    get_password_hash, ACCESS_TOKEN_EXPIRE_MINUTES
)

app = FastAPI(title="AssureX Agency Portal API")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create tables
Base.metadata.create_all(bind=engine)

# Mock In-Memory Database (for claims and clients)
db = {
    "stats": {
        "active_claims": {"value": "1,284", "change": "+12%", "trending": True},
        "processing_time": {"value": "3.8 days", "change": "Avg. 4.2d", "trending": False},
        "high_risk_alerts": {"value": "24", "change": "Urgent", "trending": True, "urgent": True},
        "churn_risk": {"value": "2.1%", "change": "+0.5%", "trending": True, "negative": True}
    },
    "claims": [
        {
            "id": "CLM-8291",
            "type": "Vehicle Collision",
            "gravity": "Critical",
            "gravity_color": "bg-error",
            "risk": 85,
            "risk_text": "High (85%)",
            "risk_color": "text-error",
            "status": "new",
            "vehicle": "Tesla Model 3 - Front Collision",
            "vehicle_type": "Electric Sedan",
            "agent_initials": "JD",
            "time_left": "2h left",
            "photos_count": 5
        },
        {
            "id": "CLM-9901",
            "type": "Property Damage",
            "gravity": "Low",
            "gravity_color": "bg-green-500",
            "risk": 15,
            "risk_text": "Low (15%)",
            "risk_color": "text-green-600",
            "status": "estimation",
            "vehicle": "Ford F-150 - Minor Scratch",
            "vehicle_type": "Pickup Truck",
            "agent_initials": "AL",
            "time_left": "2 days left",
            "photos_count": 4,
            "ai_estimate": 1240.00,
            "ai_progress": 85
        },
        {
            "id": "CLM-88219",
            "type": "Property Damage",
            "gravity": "Moderate",
            "gravity_color": "bg-orange-500",
            "risk": 45,
            "risk_text": "Medium (45%)",
            "risk_color": "text-orange-600",
            "status": "review",
            "vehicle": "Toyota RAV4 - Fender Bender",
            "vehicle_type": "SUV",
            "agent_initials": "SC",
            "time_left": "1d left",
            "photos_count": 3
        },
        {
            "id": "CLM-94002",
            "type": "Medical Expense",
            "gravity": "Minor",
            "gravity_color": "bg-green-500",
            "risk": 12,
            "risk_text": "Low (12%)",
            "risk_color": "text-green-600",
            "status": "completed",
            "vehicle": "Health Claim - Outpatient",
            "vehicle_type": "Medical Insurance",
            "agent_initials": "ER",
            "time_left": "Completed",
            "photos_count": 2
        }
    ],
    "ai_estimations": {
        "CLM-8291": {
            "claim_id": "CLM-8291",
            "vehicle": "Tesla Model 3 (2023)",
            "status": "AI Processing Complete",
            "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuCtwTDa2-m5XzOXNu3wiyMdyAAEAIefRMEA2A_p7zy-JUiFwsc0vzXyGaneZoIDNuWy72Fw2oTrt_XlGyZ3_T5Xf2tGXGzPamitpc0rbg6V8wHNT-EgGi-1W5XWJGw7VUJCbyGKHJ5fw9BHT0QvA_YFDpF5ImoYx8Sfs3TZtQu3EK2C1OVycPd-t7TAjrhknlesnxaH-_LHpUT3bu2I4q4PX7u1EQQVfyxTzlror8ZDT9OCTlEX-bECRnt3zc823kS4ddYPOSB-rRhf",
            "thumbnails": [
                "https://lh3.googleusercontent.com/aida-public/AB6AXuCJ9ygC8Pr9D1uPtaMXyIM-TgCBqmcJfcsYJIVsvVrIPbcrLjVu9pADd6CZLfje01DtGKheUfR6XDi-uCTjnf1ohU-Y6TLE8N28dRBc5upyDfACzm2LRj1gcgkbxFNNe-iCwwYjM8xjrL8G4wGwT4DIa8EjCKe6OUFvuLTxlZJ4SODxmiu1KngW-kp91EfpbQrkcs8dhBeLf9t7avCiWerveJ4RaXPPS-4fvWBmjpJW-fe6fJhjWgmNupARv4cD-NlgpTWcpeXxYMtm",
                "https://lh3.googleusercontent.com/aida-public/AB6AXuD_F8Vzf6Kv13V-ovmrpzjhh9kcQ0G0vS7JDs6eCi8FtA4j1hitZFKbXKVvt6FNeoIS7zrIMlVnihWC0VRQdNrjuW5p8aiHmxpMonQMyoEjQDXoTolT8tZg-qpv1WIv7j6l6bLq6f-Xc0Pvd9t0A159XdOB2TOQYILr_N9TBFKxKcf08sCq9tPdM5jpg606U6590PQdYTLpCg0JpGFvoTkMis2oKRGUtpHGKeOvhtTKzJ6lawircvNqA78EDT9jSfyDKh9iDYHjD36C"
            ],
            "hotspots": [
                {"id": "hs-1", "top": "45%", "left": "25%", "title": "Front Bumper", "description": "Severe bumper deformation. Structural brackets warped.", "severity": "High", "cost": 1240.00, "confidence": 95},
                {"id": "hs-2", "top": "35%", "left": "45%", "title": "Headlight (Left)", "description": "Left headlight assembly fractured. Bulbs & harness need replacement.", "severity": "Critical", "cost": 850.00, "confidence": 100}
            ],
            "subtotal": 2090.00,
            "total": 3090.00,
            "insights": "Sensor telemetry matches visual structural damage. Potential wiring harness faults identified in front-left quadrant near headlight assembly."
        },
        "CLM-9901": {
            "claim_id": "CLM-9901",
            "vehicle": "Ford F-150 (2021)",
            "status": "AI Processing Complete",
            "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuD_F8Vzf6Kv13V-ovmrpzjhh9kcQ0G0vS7JDs6eCi8FtA4j1hitZFKbXKVvt6FNeoIS7zrIMlVnihWC0VRQdNrjuW5p8aiHmxpMonQMyoEjQDXoTolT8tZg-qpv1WIv7j6l6bLq6f-Xc0Pvd9t0A159XdOB2TOQYILr_N9TBFKxKcf08sCq9tPdM5jpg606U6590PQdYTLpCg0JpGFvoTkMis2oKRGUtpHGKeOvhtTKzJ6lawircvNqA78EDT9jSfyDKh9iDYHjD36C",
            "thumbnails": [],
            "hotspots": [
                {"id": "hs-3", "top": "50%", "left": "60%", "title": "Side Door Scratch", "description": "Surface level clearcoat abrasion.", "severity": "Low", "cost": 1240.00, "confidence": 85}
            ],
            "subtotal": 1240.00,
            "total": 1240.00,
            "insights": "Cosmetic scratch only. No structural deformation or chassis mismatch detected."
        }
    },
    "clients": [
        {
            "id": "c-1",
            "name": "James Wilson",
            "type": "Personal Umbrella",
            "score": 62,
            "risk": 85,
            "risk_text": "Critical",
            "risk_color": "text-error",
            "last_contact": "2 days ago",
            "initials": "JW",
            "claims_count": 2,
            "email": "j.wilson@umbrella-corp.com",
            "phone": "+1 (555) 234-5678",
            "address": "742 Evergreen Terrace, Springfield",
            "joined": "March 2021",
            "policies": [
                {"name": "Liability Umbrella Plan", "number": "POL-9928-JW", "premium": "$1,200/yr", "status": "Active"},
                {"name": "Comprehensive Auto", "number": "POL-8812-JW", "premium": "$2,400/yr", "status": "Active"}
            ],
            "claims_history": [
                {"id": "#CL-92834", "date": "10/05/2026", "amount": "$4,500.00", "status": "Pending", "type": "Vehicle Collision"},
                {"id": "#CL-77281", "date": "14/11/2024", "amount": "$1,200.00", "status": "Paid", "type": "Glass Breakage"}
            ],
            "notes": [
                {"id": 1, "date": "2026-07-16 14:32", "author": "Alex (Agent)", "text": "Called client regarding the active Tesla collision claim. Documented missing incident photos."},
                {"id": 2, "date": "2026-07-10 09:15", "author": "System", "text": "Renewal notice successfully dispatched to client's registered email."}
            ]
        },
        {
            "id": "c-2",
            "name": "Sarah Chen",
            "type": "Commercial Fleet",
            "score": 45,
            "risk": 65,
            "risk_text": "High",
            "risk_color": "text-orange-500",
            "last_contact": "1 week ago",
            "initials": "SC",
            "claims_count": 1,
            "email": "sarah.chen@chenlogistics.com",
            "phone": "+1 (555) 987-6543",
            "address": "1208 Industrial Pkwy, Seattle, WA",
            "joined": "August 2023",
            "policies": [
                {"name": "Fleet Liability & Cargo Protection", "number": "POL-3392-SC", "premium": "$18,500/yr", "status": "Active"}
            ],
            "claims_history": [
                {"id": "#CL-88219", "date": "02/07/2026", "amount": "$9,800.00", "status": "Under AI Review", "type": "Fleet Damage"}
            ],
            "notes": [
                {"id": 1, "date": "2026-07-11 11:20", "author": "Alex (Agent)", "text": "Sarah requested update on the cargo damage claim. Advised awaiting secondary AI photo scan validation."}
            ]
        },
        {
            "id": "c-3",
            "name": "Elena Rodriguez",
            "type": "Life & Health",
            "score": 94,
            "risk": 12,
            "risk_text": "Low",
            "risk_color": "text-green-500",
            "last_contact": "Yesterday",
            "initials": "ER",
            "claims_count": 0,
            "email": "elena.r@rodriguez-law.com",
            "phone": "+1 (555) 456-7890",
            "address": "45 Park Avenue, Apt 11B, New York, NY",
            "joined": "January 2019",
            "policies": [
                {"name": "Premium Family Health", "number": "POL-1192-ER", "premium": "$950/mo", "status": "Active"},
                {"name": "Term Life 20-Yr Plan", "number": "POL-5528-ER", "premium": "$80/mo", "status": "Active"}
            ],
            "claims_history": [],
            "notes": [
                {"id": 1, "date": "2026-07-17 16:45", "author": "Alex (Agent)", "text": "Conducted annual portfolio assessment with Elena. Client is highly satisfied, loyalty score remains at 94%."}
            ]
        }
    ]
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

@app.get("/api/dashboard/stats")
async def get_stats(current_user: User = Depends(get_current_user)):
    return db["stats"]

@app.get("/api/claims")
async def get_claims(current_user: User = Depends(get_current_user)):
    return db["claims"]

@app.get("/api/claims/{claim_id}")
async def get_claim_details(claim_id: str, current_user: User = Depends(get_current_user)):
    # Find active estimation if present
    est = db["ai_estimations"].get(claim_id)
    if not est:
        # Generate default estimation record if not exists
        claim = next((c for c in db["claims"] if c["id"] == claim_id), None)
        if not claim:
            raise HTTPException(status_code=404, detail="Claim not found")
        
        # return dummy default estimation
        est = {
            "claim_id": claim_id,
            "vehicle": claim["vehicle"],
            "status": "AI Verification Required",
            "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuCtwTDa2-m5XzOXNu3wiyMdyAAEAIefRMEA2A_p7zy-JUiFwsc0vzXyGaneZoIDNuWy72Fw2oTrt_XlGyZ3_T5Xf2tGXGzPamitpc0rbg6V8wHNT-EgGi-1W5XWJGw7VUJCbyGKHJ5fw9BHT0QvA_YFDpF5ImoYx8Sfs3TZtQu3EK2C1OVycPd-t7TAjrhknlesnxaH-_LHpUT3bu2I4q4PX7u1EQQVfyxTzlror8ZDT9OCTlEX-bECRnt3zc823kS4ddYPOSB-rRhf",
            "thumbnails": [],
            "hotspots": [],
            "subtotal": 0.0,
            "total": 0.0,
            "insights": "No AI processing run for this claim yet. Request photo upload or validate manually."
        }
    return est

@app.post("/api/claims/{claim_id}/move")
async def update_claim_status(claim_id: str, payload: ClaimUpdateStatus, current_user: User = Depends(get_current_user)):
    claim = next((c for c in db["claims"] if c["id"] == claim_id), None)
    if not claim:
        raise HTTPException(status_code=404, detail="Claim not found")
    
    valid_statuses = ["new", "estimation", "review", "completed"]
    if payload.status not in valid_statuses:
        raise HTTPException(status_code=400, detail=f"Invalid status. Must be one of {valid_statuses}")
    
    claim["status"] = payload.status
    return {"message": "Status updated successfully", "claim": claim}

@app.post("/api/claims")
async def create_claim(payload: ClaimCreate, current_user: User = Depends(get_current_user)):
    new_id = f"CLM-{len(db['claims']) + 8292}"
    
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
    
    new_claim = {
        "id": new_id,
        "type": "Property Damage" if "scratch" in payload.vehicle.lower() or "bumper" in payload.vehicle.lower() else "Vehicle Collision",
        "gravity": grav,
        "gravity_color": grav_color,
        "risk": payload.risk,
        "risk_text": f"{grav} ({payload.risk}%)",
        "risk_color": risk_color,
        "status": "new",
        "vehicle": payload.vehicle,
        "vehicle_type": payload.vehicle_type,
        "agent_initials": payload.agent_initials,
        "time_left": payload.time_left,
        "photos_count": 0
    }
    
    db["claims"].append(new_claim)
    
    # Update dashboard stats: active claims count
    current_active = int(db["stats"]["active_claims"]["value"].replace(",", ""))
    db["stats"]["active_claims"]["value"] = f"{current_active + 1:,}"
    
    return new_claim

@app.get("/api/clients")
async def get_clients(current_user: User = Depends(get_current_user)):
    return db["clients"]

@app.post("/api/clients/{client_id}/notes")
async def add_client_note(client_id: str, note: NoteCreate, current_user: User = Depends(get_current_user)):
    client = next((c for c in db["clients"] if c["id"] == client_id), None)
    if not client:
        raise HTTPException(status_code=404, detail="Client not found")
    
    new_note = {
        "id": len(client["notes"]) + 1,
        "date": datetime.now().strftime("%Y-%m-%d %H:%M"),
        "author": note.author,
        "text": note.text
    }
    
    client["notes"].insert(0, new_note)  # Prepend new note
    return new_note

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)