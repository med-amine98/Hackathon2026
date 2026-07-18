"""
Fills the real constat.pdf scan (shipped as assets/constat_template.pdf) with
whatever the conversational agent has collected, producing a document that
looks like an actual filled-in paper form rather than a re-typed replica.

The template is a flat scanned image (no AcroForm fields, no text layer —
confirmed via PyMuPDF: get_text() returns nothing on either page), so this
works by overlaying text/marks directly onto the page at fixed coordinates,
using PyMuPDF (fitz). Coordinates below were measured by rendering the
template with a point-labeled coordinate grid and reading field positions
off it directly (see git history / dev notes) — they're accurate to within
a few points, not pixel-perfect, which is normal for hand-measured overlay
coordinates on a scanned form. If a future template image shifts even
slightly, these will need re-measuring the same way.

What this does NOT attempt:
  - A precise, to-scale reconstruction of the accident in the "13. croquis"
    grid — see _draw_croquis()'s docstring below for what it draws instead
    and why, and for the real alternative (a client-drawn sketch) this isn't
    a substitute for.
  - Signatures (section 15) — a scanned/typed form still needs a wet or
    real digital signature from both drivers; this is out of scope.
  - The page-2 "déclaration" back page — only the front constat (page 1) is
    filled, since that's the page the fault engine / conversation actually
    populates enough data for.
"""
from __future__ import annotations

import io
import math
from pathlib import Path

import fitz  # PyMuPDF

TEMPLATE_PATH = Path(__file__).resolve().parent / "assets" / "constat_template.pdf"

_FONT = "helv"
_FONT_SIZE = 8
_CHECK_FONT_SIZE = 9

# Circumstance letter -> row number on the printed form (a=1 ... q=17, a
# direct alphabet-position mapping since the 17 codes are exactly a-q).
_CIRCUMSTANCE_ROW = {chr(ord("a") + i): i + 1 for i in range(17)}

# y-coordinate (points, top-left origin) of each circumstance row's checkbox.
# Re-measured by rendering the blank template with a 10pt-labeled coordinate
# grid at 300dpi and reading each row's checkbox position directly off it
# (assistant/constat_pdf.py's own docstring already documented this as the
# right way to calibrate; the *previous* values in this dict just weren't
# actually accurate — row 1 was fine, but every row after it drifted further
# off, up to 84pt out by row 17, since rows 4/5/8/9/15/16/17 wrap to two
# printed lines and the original measurement didn't account for that
# consistently). Confirmed by rendering an actual filled sample afterward:
# every row's X now lands on its own printed line, not a neighboring one.
_CIRCUMSTANCE_ROW_Y = {
    1: 202, 2: 222, 3: 242, 4: 263, 5: 285, 6: 303, 7: 322,
    8: 341, 9: 361, 10: 383, 11: 403, 12: 423, 13: 443,
    14: 463, 15: 483, 16: 503, 17: 523,
}
_CHECKBOX_X_A = 229
_CHECKBOX_X_B = 379

# x-offset applied to every vehicle-A coordinate to get vehicle B's — holds
# for sections 6-9 since the form mirrors A's layout for B at a fixed offset.
_B_OFFSET_X = 375

# (x, y) for each vehicle-A field in sections 6-9; add _B_OFFSET_X for B.
# Re-measured the same grid-overlay way as the circumstance rows above —
# the previous values had policy_number landing on top of the "Agence" line
# (both drawn ~3pt apart), and insured_address/insured_phone/sens_suivi/
# venant_de/allant_a were each one full line low (landing on the *next*
# field's printed line instead of their own). Confirmed against a rendered
# filled sample with long values in every field.
_VEHICLE_FIELD_XY = {
    "insurance_company": (112, 186),
    "policy_number": (165, 201),
    "agency": (88, 220),
    "attestation_valable": (170, 238),  # not currently collected, left blank
    "driver_last_name_first_name": (95, 286),  # "Nom" — we put last name here
    "driver_first_name_row": (110, 300),       # "Prénom"
    "driver_address": (110, 320),
    "license_number": (210, 340),
    "insured_last_name": (95, 390),
    "insured_first_name": (110, 407),
    "insured_address": (115, 422),
    "insured_phone": (170, 443),
    "vehicle_make_model": (140, 478),
    "plate_number": (200, 498),
    "sens_suivi": (145, 513),   # compass heading, computed
    "venant_de": (120, 530),
    "allant_a": (115, 550),
}

