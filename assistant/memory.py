"""
Cross-session "lessons learned" log — the auto-increment learning mechanism.

This does NOT fine-tune or retrain anything. Nothing in this file touches
model weights. What it does: every time the conversational agent gets
corrected by a client, it calls the `log_correction` tool, which appends a
short (what_was_wrong, correct_version) pair here. On the next conversation
(possibly with a different client), a handful of recent lessons are loaded
and folded into the system prompt as short "watch out for this category of
mistake" notes — see prompts.build_system_prompt().

Explicitly NOT included: anything about a specific client's accident. Only
the *pattern* of the mistake is logged, per the system prompt's own
instructions to the model — this file only stores what's handed to it, so
that instruction is where the actual privacy boundary is enforced. Kept as
JSONL so it's trivial to inspect, truncate, or swap for a real datastore
later.
"""
import json
from pathlib import Path

LESSONS_PATH = Path(__file__).resolve().parent / "memory_store" / "lessons.jsonl"

# Hard cap so this can't grow unbounded / start dominating the prompt.
MAX_STORED_LESSONS = 200


def log_correction(what_was_wrong: str, correct_version: str) -> None:
    if not what_was_wrong or not correct_version:
        return
    LESSONS_PATH.parent.mkdir(parents=True, exist_ok=True)
    entry = {"what_was_wrong": what_was_wrong.strip(), "correct_version": correct_version.strip()}

    lessons = _read_all()
    lessons.append(entry)
    lessons = lessons[-MAX_STORED_LESSONS:]
    with open(LESSONS_PATH, "w", encoding="utf-8") as f:
        for l in lessons:
            f.write(json.dumps(l, ensure_ascii=False) + "\n")


def _read_all() -> list[dict]:
    if not LESSONS_PATH.exists():
        return []
    lessons = []
    for line in LESSONS_PATH.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            lessons.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return lessons


def load_recent_lessons(limit: int = 8) -> list[dict]:
    """Most recent `limit` lessons, oldest of that batch first (reads naturally top-to-bottom)."""
    return _read_all()[-limit:]
