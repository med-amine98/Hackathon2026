"""
DEPRECATED — superseded by platform/backend/app/fault_engine.py.

This file is an orphaned early copy of the fault-determination engine, kept
here (rather than deleted) only because this environment can't remove
already-written files from the mounted workspace. Nothing in the codebase
imports this module — assistant/accident_analysis.py and
platform/backend/app/routers/fault.py both import the real one directly.

To avoid two copies of the actual rule table drifting apart, this now just
re-exports the canonical implementation instead of duplicating it. If you
have a local checkout where this file is safe to delete outright, do that
instead of relying on this shim — see platform/backend/app/fault_engine.py
for the real thing (rule table, docstring caveats about the placeholder
percentages, etc.).
"""
import sys
from pathlib import Path

_PLATFORM_BACKEND_DIR = Path(__file__).resolve().parent / "platform" / "backend"
if str(_PLATFORM_BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(_PLATFORM_BACKEND_DIR))

from app.fault_engine import (  # noqa: E402,F401
    Circumstance,
    FaultResult,
    ImpactZone,
    VehicleDeclaration,
    determine_fault,
)
