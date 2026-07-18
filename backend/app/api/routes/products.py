"""
Product routes — list and retrieve insurance products.
Uses schemas from app.schemas.product (clean separation of concerns).
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional

from app.database.connection import get_db
from app.schemas.product import ProductSchema
from app.services.product_service import ProductService

router = APIRouter(prefix="/products", tags=["Products"])


@router.get("", response_model=List[ProductSchema])
def get_products(
    category: Optional[str] = None,
    db: Session = Depends(get_db),
):
    """List all active insurance products, optionally filtered by category."""
    product_service = ProductService(db)
    product_service.seed_default_products()
    return product_service.get_active_products(category)


@router.get("/{product_id}", response_model=ProductSchema)
def get_product(product_id: int, db: Session = Depends(get_db)):
    """Retrieve a specific insurance product by ID."""
    product_service = ProductService(db)
    product = product_service.get_product_by_id(product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return product
