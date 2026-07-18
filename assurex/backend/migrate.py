"""
Additive, non-destructive schema fixups for the `claims` table.

Base.metadata.create_all() (called right after this in main.py) only
CREATEs tables that don't exist yet - it never ALTERs an existing table to
add columns. The very first version of this app's models.py defined a
narrower `claims` table (fewer columns, integer autoincrement id). Once
that table exists in a real deployment, later widening models.py (more
columns, string id like "CLM-8291") does nothing to the table already
sitting in Postgres - create_all just sees "claims already exists" and
skips it, and the app then crashes querying columns that were never added.

This module closes that gap WITHOUT ever dropping or truncating anything:
existing rows and every other table (users, and anything other apps in
this Postgres instance depend on, e.g. the agent backend's `public` schema
or the mobile backend's `mobile` schema) are left completely alone. It
only ever runs ADD COLUMN / ALTER COLUMN TYPE against `claims`, and only
for the columns/type that are actually missing - safe to run on every
startup (no-ops once the table is already current).

Postgres-only; a no-op for SQLite (local/standalone dev, recreated freely
from a throwaway file).
"""

from sqlalchemy import text

from seed import DEFAULT_ESTIMATION_IMAGE, DEFAULT_ESTIMATION_INSIGHTS

# (column name, Postgres type, extra DDL like a default) for every column
# in the current Claim model that might be missing from an older table.
# NOTE: purely additive - nothing here ever removes a column.
_CLAIM_COLUMNS = [
    ("type", "VARCHAR", None),
    ("gravity_color", "VARCHAR", None),
    ("risk_text", "VARCHAR", None),
    ("risk_color", "VARCHAR", None),
    ("photos_count", "INTEGER", "0"),
    ("ai_estimate", "DOUBLE PRECISION", None),
    ("ai_progress", "INTEGER", None),
    ("estimation_status", "VARCHAR", None),
    ("image_url", "VARCHAR", None),
    ("thumbnails", "JSON", None),
    ("hotspots", "JSON", None),
    ("subtotal", "DOUBLE PRECISION", "0.0"),
    ("total", "DOUBLE PRECISION", "0.0"),
    ("insights", "TEXT", None),
    ("client_id", "VARCHAR", None),
]

# After adding the columns above, pre-existing rows have NULL in all of
# them (a column that didn't exist has no value to carry over). Backfill
# sensible, non-destructive defaults ONLY where still NULL - same "no AI
# estimation on file yet" fallback content new claims get in main.py's
# create_claim. This never overwrites a value that's actually set (every
# statement is scoped to `WHERE col IS NULL`), so it can only fill gaps,
# never lose data.
_CLAIM_BACKFILL = [
    ("estimation_status", "AI Verification Required"),
    ("image_url", DEFAULT_ESTIMATION_IMAGE),
    ("insights", DEFAULT_ESTIMATION_INSIGHTS),
]

# Same idea as _CLAIM_COLUMNS, for `clients` - cin/plate_number/car_category/
# insurance_date/payment_status were added to Client for the AssureX client
# list (immatriculation, CIN, insurance date, paid/unpaid status, car
# category) after `clients` may already have existed in a real deployment.
_CLIENT_COLUMNS = [
    ("cin", "VARCHAR(20)", None),
    ("plate_number", "VARCHAR(20)", None),
    ("car_category", "VARCHAR(50)", None),
    ("insurance_date", "TIMESTAMPTZ", None),
    ("payment_status", "VARCHAR(20)", "'unpaid'"),
]


def _add_missing_columns(engine, qualified_table: str, columns: list[tuple[str, str, str | None]]) -> None:
    """
    Adds whatever columns in `columns` are missing from an already-existing
    table. Each column gets its OWN transaction (not one shared by the
    whole batch) so a single statement failing - a type mismatch, a lock, a
    column Postgres treats as already existing under a different case -
    can't roll back columns that already succeeded earlier in this same
    run. ADD COLUMN IF NOT EXISTS makes each statement safe to just retry
    blindly rather than depending on a separately-fetched existing-columns
    snapshot staying accurate for the whole loop.
    """
    for col_name, col_type, default in columns:
        ddl = f'ALTER TABLE {qualified_table} ADD COLUMN IF NOT EXISTS "{col_name}" {col_type}'
        if default is not None:
            ddl += f" DEFAULT {default}"
        try:
            with engine.begin() as conn:
                conn.execute(text(ddl))
        except Exception as e:
            print(f"⚠️  migrate.py: failed to add {qualified_table}.{col_name}: {e!r}")


def _table_exists(engine, qualified_table: str) -> bool:
    # Previously gated on inspector.get_table_names(schema=schema) - that
    # reads Postgres's cached catalog via SQLAlchemy's reflection, which in
    # practice returned an empty list here even though the table genuinely
    # existed in this schema (stale reflection cache / a fresh Inspector not
    # picking up a schema created moments earlier by ensure_schema() in the
    # same startup). When that check wrongly said "doesn't exist", the whole
    # migration silently never ran - exactly the "seed_if_empty crashes on
    # claims.type" bug this file exists to prevent. to_regclass() is a
    # direct, uncached catalog lookup - ground truth, not a reflection
    # snapshot.
    with engine.begin() as conn:
        exists = conn.execute(
            text("SELECT to_regclass(:qualified)"), {"qualified": qualified_table}
        ).scalar()
    return exists is not None


def run_migrations(engine, schema: str) -> None:
    if engine.dialect.name != "postgresql":
        return  # SQLite dev db - create_all/seed handle it fine as-is

    claims_table = f'"{schema}".claims'
    clients_table = f'"{schema}".clients'

    if _table_exists(engine, claims_table):
        _add_missing_columns(engine, claims_table, _CLAIM_COLUMNS)

        # Fill in sensible defaults where these are still NULL (only true
        # for rows that existed before the columns did) - scoped to
        # `WHERE ... IS NULL` so it can only ever fill a gap, never
        # overwrite a real value.
        for col_name, default_value in _CLAIM_BACKFILL:
            try:
                with engine.begin() as conn:
                    conn.execute(
                        text(f'UPDATE {claims_table} SET "{col_name}" = :val WHERE "{col_name}" IS NULL'),
                        {"val": default_value},
                    )
            except Exception as e:
                print(f"⚠️  migrate.py: failed to backfill claims.{col_name}: {e!r}")

        # Older deployments have `id` as an autoincrement INTEGER; the
        # current model uses a business id like "CLM-8291" (VARCHAR). Widen
        # the column in place - existing values are CAST, not dropped (e.g.
        # integer 1 becomes the string '1'), so no row is lost. DROP
        # DEFAULT first (safe/no-op if there wasn't one) to clear any
        # autoincrement sequence tied to the old integer column before
        # changing its type.
        try:
            with engine.begin() as conn:
                id_type = conn.execute(
                    text(
                        "SELECT data_type FROM information_schema.columns "
                        "WHERE table_schema = :schema AND table_name = 'claims' AND column_name = 'id'"
                    ),
                    {"schema": schema},
                ).scalar()
                if id_type and "int" in id_type.lower():
                    conn.execute(text(f"ALTER TABLE {claims_table} ALTER COLUMN id DROP DEFAULT"))
                    conn.execute(text(
                        f"ALTER TABLE {claims_table} ALTER COLUMN id TYPE VARCHAR USING id::VARCHAR"
                    ))
        except Exception as e:
            print(f"⚠️  migrate.py: failed to widen claims.id: {e!r}")

    if _table_exists(engine, clients_table):
        _add_missing_columns(engine, clients_table, _CLIENT_COLUMNS)
