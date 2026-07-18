"""
Automated tests for assistant/accident_analysis.py / fault_engine.py — no
network, no API key, no cost. Geocoding is monkeypatched to a fixed set of
fake Tunisian coordinates so these run instantly and deterministically.

Run with (from anywhere, thanks to the sys.path bootstrap below):
    python3 test_accident_analysis.py
or, if you have pytest installed:
    pytest test_accident_analysis.py -v
or from the repo root:
    python3 -m assistant.test_accident_analysis
"""
import sys
from pathlib import Path

# This file lives in assistant/, so .parent.parent is the repo root — add it
# to sys.path so `assistant` resolves as a real package regardless of
# whether this is run as a bare script (`python3 test_accident_analysis.py`,
# cwd = assistant/) or via `-m`/pytest from the repo root. Package-qualified
# imports (not bare `import geocoding`) are required here specifically so
# the module object patched below is the exact same one accident_analysis.py
# sees via its own `from . import geocoding` — a bare top-level import would
# create a second, unrelated module instance and the monkeypatch below
# wouldn't reach it.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from assistant import geocoding

# A small fake gazetteer standing in for Nominatim. Coordinates are rough
# but directionally correct for the scenarios below (all real Tunis-area
# places, just not geocoded live).
_FAKE_COORDS = {
    "Avenue Habib Bourguiba, Tunis": (36.800, 10.181),   # centre-ville
    "La Marsa, Tunis": (36.879, 10.324),                  # ~NE of centre-ville
    "Ariana, Tunis": (36.862, 10.193),                    # ~N of centre-ville
    "Ben Arous": (36.753, 10.218),                        # ~S of centre-ville
    "Le Bardo, Tunis": (36.809, 10.140),                  # ~W of centre-ville
}


def _fake_geocode(address, country_bias="tn"):
    coords = _FAKE_COORDS.get(address)
    if not coords:
        return None
    lat, lng = coords
    return {"lat": lat, "lng": lng, "display_name": address}


geocoding.geocode = _fake_geocode  # patch before importing accident_analysis's users

from assistant.accident_analysis import VehicleInput, analyze  # noqa: E402


def test_rear_end_same_direction_no_flags():
    """Textbook case: A hits B from behind, both headed the same way."""
    a = VehicleInput("A", "Avenue Habib Bourguiba, Tunis", "La Marsa, Tunis",
                      circumstances=["h"], impact_zones=["front"])
    b = VehicleInput("B", "Avenue Habib Bourguiba, Tunis", "La Marsa, Tunis",
                      circumstances=["a"], impact_zones=["rear"])
    result = analyze(a, b)
    assert result["fault"]["fault_a_pct"] == 100
    assert result["fault"]["fault_b_pct"] == 0
    assert result["fault"]["rule_id"] == "rear_end"
    assert result["relative_direction"] == "same_direction"
    assert result["consistency_flags"] == []


def test_rear_end_but_routes_imply_opposite_directions_flags_it():
    """Same claim as above, but B's route is reversed — physically inconsistent."""
    a = VehicleInput("A", "Avenue Habib Bourguiba, Tunis", "La Marsa, Tunis",
                      circumstances=["h"], impact_zones=["front"])
    b = VehicleInput("B", "La Marsa, Tunis", "Avenue Habib Bourguiba, Tunis",
                      circumstances=["a"], impact_zones=["rear"])
    result = analyze(a, b)
    assert result["fault"]["fault_a_pct"] == 100  # engine still computes it...
    assert result["relative_direction"] == "opposite_direction"
    assert len(result["consistency_flags"]) >= 1  # ...but flags it for review


def test_reversing_vehicle_at_fault():
    a = VehicleInput("A", "Le Bardo, Tunis", "Avenue Habib Bourguiba, Tunis",
                      circumstances=["n"], impact_zones=["rear"])
    b = VehicleInput("B", "Le Bardo, Tunis", "Avenue Habib Bourguiba, Tunis",
                      circumstances=[], impact_zones=["front"])
    result = analyze(a, b)
    assert result["fault"]["fault_a_pct"] == 100
    assert result["fault"]["rule_id"] == "reversing_vs_moving"


def test_opposite_lane_encroachment():
    a = VehicleInput("A", "Ariana, Tunis", "Ben Arous",
                      circumstances=["o"], impact_zones=["front"])
    b = VehicleInput("B", "Ben Arous", "Ariana, Tunis",
                      circumstances=[], impact_zones=["front_left"])
    result = analyze(a, b)
    assert result["fault"]["fault_a_pct"] == 100
    assert result["fault"]["rule_id"] == "opposite_lane_encroach"
    assert result["relative_direction"] == "opposite_direction"
    assert result["consistency_flags"] == []  # claim matches the geometry


