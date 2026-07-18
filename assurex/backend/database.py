import os

from sqlalchemy import MetaData, create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Inside the root docker-compose stack, DATABASE_URL/DB_SCHEMA are set by
# the assurex-api service to point at the shared Postgres "db" used by
# every other backend in this repo - see docker-compose.yml at the repo
# root.
SQLALCHEMY_DATABASE_URL = os.environ["DATABASE_URL"]
DB_SCHEMA = os.environ.get("DB_SCHEMA")

# Assurex shares ONE physical Postgres database with the agent's platform
# backend ("api"/"worker", public schema) and the mobile backend
# ("mobile-api", "mobile" schema). Every connection here is pinned to
# assurex's own schema via search_path so its tables (claims, users) never
# collide with the same-named ones living in the other backends' schemas.
connect_args = (
    {"options": f"-csearch_path={DB_SCHEMA},public"} if DB_SCHEMA else {}
)
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    pool_pre_ping=True,
    connect_args=connect_args,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# search_path alone isn't enough: platform/backend's models.py ALSO defines
# a table named "claims" (in the public schema), and Base.metadata.create_all()
# checks table existence across the whole search_path, not just the first
# schema on it. Pinning an explicit schema on this Base's MetaData makes
# every generated statement - DDL from create_all/migrate.py AND every ORM
# query - fully schema-qualified (`"assurex".claims`, never a bare `claims`),
# which removes the ambiguity outright regardless of search_path or what
# other backends' schemas contain.
_metadata = MetaData(schema=DB_SCHEMA) if DB_SCHEMA else None
Base = declarative_base(metadata=_metadata)


def ensure_schema() -> None:
    """
    Create assurex's own Postgres schema if it doesn't exist yet. Safe/
    idempotent to call on every startup.
    """
    if not DB_SCHEMA:
        return
    with engine.connect() as conn:
        conn.execute(text(f'CREATE SCHEMA IF NOT EXISTS "{DB_SCHEMA}"'))
        conn.commit()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
