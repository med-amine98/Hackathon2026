"""
Read (and light write) bridge to the agent's real accident-intake data.

Why this file exists: the assurex `claims` table (models.py's Claim) is this
portal's OWN pipeline-tracking record - seeded demo rows, plus whatever an
agent creates by hand via the "New Claim" modal. It has never had anything
to do with the real constats clients file through the mobile app's agent
chat (see platform/backend/app/routers/chat.py) - those live in a
completely different table shape (`claims` / `vehicle_declarations` /
`fault_determinations` / `photos` / `conversations` / `client_profiles`),
owned by the platform backend, sitting in the `public` schema of the SAME
physical Postgres instance this service connects to (see docker-compose.yml
- one "db" service, multiple schemas). Nothing ever copied one into the
other, so real submitted constats never showed up in this portal even
though they were correctly persisted - the classic "data's in the database,
just not in the table this screen queries" gap.

This module bridges that read-only (plus one narrow write, see
update_platform_claim_status) by querying `public.*` directly with raw SQL
- assurex-api's container doesn't have platform/backend's Python package
mounted in, so importing its ORM models isn't an option the way
assistant/db.py does it; schema-qualified SQL against the shared Postgres
needs nothing extra mounted.

Real damage photos a client uploaded during the mobile chat are now shown
here too, via platform/backend's new GET /claims/{id}/photos/{photo_id}/file
(app/routers/photos.py) - that's the actual pixels an employee needs to
assess damage severity themselves, not a placeholder. The seeded demo
claims' own images (seed.py's CLAIMS/DEFAULT_ESTIMATION_IMAGE) are still
never touched or replaced - a real constat with zero uploaded photos falls
back to that same placeholder, same as before, it just no longer ALWAYS
falls back to it once real photos exist.

Real AI damage hotspots/costs also now come through here, read from
public.damage_estimates - the output of the YOLO11 pipeline in
platform/backend/app/damage_detection.py, run per-photo by
app/worker.py's run_damage_assessment (queued from app/routers/photos.py on
every upload). Empty until the worker has processed at least one photo for
a claim, in which case this falls back to the same empty-hotspots shape
AIEstimation.jsx already renders cleanly.
"""
import logging
import os
from typing import Any, Optional

from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from seed import DEFAULT_ESTIMATION_IMAGE, DEFAULT_ESTIMATION_INSIGHTS

logger = logging.getLogger(__name__)

# These queries assume the platform backend's tables (public.claims,
# public.fault_determinations, ...) already exist in the SAME Postgres
# database - true once the full docker-compose stack (db + api + worker +
# assurex-api) has started at least once, but NOT true if only this one
# container is up while the others are still starting/unhealthy. Without
# this guard,
# every GET /api/claims request would 500 with a raw, unhelpful
# "relation public.claims does not exist" in that situation, taking down the
# demo/manual claims list along with it even though those don't depend on
# the platform bridge at all. Each bridge function below instead logs a
# clear warning server-side and degrades to "no real constats available yet"
# (empty list / None / False), so the rest of the portal keeps working and
# the caller gets a clean response instead of an unhandled crash.
def _platform_unavailable(db: Session, exc: Exception) -> None:
    db.rollback()  # clears the aborted-transaction state Postgres leaves behind after a failed query
    logger.warning(
        "AssureX <-> platform bridge query failed (platform backend's tables "
        "may not exist yet, or this is running without the shared Postgres) "
        "- falling back to assurex-only data: %s",
        exc,
    )

# Base URL the BROWSER (not this container) uses to reach platform/backend's
# "api" service directly for photo bytes and the constat PDF - see
# docker-compose.yml's "api" service (host port 8010) and the Flutter app's
# ApiConstants.agentBaseUrl, which defaults to the same host:port for the
# same reason: these URLs are handed to a client outside this container,
# so "localhost" here means the browser's localhost, not assurex-api's.
PLATFORM_API_BASE = os.environ.get("PLATFORM_API_BASE", "http://localhost:8010")

