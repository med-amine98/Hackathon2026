"""
Agent chat — the REST front door for the assistant/ package's accident-
intake conversation. This is the ONLY way to reach the agent: the Flutter
app's floating chat bubble is the one client, calling this endpoint over
HTTP — there's no separate UI process for the agent anymore.

This is deliberately a thin orchestration layer: assistant/prompts.py owns
the system prompt and the tool schemas, assistant/accident_analysis.py owns
the actual fault logic, assistant/db.py owns persistence (into the SAME
Postgres tables/engine app.database already uses — see the sys.path
bootstrap below for why that's safe), and this file just runs the
OpenAI-compatible tool-use loop and dispatches whichever tool the model
calls.

Per-conversation working state (the two VehicleInput drafts, ClaimInfo, and
running message history) lives in an in-process dict, not the database —
same reasoning assistant/db.py's own docstring gives for not holding a long
-lived session: it's the "current draft" a client is actively building up
over a conversation, not itself the audit record (Message rows are the
audit record, and those ARE persisted on every turn). A server restart loses
in-flight drafts; already-persisted claims/messages are unaffected.
"""
import json
import sys
import threading
import uuid
from dataclasses import asdict
from pathlib import Path
from typing import Optional

import requests
from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse

from app import config, models, schemas
from app.database import SessionLocal

# ── Make the assistant/ package importable ──────────────────────────────────
# assistant/ lives at the repo root, a sibling of platform/ (see its own
# __init__.py docstring: "a CLI, a FastAPI chat endpoint ... could import
# this same package"). This container only ever has platform/backend/app
# copied/mounted in as the `app` package — assistant/ has to be mounted in
# separately (see docker-compose.yml's `api` service) for this to resolve.
# Walk up from this file looking for a directory containing assistant/, so
# this works both in the container (assistant mounted at /app/assistant)
# and in a plain local checkout (assistant/ under the repo root), without
# hardcoding either directory depth.
def _find_repo_root_with_assistant() -> Optional[Path]:
    for ancestor in Path(__file__).resolve().parents:
        if (ancestor / "assistant" / "__init__.py").is_file():
            return ancestor
    return None


_repo_root = _find_repo_root_with_assistant()
if _repo_root and str(_repo_root) not in sys.path:
    sys.path.insert(0, str(_repo_root))

try:
    from assistant import constat_pdf, db as assistant_db
    from assistant import language, memory, prompts, sentiment
    from assistant.accident_analysis import ClaimInfo, VehicleInput, analyze, geocode_preview

    _ASSISTANT_AVAILABLE = True
except ImportError:
    # assistant/ not mounted (e.g. an image built without the docker-compose
    # volume) — degrade instead of failing every other route in this app.
    _ASSISTANT_AVAILABLE = False


router = APIRouter(prefix="/chat", tags=["chat"])

_MAX_TOOL_ROUNDS = 6

# conversation_id -> {"vehicle_a", "vehicle_b", "claim_info", "history",
# "claim_id", "analysis", "escalation_flagged"} — see _new_session below.
_SESSIONS: dict[str, dict] = {}
_SESSIONS_LOCK = threading.Lock()


def _new_session(conversation_id: str) -> dict:
    return {
        "conversation_id": conversation_id,
        "vehicle_a": VehicleInput("A"),
        "vehicle_b": VehicleInput("B"),
        "claim_info": ClaimInfo(),
        "history": [],  # OpenAI-format messages, system prompt excluded
        "claim_id": None,
        # analyze()'s full result dict (fault/routes/relative_direction),
        # kept so the constat's auto-sketch (section 13) can use the same
        # confirmed routes/direction — cleared whenever record_vehicle
        # changes an accident-relevant field after this was set (see
        # _dispatch_tool's record_vehicle branch).
        "analysis": None,
        "escalation_flagged": False,
        # Best-guess language of the most recent user message ("ar"/"fr"/
        # "en") — set every turn in send_message, read by
        # _sync_client_profile for ClientProfile.preferred_language.
        "language": None,
        # Set once, from the first turn's payload, if the client sent
        # identity info (the Flutter chat bubble only shows once someone is
        # logged in — see AgentChatBubble/AgentSetUserEvent — so this is
        # normally set from turn one). Threaded into ClientProfile.mobile_
        # user_id and into the system prompt so the assistant doesn't ask a
        # logged-in user for their own name/phone.
        "mobile_user_id": None,
        "known_identity": None,  # {"first_name", "last_name", "phone", "email"} once set
    }


