"""
Address -> coordinates via OpenStreetMap Nominatim (free, no API key).

Respects Nominatim's usage policy: a custom User-Agent, and no more than
~1 request/second (a naive global throttle here — fine for a single-user
demo, not for concurrent production traffic). Results are cached
in-process (per server, not per conversation) so re-asking about the same
address doesn't re-hit the API or the rate limiter.
"""
import time
from functools import lru_cache
from typing import Optional

import requests

NOMINATIM_URL = "https://nominatim.openstreetmap.org/search"
USER_AGENT = "smart-constat-demo/0.1 (contact: saoussenmannai@gmail.com)"

_last_call_ts = 0.0


def _throttle() -> None:
    global _last_call_ts
    elapsed = time.time() - _last_call_ts
    if elapsed < 1.1:
        time.sleep(1.1 - elapsed)
    _last_call_ts = time.time()


@lru_cache(maxsize=512)
def geocode(address: str, country_bias: str = "tn") -> Optional[dict]:
    """
    Returns {"lat": float, "lng": float, "display_name": str} or None if the
    address couldn't be resolved. Never raises — a failed geocode is a
    normal, expected outcome (typo, vague address, etc.), not a bug.
    """
    if not address or not address.strip():
        return None
    _throttle()
    try:
        resp = requests.get(
            NOMINATIM_URL,
            params={"q": address, "format": "json", "limit": 1, "countrycodes": country_bias},
            headers={"User-Agent": USER_AGENT},
            timeout=10,
        )
        resp.raise_for_status()
        results = resp.json()
        if not results:
            return None
        top = results[0]
        return {
            "lat": float(top["lat"]),
            "lng": float(top["lon"]),
            "display_name": top.get("display_name", address),
        }
    except Exception:
        return None
