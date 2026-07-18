from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

from app.database.connection import get_db
from app.models.conseil import Conseil
from app.models.user import User
from app.services.ai_service import AIService
from app.api.dependencies import get_current_user

router = APIRouter(prefix="/conseil", tags=["conseil"])

# ─── Schémas Pydantic ──────────────────────────────────────────────────────

class ConseilRequest(BaseModel):
    age: int
    experience_years: int
    city: str
    vehicle_make: str
    vehicle_model: str
    vehicle_year: int
    annual_km: int
    usage: str

class GarantieResponse(BaseModel):
    icon: str
    title: str
    description: str
    color: str
    recommended: bool

class ConseilResponse(BaseModel):
    id: int
    user_id: int
    age: int
    experience_years: int
    city: str
    vehicle_make: str
    vehicle_model: str
    vehicle_year: int
    annual_km: int
    usage: str
    risk_score: float
    risk_analysis: str
    ia_advice: str
    garanties: List[dict]
    created_at: str

# ─── Routes ─────────────────────────────────────────────────────────────────

@router.post("/generate", response_model=ConseilResponse)
async def generate_conseil(
    data: ConseilRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Générer des conseils personnalisés avec IA"""
    
    # Calculer le score de risque
    risk_score = _calculate_risk_score(data)
    risk_analysis = _get_risk_analysis(risk_score)
    
    # Obtenir les garanties recommandées
    garanties = _get_garanties(data)
    
    # Obtenir les conseils IA
    ia_advice = await AIService.get_personalized_advice(
        age=data.age,
        experience_years=data.experience_years,
        vehicle=f"{data.vehicle_make} {data.vehicle_model}",
        usage=data.usage,
        annual_km=data.annual_km
    )
    
    # Sauvegarder
    conseil = Conseil(
        user_id=current_user.id,
        age=data.age,
        experience_years=data.experience_years,
        city=data.city,
        vehicle_make=data.vehicle_make,
        vehicle_model=data.vehicle_model,
        vehicle_year=data.vehicle_year,
        annual_km=data.annual_km,
        usage=data.usage,
        risk_score=risk_score,
        risk_analysis=risk_analysis,
        ia_advice=ia_advice,
        garanties=garanties
    )
    
    db.add(conseil)
    db.commit()
    db.refresh(conseil)
    
    return conseil.to_dict()


@router.get("/latest", response_model=ConseilResponse)
async def get_latest_conseil(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Récupérer le dernier conseil de l'utilisateur"""
    conseil = db.query(Conseil).filter(
        Conseil.user_id == current_user.id
    ).order_by(Conseil.created_at.desc()).first()
    
    if not conseil:
        raise HTTPException(status_code=404, detail="Aucun conseil trouvé")
    
    return conseil.to_dict()


# ─── Fonctions privées ─────────────────────────────────────────────────────

def _calculate_risk_score(data: ConseilRequest) -> float:
    score = 0.0
    
    if data.age < 25:
        score += 20
    if data.experience_years < 3:
        score += 15
    if data.annual_km > 20000:
        score += 15
    if data.usage == "quotidiennement":
        score += 10
    if data.city in ["Tunis", "Sfax", "Sousse"]:
        score += 10
    
    return min(score, 100)

def _get_risk_analysis(score: float) -> str:
    if score > 60:
        return "Risque élevé - Conduite à risque important. Une couverture renforcée est recommandée."
    elif score > 30:
        return "Risque modéré - Conduite standard. Une couverture adaptée à votre profil."
    else:
        return "Risque faible - Excellent profil. Vous pouvez bénéficier des meilleurs tarifs."

def _get_garanties(data: ConseilRequest) -> List[dict]:
    garanties = [
        {
            "icon": "Icons.shield",
            "title": "Protection vol",
            "description": "Couverture complète en cas de vol du véhicule",
            "color": "#2563EB",
            "recommended": True
        },
        {
            "icon": "Icons.handshake",
            "title": "Protection juridique",
            "description": "Assistance et protection en cas de litige",
            "color": "#10B981",
            "recommended": True
        }
    ]
    
    if data.age < 25:
        garanties.append({
            "icon": "Icons.people",
            "title": "Protection conducteur",
            "description": "Couverture spécifique jeune conducteur",
            "color": "#F59E0B",
            "recommended": True
        })
    
    if data.annual_km > 20000:
        garanties.append({
            "icon": "Icons.construction",
            "title": "Assistance dépannage",
            "description": "Dépannage et remorquage illimité 24/7",
            "color": "#8B5CF6",
            "recommended": True
        })
    
    return garanties