def _get_or_create_conversation(conversation_id: Optional[str]) -> tuple[str, dict]:
    with _SESSIONS_LOCK:
        if conversation_id and conversation_id in _SESSIONS:
            return conversation_id, _SESSIONS[conversation_id]
        if conversation_id:
            # Known to the DB (a returning client) but this process doesn't
            # have its draft in memory anymore (restart) — keep the same id
            # for audit continuity, start a fresh working draft.
            _SESSIONS[conversation_id] = _new_session(conversation_id)
            return conversation_id, _SESSIONS[conversation_id]
        try:
            new_id = assistant_db.create_conversation(config.LLM_BASE_URL, config.LLM_MODEL)
        except Exception:
            new_id = str(uuid.uuid4())
        _SESSIONS[new_id] = _new_session(new_id)
        return new_id, _SESSIONS[new_id]


def _call_llm(messages: list[dict], tools: list[dict]) -> Optional[dict]:
    if not config.LLM_API_KEY:
        print("❌ _call_llm: LLM_API_KEY is not set — check the api service's environment/.env")
        return None
    url = config.LLM_BASE_URL.rstrip("/") + "/chat/completions"
    headers = {"Authorization": f"Bearer {config.LLM_API_KEY}", "Content-Type": "application/json"}
    payload = {"model": config.LLM_MODEL, "messages": messages, "tools": tools, "tool_choice": "auto"}
    try:
        resp = requests.post(url, headers=headers, json=payload, timeout=30)
        resp.raise_for_status()
        return resp.json()
    except requests.RequestException as e:
        # Previously swallowed completely silently, which made this exact
        # class of failure (invalid key, rate limit, network block, wrong
        # base URL...) impossible to diagnose from the fallback message
        # alone. Log it — this is still best-effort (caller degrades to a
        # friendly fallback reply either way), just no longer silent.
        body = getattr(e.response, "text", None)
        print(f"❌ _call_llm: LLM request failed: {e!r}" + (f" — response body: {body[:500]}" if body else ""))
        return None


def _apply_vehicle_fields(vehicle: VehicleInput, args: dict) -> dict:
    geocoding: dict = {}
    if args.get("from_address"):
        vehicle.from_address = args["from_address"]
        geocoding["from"] = geocode_preview(vehicle.from_address)
    if args.get("to_address"):
        vehicle.to_address = args["to_address"]
        geocoding["to"] = geocode_preview(vehicle.to_address)
    if "circumstances" in args and args["circumstances"] is not None:
        vehicle.circumstances = list(args["circumstances"])
    if "impact_zones" in args and args["impact_zones"] is not None:
        vehicle.impact_zones = list(args["impact_zones"])
    if args.get("narrative"):
        vehicle.narrative = args["narrative"]
    if args.get("evidence"):
        # Dataclass field is a running list (audit trail); the tool schema
        # hands us one string per call, so append rather than overwrite.
        vehicle.evidence.append(args["evidence"])

    simple_fields = (
        "insurance_company", "policy_number", "agency", "driver_first_name",
        "driver_last_name", "driver_address", "license_number",
        "insured_first_name", "insured_last_name", "insured_address",
        "insured_phone", "vehicle_make_model", "plate_number",
        "damage_description", "observations",
    )
    for field_name in simple_fields:
        if args.get(field_name) is not None:
            setattr(vehicle, field_name, args[field_name])

    result = asdict(vehicle)
    if geocoding:
        result["geocoding"] = geocoding
    return result


def _apply_claim_fields(claim_info: ClaimInfo, args: dict) -> dict:
    for field_name in (
        "accident_date", "accident_time", "location", "injuries",
        "injuries_detail", "other_material_damage",
        "other_material_damage_detail", "witnesses",
    ):
        if field_name in args and args[field_name] is not None:
            setattr(claim_info, field_name, args[field_name])
    return asdict(claim_info)


