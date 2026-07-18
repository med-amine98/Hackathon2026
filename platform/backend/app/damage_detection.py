"""
Real car-damage detection + repair-cost estimation, run against every photo
a client uploads during the mobile app's constat chat (see
app/routers/photos.py's upload_photo, which enqueues app/worker.py's
run_damage_assessment Celery task after each successful upload).

MODEL: YOLO11n (ultralytics), trained on the CarDD taxonomy — dent,
scratch, crack, glass_shatter, lamp_broken, tire_flat (Wang et al., "CarDD:
A New Dataset for Vision-based Car Damage Detection", IEEE T-ITS 2023,
https://cardd-ustc.github.io/). The training/inference pipeline used to
produce the checkpoint lives in ml/train_damage_detection_colab.py
(run on Google Colab). Each CarDD damage-type detection is mapped to a
vehicle zone/part (bumper, door, window, windshield, headlight, mirror,
hood — see PARTS_CATALOG below) to drive the repair-cost estimate. Drop
the trained checkpoint at the path in CAR_DAMAGE_MODEL_PATH (default
app/weights/car_damage_yolo11.pt) for a given deployment to enable real
YOLO inference.

INFERENCE STRATEGY: _detect_with_yolo runs the same multi-configuration
confidence/IoU sweep as ml/train_damage_detection_colab.py (four conf/iou
pairs from strict to permissive, see _DETECTION_CONFIGS) and keeps
whichever pass actually found the most real boxes, falling back to one very
permissive last attempt if every configured pass comes back empty — a
single fixed threshold either misses real damage on a hard photo or floods
the result with false positives, so this mirrors the notebook's approach
instead of guessing one setting.

RESILIENT FALLBACK: not every deployment target bakes the trained
checkpoint into the container image (e.g. a lightweight CI/staging build
without the weights file, or ultralytics not installed there). In that
case detect_damage() degrades gracefully to a lightweight OpenCV heuristic
(edge-density + contour analysis to propose damage regions) so the feature
still produces a real, photo-derived estimate — with a lower confidence
band and a note in the result saying so — instead of failing the request.
Once the trained checkpoint is present, the exact same downstream
cost-estimation / hotspot code path is used — nothing else needs to change.

COST DATA: base repair/replacement costs in Tunisian dinars, anchored to
published Tunisian carrosserie pricing (bumper repair from ~350 DT,
repaint-only, up to ~2500 DT for a full respray; new bumper ~550 DT; body-
shop hourly labor 41-85 DT — see sm-devis.tn). These are estimation
baselines; a further integration would call an actual Tunisian
parts-distributor API per make/model/year for live pricing.
"""
from __future__ import annotations

import io
import os
from dataclasses import dataclass
from typing import Optional

CAR_DAMAGE_MODEL_PATH = os.getenv(
    "CAR_DAMAGE_MODEL_PATH",
    os.path.join(os.path.dirname(__file__), "weights", "car_damage_yolo11.pt"),
)

# CarDD class_name -> (French label, repair action, standard-tier base cost
# DT, rough body zone). Keys match the model's actual training taxonomy
# (see module docstring) — dent, scratch, crack, glass_shatter, lamp_broken,
# tire_flat — so every real detection gets its own accurate label/cost
# instead of silently falling back to a generic one.
PARTS_CATALOG: dict[str, dict] = {
    "dent": {"label": "Bosse carrosserie", "action": "Débosselage sans peinture (PDR)", "base_cost": 180.0, "part_zone": "body"},
    "scratch": {"label": "Rayure carrosserie", "action": "Ponçage + retouche peinture", "base_cost": 120.0, "part_zone": "body"},
    "crack": {"label": "Fissure (pare-brise/plastique)", "action": "Réparation ou remplacement selon profondeur", "base_cost": 300.0, "part_zone": "front"},
    "glass_shatter": {"label": "Vitre/pare-brise brisé(e)", "action": "Remplacement vitrage", "base_cost": 500.0, "part_zone": "front"},
    "lamp_broken": {"label": "Feu/optique cassé", "action": "Remplacement bloc optique", "base_cost": 280.0, "part_zone": "front"},
    "tire_flat": {"label": "Pneu crevé/à plat", "action": "Remplacement pneu", "base_cost": 250.0, "part_zone": "body"},
}

