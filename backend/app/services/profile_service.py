from sqlalchemy.orm import Session
from app.models.profile import UserProfile
from typing import Dict, Any, Optional

class ProfileService:
    def __init__(self, db: Session):
        self.db = db
        
    def get_or_create_profile(self, user_id: int) -> UserProfile:
        profile = self.db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
        if not profile:
            profile = UserProfile(
                user_id=user_id,
                preferred_coverage=[],
                risk_factors=[]
            )
            self.db.add(profile)
            self.db.commit()
            self.db.refresh(profile)
        return profile
        
    def update_profile_from_message(self, user_id: int, message: str, entities: Dict[str, Any]) -> UserProfile:
        profile = self.get_or_create_profile(user_id)
        
        # Update profile based on extracted entities
        if "age" in entities and entities["age"] is not None:
            profile.age = entities["age"]
        if "budget" in entities and entities["budget"] is not None:
            profile.budget_monthly = float(entities["budget"])
        if "vehicle" in entities and entities["vehicle"] is not None:
            profile.vehicle_model = entities["vehicle"]
            
        # Helper regex / keyword matching from message text
        message_lower = message.lower()
        if "garage" in message_lower:
            profile.parking_type = "garage"
        elif "rue" in message_lower or "street" in message_lower:
            profile.parking_type = "street"
        elif "privé" in message_lower or "private" in message_lower:
            profile.parking_type = "private"
            
        if "quotidien" in message_lower or "tous les jours" in message_lower or "daily" in message_lower:
            profile.vehicle_usage = "daily"
        elif "weekend" in message_lower or "fin de semaine" in message_lower:
            profile.vehicle_usage = "weekend"
        elif "occasionnel" in message_lower or "occasional" in message_lower:
            profile.vehicle_usage = "occasional"
            
        self.db.commit()
        self.db.refresh(profile)
        return profile
        
    def update_risk_score(self, profile_id: int, risk_analysis: Dict[str, Any]) -> UserProfile:
        profile = self.db.query(UserProfile).filter(UserProfile.id == profile_id).first()
        if profile:
            profile.risk_score = float(risk_analysis.get("score", 0))
            profile.risk_factors = risk_analysis.get("factors", [])
            self.db.commit()
            self.db.refresh(profile)
        return profile
