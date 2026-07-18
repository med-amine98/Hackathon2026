"""
One-time demo data for the mobile backend's `users` table - Tunisian, to
match the rest of this app (constat amiable, Derja/French client-facing
copy, Tunisian insurers referenced in assistant/prompts.py) and to give the
AssureX portal's client list (see assurex/backend/mobile_clients.py, which
bridges real mobile users in as "clients") something to show out of the box
instead of being empty until real signups happen.

Only seeds when `users` is completely empty (see seed_if_empty below) - a
real deployment with real signups is never touched or overwritten.
"""
from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.core.security import get_password_hash
from app.models.user import User


def _tn_date(year: int, month: int, day: int) -> datetime:
    return datetime(year, month, day, tzinfo=timezone.utc)


# Demo password for every seeded account - "demo1234" - fine for a
# hackathon/local-dev seed; never use a fixed demo password for real
# accounts in production.
_DEMO_PASSWORD_HASH = get_password_hash("demo1234")

USERS = [
    {
        "email": "amira.gharbi@gmail.com",
        "first_name": "Amira",
        "last_name": "Gharbi",
        "phone": "+216 25 147 963",
        "is_active": True,
        "is_verified": True,
        "cin": "06478215",
        "plate_number": "134 TUN 5567",
        "car_category": "Citadine",
        "insurance_date": _tn_date(2026, 2, 18),
        "payment_status": "paid",
    },
    {
        "email": "karim.jendoubi@outlook.com",
        "first_name": "Karim",
        "last_name": "Jendoubi",
        "phone": "+216 20 963 741",
        "is_active": True,
        "is_verified": True,
        "cin": "08234567",
        "plate_number": "201 TUN 9012",
        "car_category": "SUV",
        "insurance_date": _tn_date(2025, 11, 3),
        "payment_status": "unpaid",
    },
    {
        "email": "yasmine.dridi@yahoo.fr",
        "first_name": "Yasmine",
        "last_name": "Dridi",
        "phone": "+216 27 852 369",
        "is_active": True,
        "is_verified": False,
        "cin": "04512378",
        "plate_number": "167 TUN 3384",
        "car_category": "Berline",
        "insurance_date": _tn_date(2026, 6, 22),
        "payment_status": "paid",
    },
    {
        # Deliberately a "clean record" demo account - a real registered
        # vehicle/policy on file but no constat/claim ever filed through the
        # agent chat (see assurex/backend/mobile_clients.py, which counts
        # claims via public.vehicle_declarations joined on mobile_user_id -
        # since no claim/conversation is ever seeded for this user, that
        # count is correctly zero, not a fake/hardcoded 0). Useful for
        # demoing the client list/portfolio view with a client who has never
        # had an incident, not just ones mid-claim.
        "email": "nour.ayari@gmail.com",
        "first_name": "Nour",
        "last_name": "Ayari",
        "phone": "+216 23 741 852",
        "is_active": True,
        "is_verified": True,
        "cin": "09876543",
        "plate_number": "189 TUN 1123",
        "car_category": "Familiale",
        "insurance_date": _tn_date(2026, 5, 10),
        "payment_status": "paid",
    },
]


def seed_if_empty(db: Session) -> None:
    """Insert the demo users if `users` is completely empty. Idempotent - safe to call on every startup."""
    if db.query(User).first() is not None:
        return
    for row in USERS:
        db.add(User(hashed_password=_DEMO_PASSWORD_HASH, **row))
    db.commit()
