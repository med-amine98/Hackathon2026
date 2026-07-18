from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import json

from app.database.connection import get_db
from app.models.declaration import Declaration
from app.models.user import User
from app.services.ai_service import AIService
from app.api.dependencies import get_current_user

router = APIRouter(prefix="/declarations", tags=["declarations"])

# ─── Schémas Pydantic ──────────────────────────────────────────────────────

class DeclarationCreate(BaseModel):
    vehicle_make: str
    vehicle_model: str
    vehicle_year: Optional[int] = None
    license_plate: Optional[str] = None
    driver_name: str
    driver_email: Optional[str] = None
    driver_phone: Optional[str] = None
    driver_age: Optional[int] = None
    accident_date: str
    accident_time: str
    accident_location: str
    accident_description: str
    images: Optional[List[str]] = []

class DeclarationUpdate(BaseModel):
    status: Optional[str] = None
    analysis: Optional[dict] = None

class DeclarationResponse(BaseModel):
    id: int
    user_id: int
    vehicle_make: str
    vehicle_model: str
    vehicle_year: Optional[int]
    license_plate: Optional[str]
    driver_name: str
    driver_email: Optional[str]
    driver_phone: Optional[str]
    driver_age: Optional[int]
    accident_date: str
    accident_time: str
    accident_location: str
    accident_description: str
    images: List[str]
    analysis: dict
    status: str
    created_at: str
    updated_at: Optional[str]

# ─── Routes ─────────────────────────────────────────────────────────────────

@router.post("/", response_model=DeclarationResponse, status_code=status.HTTP_201_CREATED)
async def create_declaration(
    declaration_data: DeclarationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Créer une nouvelle déclaration avec analyse IA"""
    
    # Analyser avec IA
    ai_analysis = await AIService.analyze_declaration(
        description=declaration_data.accident_description,
        driver_name=declaration_data.driver_name,
        driver_age=declaration_data.driver_age or 30,
        vehicle=f"{declaration_data.vehicle_make} {declaration_data.vehicle_model}"
    )
    
    # Créer la déclaration
    declaration = Declaration(
        user_id=current_user.id,
        vehicle_make=declaration_data.vehicle_make,
        vehicle_model=declaration_data.vehicle_model,
        vehicle_year=declaration_data.vehicle_year,
        license_plate=declaration_data.license_plate,
        driver_name=declaration_data.driver_name,
        driver_email=declaration_data.driver_email,
        driver_phone=declaration_data.driver_phone,
        driver_age=declaration_data.driver_age,
        accident_date=declaration_data.accident_date,
        accident_time=declaration_data.accident_time,
        accident_location=declaration_data.accident_location,
        accident_description=declaration_data.accident_description,
        images=declaration_data.images,
        analysis=ai_analysis,
        status="en_attente"
    )
    
    db.add(declaration)
    db.commit()
    db.refresh(declaration)
    
    return declaration.to_dict()


@router.get("/", response_model=List[DeclarationResponse])
async def get_declarations(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Récupérer toutes les déclarations de l'utilisateur"""
    declarations = db.query(Declaration).filter(
        Declaration.user_id == current_user.id
    ).order_by(Declaration.created_at.desc()).all()
    
    return [d.to_dict() for d in declarations]


@router.get("/{declaration_id}", response_model=DeclarationResponse)
async def get_declaration(
    declaration_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Récupérer une déclaration spécifique"""
    declaration = db.query(Declaration).filter(
        Declaration.id == declaration_id,
        Declaration.user_id == current_user.id
    ).first()
    
    if not declaration:
        raise HTTPException(status_code=404, detail="Déclaration non trouvée")
    
    return declaration.to_dict()


@router.patch("/{declaration_id}", response_model=DeclarationResponse)
async def update_declaration(
    declaration_id: int,
    update_data: DeclarationUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Mettre à jour le statut d'une déclaration"""
    declaration = db.query(Declaration).filter(
        Declaration.id == declaration_id,
        Declaration.user_id == current_user.id
    ).first()
    
    if not declaration:
        raise HTTPException(status_code=404, detail="Déclaration non trouvée")
    
    if update_data.status:
        declaration.status = update_data.status
    
    if update_data.analysis:
        declaration.analysis = update_data.analysis
    
    db.commit()
    db.refresh(declaration)
    
    return declaration.to_dict()