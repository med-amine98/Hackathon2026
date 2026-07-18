"""
Conversation Memory — in-memory short-term context store per conversation.

This module provides a lightweight in-process cache for conversation context.
For production deployments, replace this with a Redis-backed store using the
REDIS_URL setting from app.core.config.
"""
from typing import Dict, Any, Optional


class ConversationMemory:
    """
    In-memory store for conversation context (slot-filling state, etc.).

    Each conversation_id maps to a free-form dict that can hold:
    - current intent
    - extracted entities so far
    - which slot we are currently filling
    - any other ephemeral state needed during a conversation turn
    """

    def __init__(self):
        self._store: Dict[int, Dict[str, Any]] = {}

    # ── Read ──────────────────────────────────────────────────────────────────

    def get_context(self, conversation_id: int) -> Dict[str, Any]:
        """Return the full context dict for a conversation (empty dict if new)."""
        return self._store.get(conversation_id, {})

    def get_value(self, conversation_id: int, key: str, default: Any = None) -> Any:
        """Return a single value from the conversation context."""
        return self._store.get(conversation_id, {}).get(key, default)

    # ── Write ─────────────────────────────────────────────────────────────────

    def update_context(self, conversation_id: int, key: str, value: Any) -> None:
        """Set a key-value pair in the conversation context."""
        if conversation_id not in self._store:
            self._store[conversation_id] = {}
        self._store[conversation_id][key] = value

    def merge_context(self, conversation_id: int, data: Dict[str, Any]) -> None:
        """Merge a dict of values into the conversation context."""
        if conversation_id not in self._store:
            self._store[conversation_id] = {}
        self._store[conversation_id].update(data)

    # ── Delete ────────────────────────────────────────────────────────────────

    def clear_context(self, conversation_id: int) -> None:
        """Remove all context for a given conversation."""
        self._store.pop(conversation_id, None)

    def remove_key(self, conversation_id: int, key: str) -> None:
        """Remove a single key from the conversation context."""
        if conversation_id in self._store:
            self._store[conversation_id].pop(key, None)

    # ── Utility ───────────────────────────────────────────────────────────────

    def active_conversations(self) -> int:
        """Return the number of conversations currently in memory."""
        return len(self._store)


# Module-level singleton — import this in other modules
memory_store = ConversationMemory()
