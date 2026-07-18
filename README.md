# Insurance AI Assistant

An intelligent automobile insurance assistant targeting the Tunisian market.

## 🏗️ Repository Overview

This repository hosts a multi-tiered AI-driven assistant split into:
- [backend](backend): the mobile app's own FastAPI backend (auth, profile, products, buy-insurance chat).
- [platform/backend](platform/backend) + [assistant](assistant): "the agent" — claims, fault engine, and the
  accident-intake chat (`POST /chat/message`). This is the only way to reach the agent's chat — there is no
  separate Streamlit app anymore.
- [frontend/flutter_app](frontend/flutter_app): Flutter mobile application, including a floating chat
  bubble (`AgentChatBubble`) wired directly to the agent's chat endpoint above, with the generated constat
  PDF surfaced right in the conversation once there's enough data (see `constat_pdf_url` on the chat
  response).

**One database.** Everything runs off a single Postgres instance (the `db` service in the root
[docker-compose.yml](docker-compose.yml)): the agent's tables live in the default `public` schema, the mobile
backend's tables live in their own `mobile` schema in that same database (see
`backend/app/database/connection.py`) — one source of truth, no data duplicated or out of sync between the
two backends. Copy [.env.example](.env.example) to `.env` and run `docker compose up --build` to start
everything (Postgres, Redis, MinIO, the agent's API/worker, and the mobile API).

Refer to the respective subdirectories' documentation for build, setup, and dependency management details.