# dégâts apparents / observations boxes are positioned differently for A vs B
# (B isn't a simple +375 shift down here), so given explicitly per vehicle.
_DAMAGE_OBS_XY = {
    "A": {"damage": (60, 700), "observations": (60, 745)},
    "B": {"damage": (500, 700), "observations": (500, 745)},
}

_HEADER_XY = {
    "date": (20, 101),
    "heure": (145, 101),
    "lieu": (185, 101),
    "blessed_non": (483, 101),
    "blessed_oui": (547, 101),
    "other_damage_non": (100, 138),
    "other_damage_oui": (163, 138),
    "witnesses": (185, 135),
}

# Inner usable area of the "13. croquis de l'accident" dashed grid box,
# measured the same grid-overlay way as everything above (the box's rounded
# corners and yellow/green vehicle-column overlap eat a few points on every
# side, so this is padded slightly inward from the box's outer edge).
_CROQUIS_BOX = fitz.Rect(183, 590, 470, 682)

# Top-down car icon size, in points — small enough that two fit in the box
# with room for arrows/labels, roughly car-shaped (longer than wide).
_CAR_LEN = 34.0
_CAR_WID = 15.0

# impact_zone code -> which corner/edge of the OTHER vehicle's rectangle
# (relative to its own heading, "front" = the direction it's driving) the
# damage mark belongs on. Mirrors ImpactZone in fault_engine.py.
_IMPACT_ZONE_POSITION = {
    "front": "front", "rear": "rear",
    "left_side": "left", "right_side": "right",
    "front_left": "front_left", "front_right": "front_right",
    "rear_left": "rear_left", "rear_right": "rear_right",
}


def _draw_text(page: "fitz.Page", xy: tuple[float, float], text: str, size: float = _FONT_SIZE, max_width: float | None = None):
    if not text:
        return
    text = str(text)
    if max_width:
        # crude wrap: fitz has no built-in wrap for insert_text, so just
        # truncate with an ellipsis rather than overrun into the next field.
        approx_chars = int(max_width / (size * 0.5))
        if len(text) > approx_chars:
            text = text[: approx_chars - 1] + "…"
    page.insert_text(xy, text, fontsize=size, fontname=_FONT, color=(0, 0, 0.55))


def _draw_check(page: "fitz.Page", xy: tuple[float, float]):
    x, y = xy
    page.insert_text((x, y), "X", fontsize=_CHECK_FONT_SIZE, fontname=_FONT, color=(0.7, 0, 0))


def _full_name(first: str | None, last: str | None) -> str:
    parts = [p for p in (first, last) if p]
    return " ".join(parts)


def _heading_vector(bearing_deg: float | None) -> tuple[float, float]:
    """
    Unit vector for a compass bearing (0=N, 90=E, ...) in PDF page space,
    where +x is right and +y is DOWN (page coordinates, not screen-up
    math). North (0°) therefore points in -y. Falls back to "pointing
    right" (east, 90°) when no bearing is known — an arbitrary but
    harmless default since a car with no heading data gets drawn without
    a direction arrow anyway (see _draw_car).
    """
    b = math.radians(bearing_deg if bearing_deg is not None else 90.0)
    return (math.sin(b), -math.cos(b))


