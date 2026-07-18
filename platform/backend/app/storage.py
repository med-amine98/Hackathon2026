"""
Thin wrapper around MinIO (S3-compatible) for photo storage. Swappable for
real AWS S3 later by just changing MINIO_ENDPOINT/credentials/secure flag.
"""
from io import BytesIO

from app.config import (
    MINIO_BUCKET,
    MINIO_ENDPOINT,
    MINIO_ROOT_PASSWORD,
    MINIO_ROOT_USER,
    MINIO_SECURE,
)

_client = None


def get_client():
    # Imported lazily so the core API (claims/vehicles/fault) can be run
    # and tested without the minio SDK installed; only photo upload needs it.
    from minio import Minio

    global _client
    if _client is None:
        _client = Minio(
            MINIO_ENDPOINT,
            access_key=MINIO_ROOT_USER,
            secret_key=MINIO_ROOT_PASSWORD,
            secure=MINIO_SECURE,
        )
    return _client


def ensure_bucket() -> None:
    try:
        client = get_client()
        if not client.bucket_exists(MINIO_BUCKET):
            client.make_bucket(MINIO_BUCKET)
    except Exception:
        # If the minio SDK isn't installed (e.g. a lightweight local smoke
        # test of just the claims/fault API) or MinIO isn't reachable (a
        # transient outage at boot), don't crash app startup over it —
        # photo uploads will surface the real error at call time instead.
        pass


def upload_bytes(key: str, data: bytes, content_type: str = "image/jpeg") -> str:
    client = get_client()
    client.put_object(
        MINIO_BUCKET,
        key,
        data=BytesIO(data),
        length=len(data),
        content_type=content_type,
    )
    return key