def _relevant_vehicle_snapshot(vehicle: VehicleInput) -> tuple:
    """The fields an already-run analyze_accident/constat sketch actually depends on — used to detect
    whether a post-analysis edit needs to invalidate the previous result (see record_vehicle below)."""
    return (
        tuple(vehicle.circumstances),
        tuple(vehicle.impact_zones),
        vehicle.from_address,
        vehicle.to_address,
    )


def _sync_client_profile(
    conversation_id: str,
    label: str,
    vehicle: VehicleInput,
    language: Optional[str],
    mobile_user_id: Optional[int] = None,
) -> None:
    """
    Mirrors whatever identity/insurance/contact info record_vehicle just
    recorded into the ClientProfile table (see assistant/db.py — this is
    what lookup_constats' phone-based search actually reads; the plate-
    number side of that search comes from VehicleDeclaration instead,
    written separately by persist_claim_and_fault once analyze_accident
    runs). Best-effort, same philosophy as every other persistence call
    here — a DB hiccup shouldn't break the conversation.

    mobile_user_id is only ever non-None for vehicle_label "A" — it's the
    logged-in mobile-app user who opened the chat bubble, never the other
    party (vehicle B has no app account in this flow).
    """
    try:
        assistant_db.upsert_client_profile(
            conversation_id,
            label,
            first_name=vehicle.driver_first_name,
            last_name=vehicle.driver_last_name,
            address=vehicle.driver_address or vehicle.insured_address,
            phone=vehicle.insured_phone,
            license_number=vehicle.license_number,
            insurance_company=vehicle.insurance_company,
            policy_number=vehicle.policy_number,
            vehicle_make_model=vehicle.vehicle_make_model,
            plate_number=vehicle.plate_number,
            preferred_language=language,
            mobile_user_id=mobile_user_id,
        )
    except Exception:
        pass


def _dispatch_tool(name: str, args: dict, conversation_id: str, state: dict) -> dict:
    if name == "record_vehicle":
        label = args.get("vehicle_label")
        vehicle = state["vehicle_a"] if label == "A" else state["vehicle_b"] if label == "B" else None
        if vehicle is None:
            return {"error": "vehicle_label must be 'A' or 'B'"}

        before = _relevant_vehicle_snapshot(vehicle)
        result = _apply_vehicle_fields(vehicle, args)
        after = _relevant_vehicle_snapshot(vehicle)

        # A route/circumstance/damage edit after analyze_accident already
        # ran invalidates that result and the sketch built on it — see the
        # system prompt's "previous_analysis_invalidated" handling.
        if state.get("analysis") is not None and before != after:
            result["previous_analysis_invalidated"] = True
            state["analysis"] = None
            state["claim_id"] = None

        result["ready_for_constat_pdf"] = vehicle.is_ready_for_constat()
        result["still_missing_for_constat"] = vehicle.constat_missing_fields()
        mobile_user_id = state.get("mobile_user_id") if label == "A" else None
        _sync_client_profile(conversation_id, label, vehicle, state.get("language"), mobile_user_id)
        return result

    if name == "record_claim_info":
        return _apply_claim_fields(state["claim_info"], args)

    if name == "analyze_accident":
        if not args.get("user_confirmed"):
            return {
                "status": "not_confirmed",
                "message": "Recap both vehicles' details to the user and get explicit confirmation first.",
            }
        a, b = state["vehicle_a"], state["vehicle_b"]
        if not (a.is_ready_for_analysis() and b.is_ready_for_analysis()):
            return {
                "status": "incomplete",
                "message": "Both vehicles need at least a damage zone (impact_zones) recorded via record_vehicle first.",
            }
        result = analyze(a, b)
        state["analysis"] = result
        try:
            claim_id = assistant_db.persist_claim_and_fault(
                conversation_id, state["claim_info"], a, b, result["fault"]
            )
            state["claim_id"] = claim_id
            result["claim_id"] = claim_id
        except Exception:
            pass  # best-effort persistence, matches assistant/db.py's own philosophy
        return result

    if name == "note_mood":
        stress_level = args.get("stress_level")
        if stress_level in ("stressed", "distressed") or args.get("injury_mentioned") or args.get("dispute_mentioned"):
            state["escalation_flagged"] = True
        return {"logged": True}

    if name == "log_correction":
        try:
            memory.log_correction(args.get("what_was_wrong", ""), args.get("correct_version", ""))
        except Exception:
            pass
        return {"logged": True}

    if name == "lookup_constats":
        try:
            claims = assistant_db.find_claims_by_identifier(
                plate_number=args.get("plate_number"), phone=args.get("phone")
            )
        except Exception:
            claims = []
        return {"claims": claims}

    return {"error": f"unknown tool '{name}'"}


