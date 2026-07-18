from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, engine
from app.routers import chat, claims, fault, photos
from app.storage import ensure_bucket

app = FastAPI(
    title="Smart Constat API",
    description="Backend platform for a digitized, fraud-aware constat amiable app (Tunisia).",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten before production
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(claims.router)
app.include_router(photos.router)
app.include_router(fault.router)
app.include_router(chat.router)


@app.on_event("startup")
def on_startup():
    # MVP: create tables directly from models. Replace with Alembic
    # migrations before this handles real data.
    Base.metadata.create_all(bind=engine)
    ensure_bucket()


@app.get("/health")
def health():
    return {"status": "ok"}