def _car_corners(cx: float, cy: float, heading_deg: float | None) -> dict[str, tuple[float, float]]:
    """
    Four corners plus edge midpoints of a car-shaped rectangle centered at
    (cx, cy), long axis pointing along heading_deg. Returns a dict keyed the
    same way as impact_zones (front/rear/left/right/front_left/...) so
    _impact_mark_xy can look a position straight up, plus "center".
    """
    dx, dy = _heading_vector(heading_deg)   # forward direction
    px, py = -dy, dx                        # perpendicular (car's right side)
    hl, hw = _CAR_LEN / 2, _CAR_WID / 2

    def pt(along: float, across: float) -> tuple[float, float]:
        return (cx + dx * along + px * across, cy + dy * along + py * across)

    return {
        "center": (cx, cy),
        "front": pt(hl, 0), "rear": pt(-hl, 0),
        "left": pt(0, -hw), "right": pt(0, hw),
        "front_left": pt(hl, -hw), "front_right": pt(hl, hw),
        "rear_left": pt(-hl, -hw), "rear_right": pt(-hl, hw),
    }


def _draw_car(page: "fitz.Page", cx: float, cy: float, heading_deg: float | None,
              label: str, impact_zones: list[str], color: tuple[float, float, float]):
    """
    One top-down car: a rectangle oriented along heading_deg (or a plain
    unrotated square if heading_deg is None — e.g. a parked vehicle with no
    route, drawn without implying a direction it never had), a small
    triangular arrowhead at the front if it DOES have a heading, its A/B
    label centered inside, and a red dot on the rectangle edge for each
    declared impact zone.
    """
    corners = _car_corners(cx, cy, heading_deg)
    body = [corners["front_left"], corners["front_right"], corners["rear_right"], corners["rear_left"]]
    page.draw_polyline(body + [body[0]], color=color, width=1.1, fill=None)

    if heading_deg is not None:
        dx, dy = _heading_vector(heading_deg)
        tip = (corners["center"][0] + dx * (_CAR_LEN / 2 + 6), corners["center"][1] + dy * (_CAR_LEN / 2 + 6))
        page.draw_line(corners["center"], tip, color=color, width=1.1)
        # small arrowhead: two short strokes back from the tip
        back = (corners["center"][0] + dx * (_CAR_LEN / 2), corners["center"][1] + dy * (_CAR_LEN / 2))
        px, py = -dy, dx
        for sign in (-1, 1):
            wing = (tip[0] - dx * 5 + px * 3 * sign, tip[1] - dy * 5 + py * 3 * sign)
            page.draw_line(tip, wing, color=color, width=1.1)

    page.insert_text(
        (corners["center"][0] - 3, corners["center"][1] + 3),
        label, fontsize=8, fontname=_FONT, color=color,
    )

    for zone in impact_zones:
        key = _IMPACT_ZONE_POSITION.get(zone)
        if key and key in corners:
            x, y = corners[key]
            page.draw_circle((x, y), 2.2, color=(0.75, 0, 0), fill=(0.75, 0, 0))


