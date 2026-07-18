# Insurance AI Assistant

Assistant IA pour l'assurance automobile, ciblant le marché tunisien.

## Vue d'ensemble

Le dépôt regroupe cinq sous-projets qui partagent une seule base Postgres :

| Service | Dossier | Rôle | Port (via Docker Compose) |
|---|---|---|---|
| `api` + `worker` | [platform/backend](platform/backend) + [assistant](assistant) | « L'agent » : sinistres, moteur de détermination de tort, chat d'accueil d'accident (`POST /chat/message`) | `8010` (agent), `9002`/`9003` (MinIO) |
| `mobile-api` | [backend](backend) | Backend propre à l'app mobile (auth, profil, produits, chat de souscription) | `8001` |
| `assurex-api` | [assurex/backend](assurex/backend) | Portail agence AssureX (sinistres, utilisateurs) | `8002` |
| `assurex-frontend` | [assurex/frontend](assurex/frontend) | Interface web (React + Vite) du portail AssureX | `5173` |
| App mobile | [frontend/flutter_app](frontend/flutter_app) | Application Flutter, avec une bulle de chat flottante (`AgentChatBubble`) branchée sur `POST /chat/message` ; le PDF de constat généré s'affiche directement dans la conversation (`constat_pdf_url`) | — (hors Docker Compose, lancée séparément) |

**Une seule base de données.** Tout tourne sur une seule instance Postgres (service `db` du [docker-compose.yml](docker-compose.yml) à la racine) : les tables de l'agent vivent dans le schéma `public`, celles du backend mobile dans le schéma `mobile`, celles d'AssureX dans le schéma `assurex` — une seule source de vérité, jamais de duplication entre les trois backends.

## Prérequis

- Docker + Docker Compose (chemin recommandé, voir plus bas) — sinon, pour lancer chaque service à la main :
  - Python 3.11+
  - Node.js 20+ (pour `assurex/frontend`)
  - Flutter SDK (canal stable, Dart ≥ 3.0) pour `frontend/flutter_app`
  - PostgreSQL 16 si vous ne passez pas par le conteneur `db`
- Une clé API pour le chat de l'agent (Gemini, gratuite — voir la section variables d'environnement)

## Installation

```bash
git clone <url-du-dépôt>
cd Hackathon2026
```

Un fichier `.env` est déjà présent à la racine et alimente tout le stack Docker (Postgres, Redis, MinIO, chat de l'agent, backend mobile, AssureX) — c'est le seul fichier de configuration nécessaire pour l'option Docker Compose ci-dessous. Avant de lancer, relisez-le et ajustez au moins : `POSTGRES_PASSWORD`, `MINIO_ROOT_PASSWORD`, `LLM_API_KEY` (chat de l'agent), et ajoutez `MOBILE_SECRET_KEY`/`ASSUREX_SECRET_KEY` si vous comptez déployer au-delà de votre poste (voir la liste complète des variables plus bas).

## Lancement

### Option A — Docker Compose (recommandé, tout le stack)

```bash
cd Hackathon2026
docker compose up --build
```

Ceci démarre Postgres, Redis, MinIO, l'API de l'agent (`api`), le worker Celery (`worker`), le backend mobile (`mobile-api`), l'API AssureX (`assurex-api`) et le frontend AssureX (`assurex-frontend`).

Une fois lancé :

| Service | URL |
|---|---|
| API agent (sinistres, tort, chat) | http://localhost:8010 — docs interactives sur `/docs` |
| API backend mobile | http://localhost:8001 — docs sur `/docs` |
| API AssureX | http://localhost:8002 |
| Frontend AssureX | http://localhost:5173 |
| Console MinIO | http://localhost:9003 (API S3 sur `9002`) |
| Postgres | `localhost:5438` |

