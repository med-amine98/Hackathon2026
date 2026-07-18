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
    # x was 200 — measured against a coordinate grid render (see git history
    # around the plate/phone overflow fix), that left only ~20-29pt of real
    # width before the circumstances checkbox column (Vehicle A) or the
    # page's own right edge (Vehicle B, via _B_OFFSET_X), while a real plate
    # number needs ~50-55pt at this font size — it was overflowing into the
    # checkbox column for A and off the page entirely for B. 160 lines up
    # with where the "N° d'immatriculation" label's underline actually
    # starts, giving ~55-58pt on both sides. See _draw_text_fit, used for
    # this field in _fill_vehicle, for the belt-and-suspenders fix (shrinks
    # to fit rather than trusting the measurement alone to always be enough).
    "plate_number": (160, 498),
    "sens_suivi": (145, 513),   # compass heading, computed
    "venant_de": (120, 530),
    "allant_a": (115, 550),
}

# Hard boundaries plate_number/insured_phone must not cross — see
# _draw_text_fit. Vehicle A's fields are bounded on the right by the
# circumstances checkbox column; Vehicle B's mirror position (_B_OFFSET_X)
# lands close enough to the page's own right edge that ITS real boundary is
# the page edge instead, not the (already-passed) checkbox column.
_TEXT_RIGHT_BOUND_A = 218.0
_TEXT_RIGHT_BOUND_B = 590.0  # page is 595pt wide (see TEMPLATE_PATH), 5pt margin

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
        # Crude wrap: fitz has no built-in wrap for insert_text, so just
        # truncate with an ellipsis rather than overrun into the next field.
        # approx_chars is a rough estimate (assumes ~0.5*size per char),
        # not a real measurement — fine for free-text fields (description,
        # observations, addresses) where losing the tail end to "…" is a
        # minor readability issue. NOT fine for an identifier that must be
        # exact (plate number, phone) — see _draw_text_fit below for those.
        approx_chars = int(max_width / (size * 0.5))
        if len(text) > approx_chars:
            text = text[: approx_chars - 1] + "…"
    page.insert_text(xy, text, fontsize=size, fontname=_FONT, color=(0, 0, 0.55))


def _draw_text_fit(
    page: "fitz.Page",
    xy: tuple[float, float],
    text: str,
    max_width: float,
    base_size: float = _FONT_SIZE,
    min_size: float = 5.5,
):
    """
    Like _draw_text, but for values that must never be silently truncated —
    a plate number or phone number cut off with "…" is actively wrong, not
    just untidy. Measures the ACTUAL rendered width with fitz.get_text_length
    (not _draw_text's rough per-character estimate) and shrinks the font in
    0.5pt steps until it genuinely fits max_width, down to min_size. Falls
    back to _draw_text's ellipsis truncation only if it still doesn't fit at
    min_size — which some real values may hit (a long international number
    with a country code) but should be rare, and is still better than
    silently overflowing into the next field/off the page, which is the bug
    this replaces (see constat_pdf.py's plate_number/insured_phone fields —
    both are positioned right up against a fixed boundary, either the
    circumstances checkbox column for Vehicle A or the page's outer edge for
    Vehicle B, with much less real width available than a generic max_width
    assumption gave credit for).
    """
    if not text:
        return
    text = str(text)
    size = base_size
    while size > min_size and fitz.get_text_length(text, fontname=_FONT, fontsize=size) > max_width:
        size -= 0.5
    if fitz.get_text_length(text, fontname=_FONT, fontsize=size) > max_width:
        _draw_text(page, xy, text, size=size, max_width=max_width)
        return
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

    # A direct collision (rear-end, head-on) legitimately puts both
    # vehicles' damage marks at the exact same point — physically correct,
    # but two identical filled red dots stacked on each other just look
    # like one dot, which is worse than showing nothing. A's mark stays a
    # small filled dot; B's is a slightly larger open ring in the same red,
    # so a coincident mark reads as "dot inside a ring" (both vehicles'
    # damage, still one point) instead of silently losing one of them.
    dot_fill = (0.75, 0, 0) if label == "A" else None
    dot_radius = 2.2 if label == "A" else 3.2
    for zone in impact_zones:
        key = _IMPACT_ZONE_POSITION.get(zone)
        if key and key in corners:
            x, y = corners[key]
            page.draw_circle((x, y), dot_radius, color=(0.75, 0, 0), fill=dot_fill, width=1.1)