def _draw_croquis(page: "fitz.Page", vehicle_a, vehicle_b, route_a: dict | None,
                   route_b: dict | None, relative_direction: str | None):
    """
    Auto-generated top-down schematic in the "13. croquis" box, built
    entirely from data already collected for the fault engine — each
    vehicle's compass bearing (from geocoded from/to addresses), the
    relative_direction classification (same/opposite/crossing) analyze()
    already computes, and impact_zones. NOT a precise, to-scale
    reconstruction of the accident (a text conversation can't produce lane
    positions or exact distances) — it's a structured, honest visual summary
    of exactly the same facts already on the rest of the form: which way
    each car was heading and where it got hit, so a reader gets a picture to
    go with the checkboxes instead of an empty grid.

    A real hand-drawn sketch (the client actually drawing the collision,
    e.g. via a canvas widget in the chat UI) would be a genuinely different
    and more expressive feature — it can capture things this can't
    (lane position, a third vehicle, a curve in the road) — but needs new UI
    plumbing this text-only chat doesn't have. This function is the
    achievable version with what the conversation already collects; it
    doesn't block adding a real canvas later; if anything, that field would
    become a fallback for when this one has too little data to be useful.

    Falls back gracefully with less data: no bearings at all (relative_direction
    is None) still draws both cars side by side, undirected, with impact
    marks — better than nothing even for a "we don't know the route" case,
    which per the loop-avoidance rules in prompts.py is a normal, expected
    outcome, not a rare one.
    """
    box = _CROQUIS_BOX
    cy = (box.y0 + box.y1) / 2
    bearing_a = (route_a or {}).get("bearing_deg")
    bearing_b = (route_b or {}).get("bearing_deg")
    parked_a = "a" in vehicle_a.circumstances
    parked_b = "a" in vehicle_b.circumstances

    if relative_direction == "same_direction" and bearing_a is not None:
        # One behind the other along the shared heading: whichever vehicle
        # was hit at the rear goes in front (it's the one that got struck
        # from behind), the other goes behind it. Falls back to A-behind-B
        # if neither declared a rear/front impact clearly enough to order them.
        a_hit_rear = any(z.startswith("rear") for z in vehicle_a.impact_zones)
        b_hit_rear = any(z.startswith("rear") for z in vehicle_b.impact_zones)
        a_ahead = a_hit_rear or not b_hit_rear
        dx, dy = _heading_vector(bearing_a)
        gap = _CAR_LEN * 0.9
        cx_mid = (box.x0 + box.x1) / 2
        ahead_pt = (cx_mid + dx * gap / 2, cy + dy * gap / 2)
        behind_pt = (cx_mid - dx * gap / 2, cy - dy * gap / 2)
        a_pt, b_pt = (ahead_pt, behind_pt) if a_ahead else (behind_pt, ahead_pt)
        _draw_car(page, *a_pt, bearing_a, "A", vehicle_a.impact_zones, (0.55, 0.45, 0))
        _draw_car(page, *b_pt, bearing_b if bearing_b is not None else bearing_a, "B", vehicle_b.impact_zones, (0, 0.35, 0.45))
    elif relative_direction == "opposite_direction" and bearing_a is not None and bearing_b is not None:
        # Nose-to-nose along their (opposite) shared line.
        dx, dy = _heading_vector(bearing_a)
        gap = _CAR_LEN * 0.9
        cx_mid = (box.x0 + box.x1) / 2
        a_pt = (cx_mid - dx * gap / 2, cy - dy * gap / 2)
        b_pt = (cx_mid + dx * gap / 2, cy + dy * gap / 2)
        _draw_car(page, *a_pt, bearing_a, "A", vehicle_a.impact_zones, (0.55, 0.45, 0))
        _draw_car(page, *b_pt, bearing_b, "B", vehicle_b.impact_zones, (0, 0.35, 0.45))
    else:
        # Crossing paths, or not enough route data to classify at all — side
        # by side, each with whatever heading it actually has (None if a
        # vehicle was parked or its route was never resolved).
        left_x = box.x0 + (box.x1 - box.x0) * 0.3
        right_x = box.x0 + (box.x1 - box.x0) * 0.7
        _draw_car(page, left_x, cy, None if parked_a else bearing_a, "A", vehicle_a.impact_zones, (0.55, 0.45, 0))
        _draw_car(page, right_x, cy, None if parked_b else bearing_b, "B", vehicle_b.impact_zones, (0, 0.35, 0.45))

    if parked_a or parked_b:
        note = " / ".join(
            f"{lbl} à l'arrêt" for lbl, is_parked in (("A", parked_a), ("B", parked_b)) if is_parked
        )
        page.insert_text((box.x0 + 2, box.y1 - 3), note, fontsize=6, fontname=_FONT, color=(0.3, 0.3, 0.3))


