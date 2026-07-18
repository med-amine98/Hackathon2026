from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from app.core.config import settings
from app.database.connection import engine, Base, ensure_schema, SessionLocal
from app.database.migrate import run_migrations
from app.database.seed import seed_if_empty
from app.api.routes import auth, chat, profile, products, recommendations ,declaration, conseil, prevention
# ✅ Créer le schéma (Postgres partagé avec le backend de l'agent) puis les tables
ensure_schema()
run_migrations(engine, settings.db_schema)
Base.metadata.create_all(bind=engine)

# Demo Tunisian users, only inserted if `users` is completely empty (see
# app/database/seed.py) - gives the AssureX portal's client list something
# real to bridge in (assurex/backend/mobile_clients.py) without waiting on
# actual signups, and never touches a deployment that already has real users.
_seed_db = SessionLocal()
try:
    seed_if_empty(_seed_db)
finally:
    _seed_db.close()

# ✅ Créer l'application FastAPI
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None
)

# ✅ CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ Inclure les routers
app.include_router(auth.router, prefix="/api/v1")
app.include_router(chat.router, prefix="/api/v1")
app.include_router(profile.router, prefix="/api/v1")
app.include_router(products.router, prefix="/api/v1")
app.include_router(recommendations.router, prefix="/api/v1")
app.include_router(declaration.router, prefix="/api/v1")  
app.include_router(conseil.router, prefix="/api/v1")      
app.include_router(prevention.router, prefix="/api/v1")    
# ✅ Routes racine
@app.get("/")
async def root():
    return {
        "name": settings.app_name,
        "version": settings.app_version,
        "status": "operational"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

# ✅ Point d'entrée
if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.debug
    )