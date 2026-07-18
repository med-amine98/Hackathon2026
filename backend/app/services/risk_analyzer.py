from typing import Dict, Any
from app.models.profile import UserProfile

class RiskAnalyzer:
    """Calculate risk scores for insurance profiles"""
    
    def __init__(self):
        self.risk_factors = {
            "age": self._calculate_age_risk,
            "driving_experience": self._calculate_driving_experience_risk,
            "annual_km": self._calculate_km_risk,
            "vehicle_usage": self._calculate_usage_risk,
            "parking": self._calculate_parking_risk,
            "city": self._calculate_city_risk
        }
    
    def calculate_risk_score(self, profile: UserProfile) -> Dict[str, Any]:
        """Calculate comprehensive risk score"""
        
        risk_details = {}
        total_score = 0
        
        # Calculate each risk factor
        for factor_name, factor_function in self.risk_factors.items():
            score = factor_function(profile)
            risk_details[factor_name] = score
            total_score += score
        
        # Normalize score to 0-100
        normalized_score = min(100, total_score)
        
        # Determine risk level
        if normalized_score < 30:
            risk_level = "low"
        elif normalized_score < 60:
            risk_level = "medium"
        else:
            risk_level = "high"
        
        return {
            "score": normalized_score,
            "level": risk_level,
            "details": risk_details,
            "factors": self._get_risk_factors(risk_details)
        }
    
    def _calculate_age_risk(self, profile: UserProfile) -> int:
        """Calculate risk based on age"""
        if not profile.age:
            return 0
        
        if profile.age < 22:
            return 25  # Very young driver
        elif profile.age < 25:
            return 20  # Young driver
        elif profile.age < 30:
            return 10  # Young adult
        elif profile.age < 60:
            return 5   # Experienced driver
        else:
            return 15  # Senior driver
    
    def _calculate_driving_experience_risk(self, profile: UserProfile) -> int:
        """Calculate risk based on driving experience"""
        if not profile.driving_experience_years:
            return 0
        
        if profile.driving_experience_years < 2:
            return 20
        elif profile.driving_experience_years < 5:
            return 10
        else:
            return 5
    
    def _calculate_km_risk(self, profile: UserProfile) -> int:
        """Calculate risk based on annual kilometers"""
        if not profile.annual_km:
            return 0
        
        if profile.annual_km > 30000:
            return 20  # Very high mileage
        elif profile.annual_km > 20000:
            return 15  # High mileage
        elif profile.annual_km > 10000:
            return 10  # Average mileage
        else:
            return 5   # Low mileage
    
    def _calculate_usage_risk(self, profile: UserProfile) -> int:
        """Calculate risk based on vehicle usage"""
        if not profile.vehicle_usage:
            return 0
        
        usage_risk = {
            "daily": 20,
            "professional": 25,
            "weekend": 10,
            "occasional": 5
        }
        return usage_risk.get(profile.vehicle_usage, 10)
    
    def _calculate_parking_risk(self, profile: UserProfile) -> int:
        """Calculate risk based on parking type"""
        if not profile.parking_type:
            return 0
        
        parking_risk = {
            "garage": 5,
            "private": 10,
            "street": 20
        }
        return parking_risk.get(profile.parking_type, 10)
    
    def _calculate_city_risk(self, profile: UserProfile) -> int:
        """Calculate risk based on city"""
        if not profile.city:
            return 0
        
        # Cities with higher traffic
        high_traffic_cities = ["Tunis", "Sfax", "Sousse"]
        if profile.city in high_traffic_cities:
            return 15
        else:
            return 5
    
    def _get_risk_factors(self, risk_details: Dict) -> list:
        """Get readable risk factors"""
        factors = []
        
        if risk_details.get("age", 0) >= 20:
            factors.append("Jeune conducteur")
        if risk_details.get("driving_experience", 0) >= 20:
            factors.append("Nouveau conducteur")
        if risk_details.get("annual_km", 0) >= 15:
            factors.append("Kilométrage élevé")
        if risk_details.get("vehicle_usage", 0) >= 20:
            factors.append("Utilisation quotidienne")
        if risk_details.get("city", 0) >= 15:
            factors.append("Zone à fort trafic")
        if risk_details.get("parking", 0) >= 15:
            factors.append("Stationnement dans la rue")
        
        return factors
