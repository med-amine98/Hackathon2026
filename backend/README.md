# AI Insurance Advisor — Backend API

Backend FastAPI de l'assistant IA d'assurance auto, conçu pour le marché tunisien.

## 🏗️ Architecture

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py               # Point d'entrée FastAPI
│   ├── ai/                   # Modules IA (intent, conversation, mémoire)
│   ├── api/                  # Routes HTTP et dépendances
│   │   └── routes/           # auth, chat, profile, products, recommendations
│   ├── core/                 # Config, sécurité, exceptions
│   ├── database/             # Connexion SQLAlchemy
│   ├── models/               # Modèles ORM (tables)
│   ├── schemas/              # Schémas Pydantic (validation requêtes/réponses)
│   └── services/             # Logique métier
├── alembic/                  # Migrations de base de données
├── tests/                    # Tests unitaires et d'intégration
├── .env.example              # Template de configuration
├── .gitignore
├── alembic.ini
├── docker-compose.yml
├── Dockerfile
└── requirements.txt
```

## 🚀 Démarrage rapide

### 1. Prérequis
- Python 3.11+
- pip ou uv

### 2. Installation

```bash
# Cloner le repo
cd backend

# Créer un environnement virtuel
python -m venv .venv
.venv\Scripts\activate  # Windows
# source .venv/bin/activate  # Linux/macOS

# Installer les dépendances
pip install -r requirements.txt

# Configurer les variables d'environnement
copy .env.example .env
# Éditez .env avec vos valeurs (SECRET_KEY, OPENAI_API_KEY, etc.)
```

### 3. Lancer le serveur

```bash
uvicorn app.main:app --reload --port 8000
```

L'API est disponible sur : http://localhost:8000
Documentation interactive : http://localhost:8000/docs

## 🐳 Docker

```bash
# Lancer avec Docker Compose (API + PostgreSQL + Redis)
docker-compose up --build
```

## 🗄️ Migrations de base de données

```bash
# Générer une nouvelle migration
alembic revision --autogenerate -m "description"

# Appliquer les migrations
alembic upgrade head

# Revenir en arrière
alembic downgrade -1
```

## 🧪 Tests

```bash
pip install pytest pytest-asyncio httpx
pytest tests/ -v
```

## 📋 Endpoints API

| Méthode | Route | Description |
|---------|-------|-------------|
| POST | `/api/v1/auth/register` | Inscription |
| POST | `/api/v1/auth/token` | Connexion (JWT) |
| GET | `/api/v1/auth/me` | Profil utilisateur courant |
| POST | `/api/v1/chat/message` | Envoyer un message à l'IA |
| GET | `/api/v1/profile` | Récupérer le profil d'assurance |
| PUT | `/api/v1/profile` | Mettre à jour le profil |
| GET | `/api/v1/products` | Lister les produits |
| GET | `/api/v1/products/{id}` | Détail d'un produit |
| GET | `/api/v1/recommendations` | Mes recommandations |
| POST | `/api/v1/recommendations/{id}/accept` | Accepter une recommandation |

## 🔧 Variables d'environnement

| Variable | Description | Défaut |
|----------|-------------|--------|
| `DATABASE_URL` | URL de connexion à la base | `sqlite:///./insurance.db` |
| `SECRET_KEY` | Clé secrète JWT (min 32 chars) | — |
| `ALGORITHM` | Algorithme JWT | `HS256` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Durée de validité du token | `30` |
| `OPENAI_API_KEY` | Clé API OpenAI (optionnel) | — |
| `REDIS_URL` | URL Redis pour le cache | `redis://localhost:6379` |
| `DEBUG` | Mode debug | `False` |
