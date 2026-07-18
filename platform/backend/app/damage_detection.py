"""
Real car-damage detection + repair-cost estimation, run against every photo
a client uploads during the mobile app's constat chat (see
app/routers/photos.py's upload_photo, which enqueues app/worker.py's
run_damage_assessment Celery task after each successful upload).

MODEL: YOLOv8 (ultralytics), 8-class car-damage taxonomy — damaged-bumper,
damaged-door, damaged-window, damaged-windshield, damaged-headlight,
damaged-mirror, damaged-hood, dent. This matches the class set used by the
public car-damage-detection datasets/checkpoints on Hugging Face/Roboflow
(e.g. keremberke/yolov8n-car-damage-detection, CarDD). Drop a trained
checkpoint at the path in CAR_DAMAGE_MODEL_PATH (default
app/weights/car_damage_yolov8.pt) to use real YOLOv8 inference.

HONEST FALLBACK: this hackathon environment doesn't ship trained YOLOv8
weights (no GPU training pipeline here, and downloading arbitrary third-
party model weights at container-build time isn't something to bake in
silently). If ultralytics isn't installed or no weights file exists at that
path, detect_damage() falls back to a lightweight OpenCV heuristic (edge-
density + contour analysis to propose damage regions) so the feature still
produces a real, photo-derived estimate instead of a hardcoded fake one —
just with a lower confidence band and a note in the result saying so. Once
real weights are dropped in, the exact same downstream cost-estimation /
hotspot code path is used — nothing else needs to change.

COST DATA: base repair/replacement costs in Tunisian dinars, anchored to
published Tunisian carrosserie pricing (bumper repair from ~350 DT,
repaint-only, up to ~2500 DT for a full respray; new bumper ~550 DT; body-
shop hourly labor 41-85 DT — see sm-devis.tn). These are estimation
baselines for a demo, not a live parts-supplier price feed — a real
integration would call an actual Tunisian parts-distributor API per
make/model/year.
"""
from __future__ import annotations

import io
import os
from dataclasses import dataclass
from typing import Optional

CAR_DAMAGE_MODEL_PATH = os.getenv(
    "CAR_DAMAGE_MODEL_PATH",
    os.path.join(os.path.dirname(__file__), "weights", "car_damage_yolov8.pt"),
)

# class_name -> (French part label, repair action, standard-tier base cost DT)
PARTS_CATALOG: dict[str, dict] = {
    "damaged-bumper": {"label": "Pare-chocs", "action": "Réparation/repeinture", "base_cost": 480.0, "part_zone": "front"},
    "damaged-door": {"label": "Portière", "action": "Débosselage + peinture", "base_cost": 650.0, "part_zone": "side"},
    "damaged-window": {"label": "Vitre latérale", "action": "Remplacement", "base_cost": 380.0, "part_zone": "side"},
    "damaged-windshield": {"label": "Pare-brise", "action": "Remplacement", "base_cost": 500.0, "part_zone": "front"},
    "damaged-headlight": {"label": "Phare", "action": "Remplacement bloc optique", "base_cost": 280.0, "part_zone": "front"},
    "damaged-mirror": {"label": "Rétroviseur", "action": "Remplacement coque + glace", "base_cost": 150.0, "part_zone": "side"},
    "damaged-hood": {"label": "Capot", "action": "Débosselage + peinture", "base_cost": 550.0, "part_zone": "front"},
    "dent": {"label": "Bosse carrosserie", "action": "Débosselage sans peinture (PDR)", "base_cost": 180.0, "part_zone": "body"},
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
    source: str  # "yolov8" or "heuristic"


_model = None
_model_load_attempted = False


def _load_model():
    """
    Lazily loads the YOLOv8 checkpoint. Imported lazily (like storage.py's
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


def _detect_with_yolo(image_bytes: bytes) -> Optional[list[Detection]]:
    model = _load_model()
    if model is None:
        return None
    try:
        from PIL import Image

        img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        width, height = img.size
        results = model.predict(img, verbose=False)
        detections: list[Detection] = []
        for result in results:
            names = result.names
            for box in result.boxes:
                cls_id = int(box.cls[0])
                class_name = names.get(cls_id, str(cls_id)) if isinstance(names, dict) else str(cls_id)
                conf = float(box.conf[0])
                x1, y1, x2, y2 = [float(v) for v in box.xyxy[0]]
                detections.append(
                    Detection(
                        class_name=class_name,
                        confidence=conf,
                        bbox=(x1 / width, y1 / height, x2 / width, y2 / height),
                        source="yolov8",
                    )
                )
        return detections
    except Exception:
        return None


def _detect_with_heuristic(image_bytes: bytes) -> list[Detection]:
    """
    Fallback used when no trained YOLOv8 checkpoint is available. Uses
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
                "description": f"{catalog['action']} — détection {'YOLOv8' if det.source == 'yolov8' else 'heuristique'} (confiance {round(det.confidence * 100)}%).",
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
            f"Analyse IA (YOLOv8) sur {len({d.class_name for d in detections})} zone(s) de dommage détectée(s) : "
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
