"""
One-time seed data for the assurex database - the exact same demo content
that used to live hardcoded in main.py's in-memory `db` dict, now persisted
as real rows instead. Car photo URLs (image_url/thumbnails) are copied over
verbatim and are never generated, replaced, or otherwise touched here.

CLIENTS below is Tunisian demo data (names, cities, +216 phone numbers, CIN/
immatriculation formats, DT pricing, real Tunisian insurers) to match the
rest of this app (constat amiable, Tunisian insurers referenced in
assistant/prompts.py, Derja/French client-facing copy) - this file
previously had generic US demo data (James Wilson, Seattle WA, USD) left
over from the original UI mockup, which didn't fit an app built specifically
for the Tunisian market.

seed_if_empty() is called once at startup (see main.py) and is a no-op if
the claims table already has rows, so it's safe to run on every restart.
"""

from datetime import datetime, timezone

from sqlalchemy.orm import Session

from models import Claim, Client, DashboardStat

# Same default/fallback estimation image previously generated on the fly by
# GET /api/claims/{id} for claims with no AI estimation on file.
DEFAULT_ESTIMATION_IMAGE = (
    "https://lh3.googleusercontent.com/aida-public/AB6AXuCtwTDa2-m5XzOXNu3wiyMdyAAEAIefRMEA2A_p7zy-"
    "JUiFwsc0vzXyGaneZoIDNuWy72Fw2oTrt_XlGyZ3_T5Xf2tGXGzPamitpc0rbg6V8wHNT-EgGi-1W5XWJGw7VUJCbyGKHJ5fw9BHT0QvA_"
    "YFDpF5ImoYx8Sfs3TZtQu3EK2C1OVycPd-t7TAjrhknlesnxaH-_LHpUT3bu2I4q4PX7u1EQQVfyxTzlror8ZDT9OCTlEX-"
    "bECRnt3zc823kS4ddYPOSB-rRhf"
)
DEFAULT_ESTIMATION_INSIGHTS = (
    "No AI processing run for this claim yet. Request photo upload or validate manually."
)

