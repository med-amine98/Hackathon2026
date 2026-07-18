from sqlalchemy.orm import Session
from app.models.product import InsuranceProduct
from typing import List, Optional

class ProductService:
    def __init__(self, db: Session):
        self.db = db
        
    def get_active_products(self, category: Optional[str] = None) -> List[InsuranceProduct]:
        query = self.db.query(InsuranceProduct).filter(InsuranceProduct.is_active == True)
        if category:
            query = query.filter(InsuranceProduct.category == category)
        return query.all()
        
    def get_product_by_id(self, product_id: int) -> Optional[InsuranceProduct]:
        return self.db.query(InsuranceProduct).filter(InsuranceProduct.id == product_id).first()
        
    def seed_default_products(self):
        # Check if already seeded
        if self.db.query(InsuranceProduct).count() > 0:
            return
            
        defaults = [
            InsuranceProduct(
                name="Auto Protect Premium",
                provider="Assurance Tunisie",
                category="auto",
                coverage_amount=150000.0,
                deductible=500.0,
                monthly_premium=85.0,
                features=["theft", "collision", "assistance", "legal_help"],
                coverage_details={"theft_limit": 100000, "collision_deductible": 500},
                min_age=18,
                max_age=75,
                vehicle_requirements={"max_age": 10},
                rating=4.8,
                reviews_count=120,
                is_active=True
            ),
            InsuranceProduct(
                name="Auto Safe Basic",
                provider="Maghreb Assurance",
                category="auto",
                coverage_amount=40000.0,
                deductible=200.0,
                monthly_premium=45.0,
                features=["liability"],
                coverage_details={"liability_limit": 40000},
                min_age=18,
                max_age=80,
                vehicle_requirements={},
                rating=4.2,
                reviews_count=85,
                is_active=True
            ),
            InsuranceProduct(
                name="Auto Med Comfort",
                provider="GAT Assurances",
                category="auto",
                coverage_amount=80000.0,
                deductible=300.0,
                monthly_premium=60.0,
                features=["theft", "assistance"],
                coverage_details={"theft_limit": 50000},
                min_age=21,
                max_age=70,
                vehicle_requirements={"usage": "daily"},
                rating=4.5,
                reviews_count=64,
                is_active=True
            )
        ]
        
        self.db.add_all(defaults)
        self.db.commit()
