"""
Read bridge to the mobile app's real registered users, shown as clients in
the AssureX agency portal - per direction "users = clients": the portal's
`clients` list should include real mobile-app account holders, not just
assurex's own seeded/manually-created demo rows (same "the data's in the
database, just not in the table this screen queries" gap already fixed for
claims - see platform_claims.py's module docstring for the fuller story).

Reuses that same file's approach: raw, schema-qualified SQL against
`mobile.*` (this container doesn't have the mobile backend's Python package
mounted in, so importing its ORM models isn't an option) rather than a
second copy of its models.
"""
from typing import Any, Optional

from sqlalchemy import text
from sqlalchemy.orm import Session


def _initials(first_name: Optional[str], last_name: Optional[str], email: str) -> str:
    parts = [p[0] for p in (first_name, last_name) if p]
    if parts:
        return "".join(parts).upper()[:2]
    return (email or "?")[:2].upper()


def _full_name(first_name: Optional[str], last_name: Optional[str], email: str) -> str:
    name = " ".join(p for p in (first_name, last_name) if p)
    return name or email


def _client_row_to_summary(row: dict, claims_count: int) -> dict[str, Any]:
    return {
        # "user-" prefix keeps these ids distinct from assurex's own demo
        # ids ("c-1", "c-2", ...) so the two lists can never collide.
        "id": f"user-{row['id']}",
        "name": _full_name(row["first_name"], row["last_name"], row["email"]),
        "type": row["car_category"] or "Client mobile",
        # No fidelity-score/risk-quiz data collected for every mobile user
        # (that only exists per-conversation in user_profiles, and only for
        # users who went through the buy-insurance chat flow) - default to
        # a neutral, clearly-a-placeholder score rather than fabricating one.
        "score": 70,
        "risk": 50,
        "risk_text": "Unrated",
        "risk_color": "text-on-surface-variant",
        "last_contact": "—",
        "initials": _initials(row["first_name"], row["last_name"], row["email"]),
        "email": row["email"],
        "phone": row["phone"] or "—",
        "address": "—",
        "joined": row["created_at"].strftime("%B %Y") if row["created_at"] else "—",
        "policies": [],
        "claims_history": [],
        # Real new fields requested for the client list - see
        # app/models/user.py (mobile backend).
        "cin": row["cin"],
        "plate_number": row["plate_number"],
        "car_category": row["car_category"],
        "insurance_date": row["insurance_date"].strftime("%d/%m/%Y") if row["insurance_date"] else None,
        "payment_status": row["payment_status"] or "unpaid",
        "claims_count": claims_count,
        # No agent-notes table for mobile-bridged clients yet - POST
        # /api/clients/{id}/notes only writes to assurex's own Client rows
        # (see main.py), so this starts empty and stays read-only for now.
        "notes": [],
    }


def fetch_mobile_clients(db: Session) -> list[dict[str, Any]]:
    """List summaries of every real mobile-app user, newest first - merged into GET /api/clients alongside assurex's own demo/manual rows."""
    rows = db.execute(
        text(
            """
            SELECT id, email, first_name, last_name, phone, created_at,
                   cin, plate_number, car_category, insurance_date, payment_status
            FROM mobile.users
            ORDER BY created_at DESC
            """
        )
    ).mappings().all()

    if not rows:
        return []

    claims_counts = dict(
        db.execute(
            text(
                "SELECT user_id, COUNT(*) FROM mobile.declarations "
                "WHERE user_id = ANY(:ids) GROUP BY user_id"
            ),
            {"ids": [r["id"] for r in rows]},
        ).all()
    )

    return [_client_row_to_summary(dict(r), claims_counts.get(r["id"], 0)) for r in rows]