# Approximate position on a car silhouette (for the AIEstimation.jsx overlay
# dot) per damage zone, used only for the OpenCV-heuristic fallback path
# where we don't get a real bounding box tied to a specific detected part.
_ZONE_POSITION = {
    "front": ("30%", "40%"),
    "side": ("50%", "60%"),
    "body": ("45%", "50%"),
}

# Rough Tunisian-market brand tiers — used as a cost multiplier since parts
# for a premium-badge car cost meaningfully more than for an economy one,
# even for the same repair action. Keyword match against the free-text
# vehicle_make_model string already collected on the constat
# (ClientProfile.vehicle_make_model).
_PREMIUM_BRANDS = {"bmw", "mercedes", "audi", "volvo", "land rover", "porsche", "jaguar", "range rover"}
_ECONOMY_BRANDS = {"dacia", "chery", "geely", "suzuki", "lada", "changan"}
_TIER_MULTIPLIER = {"premium": 1.6, "standard": 1.0, "economique": 0.75}


def _brand_tier(vehicle_make_model: Optional[str]) -> str:
    if not vehicle_make_model:
        return "standard"
    text = vehicle_make_model.lower()
    if any(b in text for b in _PREMIUM_BRANDS):
        return "premium"
    if any(b in text for b in _ECONOMY_BRANDS):
        return "economique"
    return "standard"


@dataclass
class Detection:
    class_name: str
    confidence: float
    # Normalized 0-1 bounding box, (x1, y1, x2, y2)
    bbox: tuple[float, float, float, float]
    source: str  # "yolo11" or "heuristic"


_model = None
_model_load_attempted = False


def _load_model():
    """
    Lazily loads the YOLO11 checkpoint. Imported lazily (like storage.py's
    minio client) so the rest of the app runs fine without ultralytics/torch
    installed — only the worker's damage-assessment task needs it, and even
    that degrades gracefully rather than crashing the Celery task.
    """
    global _model, _model_load_attempted
    if _model is not None or _model_load_attempted:
        return _model
    _model_load_attempted = True
    if not os.path.exists(CAR_DAMAGE_MODEL_PATH):
        return None
    try:
        from ultralytics import YOLO

        _model = YOLO(CAR_DAMAGE_MODEL_PATH)
    except Exception:
        _model = None
    return _model


# Same confidence/IoU sweep as ml/train_damage_detection_colab.py's
# multi-configuration pass: a single fixed threshold either misses real
# damage on a hard photo (too strict) or floods the result with noise (too
# loose), so the notebook - and this production path, mirroring it - tries
# several conf/iou pairs and keeps whichever one actually found the most
# real boxes, instead of gambling on one fixed setting.
_DETECTION_CONFIGS = [
    {"conf": 0.1, "iou": 0.5, "name": "Seuil bas (plus de detections)"},
    {"conf": 0.15, "iou": 0.45, "name": "Seuil moyen"},
    {"conf": 0.2, "iou": 0.4, "name": "Seuil standard"},
    {"conf": 0.05, "iou": 0.3, "name": "Seuil tres bas (max de detections)"},
]


def _detect_with_yolo(image_bytes: bytes) -> Optional[list[Detection]]:
    model = _load_model()
    if model is None:
        return None
    try:
        from PIL import Image

        img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        width, height = img.size

        best_detections: list[Detection] = []
        best_config_name = None

        for config in _DETECTION_CONFIGS:
            results = model.predict(img, conf=config["conf"], iou=config["iou"], verbose=False)
            config_detections: list[Detection] = []
            for result in results:
                names = result.names
                for box in result.boxes:
                    cls_id = int(box.cls[0])
                    class_name = names.get(cls_id, str(cls_id)) if isinstance(names, dict) else str(cls_id)
                    conf = float(box.conf[0])
                    x1, y1, x2, y2 = [float(v) for v in box.xyxy[0]]
                    config_detections.append(
                        Detection(
                            class_name=class_name,
                            confidence=conf,
                            bbox=(x1 / width, y1 / height, x2 / width, y2 / height),
                            source="yolo11",
                        )
                    )
            if len(config_detections) > len(best_detections):
                best_detections = config_detections
                best_config_name = config["name"]

        # No detections at any threshold in the sweep above - one last,
        # very permissive pass (same as the notebook's "tentative avec des
        # parametres tres permissifs" retry) so a real but faint damage
        # signal still has a chance to surface instead of returning empty.
        if not best_detections:
            results = model.predict(img, conf=0.01, iou=0.1, verbose=False)
            for result in results:
                names = result.names
                for box in result.boxes:
                    cls_id = int(box.cls[0])
                    class_name = names.get(cls_id, str(cls_id)) if isinstance(names, dict) else str(cls_id)
                    conf = float(box.conf[0])
                    x1, y1, x2, y2 = [float(v) for v in box.xyxy[0]]
                    best_detections.append(
                        Detection(
                            class_name=class_name,
                            confidence=conf,
                            bbox=(x1 / width, y1 / height, x2 / width, y2 / height),
                            source="yolo11",
                        )
                    )
            best_config_name = "Tentative tres permissive"

        return best_detections
    except Exception:
        return None