L'app Flutter n'est pas incluse dans `docker compose` (c'est une app mobile) : lancez-la séparément, voir plus bas. Elle se connecte aux services ci-dessus via `AGENT_API_URL` et `BACKEND_URL` dans son propre `.env`.

Pour arrêter et repartir de zéro (attention, efface les données Postgres/MinIO) :

```bash
docker compose down -v
```

### Option B — Lancer chaque service en local (sans Docker)

Chaque sous-projet peut tourner seul, avec une base SQLite locale par défaut si vous ne voulez pas installer Postgres. Créez un fichier `.env` dans le dossier du service concerné avec les variables listées dans la section « Variables d'environnement » ci-dessous (aucune valeur n'est requise pour démarrer en SQLite, hors clés d'API tierces).

**Agent (`platform/backend`, expose le chat et le moteur de tort) :**

```bash
cd platform/backend
python -m venv .venv && source .venv/bin/activate   # Windows : .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

**Backend mobile (`backend`) :**

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

Migrations de base de données (Alembic) :

```bash
alembic revision --autogenerate -m "description"
alembic upgrade head
```

**API AssureX (`assurex/backend`) :**

```bash
cd assurex/backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

**Frontend AssureX (`assurex/frontend`) :**

```bash
cd assurex/frontend
npm install
npm run dev
```

**App mobile Flutter (`frontend/flutter_app`) :**

Un `.env` existe déjà dans ce dossier (`BACKEND_URL`, `AGENT_API_URL`, clés météo/trafic) — ajustez-le si besoin, puis :

```bash
cd frontend/flutter_app
flutter pub get
flutter run
```

### Vérifier que ça tourne

```bash
curl localhost:8010/docs      # API agent
curl localhost:8001/docs      # API backend mobile
curl localhost:8002/docs      # API AssureX
```

## Variables d'environnement

### `.env` à la racine (stack Docker Compose complet)

Reflète ce qui est réellement dans le `.env` du repo (pas un modèle) : les blocs ci-dessous couvrent les variables consommées par `docker-compose.yml`. Le fichier contient aussi quelques clés propres à l'app Flutter (`API_URL`, `DEBUG`, `OPENWEATHER_URL`, `TOMTOM_BASE_URL`, `BACKEND_URL`) laissées là par commodité — Docker Compose ne les lit pas, elles ne servent que si vous copiez ce `.env` tel quel pour `frontend/flutter_app`.

**Postgres partagé (service `db`)**

| Variable | Description |
|---|---|
| `POSTGRES_USER` | Utilisateur Postgres |
| `POSTGRES_PASSWORD` | Mot de passe Postgres — à changer |
| `POSTGRES_DB` | Nom de la base |
| `DATABASE_URL` | URL utilisée par `api`/`worker` (agent), schéma `public` par défaut |

**Redis / MinIO**

| Variable | Description |
|---|---|
| `REDIS_URL` | File de tâches Celery |
| `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` | Identifiants MinIO |
| `MINIO_ENDPOINT` | Endpoint interne au réseau Docker (`minio:9000`) |
| `MINIO_BUCKET` | Bucket des photos de sinistre |
| `MINIO_SECURE` | `true`/`false` selon TLS |

**Chat de l'agent (`api`, wrap `assistant/`)**

| Variable | Description | Défaut |
|---|---|---|
| `LLM_API_KEY` | Clé de l'API compatible OpenAI. Laisser vide fait répondre le chat avec un message « non configuré » sans planter | — |
| `LLM_BASE_URL` | Endpoint compatible OpenAI | `https://generativelanguage.googleapis.com/v1beta/openai/` (Gemini) |
| `LLM_MODEL` | Modèle utilisé | `gemini-3.5-flash` |

Clé Gemini gratuite (sans carte bancaire) : créez-la sur [aistudio.google.com/apikey](https://aistudio.google.com/apikey).

**Détection de dommages (`api`/`worker`)**

| Variable | Description |
|---|---|
| `CAR_DAMAGE_MODEL_PATH` | Chemin du checkpoint YOLO11/CarDD **à l'intérieur du conteneur**. Déposez le fichier `.pt` sur l'hôte dans `platform/backend/app/weights/car_damage_yolo11.pt` — le bind mount le rend visible automatiquement, rien d'autre à faire |

**Backend mobile (`mobile-api`)**

| Variable | Description | Défaut |
|---|---|---|
| `MOBILE_SECRET_KEY` | Clé JWT — à changer en production | — |
| `OPENAI_API_KEY` | Optionnelle | — |
| `OPENWEATHER_API_KEY` | Optionnelle, sinon repli sur des données météo statiques | — |
| `TOMTOM_API_KEY` | Optionnelle, sinon repli sur des données trafic statiques | — |

Le service partage la même base Postgres que l'agent, isolée dans le schéma `mobile` (`backend/app/database/connection.py`).

**AssureX (`assurex-api`)**

| Variable | Description |
|---|---|
| `ASSUREX_SECRET_KEY` | Clé JWT — à changer en production |

Isolée dans son propre schéma `assurex` de la même base Postgres partagée.

### `.env` par service (uniquement si vous lancez hors Docker, Option B)

**`platform/backend/.env`** — mêmes variables Postgres/Redis/MinIO/LLM que ci-dessus, en pointant vers `localhost` plutôt que les noms de services Docker.

**`backend/.env`**

| Variable | Description | Défaut |
|---|---|---|
| `DATABASE_URL` | URL de connexion | `sqlite:///./insurance.db` |
| `SECRET_KEY` | Clé JWT (min. 32 caractères) | — |
| `ALGORITHM` | Algorithme JWT | `HS256` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Durée de validité du token | `30` |
| `OPENAI_API_KEY` | Optionnelle | — |
| `REDIS_URL` | Cache | `redis://localhost:6379` |
| `DEBUG` | Mode debug | `False` |

**`assurex/backend/.env`**

| Variable | Description | Défaut |
|---|---|---|
| `DATABASE_URL` | Repli sur SQLite local si absent | `sqlite:///./assurex.db` |
| `DB_SCHEMA` | Schéma isolé si vous pointez vers le Postgres partagé | `assurex` |
| `SECRET_KEY` | Clé JWT — générez-en une avec `openssl rand -hex 32` en prod | — |

**`assurex/frontend/.env`**

| Variable | Description | Défaut |
|---|---|---|
| `VITE_API_BASE` | URL de l'API AssureX | `http://localhost:8002/api` |
| `VITE_PLATFORM_API_BASE` | URL de l'API agent, utilisée par la page « Damage Scanner » | `http://localhost:8010` |

**`frontend/flutter_app/.env`**

| Variable | Description | Défaut |
|---|---|---|
| `BACKEND_URL` | Backend mobile | `http://localhost:8001/api/v1` |
| `AGENT_API_URL` | API de l'agent, utilisée par la bulle de chat flottante | `http://localhost:8010` |
| `OPENAI_API_KEY` | — | — |
| `OPENWEATHER_API_KEY` / `OPENWEATHER_URL` | — | — |
| `TOMTOM_API_KEY` / `TOMTOM_BASE_URL` | — | — |

## Endpoints principaux

**Agent (`platform/backend`, port `8010` en Docker)**

| Méthode | Route | Description |
|---|---|---|
| POST | `/claims` | Créer un sinistre |
| POST | `/claims/{id}/vehicles` | Déclarer les circonstances d'un véhicule |
| POST | `/claims/{id}/determine-fault` | Lancer le moteur de détermination de tort |
| POST | `/claims/{id}/photos` | Uploader une photo du sinistre |
| POST | `/chat/message` | Envoyer un message au chat d'accueil d'accident |

**Backend mobile (port `8001`)**

| Méthode | Route | Description |
|---|---|---|
| POST | `/api/v1/auth/register` | Inscription |
| POST | `/api/v1/auth/token` | Connexion (JWT) |
| GET | `/api/v1/auth/me` | Profil utilisateur courant |
| POST | `/api/v1/chat/message` | Chat de souscription |
| GET | `/api/v1/profile` | Profil d'assurance |
| PUT | `/api/v1/profile` | Mettre à jour le profil |
| GET | `/api/v1/products` | Lister les produits |
| GET | `/api/v1/products/{id}` | Détail d'un produit |
| GET | `/api/v1/recommendations` | Recommandations |
| POST | `/api/v1/recommendations/{id}/accept` | Accepter une recommandation |

Documentation interactive (Swagger) disponible sur `/docs` pour chaque API.

## Documentation complémentaire

- [platform/README.md](platform/README.md) — détail de l'agent (moteur de tort, stockage photos, worker asynchrone)
- [backend/README.md](backend/README.md) — détail du backend mobile
