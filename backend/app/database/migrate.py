"""
Additive, non-destructive schema fixups for tables whose Python model grew
new columns after the table already existed in a real Postgres deployment.

Base.metadata.create_all() (called right after this in main.py) only
CREATEs tables that don't exist yet — it never ALTERs an existing one. This
backend never had a reconciler for that gap (unlike platform/backend's
ensure_schema() and assurex/backend's migrate.py, which both exist for the
exact same reason) — the first columns to actually hit it are User's new
cin/plate_number/car_category/insurance_date/payment_status fields (see
app/models/user.py): on any deployment where `users` already exists from
before those columns were added, every query touching them would otherwise
crash with UndefinedColumn, exactly like the assurex claims.type bug this
pattern was written to prevent.

Uses to_regclass() for existence (a direct, uncached catalog lookup) and
one transaction per column (so one failing statement can't roll back
columns that already succeeded) — see assurex/backend/migrate.py's
docstring for the full reasoning behind both choices.

Postgres-only; a no-op for SQLite (local/standalone dev, recreated freely
from a throwaway file).
"""
from sqlalchemy import text

# (column name, Postgres type, extra DDL like a default) for every column
# added to User after `users` may already have existed in a real deployment.
_USER_COLUMNS = [
    ("cin", "VARCHAR(20)", None),
    ("plate_number", "VARCHAR(20)", None),
    ("car_category", "VARCHAR(50)", None),
    ("insurance_date", "TIMESTAMPTZ", None),
    ("payment_status", "VARCHAR(20)", "'unpaid'"),
]


def run_migrations(engine, schema: str | None) -> None:
    if engine.dialect.name != "postgresql":
        return  # SQLite dev db - create_all handles it fine as-is

    qualified = f'"{schema}".users' if schema else "users"

    with engine.begin() as conn:
        exists = conn.execute(text("SELECT to_regclass(:q)"), {"q": qualified}).scalar()
    if exists is None:
        return  # doesn't exist yet - create_all will make it with every current column

    for col_name, col_type, default in _USER_COLUMNS:
        ddl = f'ALTER TABLE {qualified} ADD COLUMN IF NOT EXISTS "{col_name}" {col_type}'
        if default is not None:
            ddl += f" DEFAULT {default}"
        try:
            with engine.begin() as conn:
                conn.execute(text(ddl))
        except Exception as e:
            print(f"⚠️  migrate.py: failed to add users.{col_name}: {e!r}")
