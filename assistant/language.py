"""
Tiny script/word heuristic for tagging which language a piece of text is in
— used to tag stored messages and client profiles, not a real language
detector. Tunisian Derja in Arabic script is indistinguishable from
Standard Arabic by this heuristic (that's fine here: it's a storage tag,
not something the conversation logic depends on — the system prompt is
what actually handles Derja).

Also tags Arabizi (Derja written in Latin letters, e.g. "3andi accident,
khbatouni men lwara") as "ar" rather than letting it fall through to "en" —
it's still Derja, just a different script, and untagging it as English
would be a wrong label on exactly the messages this app cares most about
getting right. Detected two ways: a digit from Arabizi's standard
letter-substitution set (2/3/5/7/8/9) sitting inside a word (something
ordinary French/English text essentially never does), or a short list of
very common Derja words/roots that carry no such digit at all
("chnowa", "barcha", "wallah", ...).
"""
import re

_ARABIC_RE = re.compile(r"[؀-ۿ]")

_FRENCH_HINTS_RE = re.compile(
    r"[éèàçùâêîôûœ]|\b(vous|le|la|les|est|une?|c'est|bonjour|merci|voiture)\b",
    re.IGNORECASE,
)

# A digit from Arabizi's letter-substitution set glued onto letters within
# the same word ("3andi", "5dhit", "n7eb") — ordinary French/English words
# essentially never mix digits into letters like this.
_ARABIZI_DIGIT_RE = re.compile(r"\b[a-zA-Z]+[23578][a-zA-Z]*\b|\b[23578][a-zA-Z]+\b")

# Common Derja words/roots with no digit at all, so an Arabizi message that
# happens not to use any substitution digit still gets caught.
_ARABIZI_WORD_HINTS_RE = re.compile(
    r"\b(chnowa|kifech|barcha|chwaya|sahit|wallah|yezzi|behi|hedhi|hedha|"
    r"win|fama|famma|mte3i|mte3ek|mte3na|taw|ghodwa|lyoum|khbat|khabat|"
    r"karhba|kerhba|mochkil|ba3d|3lech|9addech)\b",
    re.IGNORECASE,
)


def detect(text: str) -> str:
    """Returns 'ar', 'fr', or 'en' — best guess only."""
    if not text:
        return "fr"
    if _ARABIC_RE.search(text):
        return "ar"
    if _ARABIZI_DIGIT_RE.search(text) or _ARABIZI_WORD_HINTS_RE.search(text):
        return "ar"
    if _FRENCH_HINTS_RE.search(text):
        return "fr"
    return "en"
