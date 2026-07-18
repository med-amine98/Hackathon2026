"""
Central place for environment-driven config. Kept dependency-free (plain
os.getenv) rather than pydantic-settings, so the module has zero import-time
surprises in local dev vs. docker.
"""
import os

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./local_dev.db")
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

MINIO_ENDPOINT = os.getenv("MINIO_ENDPOINT", "localhost:9001")
MINIO_ROOT_USER = os.getenv("MINIO_ROOT_USER", "minioadmin")
MINIO_ROOT_PASSWORD = os.getenv("MINIO_ROOT_PASSWORD", "minioadmin")
MINIO_BUCKET = os.getenv("MINIO_BUCKET", "constat-photos")
MINIO_SECURE = os.getenv("MINIO_SECURE", "false").lower() == "true"

# Perceptual-hash Hamming-distance threshold below which two photos are
# treated as "the same image" (duplicate/reuse fraud signal). 8 is a
# reasonably strict default for 64-bit average-hash; tune once you have
# real claim volume to check false-positive rate against.
PHASH_DUPLICATE_THRESHOLD = int(os.getenv("PHASH_DUPLICATE_THRESHOLD", "8"))

# IDA convention cap (see ARCHITECTURE.md) — claims above this need manual
# routing since the automated direct-indemnification flow no longer applies.
IDA_DAMAGE_CAP_TND = float(os.getenv("IDA_DAMAGE_CAP_TND", "2000"))

# Agent chat (app/routers/chat.py) — any OpenAI-compatible chat completions
# endpoint. Defaults to Gemini. Left blank, /chat/message still works but
# replies with a "not configured" message instead of calling out to an LLM.
LLM_API_KEY = os.getenv("LLM_API_KEY")
LLM_BASE_URL = os.getenv("LLM_BASE_URL", "https://generativelanguage.googleapis.com/v1beta/openai/")
LLM_MODEL = os.getenv("LLM_MODEL", "gemini-2.5-flash")
