"""
Ties together three things for one accident:
  1. The legal fault determination (fault_engine.py — the same deterministic
     rules engine used by the platform's API, imported directly so there's
     one source of truth).
  2. Each vehicle's declared route (from -> to address), geocoded and turned
     into a heading, to classify whether the two vehicles were headed the
     same way, opposite ways, or crossing.
  3. A lightweight plausibility check: does each vehicle's declared
     circumstance / damage location actually make sense given that route
     geometry? Mismatches are surfaced as flags for a human to look at —
     this is a heuristic signal, not a fraud verdict, and it cannot replace
     photo/expert damage assessment (that's the CV pipeline stubbed in the
     platform's worker.py).
"""
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

from . import geocoding
from . import geometry

# Import the canonical engine from the platform backend rather than keeping
# a second copy — avoids the two drifting out of sync. assistant/ is a
# sibling of platform/ under the repo root, so .parent.parent here is the
# repo root regardless of which process imports this module.
_BACKEND_APP_DIR = Path(__file__).resolve().parent.parent / "platform" / "backend"
if str(_BACKEND_APP_DIR) not in sys.path:
    sys.path.insert(0, str(_BACKEND_APP_DIR))

from app.fault_engine import Circumstance, ImpactZone, VehicleDeclaration, determine_fault  # noqa: E402

# Circumstances that only make physical sense if both vehicles were heading
# roughly the same direction.
_REQUIRES_SAME_DIRECTION = {
    Circumstance.REAR_ENDED_SAME_LANE,
    Circumstance.SAME_DIRECTION_DIFF_LANE,
    Circumstance.CHANGING_LANE,
    Circumstance.OVERTAKING,
}
# Circumstances that only make sense heading toward each other.
_REQUIRES_OPPOSITE_DIRECTION = {
    Circumstance.ENCROACHING_OPPOSITE_LANE,
}

# For a handful of circumstances there's a fairly clear expected impact zone
# on the *declaring* vehicle. Anything not listed here is left unchecked —
# too ambiguous to assert without more data than a text conversation gives.
_EXPECTED_IMPACT_ZONE = {
    Circumstance.REAR_ENDED_SAME_LANE: {ImpactZone.FRONT, ImpactZone.FRONT_LEFT, ImpactZone.FRONT_RIGHT},
    Circumstance.REVERSING: {ImpactZone.REAR, ImpactZone.REAR_LEFT, ImpactZone.REAR_RIGHT},
    Circumstance.ENCROACHING_OPPOSITE_LANE: {
        ImpactZone.FRONT, ImpactZone.FRONT_LEFT, ImpactZone.FRONT_RIGHT, ImpactZone.LEFT_SIDE,
    },
}


@dataclass
class VehicleInput:
    """What the conversational agent has collected so far for one vehicle."""
    vehicle_label: str
    from_address: Optional[str] = None
    to_address: Optional[str] = None
    circumstances: list[str] = field(default_factory=list)  # raw string codes, e.g. "h"
    impact_zones: list[str] = field(default_factory=list)   # raw string codes, e.g. "front"
    narrative: str = ""
    evidence: list[str] = field(default_factory=list)  # audit trail: user's own words backing circumstances/impact_zones

    # --- administrative / identity fields — needed to fill the actual constat
    # form (sections 6-9), not used by the fault engine or route checks at all.
    insurance_company: Optional[str] = None
    policy_number: Optional[str] = None
    agency: Optional[str] = None
    driver_first_name: Optional[str] = None
    driver_last_name: Optional[str] = None
    driver_address: Optional[str] = None
    license_number: Optional[str] = None
    insured_first_name: Optional[str] = None
    insured_last_name: Optional[str] = None
    insured_address: Optional[str] = None
    insured_phone: Optional[str] = None
    vehicle_make_model: Optional[str] = None
    plate_number: Optional[str] = None
    damage_description: str = ""
    observations: str = ""

    def is_ready_for_analysis(self) -> bool:
        """
        Minimum info to run the fault engine for this vehicle: a damage
        zone. That's genuinely all the fault engine itself consumes (see
        fault_engine.VehicleDeclaration — circumstances + impact_zones,
        nothing else); a from/to route is only ever used opportunistically
        by the plausibility cross-check in analyze() below, and that check
        already skips cleanly whenever a route is missing.

        Originally this also hard-required a route for every vehicle, which
        sounds reasonable until a real conversation hits a vehicle that was
        parked (no route by definition — it wasn't going anywhere), or a
        client who genuinely doesn't know what the other driver was doing
        or where they came from (a very ordinary real scenario: discovering
        parking-lot damage after the fact, a driver who left before any
        details were exchanged). Hard-blocking on facts nobody can supply
        traps the conversation in an unanswerable loop — the system prompt
        is responsible for actually trying to get a route/circumstance
        through conversation; this gate should only stop truly empty data
        (not even a damage zone), not penalize an honest "I don't know."
        """
        return bool(self.impact_zones)

    def constat_missing_fields(self) -> list[str]:
        """
        Human, ordered list of what's still missing for this vehicle's
        section of the constat — used to offer a draft PDF with the gaps
        called out, rather than an all-or-nothing gate that blocks
        generating anything at all until every field is perfect. A client
        who wants to stop early should be able to get *something*, with the
        rest clearly marked as needing to be completed later.
        """
        missing = []
        if not self.circumstances:
            missing.append("what this vehicle was doing (circumstance)")
        if not self.impact_zones:
            missing.append("damage location")
        if "a" not in self.circumstances and not (self.from_address and self.to_address):
            missing.append("route (from/to address)")
        if not self.driver_last_name:
            missing.append("driver's name")
        if not self.plate_number:
            missing.append("plate number")
        if not self.insurance_company:
            missing.append("insurance company")
        return missing

    def is_ready_for_constat(self) -> bool:
        """True only once nothing at all is missing for this vehicle's constat section."""
        return not self.constat_missing_fields()

    def has_minimum_for_draft_constat(self) -> bool:
        """
        Much lower bar than is_ready_for_constat(): enough to produce a
        partial/draft PDF worth handing to the client at all (their own
        narrative recorded, or at least one identity fact) — not "complete,"
        just "not blank."
        """
        return bool(self.circumstances or self.impact_zones or self.driver_last_name or self.plate_number)