# platform Claim.status -> this portal's 4-stage pipeline column.
# draft/both_declared: still being filled in by the client(s) in chat.
# fault_determined: the fault engine has run - ready for an agent to review
# the estimate, same meaning as this portal's "estimation" column.
# needs_review: fault engine couldn't determine a clean split - needs a
# human, same meaning as this portal's "review" column.
# closed: done.
_STATUS_TO_ASSUREX = {
    "draft": "new",
    "both_declared": "new",
    "fault_determined": "estimation",
    "needs_review": "review",
    "closed": "completed",
}
# Reverse of the above, used by update_platform_claim_status when an agent
# drags a real-constat card between pipeline columns in this portal. Several
# assurex statuses could plausibly map back to more than one platform
# status ("estimation" could mean fault_determined OR needs_review) - this
# picks the more common/expected one for a manual move in that direction.
_STATUS_FROM_ASSUREX = {
    "new": "draft",
    "estimation": "fault_determined",
    "review": "needs_review",
    "completed": "closed",
}


def _gravity_and_risk(fault_row: Optional[dict], damages_exceed_cap: bool) -> tuple[str, int]:
    """
    Heuristic only - platform's data model has no gravity/risk-percentage
    concept at all (see platform/backend/app/models.py's FaultDetermination
    - just a fault split and a manual-review flag). This maps what IS there
    onto assurex's display vocabulary so a real claim renders sensibly in a
    UI built for the demo shape, same spirit as the fault percentages
    themselves being explicitly flagged elsewhere in this codebase as
    prototype placeholders pending the official FTUSA barème.
    """
    if fault_row is None:
        return "Moderate", 50  # no fault result yet - genuinely unknown
    if fault_row["needs_manual_review"]:
        return "High", 75
    if damages_exceed_cap:
        return "Moderate", 60
    return "Minor", max(int(fault_row["fault_a_pct"] or 0), int(fault_row["fault_b_pct"] or 0))


def _claim_row_to_summary(row: dict, photos_count: int) -> dict[str, Any]:
    fault_row = (
        {
            "fault_a_pct": row["fault_a_pct"],
            "fault_b_pct": row["fault_b_pct"],
            "needs_manual_review": row["needs_manual_review"],
        }
        if row["fault_a_pct"] is not None
        else None
    )
    gravity, risk = _gravity_and_risk(fault_row, row["damages_exceed_cap"])
    gravity_colors = {"Critical": "bg-error", "High": "bg-error", "Moderate": "bg-orange-500", "Minor": "bg-green-500"}
    risk_colors = {"Critical": "text-error", "High": "text-error", "Moderate": "text-orange-600", "Minor": "text-green-600"}

    vehicle = row["vehicle_make_model"] or (
        f"Plate {row['plate_number']}" if row["plate_number"] else "Unregistered vehicle"
    )

    return {
        "id": row["id"],
        "type": "Constat Amiable (Mobile)",
        "gravity": gravity,
        "gravity_color": gravity_colors.get(gravity, "bg-primary"),
        "risk": risk,
        "risk_text": f"{gravity} ({risk}%)",
        "risk_color": risk_colors.get(gravity, "text-primary"),
        "status": _STATUS_TO_ASSUREX.get(row["status"], "new"),
        "vehicle": vehicle,
        "vehicle_type": "—",
        "agent_initials": "AI",
        "time_left": "Filed via app",
        "photos_count": photos_count,
    }