# Same Tunisianization pass as CLIENTS below: vehicle makes/models common on
# Tunisian roads, DT instead of implicit USD, Tunisian agent names, French
# insights text. Car photo URLs (image_url/thumbnails) are the one thing
# left completely untouched, per instruction - never generated, replaced,
# or swapped for different stock photos.
CLAIMS = [
    {
        "id": "CLM-8291",
        "type": "Collision Véhicule",
        "gravity": "Critical",
        "gravity_color": "bg-error",
        "risk": 85,
        "risk_text": "Élevé (85%)",
        "risk_color": "text-error",
        "status": "new",
        "vehicle": "Peugeot 208 - Collision Avant",
        "vehicle_type": "Citadine",
        "agent_initials": "MK",
        "time_left": "Reste 2h",
        "photos_count": 5,
        "ai_estimate": None,
        "ai_progress": None,
        "estimation_status": "Analyse IA terminée",
        "image_url": DEFAULT_ESTIMATION_IMAGE,
        "thumbnails": [
            "https://lh3.googleusercontent.com/aida-public/AB6AXuCJ9ygC8Pr9D1uPtaMXyIM-TgCBqmcJfcsYJIVsvVrIPbcrLjVu9pADd6CZLfje01DtGKheUfR6XDi-uCTjnf1ohU-Y6TLE8N28dRBc5upyDfACzm2LRj1gcgkbxFNNe-iCwwYjM8xjrL8G4wGwT4DIa8EjCKe6OUFvuLTxlZJ4SODxmiu1KngW-kp91EfpbQrkcs8dhBeLf9t7avCiWerveJ4RaXPPS-4fvWBmjpJW-fe6fJhjWgmNupARv4cD-NlgpTWcpeXxYMtm",
            "https://lh3.googleusercontent.com/aida-public/AB6AXuD_F8Vzf6Kv13V-ovmrpzjhh9kcQ0G0vS7JDs6eCi8FtA4j1hitZFKbXKVvt6FNeoIS7zrIMlVnihWC0VRQdNrjuW5p8aiHmxpMonQMyoEjQDXoTolT8tZg-qpv1WIv7j6l6bLq6f-Xc0Pvd9t0A159XdOB2TOQYILr_N9TBFKxKcf08sCq9tPdM5jpg606U6590PQdYTLpCg0JpGFvoTkMis2oKRGUtpHGKeOvhtTKzJ6lawircvNqA78EDT9jSfyDKh9iDYHjD36C",
        ],
        "hotspots": [
            {"id": "hs-1", "top": "45%", "left": "25%", "title": "Pare-chocs avant", "description": "Déformation sévère du pare-chocs. Supports structurels tordus.", "severity": "High", "cost": 1240.00, "confidence": 95},
            {"id": "hs-2", "top": "35%", "left": "45%", "title": "Phare (gauche)", "description": "Bloc optique gauche fracturé. Ampoules et faisceau à remplacer.", "severity": "Critical", "cost": 850.00, "confidence": 100},
        ],
        "subtotal": 2090.00,
        "total": 3090.00,
        "insights": "La télémétrie des capteurs correspond aux dégâts structurels visibles. Défauts potentiels du faisceau électrique identifiés côté avant-gauche, près du bloc optique.",
    },
    {
        "id": "CLM-9901",
        "type": "Dommage Matériel",
        "gravity": "Low",
        "gravity_color": "bg-green-500",
        "risk": 15,
        "risk_text": "Faible (15%)",
        "risk_color": "text-green-600",
        "status": "estimation",
        "vehicle": "Peugeot Partner - Rayure légère",
        "vehicle_type": "Utilitaire",
        "agent_initials": "AS",
        "time_left": "Reste 2 jours",
        "photos_count": 4,
        "ai_estimate": 1240.00,
        "ai_progress": 85,
        "estimation_status": "Analyse IA terminée",
        "image_url": "https://lh3.googleusercontent.com/aida-public/AB6AXuD_F8Vzf6Kv13V-ovmrpzjhh9kcQ0G0vS7JDs6eCi8FtA4j1hitZFKbXKVvt6FNeoIS7zrIMlVnihWC0VRQdNrjuW5p8aiHmxpMonQMyoEjQDXoTolT8tZg-qpv1WIv7j6l6bLq6f-Xc0Pvd9t0A159XdOB2TOQYILr_N9TBFKxKcf08sCq9tPdM5jpg606U6590PQdYTLpCg0JpGFvoTkMis2oKRGUtpHGKeOvhtTKzJ6lawircvNqA78EDT9jSfyDKh9iDYHjD36C",
        "thumbnails": [],
        "hotspots": [
            {"id": "hs-3", "top": "50%", "left": "60%", "title": "Rayure portière", "description": "Abrasion superficielle du vernis, sans déformation.", "severity": "Low", "cost": 1240.00, "confidence": 85},
        ],
        "subtotal": 1240.00,
        "total": 1240.00,
        "insights": "Rayure esthétique uniquement. Aucune déformation structurelle ni désalignement du châssis détecté.",
    },
    {
        "id": "CLM-88219",
        "type": "Dommage Matériel",
        "gravity": "Moderate",
        "gravity_color": "bg-orange-500",
        "risk": 45,
        "risk_text": "Moyen (45%)",
        "risk_color": "text-orange-600",
        "status": "review",
        "vehicle": "Volkswagen Tiguan - Choc léger",
        "vehicle_type": "SUV",
        "agent_initials": "YB",
        "time_left": "Reste 1j",
        "photos_count": 3,
        "ai_estimate": None,
        "ai_progress": None,
        # No AI estimation on file - same fallback content the old
        # in-memory version generated on the fly for this claim.
        "estimation_status": "AI Verification Required",
        "image_url": DEFAULT_ESTIMATION_IMAGE,
        "thumbnails": [],
        "hotspots": [],
        "subtotal": 0.0,
        "total": 0.0,
        "insights": DEFAULT_ESTIMATION_INSIGHTS,
    },
    {
        "id": "CLM-94002",
        "type": "Frais Médicaux",
        "gravity": "Minor",
        "gravity_color": "bg-green-500",
        "risk": 12,
        "risk_text": "Faible (12%)",
        "risk_color": "text-green-600",
        "status": "completed",
        "vehicle": "Sinistre Santé - Consultation externe",
        "vehicle_type": "Assurance Santé",
        "agent_initials": "HN",
        "time_left": "Terminé",
        "photos_count": 2,
        "ai_estimate": None,
        "ai_progress": None,
        "estimation_status": "AI Verification Required",
        "image_url": DEFAULT_ESTIMATION_IMAGE,
        "thumbnails": [],
        "hotspots": [],
        "subtotal": 0.0,
        "total": 0.0,
        "insights": DEFAULT_ESTIMATION_INSIGHTS,
    },
]

def _tn_date(year: int, month: int, day: int) -> datetime:
    return datetime(year, month, day, tzinfo=timezone.utc)


