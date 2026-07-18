# ============================================
# ANALYSE COMPLÈTE - DÉTECTION DE TOUS LES DOMMAGES
# ============================================
#
# Modele : YOLO11n (ultralytics), taxonomie CarDD (6 classes)
# Reference dataset : Wang et al., "CarDD: A New Dataset for Vision-based
# Car Damage Detection", IEEE T-ITS 2023 - https://cardd-ustc.github.io/
# Classes CarDD : dent, scratch, crack, glass_shatter, lamp_broken, tire_flat
#
# Ce script (execute sur Google Colab) charge le checkpoint entraine
# (best.pt) et teste plusieurs configurations de seuil confiance/IoU pour
# trouver celle qui detecte le plus de dommages reels sur une photo donnee.
# Le meme algorithme de balayage multi-configurations est repris cote
# backend dans platform/backend/app/damage_detection.py
# (_detect_with_yolo / _DETECTION_CONFIGS) pour l'inference en production.

import os
import cv2
import numpy as np
import matplotlib.pyplot as plt
from ultralytics import YOLO
from google.colab import files
from PIL import Image
import io
import json

# 1. CHARGER LE MODÈLE
print("="*60)
print("CHARGEMENT DU MODÈLE")
print("="*60)

model_path = "/content/runs/detect/damage_detection/yolo11n/weights/best.pt"

if os.path.exists(model_path):
    model = YOLO(model_path)
    print(f"Modèle chargé!")
    print(f"Classes: {model.names}")
else:
    print("Modèle non trouvé!")
    model = YOLO("yolo11n.pt")

# 2. TÉLÉCHARGER L'IMAGE
print("\n" + "="*60)
print("TÉLÉCHARGEZ VOTRE IMAGE")
print("="*60)

uploaded = files.upload()

if not uploaded:
    print("Aucune image téléchargée!")
    exit()

filename = list(uploaded.keys())[0]
print(f"\nImage chargée: {filename}")

# 3. ANALYSE COMPLÈTE
print("\n" + "="*60)
print("ANALYSE COMPLÈTE DES DOMMAGES")
print("="*60)

# Lire l'image
image = cv2.imread(filename)
image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
h, w = image.shape[:2]

print(f"Taille: {w}x{h} pixels")

# ------------------------------------------------------------
# TEST AVEC DIFFÉRENTES CONFIGURATIONS
# ------------------------------------------------------------

configs = [
    {"conf": 0.1, "iou": 0.5, "name": "Seuil bas (plus de détections)"},
    {"conf": 0.15, "iou": 0.45, "name": "Seuil moyen"},
    {"conf": 0.2, "iou": 0.4, "name": "Seuil standard"},
    {"conf": 0.05, "iou": 0.3, "name": "Seuil très bas (max de détections)"},
]

best_results = None
best_num = 0
best_config = None
all_detections = []

for config in configs:
    print(f"\n--- {config['name']} ---")
    results = model(filename, conf=config['conf'], iou=config['iou'])

    for result in results:
        num = len(result.boxes) if result.boxes else 0
        print(f"  {num} détection(s)")

        if result.boxes and len(result.boxes) > 0:
            for box in result.boxes:
                conf = box.conf[0].item()
                cls = int(box.cls[0].item())
                label = model.names[cls]
                bbox = box.xyxy[0].tolist()
                print(f"    - {label}: {conf:.1%}")
                all_detections.append({
                    "class": label,
                    "confidence": conf,
                    "bbox": bbox,
                    "config": config['name']
                })

            if num > best_num:
                best_num = num
                best_results = result
                best_config = config['name']

# ------------------------------------------------------------
# AFFICHER LES RÉSULTATS FINAUX
# ------------------------------------------------------------

print("\n" + "="*60)
print("RÉSULTATS FINAUX")
print("="*60)

if best_results and best_num > 0:
    print(f"\n{best_num} dommages détectés (avec {best_config})")

    # Afficher l'image annotée
    annotated_img = best_results.plot()
    annotated_img_rgb = cv2.cvtColor(annotated_img, cv2.COLOR_BGR2RGB)

    plt.figure(figsize=(15, 10))
    plt.imshow(annotated_img_rgb)
    plt.axis('off')

    # Ajouter un titre avec la liste des détections
    title = f"{best_num} dommages détectés"
    detections_list = []
    for box in best_results.boxes:
        cls = int(box.cls[0].item())
        label = model.names[cls]
        conf = box.conf[0].item()
        detections_list.append(f"{label} ({conf:.1%})")

    if detections_list:
        title += "\n" + " | ".join(detections_list[:5])
        if len(detections_list) > 5:
            title += f" + {len(detections_list)-5} autres"

    plt.title(title, fontsize=12, pad=20)
    plt.tight_layout()
    plt.show()

    # Détails complets
    print("\nDÉTAILS COMPLETS:")

    # Grouper par type
    damage_types = {}
    damage_details = []

    for i, box in enumerate(best_results.boxes, 1):
        conf = box.conf[0].item()
        cls = int(box.cls[0].item())
        label = model.names[cls]
        bbox = box.xyxy[0].tolist()
        area = (bbox[2]-bbox[0]) * (bbox[3]-bbox[1])

        damage_types[label] = damage_types.get(label, 0) + 1

        damage_details.append({
            "num": i,
            "type": label,
            "confidence": f"{conf:.1%}",
            "position": f"x={int(bbox[0])}, y={int(bbox[1])}",
            "size": f"{int(bbox[2]-bbox[0])}×{int(bbox[3]-bbox[1])}px",
            "area": area
        })

    print("\nRésumé par type de dommage:")
    for label, count in damage_types.items():
        emoji = {
            'dent': '',
            'scratch': '',
            'crack': '',
            'glass_shatter': '',
            'lamp_broken': '',
            'tire_flat': ''
        }.get(label, '')
        print(f"  {emoji} {label}: {count}")

    print("\nDétails complets:")
    for detail in damage_details:
        print(f"\n  {detail['num']}. {detail['type'].upper()}")
        print(f"     Confiance: {detail['confidence']}")
        print(f"     Position: {detail['position']}")
        print(f"     Taille: {detail['size']}")

