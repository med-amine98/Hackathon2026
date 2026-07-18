from sqlalchemy import MetaData, create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

# Check if SQLite is used to apply correct arguments
is_sqlite = settings.database_url.startswith("sqlite")

if is_sqlite:
    engine = create_engine(
        settings.database_url,
        connect_args={"check_same_thread": False}
    )
else:
    # Postgres: this backend now shares one physical database with the
    # agent's platform backend (see docker-compose.yml) instead of having
    # its own — every connection is pinned to this backend's own schema via
    # search_path, so its tables never collide with the agent's same-named
    # ones (conversations, messages) living in `public`.
    connect_args = (
        {"options": f"-csearch_path={settings.db_schema},public"}
        if settings.db_schema
        else {}
    )
    engine = create_engine(
        settings.database_url,
        pool_pre_ping=True,
        pool_size=10,
        max_overflow=20,
        connect_args=connect_args,
    )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# search_path alone doesn't stop this collision: platform/backend/app/
# models.py ALSO defines tables named "conversations" and "messages" (in
# the public schema) — the exact names this backend uses too, per the
# comment above. Base.metadata.create_all()'s existence check is visible
# across the whole search_path, not just the first schema on it, so it saw
# platform's public.conversations/messages already there and silently never
# created this backend's own mobile.conversations/mobile.messages — every
# ORM query against the unqualified table name then resolved via
# search_path straight into platform's unrelated agent-chat tables instead.
# Pinning an explicit schema on this Base's MetaData makes every generated
# statement (create_all's DDL and every ORM query) fully schema-qualified
# regardless of search_path, closing that gap for good.
_metadata = MetaData(schema=settings.db_schema) if (not is_sqlite and settings.db_schema) else None
Base = declarative_base(metadata=_metadata)


def ensure_schema() -> None:
    """
    Create this backend's Postgres schema if it doesn't exist yet. No-op for
    SQLite. Safe/idempotent to call on every startup.
    """
    if is_sqlite or not settings.db_schema:
        return
    with engine.connect() as conn:
        conn.execute(text(f'CREATE SCHEMA IF NOT EXISTS "{settings.db_schema}"'))
        conn.commit()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
