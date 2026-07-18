from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from app.core.config import settings
from app.database.connection import engine, Base
from app.api.routes import auth, chat, profile, products, recommendations ,declaration, conseil, prevention
# ✅ Créer les tables
Base.metadata.create_all(bind=engine)

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