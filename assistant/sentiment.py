"""
Lightweight, deterministic backstop for injury/distress detection.

The primary sentiment signal is the `note_mood` tool the LLM calls each turn
(see prompts.py) — it understands context, sarcasm, and code-switched
Derja/French far better than any keyword list could. But an escalation flag
that decides whether a human reviews the conversation shouldn't rely
*solely* on the model remembering to call a tool every time. This module is
a crude, deliberately over-inclusive keyword check across French, English,
and common Tunisian Arabic (Derja) renderings — both Arabic script and
Arabizi — that runs on every raw client message regardless of what the model
does. False positives (flagging a conversation that didn't need it) are
cheap; false negatives on a real injury are not.
"""
import re

# Deliberately broad — stems and common variants, not exact-word matches.
_INJURY_PATTERNS = [
    # French
    r"\bbless", r"\bmal\b", r"\bsang\b", r"\bh[oô]pital", r"\bambulance\b",
    r"\bdouleur", r"\bfractur", r"\bévanoui", r"\bevanoui", r"\binconscien",
    # English
    r"\binjur", r"\bhurt", r"\bbleed", r"\bhospital\b", r"\bambulance\b",
    r"\bpain\b", r"\bunconscious\b", r"\bbroke\w*\b.*\b(arm|leg|bone|rib)",
    # Tunisian Arabic — Arabic script (common accident-distress words)
    r"مصاب", r"جرح", r"دم", r"مستشفى", r"إسعاف", r"اسعاف", r"وجع", r"موجوع",
    # Tunisian Arabic — Arabizi (Latin transliteration)
    r"\bwaja\w*", r"\bmwaja3", r"\bmajrou7", r"\bd[ae]m\b", r"\bisaaf\b",
    r"\bel\s*isaaf\b", r"\bsbitar\b",  # sbitar = hospital (Derja)
]
_INJURY_RE = re.compile("|".join(_INJURY_PATTERNS), re.IGNORECASE)

_DISTRESS_PATTERNS = [
    r"\bpeur\b", r"\bpanique", r"\bau secours\b", r"\baidez[- ]moi\b",
    r"\bscared\b", r"\bafraid\b", r"\bpanic", r"\bhelp me\b",
    r"خايف", r"خفت", r"عاونوني",
    r"\b5[ao]yef\b", r"\b5[ao]uf\b", r"\b5ift\b", r"\baw[ée]ni\b",
]
_DISTRESS_RE = re.compile("|".join(_DISTRESS_PATTERNS), re.IGNORECASE)


def scan_message(text: str) -> dict:
    """Returns {"injury_keyword_hit": bool, "distress_keyword_hit": bool} — a heuristic, not a verdict."""
    if not text:
        return {"injury_keyword_hit": False, "distress_keyword_hit": False}
    return {
        "injury_keyword_hit": bool(_INJURY_RE.search(text)),
        "distress_keyword_hit": bool(_DISTRESS_RE.search(text)),
    }
