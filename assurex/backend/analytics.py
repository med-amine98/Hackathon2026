"""
Aggregate statistics across every data source this portal touches - its own
seeded/manually-created claims & clients (assurex schema) AND the real
bridged data from the mobile app / agent chat (platform_claims.py /
mobile_clients.py, reading platform's `public` schema and the mobile
backend's `mobile` schema). Powers the "Analyse" page (GET
/api/analytics/overview) - a Power-BI-style overview of what's actually in
the database across all three backends sharing this one Postgres instance,
not just assurex's own slice of it.

Reuses fetch_platform_claims/fetch_mobile_clients rather than re-deriving
their gravity/status/payment-status mappings a second time here, so this
page can never drift out of sync with what the Claims/Clients pages
themselves show.
"""
import logging
from collections import Counter
from datetime import datetime
from typing import Any

from sqlalchemy import text
from sqlalchemy.orm import Session

from models import Claim, Client
import mobile_clients
import platform_claims

logger = logging.getLogger(__name__)


def _month_key(dt: datetime) -> str:
    return dt.strftime("%Y-%m")


def build_overview(db: Session) -> dict[str, Any]:
    assurex_claims = db.query(Claim).all()
    assurex_clients = db.query(Client).all()
    real_claims = platform_claims.fetch_platform_claims(db)
    real_clients = mobile_clients.fetch_mobile_clients(db)

    # --- Claims: status + gravity, merged across both sources ---
    status_counts = Counter(
        [c.status for c in assurex_claims] + [c["status"] for c in real_claims]
    )
    gravity_counts = Counter(
        [c.gravity for c in assurex_claims if c.gravity] + [c["gravity"] for c in real_claims if c["gravity"]]
    )

    # --- Clients: payment status + car category, merged across both sources ---
    payment_counts = Counter(
        [(c.payment_status or "unpaid") for c in assurex_clients]
        + [c["payment_status"] for c in real_clients]
    )
    category_counts = Counter(
        [c.car_category for c in assurex_clients if c.car_category]
        + [c["car_category"] for c in real_clients if c["car_category"]]
    )

    # --- Fault engine + photos: platform-only concepts, no assurex equivalent ---
    # Same standalone/not-yet-migrated fallback as platform_claims.py /
    # mobile_clients.py: these raw queries hit platform/backend's own
    # public.* tables directly, which may not exist if that backend hasn't
    # started/migrated against the shared Postgres yet (or this container is
    # running on its own SQLite). Degrade to zeros/empty rather than 500 the
    # whole "Analyse" page over stats that are genuinely just unavailable
    # yet, not broken.
    try:
        fault_reviews = db.execute(
            text("SELECT needs_manual_review FROM public.fault_determinations")
        ).scalars().all()
        photos_count = db.execute(text("SELECT COUNT(*) FROM public.photos")).scalar() or 0
        # Only populated for conversations that happened after this column was
        # added (see platform/backend/app/models.py's Conversation.last_mood) -
        # older conversations just have NULL here, which is why this is built
        # to render an empty state gracefully rather than assume data exists.
        mood_rows = db.execute(
            text(
                "SELECT last_mood, injury_mentioned, dispute_mentioned "
                "FROM public.conversations WHERE last_mood IS NOT NULL"
            )
        ).all()
        platform_dates = [
            d for d in db.execute(text("SELECT created_at FROM public.claims")).scalars().all() if d
        ]
    except Exception as exc:
        db.rollback()
        logger.warning(
            "AssureX analytics <-> platform bridge query failed (platform "
            "backend's tables may not exist yet, or this is running without "
            "the shared Postgres) - falling back to assurex-only stats: %s",
            exc,
        )
        fault_reviews, photos_count, mood_rows, platform_dates = [], 0, [], []

    fault_total = len(fault_reviews)
    needs_review_count = sum(1 for r in fault_reviews if r)
    mood_counts = Counter(r[0] for r in mood_rows)
    injury_mentioned_count = sum(1 for r in mood_rows if r[1])
    dispute_mentioned_count = sum(1 for r in mood_rows if r[2])

    # --- Claims filed over time (both sources combined, by month) ---
    assurex_dates = [c.created_at for c in assurex_claims if c.created_at]
    month_counts = Counter(_month_key(d) for d in assurex_dates + platform_dates)
    claims_over_time = [{"month": m, "count": c} for m, c in sorted(month_counts.items())]

    return {
        "kpis": {
            "total_claims": len(assurex_claims) + len(real_claims),
            "total_clients": len(assurex_clients) + len(real_clients),
            "unpaid_clients": payment_counts.get("unpaid", 0),
            "photos_uploaded": photos_count,
            "fault_needs_review_pct": (
                round(100 * needs_review_count / fault_total, 1) if fault_total else 0
            ),
        },
        "claims_by_status": [{"status": s, "count": c} for s, c in status_counts.items()],
        "claims_by_gravity": [{"gravity": g, "count": c} for g, c in gravity_counts.items()],
        "clients_by_payment_status": [{"status": s, "count": c} for s, c in payment_counts.items()],
        "clients_by_car_category": [{"category": cat, "count": c} for cat, c in category_counts.items()],
        "claims_over_time": claims_over_time,
        "mood": {
            "distribution": [{"mood": m, "count": c} for m, c in mood_counts.items()],
            "total_tracked": len(mood_rows),
            "injury_mentioned_count": injury_mentioned_count,
            "dispute_mentioned_count": dispute_mentioned_count,
        },
    }