# Keywords that mean "roundabout" across the languages this chat actually
# sees (assistant/language.py detects ar/fr/en) — checked against everything
# the client typed in free text, not just one field, since a roundabout is
# as likely to come up describing the location ("au rond-point de la Marsa")
# as describing what happened (the narrative/evidence trail).
_ROUNDABOUT_KEYWORDS = ("rond-point", "rond point", "rondpoint", "giratoire", "roundabout", "دوار")


def _mentions_roundabout(claim, vehicle_a, vehicle_b) -> bool:
    texts = [
        claim.location or "",
        vehicle_a.narrative or "", vehicle_b.narrative or "",
        vehicle_a.damage_description or "", vehicle_b.damage_description or "",
        vehicle_a.observations or "", vehicle_b.observations or "",
        " ".join(vehicle_a.evidence), " ".join(vehicle_b.evidence),
    ]
    blob = " ".join(texts).lower()
    return any(kw in blob for kw in _ROUNDABOUT_KEYWORDS)


def _draw_roundabout(page: "fitz.Page", cx: float, cy: float, radius: float):
    """
    The circle + 4 short entry/exit tick marks that stand in for a
    roundabout in the croquis — drawn whenever the conversation actually
    mentioned one (see _mentions_roundabout), instead of leaving the reader
    to infer it from two car icons alone. Two small curved-flow arrows on
    the circle hint the direction of travel around it (counter-clockwise,
    correct for Tunisia/right-hand-traffic countries — this whole app
    already assumes that side of the road, see geometry.py).
    """
    page.draw_circle((cx, cy), radius, color=(0.35, 0.35, 0.35), width=1.2)
    page.insert_text((cx - 18, cy - radius - 4), "rond-point", fontsize=6, fontname=_FONT, color=(0.35, 0.35, 0.35))

    # Two short tangential arrow ticks on the circle showing counter-
    # clockwise flow — just enough to read as "this is a roundabout, traffic
    # circulates this way," not a full lane diagram.
    for angle_deg in (20, 200):
        angle = math.radians(angle_deg)
        px, py = cx + radius * math.cos(angle), cy + radius * math.sin(angle)
        # tangent direction for counter-clockwise travel at this point
        tdx, tdy = math.sin(angle), -math.cos(angle)
        tip = (px + tdx * 7, py + tdy * 7)
        page.draw_line((px, py), tip, color=(0.35, 0.35, 0.35), width=1.0)
        ndx, ndy = -tdy, tdx
        for sign in (-1, 1):
            wing = (tip[0] - tdx * 3 + ndx * 2 * sign, tip[1] - tdy * 3 + ndy * 2 * sign)
            page.draw_line(tip, wing, color=(0.35, 0.35, 0.35), width=1.0)


