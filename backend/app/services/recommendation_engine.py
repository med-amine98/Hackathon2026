from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session
from sqlalchemy import and_
from app.models.product import InsuranceProduct
from app.models.profile import UserProfile
from app.models.recommendation import Recommendation

class RecommendationEngine:
    def __init__(self, db: Session):
        self.db = db
    
    def get_recommendations(self, profile: UserProfile, risk_score: Dict) -> List[Dict]:
        """Get insurance recommendations based on profile and risk"""
        
        # Get eligible products
        products = self._get_eligible_products(profile)
        
        # Score each product
        scored_products = []
        for product in products:
            score = self._score_product(product, profile, risk_score)
            scored_products.append({
                "product": product,
                "score": score,
                "match_reasons": self._get_match_reasons(product, profile)
            })
        
        # Sort by score
        scored_products.sort(key=lambda x: x["score"], reverse=True)
        
        # Format recommendations
        recommendations = []
        for item in scored_products[:5]:  # Top 5
            product = item["product"]
            recommendations.append({
                "id": product.id,
                "name": product.name,
                "provider": product.provider,
                "monthly_premium": product.monthly_premium,
                "coverage_amount": product.coverage_amount,
                "features": product.features or [],
                "match_score": item["score"],
                "match_reasons": item["match_reasons"],
                "is_best": item["score"] >= 80
            })
        
        # Save recommendations
        self._save_recommendations(profile.user_id, recommendations)
        
        return recommendations
    
    def _get_eligible_products(self, profile: UserProfile) -> List[InsuranceProduct]:
        """Get products that match user eligibility"""
        query = self.db.query(InsuranceProduct).filter(
            InsuranceProduct.is_active == True,
            InsuranceProduct.category == "auto"
        )
        
        # Filter by age
        if profile.age:
            query = query.filter(
                and_(
                    InsuranceProduct.min_age <= profile.age,
                    InsuranceProduct.max_age >= profile.age
                )
            )
        
        return query.all()
    
    def _score_product(self, product: InsuranceProduct, profile: UserProfile, risk_score: Dict) -> int:
        """Score a product based on user profile"""
        score = 50  # Base score
        
        # Budget fit
        if profile.budget_monthly and product.monthly_premium <= profile.budget_monthly:
            score += 20
        elif profile.budget_monthly and product.monthly_premium <= profile.budget_monthly * 1.2:
            score += 10
        
        # Risk fit
        if risk_score["level"] == "high" and product.coverage_amount > 100000:
            score += 15
        elif risk_score["level"] == "low" and product.coverage_amount < 50000:
            score += 10
        
        # Features match
        if profile.preferred_coverage:
            preferred = set(profile.preferred_coverage)
            features = set(product.features or [])
            match_ratio = len(preferred & features) / len(preferred) if preferred else 0
            score += match_ratio * 15
        
        # Rating bonus
        if product.rating:
            score += product.rating * 2
        
        return min(100, int(score))
    
    def _get_match_reasons(self, product: InsuranceProduct, profile: UserProfile) -> List[str]:
        """Get reasons why a product matches the user"""
        reasons = []
        
        if profile.budget_monthly and product.monthly_premium <= profile.budget_monthly:
            reasons.append("✓ adapté à votre budget")
        
        if product.features:
            if "theft" in product.features:
                reasons.append("✓ protection vol")
            if "collision" in product.features:
                reasons.append("✓ protection collision")
            if "assistance" in product.features:
                reasons.append("✓ assistance 24/7")
            if "legal_help" in product.features:
                reasons.append("✓ protection juridique")
        
        if profile.vehicle_usage == "daily":
            reasons.append("✓ adapté à une utilisation quotidienne")
        
        return reasons[:4]  # Limit to 4 reasons
    
    def _save_recommendations(self, user_id: int, recommendations: List[Dict]):
        """Save recommendations to database"""
        # Clear old recommendations
        self.db.query(Recommendation).filter(
            Recommendation.user_id == user_id
        ).delete()
        
        for rec in recommendations[:5]:
            recommendation = Recommendation(
                user_id=user_id,
                product_id=rec["id"],
                match_score=rec["match_score"],
                is_accepted=False
            )
            self.db.add(recommendation)
        
        self.db.commit()
    
    def get_quick_quote(self, user_id: int, product_category: Optional[str] = None) -> Dict:
        """Get quick quote for user"""
        # Simplified quote logic
        return {
            "message": "Voici quelques devis adaptés à votre profil",
            "products": [
                {
                    "name": "Auto Protect Premium",
                    "provider": "Assurance Tunisie",
                    "monthly_premium": 85.0,
                    "coverage": "Tous risques"
                },
                {
                    "name": "Auto Safe Basic",
                    "provider": "Maghreb Assurance",
                    "monthly_premium": 55.0,
                    "coverage": "Responsabilité civile"
                }
            ]
        }
