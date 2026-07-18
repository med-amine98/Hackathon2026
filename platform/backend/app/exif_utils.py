"""
Extract EXIF timestamp/GPS and compute a perceptual hash for uploaded
photos. Both are anti-fraud signals: a photo with no EXIF metadata at all
is suspicious for an app that's supposed to capture via the in-app camera
(screenshots and re-saved/edited images often strip EXIF); a photo whose
perceptual hash matches one already in the database is a reused-image flag.
"""
import io
from datetime import datetime
from typing import Optional

from PIL import ExifTags, Image

# imagehash pulls in numpy/scipy/PyWavelets — import lazily so the core API
# (claims/vehicles/fault) can run and be tested without that dependency
# chain installed; only photo upload actually needs it.

_GPS_TAG_ID = next((k for k, v in ExifTags.TAGS.items() if v == "GPSInfo"), None)
_DATETIME_TAG_ID = next((k for k, v in ExifTags.TAGS.items() if v == "DateTimeOriginal"), None)


def _dms_to_decimal(dms, ref) -> float:
    degrees, minutes, seconds = [float(x) for x in dms]
    decimal = degrees + minutes / 60.0 + seconds / 3600.0
    if ref in ("S", "W"):
        decimal = -decimal
    return decimal


def extract_datetime_and_gps(image_bytes: bytes) -> dict:
    """
    Returns {"has_metadata": bool, "datetime": datetime|None, "lat": float|None, "lng": float|None}
    Never raises — a corrupt/missing EXIF block is itself just a fraud signal, not an error.
    """
    result = {"has_metadata": False, "datetime": None, "lat": None, "lng": None}
    try:
        image = Image.open(io.BytesIO(image_bytes))
        exif = image.getexif()
        if not exif:
            return result

        if _DATETIME_TAG_ID and _DATETIME_TAG_ID in exif:
            try:
                result["datetime"] = datetime.strptime(exif[_DATETIME_TAG_ID], "%Y:%m:%d %H:%M:%S")
            except ValueError:
                pass

        if _GPS_TAG_ID and _GPS_TAG_ID in exif:
            gps_info = exif.get_ifd(_GPS_TAG_ID)
            lat_dms = gps_info.get(2)
            lat_ref = gps_info.get(1)
            lng_dms = gps_info.get(4)
            lng_ref = gps_info.get(3)
            if lat_dms and lng_dms and lat_ref and lng_ref:
                result["lat"] = _dms_to_decimal(lat_dms, lat_ref)
                result["lng"] = _dms_to_decimal(lng_dms, lng_ref)

        result["has_metadata"] = bool(result["datetime"] or result["lat"])
    except Exception:
        pass
    return result


def compute_phash(image_bytes: bytes) -> Optional[str]:
    import imagehash
    try:
        image = Image.open(io.BytesIO(image_bytes))
        return str(imagehash.phash(image))
    except Exception:
        return None


def hamming_distance(hash_a: str, hash_b: str) -> int:
    import imagehash
    return imagehash.hex_to_hash(hash_a) - imagehash.hex_to_hash(hash_b)
