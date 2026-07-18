"""
Chat Schemas — Pydantic models for chat requests/responses.
"""
from pydantic import BaseModel
from typing import Optional, List, Dict, Any


# ─── Request Schemas ──────────────────────────────────────────────────────────

class ChatRequest(BaseModel):
    """Schema for sending a chat message."""
    message: str
    conversation_id: Optional[int] = None


# ─── Response Schemas ─────────────────────────────────────────────────────────

class ChatResponse(BaseModel):
    """Schema for the AI assistant's chat response."""
    message: str
    conversation_id: int
    intent: str
    next_step: Optional[str] = None
    recommendations: Optional[List[Dict[str, Any]]] = None
    profile_data: Optional[Dict[str, Any]] = None


class ConversationSummary(BaseModel):
    """Summary of a conversation for listing."""
    id: int
    status: str
    intent: Optional[str] = None
    messages_count: int
    current_step: Optional[str] = None

    class Config:
        from_attributes = True