@dataclass
class ClaimInfo:
    """Claim-level facts not specific to either vehicle (constat sections 1-5)."""
    accident_date: Optional[str] = None
    accident_time: Optional[str] = None
    location: Optional[str] = None
    injuries: Optional[bool] = None
    injuries_detail: str = ""
    other_material_damage: Optional[bool] = None
    other_material_damage_detail: str = ""
    witnesses: list[str] = field(default_factory=list)


def geocode_preview(address: str) -> Optional[dict]:
    """
    Resolve one address the moment it's given, rather than waiting for the
    final analysis — so the conversation can confirm it back to the user
    ("got that as X") or flag it right away if Nominatim couldn't find it,
    instead of the failure only surfacing once, silently, at the end.
    Returns {"lat", "lng", "display_name"} or None if not found.
    """
    return geocoding.geocode(address)


def _geocode_route(v: VehicleInput) -> dict:
    route = {"from": None, "to": None, "bearing_deg": None, "compass": None}
    if v.from_address:
        route["from"] = geocoding.geocode(v.from_address)
    if v.to_address:
        route["to"] = geocoding.geocode(v.to_address)
    if route["from"] and route["to"]:
        b = geometry.bearing_degrees(
            route["from"]["lat"], route["from"]["lng"], route["to"]["lat"], route["to"]["lng"]
        )
        route["bearing_deg"] = round(b, 1)
        route["compass"] = geometry.compass_label(b)
    return route


def _to_engine_declaration(v: VehicleInput) -> VehicleDeclaration:
    circumstances = set()
    for code in v.circumstances:
        try:
            circumstances.add(Circumstance(code))
        except ValueError:
            continue  # unknown code from the model — ignore rather than crash
    impact_zones = set()
    for code in v.impact_zones:
        try:
            impact_zones.add(ImpactZone(code))
        except ValueError:
            continue
    return VehicleDeclaration(vehicle_id=v.vehicle_label, circumstances=circumstances, impact_zones=impact_zones)


def analyze(vehicle_a: VehicleInput, vehicle_b: VehicleInput) -> dict:
    route_a = _geocode_route(vehicle_a)
    route_b = _geocode_route(vehicle_b)

    relative_direction = None
    if route_a["bearing_deg"] is not None and route_b["bearing_deg"] is not None:
        relative_direction = geometry.classify_relative_direction(route_a["bearing_deg"], route_b["bearing_deg"])

    engine_a = _to_engine_declaration(vehicle_a)
    engine_b = _to_engine_declaration(vehicle_b)
    fault_result = determine_fault(engine_a, engine_b)

    flags: list[str] = []
    for label, engine_v in (("A", engine_a), ("B", engine_b)):
        if relative_direction:
            for c in engine_v.circumstances:
                if c in _REQUIRES_SAME_DIRECTION and relative_direction != "same_direction":
                    flags.append(
                        f"Vehicle {label} declared '{c.name}', which assumes both cars traveling the same "
                        f"direction, but the given routes imply the paths were '{relative_direction}' "
                        f"(A heading {route_a['compass']}, B heading {route_b['compass']}). Worth double-checking."
                    )
                if c in _REQUIRES_OPPOSITE_DIRECTION and relative_direction != "opposite_direction":
                    flags.append(
                        f"Vehicle {label} declared '{c.name}', which assumes oncoming traffic, but the given "
                        f"routes imply the paths were '{relative_direction}'. Worth double-checking."
                    )
        for c in engine_v.circumstances:
            expected = _EXPECTED_IMPACT_ZONE.get(c)
            if expected and engine_v.impact_zones and not (engine_v.impact_zones & expected):
                got = ", ".join(z.value for z in engine_v.impact_zones)
                flags.append(
                    f"Vehicle {label} declared '{c.name}' but reported damage at ({got}), which doesn't match "
                    f"where that scenario would typically cause damage. Worth double-checking."
                )

    return {
        "fault": {
            "fault_a_pct": fault_result.fault_a_pct,
            "fault_b_pct": fault_result.fault_b_pct,
            "rule_id": fault_result.rule_id,
            "explanation": fault_result.explanation,
            "needs_manual_review": fault_result.needs_manual_review,
        },
        "routes": {"A": route_a, "B": route_b},
        "relative_direction": relative_direction,
        "consistency_flags": flags,
    }
