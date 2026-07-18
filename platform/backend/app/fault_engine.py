"""
Fault-determination engine for a Tunisian "constat amiable" app.

IMPORTANT — READ BEFORE USING IN PRODUCTION
--------------------------------------------
Under the FTUSA Convention IDA, fault must be determined by *strict, mandatory
application* of the official FTUSA "barème de responsabilité", using only:
direction of travel, position of vehicles on the roadway, and points of impact.

The exact percentage table in this file is a PLACEHOLDER built from the
well-established, France/Tunisia-shared traffic-fault conventions (rear-end
collision = struck vehicle not at fault, reversing vehicle at fault, etc.).
It is NOT a verified copy of the confidential FTUSA barème. Before shipping
this for real claims, replace RULES below with the actual FTUSA table
(obtainable from FTUSA or a partner insurer) — the engine's job is just to
apply whatever table you give it, transparently and reproducibly.

Design goals:
  1. Deterministic, auditable — every result names the rule that fired.
  2. No guessing from photos/narrative — only the same three legal inputs
     the convention allows.
  3. Unmatched scenarios fall back to "needs manual/expert review" rather
     than silently guessing 50/50 and pretending that's authoritative.
"""

from dataclasses import dataclass, field
from enum import Enum


class Circumstance(str, Enum):
    """The 17 standard constat circumstance checkboxes (FR letters a-q)."""
    PARKED_STOPPED = "a"                    # en stationnement / à l'arrêt
    LEAVING_PARKING = "b"                   # quittait un stationnement
    TAKING_PARKING = "c"                    # prenait un stationnement
    EXITING_PRIVATE_GROUND = "d"            # sortait d'un parking / lieu privé
    ENTERING_PRIVATE_GROUND = "e"           # s'engageait dans un parking / lieu privé
    TRAFFIC_STOP = "f"                      # arrêt de circulation
    SIDESWIPE_NO_LANE_CHANGE = "g"          # frottement sans changement de file
    REAR_ENDED_SAME_LANE = "h"              # heurtait l'arrière, même sens, même file
    SAME_DIRECTION_DIFF_LANE = "i"          # roulait même sens, file différente
    CHANGING_LANE = "j"                     # changeait de file
    OVERTAKING = "k"                        # doublait
    TURNING_RIGHT = "l"                     # virait à droite
    TURNING_LEFT = "m"                      # virait à gauche
    REVERSING = "n"                         # reculait
    ENCROACHING_OPPOSITE_LANE = "o"         # empiétait sur la chaussée en sens inverse
    COMING_FROM_RIGHT = "p"                 # venait de droite (priorité à droite)
    IGNORED_PRIORITY_SIGNAL = "q"           # n'avait pas observé un signal / stop / feu


class ImpactZone(str, Enum):
    FRONT = "front"
    REAR = "rear"
    LEFT_SIDE = "left_side"
    RIGHT_SIDE = "right_side"
    FRONT_LEFT = "front_left"
    FRONT_RIGHT = "front_right"
    REAR_LEFT = "rear_left"
    REAR_RIGHT = "rear_right"


@dataclass
class VehicleDeclaration:
    """What one driver ticked/declared on the constat."""
    vehicle_id: str  # "A" or "B"
    circumstances: set[Circumstance] = field(default_factory=set)
    impact_zones: set[ImpactZone] = field(default_factory=set)


@dataclass
class FaultResult:
    fault_a_pct: int
    fault_b_pct: int
    rule_id: str
    explanation: str
    needs_manual_review: bool = False


def _has(v: VehicleDeclaration, *circs: Circumstance) -> bool:
    return any(c in v.circumstances for c in circs)


def _rule_rear_end(a: VehicleDeclaration, b: VehicleDeclaration):
    if _has(a, Circumstance.REAR_ENDED_SAME_LANE) and not _has(b, Circumstance.REAR_ENDED_SAME_LANE):
        return (100, 0, "A struck B from behind, same lane/direction: A fully at fault.")
    return None


def _rule_reversing(a: VehicleDeclaration, b: VehicleDeclaration):
    if _has(a, Circumstance.REVERSING) and not _has(b, Circumstance.REVERSING):
        return (100, 0, "A was reversing when struck by B moving forward: A fully at fault.")
    return None


def _rule_both_reversing(a: VehicleDeclaration, b: VehicleDeclaration):
    if _has(a, Circumstance.REVERSING) and _has(b, Circumstance.REVERSING):
        return (50, 50, "Both vehicles reversing: shared fault.")
    return None


