from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # Database
    database_url: str
    # Postgres schema this backend's tables live in. Only used when
    # database_url is Postgres — lets the mobile backend and the agent's
    # platform backend share one physical Postgres instance/database
    # without their same-named tables (conversations, messages, ...)
    # colliding, since each backend owns its own schema/namespace within
    # it. Ignored for SQLite (no schema concept).
    db_schema: Optional[str] = "mobile"

    # JWT
    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    
    # OpenAI
    openai_api_key: Optional[str] = None

    # Weather / traffic (used by app/api/routes/prevention.py)
    openweather_api_key: Optional[str] = None
    tomtom_api_key: Optional[str] = None

    # Redis
    redis_url: Optional[str] = "redis://localhost:6379"
    
    # App
    app_name: str = "AI Insurance Advisor"
    app_version: str = "1.0.0"
    debug: bool = False
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"

settings = Settings()