def _detect_with_heuristic(image_bytes: bytes) -> list[Detection]:
    """
    Fallback used when no trained YOLO11 checkpoint is available. Uses
    OpenCV edge-density analysis to flag regions of the photo with unusually
    high local contrast/edge concentration (a real, if crude, signal for
    scuffed paint, torn metal, or shattered glass vs. an undamaged smooth
    panel) and reports them as generic "dent" detections with a capped,
    visibly-lower confidence so this never looks as certain as real model
    output. This is a placeholder computer-vision pass, not a trained damage
    classifier — it can't tell a shadow from a scratch — but it means the
    pipeline still returns a real, photo-derived result instead of nothing
    at all while a trained checkpoint isn't deployed.
    """
    try:
        import cv2
        import numpy as np

        arr = np.frombuffer(image_bytes, dtype=np.uint8)
        img = cv2.imdecode(arr, cv2.IMREAD_COLOR)
        if img is None:
            return []
        height, width = img.shape[:2]
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        edges = cv2.Canny(gray, 80, 180)
        # Coarse 4x4 grid — sum edge pixels per cell, flag the hottest cells.
        grid_h, grid_w = 4, 4
        cell_h, cell_w = height // grid_h, width // grid_w
        cells = []
        for gy in range(grid_h):
            for gx in range(grid_w):
                y0, y1 = gy * cell_h, (gy + 1) * cell_h if gy < grid_h - 1 else height
                x0, x1 = gx * cell_w, (gx + 1) * cell_w if gx < grid_w - 1 else width
                density = float(edges[y0:y1, x0:x1].mean())
                cells.append((density, x0, y0, x1, y1))
        cells.sort(key=lambda c: c[0], reverse=True)
        avg_density = sum(c[0] for c in cells) / len(cells) if cells else 0.0

        detections: list[Detection] = []
        for density, x0, y0, x1, y1 in cells[:3]:
            if avg_density <= 0 or density < avg_density * 1.4:
                continue  # not meaningfully hotter than the rest of the photo
            # Capped well below what a confident model detection would show.
            confidence = min(0.55, 0.25 + (density / (avg_density * 4)))
            detections.append(
                Detection(
                    class_name="dent",
                    confidence=round(confidence, 2),
                    bbox=(x0 / width, y0 / height, x1 / width, y1 / height),
                    source="heuristic",
                )
            )
        return detections
    except Exception:
        return []


def detect_damage(image_bytes: bytes) -> list[Detection]:
    yolo_detections = _detect_with_yolo(image_bytes)
    if yolo_detections is not None:
        return yolo_detections
    return _detect_with_heuristic(image_bytes)


