from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import declarative_base, sessionmaker

from app.config import DATABASE_URL

connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}
engine = create_engine(DATABASE_URL, connect_args=connect_args)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def ensure_schema() -> None:
    """
    MVP substitute for real migrations (see main.py's on_startup comment).
    Base.metadata.create_all() only creates tables that don't exist yet — it
    silently does NOT add new columns to a table that already exists. That
    gap let a real bug ship: ClientProfile.mobile_user_id was added to the
    model, but pgdata is a named, persistent Docker volume (see
    docker-compose.yml), so every already-running deployment kept its OLD
    client_profiles table without that column. Every INSERT/UPDATE into it
    then failed with an UndefinedColumn error, silently swallowed by the
    best-effort try/except around every call site (see assistant/db.py's
    module docstring) — no error surfaced anywhere, the table just stayed
    empty forever even though the code looked correct.

    This walks every model's columns, compares against what's actually in
    the database, and ALTERs in whatever's missing. Deliberately additive
    only (ADD COLUMN, always nullable) — never drops or modifies an existing
    column, so the worst-case failure mode is "a column doesn't get added
    automatically," never data loss. Replace with real Alembic migrations
    before this handles anything beyond a hackathon prototype.
    """
    inspector = inspect(engine)
    existing_tables = set(inspector.get_table_names())
    with engine.begin() as conn:
        for table in Base.metadata.sorted_tables:
            if table.name not in existing_tables:
                continue  # brand new table — create_all() already created it with every column
            existing_columns = {col["name"] for col in inspector.get_columns(table.name)}
            for column in table.columns:
                if column.name in existing_columns:
                    continue
                ddl_type = column.type.compile(dialect=engine.dialect)
                conn.execute(text(f'ALTER TABLE "{table.name}" ADD COLUMN "{column.name}" {ddl_type}'))