def fetch_platform_claims(db: Session) -> list[dict[str, Any]]:
    """List summaries of every real constat, newest first - merged into GET /api/claims alongside assurex's own demo/manual rows."""
    try:
        rows = db.execute(
            text(
                """
                SELECT
                    c.id, c.status, c.created_at, c.damages_exceed_cap,
                    fd.fault_a_pct, fd.fault_b_pct, fd.needs_manual_review,
                    cp.vehicle_make_model, vd.plate_number
                FROM public.claims c
                LEFT JOIN public.fault_determinations fd ON fd.claim_id = c.id
                LEFT JOIN public.conversations co ON co.claim_id = c.id
                LEFT JOIN public.client_profiles cp
                    ON cp.conversation_id = co.id AND cp.vehicle_label = 'A'
                LEFT JOIN public.vehicle_declarations vd
                    ON vd.claim_id = c.id AND vd.vehicle_label = 'A'
                ORDER BY c.created_at DESC
                """
            )
        ).mappings().all()
    except (SQLAlchemyError, Exception) as exc:
        _platform_unavailable(db, exc)
        return []

    if not rows:
        return []

    try:
        photo_counts = dict(
            db.execute(
                text(
                    "SELECT claim_id, COUNT(*) FROM public.photos "
                    "WHERE claim_id = ANY(:ids) GROUP BY claim_id"
                ),
                {"ids": [r["id"] for r in rows]},
            ).all()
        )
    except (SQLAlchemyError, Exception) as exc:
        _platform_unavailable(db, exc)
        photo_counts = {}

    return [_claim_row_to_summary(dict(r), photo_counts.get(r["id"], 0)) for r in rows]


def _photo_urls(db: Session, claim_id: str) -> list[str]:
    """
    Real uploaded-photo URLs for one claim, newest first, via
    platform/backend's file-serving routes. Prefers the boxes-drawn
    annotated version (.../annotated - app/worker.py's run_damage_assessment
    saves one per photo once analyzed, see Photo.annotated_s3_key) so an
    agent sees exactly what the model detected instead of a plain photo;
    falls back to the raw file (.../file) for a photo the worker hasn't
    processed yet, so nothing 404s while analysis is still in flight.
    """
    rows = db.execute(
        text(
            "SELECT id, annotated_s3_key FROM public.photos "
            "WHERE claim_id = :claim_id ORDER BY uploaded_at DESC"
        ),
        {"claim_id": claim_id},
    ).mappings().all()
    return [
        f"{PLATFORM_API_BASE}/claims/{claim_id}/photos/{r['id']}/annotated"
        if r["annotated_s3_key"]
        else f"{PLATFORM_API_BASE}/claims/{claim_id}/photos/{r['id']}/file"
        for r in rows
    ]