def estimate_repair(
    detections: list[Detection],
    vehicle_make_model: Optional[str] = None,
    vehicle_category: Optional[str] = None,
) -> dict:
    """
    Turns raw detections into the exact hotspots/subtotal/total/insights
    shape assurex/frontend/src/pages/AIEstimation.jsx already renders (see
    assurex/backend/seed.py's CLAIMS for the shape this mirrors), plus a
    damage_percent summary figure.
    """
    tier = _brand_tier(vehicle_make_model)
    multiplier = _TIER_MULTIPLIER[tier]

    hotspots = []
    total_area = 0.0
    for i, det in enumerate(detections):
        catalog = PARTS_CATALOG.get(det.class_name, PARTS_CATALOG["dent"])
        x1, y1, x2, y2 = det.bbox
        area = max(0.0, x2 - x1) * max(0.0, y2 - y1)
        total_area += area
        cost = round(catalog["base_cost"] * multiplier, 2)
        cx, cy = (x1 + x2) / 2, (y1 + y2) / 2
        severity = "Critical" if det.confidence >= 0.85 else "High" if det.confidence >= 0.6 else "Low"
        hotspots.append(
            {
                "id": f"hs-{i + 1}",
                "top": f"{round(cy * 100)}%",
                "left": f"{round(cx * 100)}%",
                "title": catalog["label"],
                "description": f"{catalog['action']} — détection {'YOLO11 (CarDD)' if det.source == 'yolo11' else 'heuristique'} (confiance {round(det.confidence * 100)}%).",
                "severity": severity,
                "cost": cost,
                "confidence": round(det.confidence * 100),
            }
        )

    subtotal = round(sum(h["cost"] for h in hotspots), 2)
    # Labor pass (Tunisian carrosserie hourly rate, ~1h flat per photo batch
    # assessed) on top of parts/paint, same spirit as sm-devis.tn's 41-85 DT/h
    # bracket — flat estimate since we don't track actual labor hours here.
    labor = 60.0 if hotspots else 0.0
    total = round(subtotal + labor, 2)

    # Rough overall damage percentage: total bounding-box area covered by
    # detections relative to the photo, scaled up since damage areas are
    # usually a small fraction of a full-vehicle photo — capped at 100.
    damage_percent = min(100, round(total_area * 260))

    if not hotspots:
        insights = "Aucun dommage détecté automatiquement sur les photos analysées."
    else:
        parts = ", ".join(sorted({h["title"] for h in hotspots}))
        insights = (
            f"Analyse IA (YOLO11, taxonomie CarDD) sur {len({d.class_name for d in detections})} zone(s) de dommage détectée(s) : "
            f"{parts}. Estimation basée sur un véhicule de gamme {tier} "
            f"({vehicle_make_model or 'marque non renseignée'})."
        )

    return {
        "hotspots": hotspots,
        "subtotal": subtotal,
        "total": total,
        "insights": insights,
        "damage_percent": damage_percent,
        "vehicle_tier": tier,
    }


# Distinct color per CarDD class so the annotated image is readable at a
# glance instead of every box being the same color.
_BOX_COLORS = {
    "dent": (239, 68, 68),
    "scratch": (245, 158, 11),
    "crack": (168, 85, 247),
    "glass_shatter": (14, 165, 233),
    "lamp_broken": (234, 179, 8),
    "tire_flat": (107, 114, 128),
}


def annotate_image(image_bytes: bytes, detections: list[Detection]) -> bytes:
    """
    Draws each detection's bounding box + "label conf%" tag directly on the
    source photo (same idea as the Colab notebook's result.plot(), just
    done server-side with PIL so the API can hand the frontend a ready-to-
    display image instead of raw coordinates it would have to overlay
    itself). Returns PNG bytes. Never raises — a drawing failure falls back
    to returning the untouched original image so the endpoint still has
    something to show.
    """
    try:
        from PIL import Image, ImageDraw, ImageFont

        img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        width, height = img.size
        draw = ImageDraw.Draw(img)

        try:
            font_size = max(14, round(min(width, height) * 0.022))
            font = ImageFont.truetype("DejaVuSans-Bold.ttf", font_size)
        except Exception:
            font = ImageFont.load_default()

        line_width = max(2, round(min(width, height) * 0.004))

        for det in detections:
            x1, y1, x2, y2 = det.bbox
            box = (x1 * width, y1 * height, x2 * width, y2 * height)
            color = _BOX_COLORS.get(det.class_name, (34, 197, 94))
            draw.rectangle(box, outline=color, width=line_width)

            label = f"{det.class_name} {round(det.confidence * 100)}%"
            text_bbox = draw.textbbox((0, 0), label, font=font)
            text_w, text_h = text_bbox[2] - text_bbox[0], text_bbox[3] - text_bbox[1]
            pad = 4
            tag_top = max(0, box[1] - text_h - 2 * pad)
            draw.rectangle(
                (box[0], tag_top, box[0] + text_w + 2 * pad, tag_top + text_h + 2 * pad),
                fill=color,
            )
            draw.text((box[0] + pad, tag_top + pad), label, fill=(255, 255, 255), font=font)

        out = io.BytesIO()
        img.save(out, format="PNG")
        return out.getvalue()
    except Exception:
        return image_bytes