def test_priority_from_right():
    a = VehicleInput("A", "Le Bardo, Tunis", "Ariana, Tunis",
                      circumstances=[], impact_zones=["right_side"])
    b = VehicleInput("B", "Ben Arous", "Le Bardo, Tunis",
                      circumstances=["p"], impact_zones=["front"])
    result = analyze(a, b)
    assert result["fault"]["fault_a_pct"] == 75
    assert result["fault"]["fault_b_pct"] == 25
    assert result["fault"]["rule_id"] == "priority_from_right"


def test_ambiguous_scenario_falls_back_to_manual_review():
    """Both drivers claim the vague 'same direction, different lane' box —
    not enough for any rule to fire cleanly, and it should say so rather
    than silently guessing 50/50 as if that were authoritative."""
    a = VehicleInput("A", "Avenue Habib Bourguiba, Tunis", "La Marsa, Tunis",
                      circumstances=["i"], impact_zones=["left_side"])
    b = VehicleInput("B", "Avenue Habib Bourguiba, Tunis", "La Marsa, Tunis",
                      circumstances=["i"], impact_zones=["right_side"])
    result = analyze(a, b)
    assert result["fault"]["rule_id"] == "unmatched"
    assert result["fault"]["needs_manual_review"] is True
    assert result["fault"]["fault_a_pct"] == 50
    assert result["fault"]["fault_b_pct"] == 50


def test_unresolvable_address_skips_route_checks_without_crashing():
    """A typo'd/unknown address shouldn't take down the fault result with it."""
    a = VehicleInput("A", "some made-up nonexistent street, nowhere",
                      "also nowhere", circumstances=["h"], impact_zones=["front"])
    b = VehicleInput("B", "Avenue Habib Bourguiba, Tunis", "La Marsa, Tunis",
                      circumstances=["a"], impact_zones=["rear"])
    result = analyze(a, b)
    assert result["fault"]["fault_a_pct"] == 100  # engine result unaffected
    assert result["relative_direction"] is None    # couldn't classify, and says so
    assert result["consistency_flags"] == []       # no route data -> nothing to flag


def test_parked_vehicle_with_no_route_and_unknown_other_circumstance():
    """
    Regression test for a real deadlock: a parked vehicle (circumstance "a")
    has no route by definition, and the client often can't say what the
    other driver was doing either (discovered parking-lot damage, a
    hit-and-run). Neither gap should block is_ready_for_analysis() or crash
    analyze() -- it should just fall back to needs_manual_review, same as
    any other genuinely ambiguous case.
    """
    a = VehicleInput("A", circumstances=["a"], impact_zones=["left_side"])  # parked, no route at all
    b = VehicleInput("B", circumstances=[], impact_zones=["front"])         # circumstance genuinely unknown
    assert a.is_ready_for_analysis() is True
    assert b.is_ready_for_analysis() is True

    result = analyze(a, b)
    assert result["fault"]["needs_manual_review"] is True
    assert result["fault"]["rule_id"] == "unmatched"
    assert result["relative_direction"] is None       # neither side gave a route -- nothing to classify
    assert result["consistency_flags"] == []          # nothing to cross-check without routes


def test_vehicle_missing_only_impact_zones_is_not_ready():
    """The one thing genuinely required is a damage zone -- confirm that's still actually enforced."""
    a = VehicleInput("A", circumstances=["a"], impact_zones=[])
    assert a.is_ready_for_analysis() is False


def test_constat_missing_fields_and_draft_eligibility():
    """
    A vehicle with only a name/plate (no circumstance, no impact zone, no
    insurance) should be eligible for a *draft* constat (has_minimum_for_
    draft_constat) but correctly reported as incomplete (is_ready_for_constat
    is False, constat_missing_fields lists what's left).
    """
    partial = VehicleInput("A", driver_last_name="Hechmi", plate_number="123 TU 4453")
    assert partial.has_minimum_for_draft_constat() is True
    assert partial.is_ready_for_constat() is False
    missing = partial.constat_missing_fields()
    assert "insurance company" in missing
    assert "what this vehicle was doing (circumstance)" in missing
    assert "damage location" in missing

    blank = VehicleInput("B")
    assert blank.has_minimum_for_draft_constat() is False
    assert blank.is_ready_for_constat() is False


def _run_all():
    tests = [obj for name, obj in globals().items() if name.startswith("test_") and callable(obj)]
    passed = 0
    for t in tests:
        t()
        print(f"PASS  {t.__name__}")
        passed += 1
    print(f"\n{passed}/{len(tests)} tests passed")


if __name__ == "__main__":
    _run_all()