CLIENTS = [
    {
        "id": "c-1",
        "name": "Mohamed Ben Salah",
        "type": "Assurance Auto Tous Risques",
        "score": 62,
        "risk": 85,
        "risk_text": "Critical",
        "risk_color": "text-error",
        "last_contact": "Il y a 2 jours",
        "initials": "MB",
        "email": "mohamed.bensalah@gmail.com",
        "phone": "+216 22 345 678",
        "address": "Avenue Habib Bourguiba, Tunis",
        "joined": "Mars 2021",
        "cin": "07845213",
        "plate_number": "146 TUN 8823",
        "car_category": "Berline",
        "insurance_date": _tn_date(2026, 3, 12),
        "payment_status": "paid",
        "policies": [
            {"name": "Assurance Tous Risques", "number": "POL-9928-MB", "premium": "1 450 DT/an", "status": "Active"},
            {"name": "Assistance Routière", "number": "POL-8812-MB", "premium": "120 DT/an", "status": "Active"},
        ],
        "claims_history": [
            {"id": "#CL-92834", "date": "10/05/2026", "amount": "4 500,00 DT", "status": "Pending", "type": "Collision véhicule"},
            {"id": "#CL-77281", "date": "14/11/2024", "amount": "1 200,00 DT", "status": "Paid", "type": "Bris de glace"},
        ],
        "notes": [
            {"id": 1, "date": "2026-07-16 14:32", "author": "Alex (Agent)", "text": "Appel du client concernant le sinistre collision en cours. Photos de l'accident manquantes à documenter."},
            {"id": 2, "date": "2026-07-10 09:15", "author": "System", "text": "Avis de renouvellement envoyé avec succès à l'adresse email du client."},
        ],
    },
    {
        "id": "c-2",
        "name": "Sarra Chebbi",
        "type": "Assurance Flotte Commerciale",
        "score": 45,
        "risk": 65,
        "risk_text": "High",
        "risk_color": "text-orange-500",
        "last_contact": "Il y a 1 semaine",
        "initials": "SC",
        "email": "sarra.chebbi@chebbi-logistique.tn",
        "phone": "+216 98 765 432",
        "address": "Zone Industrielle, Sfax",
        "joined": "Août 2023",
        "cin": "05612398",
        "plate_number": "212 TUN 4471",
        "car_category": "Utilitaire",
        "insurance_date": _tn_date(2026, 1, 30),
        "payment_status": "unpaid",
        "policies": [
            {"name": "Flotte Responsabilité & Marchandises", "number": "POL-3392-SC", "premium": "18 500 DT/an", "status": "Active"},
        ],
        "claims_history": [
            {"id": "#CL-88219", "date": "02/07/2026", "amount": "9 800,00 DT", "status": "Under AI Review", "type": "Dommages flotte"},
        ],
        "notes": [
            {"id": 1, "date": "2026-07-11 11:20", "author": "Alex (Agent)", "text": "Sarra a demandé une mise à jour sur le sinistre de la flotte. Analyse photo IA en cours de validation."},
        ],
    },
    {
        "id": "c-3",
        "name": "Elyes Trabelsi",
        "type": "Assurance Vie & Santé",
        "score": 94,
        "risk": 12,
        "risk_text": "Low",
        "risk_color": "text-green-500",
        "last_contact": "Hier",
        "initials": "ET",
        "email": "elyes.trabelsi@yahoo.fr",
        "phone": "+216 71 456 789",
        "address": "Rue de Marseille, Sousse",
        "joined": "Janvier 2019",
        "cin": "09123456",
        "plate_number": "178 TUN 2290",
        "car_category": "Citadine",
        "insurance_date": _tn_date(2026, 6, 5),
        "payment_status": "paid",
        "policies": [
            {"name": "Santé Famille Premium", "number": "POL-1192-ET", "premium": "180 DT/mois", "status": "Active"},
            {"name": "Assurance Vie 20 ans", "number": "POL-5528-ET", "premium": "60 DT/mois", "status": "Active"},
        ],
        "claims_history": [],
        "notes": [
            {"id": 1, "date": "2026-07-17 16:45", "author": "Alex (Agent)", "text": "Bilan annuel du portefeuille effectué avec Elyes. Client très satisfait, score de fidélité stable à 94%."},
        ],
    },
]

DASHBOARD_STATS = {
    "active_claims": {"value": "1,284", "change": "+12%", "trending": True},
    "processing_time": {"value": "3.8 days", "change": "Avg. 4.2d", "trending": False},
    "high_risk_alerts": {"value": "24", "change": "Urgent", "trending": True, "urgent": True},
    "churn_risk": {"value": "2.1%", "change": "+0.5%", "trending": True, "negative": True},
}


def seed_if_empty(db: Session) -> None:
    """Insert the demo claims/clients/stats rows if the database is empty.
    Idempotent - safe to call on every startup."""
    if db.query(Claim).first() is None:
        for row in CLAIMS:
            db.add(Claim(**row))

    if db.query(Client).first() is None:
        for row in CLIENTS:
            db.add(Client(**row))

    if db.get(DashboardStat, 1) is None:
        db.add(DashboardStat(id=1, data=DASHBOARD_STATS))

    # Every db.add() above only stages the row in this Session - without an
    # explicit commit, main.py's `finally: _seed_db.close()` right after
    # calling this function rolls the whole pending transaction back and
    # none of it was ever actually written. Every one of these rows was
    # silently discarded on every single startup until now.
    db.commit()

    db.commit()