def _draw_croquis(page: "fitz.Page", claim, vehicle_a, vehicle_b, route_a: dict | None,
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
    cx_mid = (box.x0 + box.x1) / 2
    bearing_a = (route_a or {}).get("bearing_deg")
    bearing_b = (route_b or {}).get("bearing_deg")
    parked_a = "a" in vehicle_a.circumstances
    parked_b = "a" in vehicle_b.circumstances

    if _mentions_roundabout(claim, vehicle_a, vehicle_b):
        # Takes priority over the same/opposite/crossing layouts below — a
        # roundabout is a visually distinct, more informative picture than
        # generic "side by side" once we know that's what it was, and the
        # heading-based layouts below don't have a way to represent a
        # circular junction anyway (they're built around a single shared
        # straight line).
        radius = min(box.x1 - box.x0, box.y1 - box.y0) * 0.22
        _draw_roundabout(page, cx_mid, cy, radius)
        # Each car sits just outside the circle, on the approach it
        # actually came from if we know a heading, otherwise a plain
        # opposite-sides default — still carries its own directional arrow
        # via _draw_car (the "indiquer par une flèche" mark from the
        # printed form's own instructions), just anchored at the roundabout
        # edge instead of a straight shared line.
        #
        # Position is computed as an ANGLE around the circle (not two
        # independent heading vectors) specifically so A and B's angles can
        # be checked against each other and forced apart — computing each
        # car's spot purely from its own heading independently (the first
        # version of this) let them land on the exact same point whenever
        # one heading (or its 90°/270° "unknown" fallback) happened to
        # match the other's, e.g. one vehicle genuinely heading east and
        # the other's heading unknown — both are visually distinct
        # accidents, but rendered identically on top of each other, which
        # is exactly the "not clean" failure this guards against.
        gap = radius + _CAR_LEN * 0.65

        def approach_angle(heading_deg: float | None, default_deg: float) -> float:
            # Angle (radians, standard math convention) of the point the car
            # sits at, given the compass heading it was travelling on — the
            # car sits on the side it approached FROM, i.e. opposite its
            # direction of travel, then bearing is converted from
            # "0=north, clockwise" to plain math angle.
            b = heading_deg if heading_deg is not None else default_deg
            return math.radians(90 - b) + math.pi  # +pi: FROM side, not travelling-to side

        a_heading = None if parked_a else bearing_a
        b_heading = None if parked_b else bearing_b
        angle_a = approach_angle(a_heading, default_deg=180.0)  # default: from the south
        angle_b = approach_angle(b_heading, default_deg=0.0)    # default: from the north

        # Guarantee real separation regardless of what the headings said —
        # if they'd land within min_sep of each other on the circle, fan
        # both apart symmetrically around their shared midpoint instead of
        # flipping one 180°. A hard 180° flip used to move a car's
        # *position* to the opposite side of the circle while its
        # directional arrow (_draw_car) kept pointing along its real,
        # unchanged heading — so a car flipped to the east side could end
        # up drawn there with an arrow pointing further east, i.e. away
        # from the roundabout instead of into it. Fanning both angles out
        # from their common midpoint keeps each car on (approximately) the
        # side its real heading actually approaches from, so the arrow
        # still reads as "entering the roundabout" — it only nudges the
        # two apart just enough to stop the icons/labels from overlapping.
        # Still honest about "unknown," since a missing heading was already
        # forced to a distinct default above; this only catches two REAL
        # headings that happen to roughly agree, or a real heading
        # colliding with the other vehicle's default.
        min_sep = math.radians(70)
        d_signed = ((angle_b - angle_a + math.pi) % (2 * math.pi)) - math.pi  # (-pi, pi]
        if abs(d_signed) < min_sep:
            mid = angle_a + d_signed / 2
            sign = 1.0 if d_signed >= 0 else -1.0
            angle_a = mid - sign * min_sep / 2
            angle_b = mid + sign * min_sep / 2

        a_pt = (cx_mid + gap * math.cos(angle_a), cy - gap * math.sin(angle_a))
        b_pt = (cx_mid + gap * math.cos(angle_b), cy - gap * math.sin(angle_b))
        _draw_car(page, *a_pt, a_heading, "A", vehicle_a.impact_zones, (0.55, 0.45, 0))
        _draw_car(page, *b_pt, b_heading, "B", vehicle_b.impact_zones, (0, 0.35, 0.45))
    elif relative_direction == "same_direction" and bearing_a is not None:
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
    right_bound = _TEXT_RIGHT_BOUND_A if label == "A" else _TEXT_RIGHT_BOUND_B

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
    # Phone/plate must never be silently truncated with "…" — a cut-off
    # identifier is wrong, not just untidy — so these two use _draw_text_fit
    # (shrinks the font to actually fit right_bound) instead of the plain
    # _draw_text used above, whose max_width is just a rough guess. See
    # _TEXT_RIGHT_BOUND_A/_B's docstring for why A and B need different
    # bounds here specifically (checkbox column vs. page edge).
    phone_xy = pt("insured_phone")
    _draw_text_fit(page, phone_xy, v.insured_phone or "", max_width=right_bound - phone_xy[0])

    _draw_text(page, pt("vehicle_make_model"), v.vehicle_make_model or "", max_width=220)
    plate_xy = pt("plate_number")
    _draw_text_fit(page, plate_xy, v.plate_number or "", max_width=right_bound - plate_xy[0])
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
    _draw_croquis(page, claim, vehicle_a, vehicle_b, route_a, route_b, relative_direction)

    buf = io.BytesIO()
    doc.save(buf)
    doc.close()
    return buf.getvalue()
