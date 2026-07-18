"""
Bearing/direction-of-travel math used to turn two addresses (from -> to)
into a heading, and to classify how two vehicles' headings relate to each
other (same direction / opposite / crossing). This is a coarse straight-line
approximation (ignores actual road curvature) — good enough to sanity-check
a declared scenario against the stated route, not to reconstruct the exact
path taken.
"""
import math

_COMPASS_LABELS = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]


def bearing_degrees(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Initial compass bearing (0-360, 0=North) from point 1 to point 2."""
    lat1r, lon1r, lat2r, lon2r = map(math.radians, [lat1, lon1, lat2, lon2])
    dlon = lon2r - lon1r
    x = math.sin(dlon) * math.cos(lat2r)
    y = math.cos(lat1r) * math.sin(lat2r) - math.sin(lat1r) * math.cos(lat2r) * math.cos(dlon)
    brng = math.degrees(math.atan2(x, y))
    return (brng + 360) % 360


def compass_label(bearing: float) -> str:
    idx = round(bearing / 45) % 8
    return _COMPASS_LABELS[idx]


def angular_difference(bearing_a: float, bearing_b: float) -> float:
    """Smallest angle (0-180) between two bearings."""
    diff = abs(bearing_a - bearing_b) % 360
    return min(diff, 360 - diff)


def classify_relative_direction(bearing_a: float, bearing_b: float) -> str:
    """
    same_direction: both cars heading roughly the same way (within 30°) —
    consistent with rear-end / lane-change / overtaking scenarios.
    opposite_direction: heading roughly toward each other (within 30° of
    180° apart) — consistent with an oncoming/head-on or lane-encroachment
    scenario.
    crossing: anything in between — consistent with intersections, turns,
    roundabouts.
    """
    diff = angular_difference(bearing_a, bearing_b)
    if diff <= 30:
        return "same_direction"
    if diff >= 150:
        return "opposite_direction"
    return "crossing"
