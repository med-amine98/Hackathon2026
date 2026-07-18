"""
Smart Constat — the conversational assistant's core logic, deliberately kept
independent of any particular UI.

Nothing in this package depends on any specific frontend. Today the only
consumer is platform/backend/app/routers/chat.py's `POST /chat/message` (in
turn driven by the Flutter app's floating agent chat bubble) — but a CLI or
a different UI could equally well import this same package directly.

Modules:
  - accident_analysis: ties the fault engine, route geocoding, and route/
    circumstance plausibility checks together into one analyze() call.
  - constat_pdf: fills the real constat.pdf scan with collected data.
  - db: persistence (Postgres/SQLite) for conversations, messages, client
    profiles, claims, and generated constats — reuses the platform backend's
    own SQLAlchemy models rather than a second schema.
  - geocoding / geometry: address -> coordinates -> bearing/direction math.
  - language: crude script/word heuristic for tagging message language.
  - memory: cross-conversation "lessons learned" log (prompt-level, not
    model retraining).
  - prompts: the system prompt and tool schemas the LLM tool-use loop runs on.
  - sentiment: deterministic injury/distress keyword backstop.
"""