def _rule_encroaching_opposite_lane(a: VehicleDeclaration, b: VehicleDeclaration):
    if _has(a, Circumstance.ENCROACHING_OPPOSITE_LANE) and not _has(b, Circumstance.ENCROACHING_OPPOSITE_LANE):
        return (100, 0, "A encroached onto the oncoming lane: A fully at fault.")
    return None


def _rule_changing_lane_or_overtaking(a: VehicleDeclaration, b: VehicleDeclaration):
    a_maneuvering = _has(a, Circumstance.CHANGING_LANE, Circumstance.OVERTAKING)
    b_straight = not _has(
        b, Circumstance.CHANGING_LANE, Circumstance.OVERTAKING,
        Circumstance.REVERSING, Circumstance.ENCROACHING_OPPOSITE_LANE,
    )
    if a_maneuvering and b_straight:
        return (100, 0, "A was changing lanes/overtaking into B's path while B continued straight: A fully at fault.")
    return None


def _rule_exiting_parking_or_private_ground(a: VehicleDeclaration, b: VehicleDeclaration):
    a_exiting = _has(a, Circumstance.LEAVING_PARKING, Circumstance.EXITING_PRIVATE_GROUND)
    b_on_road = not _has(b, Circumstance.LEAVING_PARKING, Circumstance.EXITING_PRIVATE_GROUND,
                          Circumstance.TAKING_PARKING, Circumstance.ENTERING_PRIVATE_GROUND)
    if a_exiting and b_on_road:
        return (100, 0, "A was exiting a parking spot/private ground onto the road: A fully at fault.")
    return None


def _rule_priority_signal(a: VehicleDeclaration, b: VehicleDeclaration):
    if _has(a, Circumstance.IGNORED_PRIORITY_SIGNAL) and not _has(b, Circumstance.IGNORED_PRIORITY_SIGNAL):
        return (100, 0, "A failed to observe a stop/yield/traffic signal: A fully at fault.")
    return None


def _rule_priority_from_right(a: VehicleDeclaration, b: VehicleDeclaration):
    if _has(b, Circumstance.COMING_FROM_RIGHT) and not _has(a, Circumstance.COMING_FROM_RIGHT):
        return (75, 25, "B approached from A's right with no other priority signal noted: A mostly at fault.")
    return None


_RULES = [
    ("rear_end", _rule_rear_end),
    ("reversing_vs_moving", _rule_reversing),
    ("both_reversing", _rule_both_reversing),
    ("opposite_lane_encroach", _rule_encroaching_opposite_lane),
    ("lane_change_or_overtake", _rule_changing_lane_or_overtaking),
    ("exiting_parking", _rule_exiting_parking_or_private_ground),
    ("priority_signal", _rule_priority_signal),
    ("priority_from_right", _rule_priority_from_right),
]
# Anything not matched above (including "neither party declared any
# distinguishing circumstance") falls through to determine_fault()'s
# unmatched-scenario branch, which correctly sets needs_manual_review=True
# instead of silently asserting a 50/50 split.
#
# NOTE: the real constat form (see constat.pdf) has no dedicated "roundabout"
# checkbox — rows f/g on the actual form are "arrêt de circulation" (stopped
# in traffic) and "frottement sans changement de file" (sideswipe, no lane
# change), not roundabout entry/circulating. Roundabout accidents still
# happen, but on this form they're captured via whichever of the 17 real
# codes actually applies (often COMING_FROM_RIGHT / IGNORED_PRIORITY_SIGNAL)
# plus the free-text narrative and sketch — not a dedicated rule here.


def determine_fault(a: VehicleDeclaration, b: VehicleDeclaration) -> FaultResult:
    """
    Apply the rule table symmetrically: try each rule as declared (a, b),
    then with roles swapped (b, a) so direction-specific rules catch both
    orderings without duplicating every rule twice.
    """
    for rule_id, rule_fn in _RULES:
        result = rule_fn(a, b)
        if result:
            fault_a, fault_b, explanation = result
            return FaultResult(fault_a, fault_b, rule_id, explanation)

        swapped = rule_fn(b, a)
        if swapped:
            fault_b2, fault_a2, explanation = swapped
            return FaultResult(fault_a2, fault_b2, rule_id, explanation)

    return FaultResult(
        fault_a_pct=50,
        fault_b_pct=50,
        rule_id="unmatched",
        explanation=(
            "Declared circumstances did not match a known rule combination. "
            "This must be routed to a human adjuster / the official FTUSA "
            "barème rather than settled automatically."
        ),
        needs_manual_review=True,
    )