def fetch_platform_claim_detail(db: Session, claim_id: str) -> Optional[dict[str, Any]]:
    """GET /api/claims/{id} shape for one real constat, or None if claim_id isn't a real platform claim (or the platform bridge is unavailable - see _platform_unavailable)."""
    try:
        row = db.execute(
            text(
                """
                SELECT
                    c.id, c.status, c.location_text, c.damages_exceed_cap,
                    fd.fault_a_pct, fd.fault_b_pct, fd.needs_manual_review, fd.explanation, fd.rule_id,
                    cp.vehicle_make_model, vd.plate_number
                FROM public.claims c
                LEFT JOIN public.fault_determinations fd ON fd.claim_id = c.id
                LEFT JOIN public.conversations co ON co.claim_id = c.id
                LEFT JOIN public.client_profiles cp
                    ON cp.conversation_id = co.id AND cp.vehicle_label = 'A'
                LEFT JOIN public.vehicle_declarations vd
                    ON vd.claim_id = c.id AND vd.vehicle_label = 'A'
                WHERE c.id = :claim_id
                """
            ),
            {"claim_id": claim_id},
        ).mappings().first()
    except Exception as exc:
        _platform_unavailable(db, exc)
        return None
    if row is None:
        return None

    vehicle = row["vehicle_make_model"] or (
        f"Plate {row['plate_number']}" if row["plate_number"] else "Unregistered vehicle"
    )

    fault = None
    if row["fault_a_pct"] is not None:
        status_label = "AI Verification Required" if row["needs_manual_review"] else "AI Processing Complete"
        insights = row["explanation"] or DEFAULT_ESTIMATION_INSIGHTS
        # Surfaced separately from `insights` (free text) as actual numbers
        # an employee can act on - "who's at fault, as a %" was the whole
        # point of running the fault engine, and until now nothing past
        # persist_claim_and_fault ever read fault_a_pct/fault_b_pct back out
        # again anywhere in this portal.
        fault = {
            "fault_a_pct": row["fault_a_pct"],
            "fault_b_pct": row["fault_b_pct"],
            "rule_id": row["rule_id"],
            "explanation": row["explanation"],
            "needs_manual_review": row["needs_manual_review"],
        }
    else:
        status_label = "Awaiting client narrative"
        insights = "This constat was filed via the mobile app but the fault engine hasn't run yet - no analysis on file."

    try:
        photo_urls = _photo_urls(db, claim_id)
    except Exception as exc:
        _platform_unavailable(db, exc)
        photo_urls = []

    # Real YOLO11 damage-detection output (app/damage_detection.py /
    # app/worker.py's run_damage_assessment, triggered on every photo
    # upload) - one row per claim, aggregated across every photo analyzed
    # so far. None until at least one photo has finished being processed by
    # the worker, in which case this still cleanly falls back to an empty
    # hotspot list (AIEstimation.jsx's own "No automatic damage detections
    # found" empty state), not a fabricated one.
    try:
        damage_row = db.execute(
            text(
                "SELECT hotspots, subtotal, total, insights, damage_percent "
                "FROM public.damage_estimates WHERE claim_id = :claim_id"
            ),
            {"claim_id": claim_id},
        ).mappings().first()
    except Exception as exc:
        _platform_unavailable(db, exc)
        damage_row = None

    if damage_row and damage_row["hotspots"]:
        hotspots = damage_row["hotspots"]
        subtotal = damage_row["subtotal"] or 0.0
        total = damage_row["total"] or 0.0
        damage_insights = damage_row["insights"] or insights
        damage_percent = damage_row["damage_percent"]
    else:
        hotspots = []
        subtotal = 0.0
        total = 0.0
        damage_insights = insights
        damage_percent = None

    return {
        "claim_id": row["id"],
        "vehicle": vehicle,
        "status": status_label,
        # Real uploaded photos when there are any; the exact same
        # placeholder seed.py uses elsewhere only when there aren't -
        # never a generated/substitute image, never touching the seeded
        # demo claims' own photos.
        "image_url": photo_urls[0] if photo_urls else DEFAULT_ESTIMATION_IMAGE,
        "thumbnails": photo_urls[1:],
        "hotspots": hotspots,
        "subtotal": subtotal,
        "total": total,
        "insights": damage_insights,
        "damage_percent": damage_percent,
        "fault": fault,
    }


def is_platform_claim(db: Session, claim_id: str) -> bool:
    try:
        return (
            db.execute(
                text("SELECT 1 FROM public.claims WHERE id = :claim_id"), {"claim_id": claim_id}
            ).first()
            is not None
        )
    except Exception as exc:
        _platform_unavailable(db, exc)
        return False


def update_platform_claim_status(db: Session, claim_id: str, assurex_status: str) -> bool:
    """
    Applies a portal drag-between-columns move to the real underlying
    platform claim (see _STATUS_FROM_ASSUREX). Returns False if claim_id
    isn't a real platform claim, so the caller can fall back to a 404
    instead of silently no-op'ing.
    """
    platform_status = _STATUS_FROM_ASSUREX.get(assurex_status)
    if platform_status is None:
        return False
    try:
        result = db.execute(
            text('UPDATE public.claims SET status = :status WHERE id = :claim_id'),
            {"status": platform_status, "claim_id": claim_id},
        )
        db.commit()
        return result.rowcount > 0
    except Exception as exc:
        _platform_unavailable(db, exc)
        return False