def _maybe_generate_constat(conversation_id: str, state: dict) -> Optional[str]:
    """
    Regenerates the draft/final constat PDF from whatever's currently in
    state and saves it, once either vehicle has enough to be worth showing
    (assistant.accident_analysis.VehicleInput.has_minimum_for_draft_constat)
    — matches the system prompt's "a draft is available right here in the
    chat the moment there's real data for either vehicle" promise. Called
    once per turn (not per tool call) so a multi-tool-call turn doesn't
    regenerate the same PDF several times in a row. Returns the relative
    URL path to fetch it, or None if there's nothing worth generating yet
    or PDF generation failed (best-effort, same philosophy as persistence).
    """
    a, b = state["vehicle_a"], state["vehicle_b"]
    if not (a.has_minimum_for_draft_constat() or b.has_minimum_for_draft_constat()):
        return None
    analysis = state.get("analysis") or {}
    try:
        pdf_bytes = constat_pdf.generate_filled_constat(
            state["claim_info"],
            a,
            b,
            routes=analysis.get("routes"),
            relative_direction=analysis.get("relative_direction"),
        )
        assistant_db.save_generated_constat(conversation_id, pdf_bytes)
        return f"/chat/{conversation_id}/constat.pdf"
    except Exception:
        return None


@router.get("/{conversation_id}/constat.pdf")
def get_constat_pdf(conversation_id: str):
    """Serves the most recently generated constat PDF for a conversation (see _maybe_generate_constat)."""
    with SessionLocal() as db:
        convo = db.get(models.Conversation, conversation_id)
    path = convo.constat_pdf_path if convo else None
    if not path or not Path(path).exists():
        raise HTTPException(404, "No constat generated yet for this conversation")
    return FileResponse(path, media_type="application/pdf", filename=f"constat_{conversation_id}.pdf")