def _fill_vehicle(page: "fitz.Page", label: str, v, route: dict | None):
    off = 0 if label == "A" else _B_OFFSET_X

    def pt(name):
        x, y = _VEHICLE_FIELD_XY[name]
        return (x + off, y)

    _draw_text(page, pt("insurance_company"), v.insurance_company or "", max_width=250)
    _draw_text(page, pt("policy_number"), v.policy_number or "", max_width=180)
    _draw_text(page, pt("agency"), v.agency or "", max_width=250)
    _draw_text(page, pt("driver_last_name_first_name"), v.driver_last_name or "", max_width=200)
    _draw_text(page, pt("driver_first_name_row"), v.driver_first_name or "", max_width=200)
    _draw_text(page, pt("driver_address"), v.driver_address or "", max_width=220)
    _draw_text(page, pt("license_number"), v.license_number or "", max_width=140)

    insured_last = v.insured_last_name or v.driver_last_name
    insured_first = v.insured_first_name or v.driver_first_name
    _draw_text(page, pt("insured_last_name"), insured_last or "", max_width=200)
    _draw_text(page, pt("insured_first_name"), insured_first or "", max_width=200)
    _draw_text(page, pt("insured_address"), v.insured_address or v.driver_address or "", max_width=220)
    _draw_text(page, pt("insured_phone"), v.insured_phone or "", max_width=180)

    _draw_text(page, pt("vehicle_make_model"), v.vehicle_make_model or "", max_width=220)
    _draw_text(page, pt("plate_number"), v.plate_number or "", max_width=180)
    compass = route["compass"] if route else None
    _draw_text(page, pt("sens_suivi"), compass or "", max_width=220)
    _draw_text(page, pt("venant_de"), v.from_address or "", max_width=240)
    _draw_text(page, pt("allant_a"), v.to_address or "", max_width=240)

    for code in v.circumstances:
        row = _CIRCUMSTANCE_ROW.get(code)
        if row is None:
            continue
        x = _CHECKBOX_X_A if label == "A" else _CHECKBOX_X_B
        y = _CIRCUMSTANCE_ROW_Y[row]
        _draw_check(page, (x, y))

    damage_text = v.damage_description or (", ".join(z.replace("_", " ") for z in v.impact_zones))
    _draw_text(page, _DAMAGE_OBS_XY[label]["damage"], damage_text, max_width=220)
    _draw_text(page, _DAMAGE_OBS_XY[label]["observations"], v.observations or "", max_width=220)


def generate_filled_constat(
    claim, vehicle_a, vehicle_b, routes: dict | None = None, relative_direction: str | None = None
) -> bytes:
    """
    claim: accident_analysis.ClaimInfo
    vehicle_a, vehicle_b: accident_analysis.VehicleInput
    routes: optional {"A": {...}, "B": {...}} from analyze()'s "routes" key —
            used to write each vehicle's compass heading into "Sens suivi"
            AND (together with relative_direction below) to draw the
            auto-generated croquis. Safe to omit; sections just render blank/
            undirected.
    relative_direction: optional "same_direction" / "opposite_direction" /
            "crossing" / None, straight from analyze()'s top-level key of the
            same name — drives the croquis layout (see _draw_croquis).
    Returns the filled PDF as bytes.
    """
    if not TEMPLATE_PATH.exists():
        raise FileNotFoundError(
            f"Constat template not found at {TEMPLATE_PATH} — expected the scanned "
            "constat.pdf to be shipped at assistant/assets/constat_template.pdf."
        )

    doc = fitz.open(TEMPLATE_PATH)
    page = doc[0]

    _draw_text(page, _HEADER_XY["date"], claim.accident_date or "", max_width=100)
    _draw_text(page, _HEADER_XY["heure"], claim.accident_time or "", max_width=100)
    _draw_text(page, _HEADER_XY["lieu"], claim.location or "", max_width=240)
    if claim.injuries is True:
        _draw_check(page, _HEADER_XY["blessed_oui"])
    elif claim.injuries is False:
        _draw_check(page, _HEADER_XY["blessed_non"])
    if claim.other_material_damage is True:
        _draw_check(page, _HEADER_XY["other_damage_oui"])
    elif claim.other_material_damage is False:
        _draw_check(page, _HEADER_XY["other_damage_non"])
    if claim.witnesses:
        _draw_text(page, _HEADER_XY["witnesses"], "; ".join(claim.witnesses), max_width=230)

    route_a = (routes or {}).get("A")
    route_b = (routes or {}).get("B")
    _fill_vehicle(page, "A", vehicle_a, route_a)
    _fill_vehicle(page, "B", vehicle_b, route_b)
    _draw_croquis(page, vehicle_a, vehicle_b, route_a, route_b, relative_direction)

    buf = io.BytesIO()
    doc.save(buf)
    doc.close()
    return buf.getvalue()
