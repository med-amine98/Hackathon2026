from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
import requests

from app.database.connection import get_db
from app.models.prevention import Prevention
from app.models.user import User
from app.api.dependencies import get_current_user
from app.core.config import settings

router = APIRouter(prefix="/prevention", tags=["prevention"])

# ─── Schémas Pydantic ──────────────────────────────────────────────────────

class WeatherData(BaseModel):
    temperature: str
    feels_like: str
    humidity: str
    description: str
    icon: str
    wind_speed: str
    city: str
    country: str

class MaintenanceItem(BaseModel):
    icon: str
    title: str
    description: str
    date: str
    color: str
    urgent: bool

class PreventionResponse(BaseModel):
    id: int
    user_id: int
    weather_data: dict
    traffic_data: List[dict]
    maintenances: List[dict]
    safety_tips: List[str]
    alerts: List[str]
    created_at: str

# ─── Routes ─────────────────────────────────────────────────────────────────

@router.get("/data", response_model=PreventionResponse)
async def get_prevention_data(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Récupérer les données de prévention en temps réel"""
    
    # Récupérer la météo
    weather = await _get_weather()
    
    # Récupérer le trafic
    traffic = await _get_traffic()
    
    # Générer les rappels
    maintenances = _get_maintenance_reminders()
    
    # Générer les conseils
    safety_tips = _get_safety_tips(weather)
    
    # Générer les alertes
    alerts = _get_alerts(weather, traffic)
    
    # Sauvegarder
    prevention = Prevention(
        user_id=current_user.id,
        weather_data=weather,
        traffic_data=traffic,
        maintenances=maintenances,
        safety_tips=safety_tips,
        alerts=alerts
    )
    
    db.add(prevention)
    db.commit()
    db.refresh(prevention)
    
    return prevention.to_dict()


# ─── Fonctions privées ─────────────────────────────────────────────────────

async def _get_weather() -> dict:
    """Récupérer la météo depuis OpenWeather"""
    try:
        url = f"https://api.openweathermap.org/data/2.5/weather"
        params = {
            "lat": 36.8065,
            "lon": 10.1815,
            "appid": settings.openweather_api_key,
            "units": "metric",
            "lang": "fr"
        }
        response = requests.get(url, params=params)
        
        if response.status_code == 200:
            data = response.json()
            return {
                "temperature": f"{data['main']['temp']:.0f}°C",
                "feels_like": f"{data['main']['feels_like']:.0f}°C",
                "humidity": f"{data['main']['humidity']}%",
                "description": data['weather'][0]['description'],
                "icon": data['weather'][0]['icon'],
                "wind_speed": f"{data['wind']['speed']:.0f} km/h",
                "city": data.get('name', 'Tunis'),
                "country": data.get('sys', {}).get('country', 'TN')
            }
    except Exception as e:
        print(f"❌ Weather error: {e}")
    
    return {
        "temperature": "28°C",
        "feels_like": "26°C",
        "humidity": "65%",
        "description": "Ensoleillé avec quelques nuages",
        "icon": "01d",
        "wind_speed": "12 km/h",
        "city": "Tunis",
        "country": "TN"
    }

async def _get_traffic() -> List[dict]:
    """Récupérer les données de trafic depuis TomTom"""
    try:
        api_key = settings.tomtom_api_key
        if not api_key or api_key == "VOTRE_CLE_TOMTOM":
            return [{"type": "Information", "description": "Trafic fluide", "location": "Tunis", "delay": 0}]
        
        # Bounding box pour Tunis
        bbox = "10.125,36.761,10.238,36.852"
        url = f"https://api.tomtom.com/traffic/services/4/incidentDetails"
        params = {
            "key": api_key,
            "bbox": bbox,
            "language": "fr-FR",
            "fields": "{incidents{properties{category,from,to,delay}}}",
            "categoryFilter": "0,1,2,3,4,5,6,7,8,9,10,11,12,13,14"
        }
        response = requests.get(url, params=params)
        
        if response.status_code == 200:
            data = response.json()
            incidents = data.get('incidents', [])
            return [{
                "type": _get_category_name(incident.get('properties', {}).get('category', 0)),
                "description": incident.get('properties', {}).get('from', 'Incident'),
                "location": incident.get('properties', {}).get('to', 'Route'),
                "delay": incident.get('properties', {}).get('delay', 0)
            } for incident in incidents]
    except Exception as e:
        print(f"❌ Traffic error: {e}")
    
    return [{"type": "Information", "description": "Trafic fluide", "location": "Tunis", "delay": 0}]

def _get_category_name(category: int) -> str:
    categories = {
        0: "Accident", 1: "Congestion", 2: "Incident", 3: "Météo",
        4: "Route barrée", 5: "Chantier", 8: "Information",
        11: "Animal", 12: "Véhicule en panne"
    }
    return categories.get(category, "Incident")

def _get_maintenance_reminders() -> List[dict]:
    """Générer des rappels de maintenance"""
    return [
        {
            "icon": "Icons.oil_barrel",
            "title": "Vidange d'huile",
            "description": "Prévue dans 500 km",
            "date": "15/08/2026",
            "color": "#F59E0B",
            "urgent": False
        },
        {
            "icon": "Icons.car_repair",
            "title": "Plaquettes de frein",
            "description": "Usure avancée - À remplacer",
            "date": "01/08/2026",
            "color": "#EF4444",
            "urgent": True
        },
        {
            "icon": "Icons.battery_full",
            "title": "Batterie",
            "description": "Contrôle recommandé",
            "date": "20/08/2026",
            "color": "#3B82F6",
            "urgent": False
        }
    ]

def _get_safety_tips(weather: dict) -> List[str]:
    tips = [
        "✅ Vérifiez la pression des pneus avant chaque long trajet",
        "✅ Contrôlez les feux de signalisation mensuellement",
        "✅ Gardez une distance de sécurité de 2 secondes",
        "✅ Adaptez votre vitesse aux conditions de circulation",
        "✅ Faites une pause toutes les 2 heures sur les longs trajets"
    ]
    
    if "pluie" in weather.get("description", ""):
        tips.append("🌧️ Réduisez votre vitesse sur route mouillée")
    
    if "orage" in weather.get("description", ""):
        tips.append("⚡ Évitez de conduire pendant l'orage")
    
    return tips

def _get_alerts(weather: dict, traffic: List[dict]) -> List[str]:
    alerts = []
    
    if "pluie" in weather.get("description", ""):
        alerts.append("🌧️ Risque de pluie - Conduite prudente")
    
    for incident in traffic:
        if incident.get("delay", 0) > 5:
            alerts.append(f"🚦 Trafic dense - Prévoyez du temps supplémentaire")
            break
    
    return alerts