@router.post("/message", response_model=schemas.ChatMessageOut)
def send_message(payload: schemas.ChatMessageIn) -> schemas.ChatMessageOut:
    if not _ASSISTANT_AVAILABLE:
        return schemas.ChatMessageOut(
            conversation_id=payload.conversation_id or str(uuid.uuid4()),
            message="Le chat de l'agent n'est pas disponible sur ce serveur (module assistant introuvable).",
        )

    conversation_id, state = _get_or_create_conversation(payload.conversation_id)
    user_message = payload.message

    # Logged-in user's identity, sent by the Flutter chat bubble (which only
    # shows once someone is authenticated). Captured once per conversation —
    # a later turn's payload always repeats the same identity, so only the
    # first one that arrives matters. Prefills Vehicle A (the app user is
    # always the one filing, never the other party) so the assistant already
    # knows who it's talking to and doesn't ask for a name/phone it already
    # has — see the known-identity note appended to the system prompt in
    # _run_turn. Fields already typed by the user in chat are never
    # clobbered (only fills what's still empty).
    if state["known_identity"] is None and (payload.first_name or payload.last_name or payload.phone):
        state["mobile_user_id"] = payload.user_id
        state["known_identity"] = {
            "first_name": payload.first_name,
            "last_name": payload.last_name,
            "phone": payload.phone,
            "email": payload.email,
        }
        vehicle_a = state["vehicle_a"]
        if not vehicle_a.driver_first_name:
            vehicle_a.driver_first_name = payload.first_name
        if not vehicle_a.driver_last_name:
            vehicle_a.driver_last_name = payload.last_name
        if not vehicle_a.insured_first_name:
            vehicle_a.insured_first_name = payload.first_name
        if not vehicle_a.insured_last_name:
            vehicle_a.insured_last_name = payload.last_name
        if not vehicle_a.insured_phone:
            vehicle_a.insured_phone = payload.phone
        _sync_client_profile(conversation_id, "A", vehicle_a, state.get("language"), state["mobile_user_id"])

    lang = language.detect(user_message)
    state["language"] = lang
    hit = sentiment.scan_message(user_message)
    if hit["injury_keyword_hit"] or hit["distress_keyword_hit"]:
        state["escalation_flagged"] = True

    state["history"].append({"role": "user", "content": user_message})
    try:
        assistant_db.log_message(conversation_id, "user", user_message, lang)
    except Exception:
        pass

    reply_text = _run_turn(state)
    constat_pdf_url = _maybe_generate_constat(conversation_id, state)

    try:
        assistant_db.log_message(conversation_id, "assistant", reply_text)
        assistant_db.update_conversation_llm_config(conversation_id, config.LLM_BASE_URL, config.LLM_MODEL)
        if state["escalation_flagged"]:
            assistant_db.update_conversation_escalation(conversation_id, True, ["auto-detected"])
    except Exception:
        pass

    return schemas.ChatMessageOut(
        conversation_id=conversation_id,
        message=reply_text,
        claim_id=state.get("claim_id"),
        escalation_flag=state["escalation_flagged"],
        constat_pdf_url=constat_pdf_url,
    )


def _run_turn(state: dict) -> str:
    if not config.LLM_API_KEY:
        return (
            "Le chat de l'agent n'est pas encore configuré côté serveur (clé LLM manquante) — "
            "un humain reprendra votre demande dès que possible."
        )

    try:
        lessons = memory.load_recent_lessons()
    except Exception:
        lessons = []
    system_prompt = prompts.build_system_prompt(lessons)

    identity = state.get("known_identity")
    if identity:
        name = " ".join(p for p in (identity.get("first_name"), identity.get("last_name")) if p)
        details = ", ".join(
            f"{label}: {value}"
            for label, value in (("nom", name), ("téléphone", identity.get("phone")), ("email", identity.get("email")))
            if value
        )
        system_prompt += (
            "\n\nContexte interne (ne pas répéter cette phrase à l'utilisateur) : "
            f"l'utilisateur connecté est déjà identifié comme conducteur/assuré du Véhicule A ({details}). "
            "Ces informations sont déjà enregistrées — ne les redemande pas, contente-toi de les confirmer "
            "brièvement si utile, ou de les corriger si l'utilisateur en donne une version différente."
        )

    messages = [{"role": "system", "content": system_prompt}] + state["history"]

    reply_text = None
    for _ in range(_MAX_TOOL_ROUNDS):
        resp = _call_llm(messages, prompts.TOOLS)
        if resp is None or not resp.get("choices"):
            reply_text = "Désolé, je n'arrive pas à joindre l'assistant IA pour le moment. Réessayez dans un instant."
            break

        msg = resp["choices"][0]["message"]
        messages.append(msg)
        tool_calls = msg.get("tool_calls") or []
        if not tool_calls:
            reply_text = msg.get("content") or ""
            break

        for tc in tool_calls:
            fn = tc.get("function", {})
            try:
                args = json.loads(fn.get("arguments") or "{}")
            except json.JSONDecodeError:
                args = {}
            result = _dispatch_tool(fn.get("name", ""), args, state["conversation_id"], state)
            messages.append(
                {
                    "role": "tool",
                    "tool_call_id": tc.get("id"),
                    "name": fn.get("name", ""),
                    "content": json.dumps(result, ensure_ascii=False, default=str),
                }
            )
    else:
        reply_text = reply_text or "Désolé, ça prend plus de temps que prévu — pouvez-vous reformuler votre dernier message ?"

    state["history"] = messages[1:]  # drop the system prompt before next turn
    return reply_text or ""