else:
    print("\nAucun dommage détecté avec les paramètres standard")

    # Tentative avec des paramètres très bas
    print("\nTentative avec des paramètres très permissifs...")
    results = model(filename, conf=0.01, iou=0.1)
    for result in results:
        num = len(result.boxes) if result.boxes else 0
        if num > 0:
            print(f"{num} détections potentielles trouvées!")
            annotated_img = result.plot()
            annotated_img_rgb = cv2.cvtColor(annotated_img, cv2.COLOR_BGR2RGB)

            plt.figure(figsize=(15, 10))
            plt.imshow(annotated_img_rgb)
            plt.axis('off')
            plt.title(f"{num} détections potentielles (confiance très basse)")
            plt.tight_layout()
            plt.show()
        else:
            print("Aucune détection même avec les paramètres minimaux")

# ------------------------------------------------------------
# SAUVEGARDE DES RÉSULTATS
# ------------------------------------------------------------

print("\n" + "="*60)
print("SAUVEGARDE DES RÉSULTATS")
print("="*60)

# Sauvegarder l'image annotée
if best_results and best_num > 0:
    output_path = f"annotated_{filename}"
    cv2.imwrite(output_path, annotated_img)
    print(f"Image annotée: {output_path}")
    files.download(output_path)

# Sauvegarder le rapport JSON
report = {
    "image": filename,
    "dimensions": {"width": w, "height": h},
    "total_damages": best_num if best_results else 0,
    "detections": damage_details if 'damage_details' in locals() else [],
    "damage_types": damage_types if 'damage_types' in locals() else {}
}

report_path = "damage_report.json"
with open(report_path, 'w') as f:
    json.dump(report, f, indent=2)
print(f"Rapport: {report_path}")
files.download(report_path)

# ------------------------------------------------------------
# POUR AMÉLIORER LA DÉTECTION
# ------------------------------------------------------------

print("\n" + "="*60)
print("CONSEILS POUR AMÉLIORER LA DÉTECTION")
print("="*60)

print("""
Si certains dommages ne sont pas détectés:

1. QUALITÉ DE L'IMAGE:
   - Assurez-vous que l'image est nette
   - Les dommages doivent être visibles
   - Évitez les ombres trop fortes

2. TYPE DE DOMMAGES:
   - Le modèle détecte: dent, scratch, crack, glass_shatter, lamp_broken, tire_flat
   - Si d'autres types, il faudra les ajouter

3. POSITION:
   - Les dommages doivent être sur la carrosserie
   - Évitez les éléments qui se confondent (réflexions, saletés)

4. POUR AMÉLIORER LE MODÈLE:
   - Entraîner avec plus d'images réelles
   - Ajouter vos propres annotations
   - Augmenter le nombre d'époques
""")

print("\nANALYSE TERMINÉE!")

# ============================================
# FONCTION POUR ANALYSER AVEC PARAMÈTRES PERSONNALISÉS
# ============================================

def analyze_with_custom_params(image_path, conf=0.1, iou=0.4):
    """
    Analyse une image avec des paramètres personnalisés
    """
    results = model(image_path, conf=conf, iou=iou)

    for result in results:
        num = len(result.boxes) if result.boxes else 0

        print(f"\nRésultats (conf={conf}, iou={iou}):")
        print(f"  {num} détection(s)")

        if result.boxes and len(result.boxes) > 0:
            annotated = result.plot()
            annotated_rgb = cv2.cvtColor(annotated, cv2.COLOR_BGR2RGB)

            plt.figure(figsize=(12, 8))
            plt.imshow(annotated_rgb)
            plt.axis('off')
            plt.title(f"{num} dommages détectés (conf={conf})")
            plt.tight_layout()
            plt.show()

            for box in result.boxes:
                cls = int(box.cls[0].item())
                label = model.names[cls]
                conf_val = box.conf[0].item()
                print(f"  - {label}: {conf_val:.1%}")

        return result

# Exemple d'utilisation avec différents paramètres
print("\n" + "="*60)
print("TEST AVEC PARAMÈTRES PERSONNALISÉS")
print("="*60)
print("\nPour tester avec d'autres paramètres:")
print("analyze_with_custom_params('votre_image.jpg', conf=0.05, iou=0.3)")
