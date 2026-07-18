"""
Chat routes — conversational AI endpoint.
Uses schemas from app.schemas.chat (clean separation of concerns).
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.schemas.chat import ChatRequest, ChatResponse
from app.services.profile_service import ProfileService
from app.services.risk_analyzer import RiskAnalyzer
from app.services.recommendation_engine import RecommendationEngine
from app.ai.intent_detector import IntentDetector
from app.ai.conversation_manager import ConversationManager
from app.models.user import User
from app.api.dependencies import get_current_user

router = APIRouter(prefix="/chat", tags=["Chat"])


@router.post("/message", response_model=ChatResponse)
async def chat_message(
    request: ChatRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Send a message to the AI assistant and receive a response."""
    # Initialize services
    intent_detector = IntentDetector()
    conversation_manager = ConversationManager(db)
    profile_service = ProfileService(db)
    risk_analyzer = RiskAnalyzer()
    recommendation_engine = RecommendationEngine(db)

    # Get or create conversation
    conversation = conversation_manager.get_or_create_conversation(
        user_id=current_user.id,
        conversation_id=request.conversation_id,
    )

    # Detect intent
    intent_result = await intent_detector.detect_intent(
        message=request.message,
        conversation_context=conversation.context_data,
    )

    # Update conversation with intent
    conversation_manager.update_intent(conversation.id, intent_result["intent"])

    # Build response skeleton
    response: dict = {
        "conversation_id": conversation.id,
        "intent": intent_result["intent"],
        "next_step": None,
        "recommendations": None,
        "profile_data": None,
    }

    if intent_result["intent"] == "buy_car_insurance":
        profile = profile_service.update_profile_from_message(
            user_id=current_user.id,
            message=request.message,
            entities=intent_result.get("entities", {}),
        )

        next_question = conversation_manager.get_next_question(conversation.id, profile)

        if next_question:
            response["message"] = next_question
            response["next_step"] = "collecting_info"
        else:
            # Profile complete — analyze risk and recommend
            risk_score = risk_analyzer.calculate_risk_score(profile)
            profile_service.update_risk_score(profile.id, risk_score)

            recommendations = recommendation_engine.get_recommendations(
                profile=profile,
                risk_score=risk_score,
            )

            response["message"] = "Basé sur votre profil, voici mes recommandations :"
            response["recommendations"] = recommendations
            response["profile_data"] = {
                k: v for k, v in profile.__dict__.items() if not k.startswith("_")
            }
            response["next_step"] = "recommendations"

    elif intent_result["intent"] == "get_quote":
        quote = recommendation_engine.get_quick_quote(
            user_id=current_user.id,
            product_category=intent_result.get("entities", {}).get("category"),
        )
        response["message"] = quote["message"]
        response["recommendations"] = quote["products"]

    else:
        # General question — use GPT or rules-based fallback
        gpt_response = await conversation_manager.get_gpt_response(
            conversation_id=conversation.id,
            user_message=request.message,
        )
        response["message"] = gpt_response

    # Persist messages
    conversation_manager.save_message(
        conversation_id=conversation.id,
        role="user",
        content=request.message,
        metadata=intent_result,
    )
    conversation_manager.save_message(
        conversation_id=conversation.id,
        role="assistant",
        content=response["message"],
    )

    return ChatResponse(**response)
