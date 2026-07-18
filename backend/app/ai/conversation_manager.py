from sqlalchemy.orm import Session
from datetime import datetime
from typing import Optional, Dict, Any, List
from openai import AsyncOpenAI
from app.models.conversation import Conversation, Message
from app.models.profile import UserProfile
from app.ai.prompt_templates import SYSTEM_PROMPT
from app.core.config import settings

class ConversationManager:
    def __init__(self, db: Session):
        self.db = db
        self.api_key = settings.openai_api_key
        self.client = None
        if self.api_key and "your-openai-api-key" not in self.api_key:
            self.client = AsyncOpenAI(api_key=self.api_key)
            
    def get_or_create_conversation(self, user_id: int, conversation_id: Optional[int] = None) -> Conversation:
        if conversation_id:
            conv = self.db.query(Conversation).filter(
                Conversation.id == conversation_id,
                Conversation.user_id == user_id
            ).first()
            if conv:
                return conv
                
        # Create new conversation
        conv = Conversation(
            user_id=user_id,
            status="active",
            context_data={},
            messages_count=0
        )
        self.db.add(conv)
        self.db.commit()
        self.db.refresh(conv)
        return conv
        
    def update_intent(self, conversation_id: int, intent: str):
        conv = self.db.query(Conversation).filter(Conversation.id == conversation_id).first()
        if conv:
            conv.intent = intent
            self.db.commit()
            
    def save_message(self, conversation_id: int, role: str, content: str, metadata: Optional[Dict] = None):
        msg = Message(
            conversation_id=conversation_id,
            role=role,
            content=content,
            meta_data=metadata or {}
        )
        self.db.add(msg)
        
        # Increment message count
        conv = self.db.query(Conversation).filter(Conversation.id == conversation_id).first()
        if conv:
            conv.messages_count += 1
            conv.updated_at = datetime.utcnow()
            
        self.db.commit()
        
    def get_next_question(self, conversation_id: int, profile: UserProfile) -> Optional[str]:
        """Slot filling questions for auto insurance"""
        conv = self.db.query(Conversation).filter(Conversation.id == conversation_id).first()
        
        if not profile.age:
            conv.current_step = "collecting_age"
            self.db.commit()
            return "Quel âge avez-vous ?"
            
        if not profile.city:
            conv.current_step = "collecting_city"
            self.db.commit()
            return "Dans quelle ville habitez-vous (ex: Tunis, Sfax, Sousse) ?"
            
        if not profile.vehicle_model:
            conv.current_step = "collecting_vehicle"
            self.db.commit()
            return "Quel est le modèle ou la marque de votre véhicule ?"
            
        if not profile.vehicle_usage:
            conv.current_step = "collecting_usage"
            self.db.commit()
            return "Comment utilisez-vous votre véhicule : quotidien (trajet travail), weekend (loisirs), ou occasionnel ?"
            
        if not profile.annual_km:
            conv.current_step = "collecting_km"
            self.db.commit()
            return "Combien de kilomètres estimez-vous parcourir par an ?"
            
        if not profile.driving_experience_years:
            conv.current_step = "collecting_experience"
            self.db.commit()
            return "Depuis combien d'années avez-vous votre permis de conduire ?"
            
        if not profile.parking_type:
            conv.current_step = "collecting_parking"
            self.db.commit()
            return "Où garez-vous votre véhicule la nuit (dans un garage, un parking privé, ou dans la rue) ?"
            
        if not profile.budget_monthly:
            conv.current_step = "collecting_budget"
            self.db.commit()
            return "Quel est votre budget mensuel approximatif en Dinars (ex: 80 DT) ?"
            
        conv.current_step = "complete"
        self.db.commit()
        return None
        
    async def get_gpt_response(self, conversation_id: int, user_message: str) -> str:
        """Call GPT with conversation context, or use rules-based fallback"""
        
        # Load conversation history
        messages = self.db.query(Message).filter(Message.conversation_id == conversation_id).order_by(Message.created_at.asc()).all()
        
        if self.client:
            try:
                api_messages = [{"role": "system", "content": SYSTEM_PROMPT}]
                for msg in messages:
                    api_messages.append({"role": msg.role, "content": msg.content})
                # Add current user message (since it might not be saved yet when generating response)
                api_messages.append({"role": "user", "content": user_message})
                
                response = await self.client.chat.completions.create(
                    model="gpt-4",
                    messages=api_messages
                )
                return response.choices[0].message.content
            except Exception as e:
                # Fallback to rules if API fails
                pass
                
        # Rules-based fallback response
        message_lower = user_message.lower()
        if "bonjour" in message_lower or "salut" in message_lower or "hello" in message_lower:
            return "Bonjour ! Je suis votre conseiller IA en assurance. Je peux vous aider à obtenir un devis pour votre voiture ou répondre à vos questions. Que puis-je faire pour vous ?"
        elif "tarif" in message_lower or "devis" in message_lower or "prix" in message_lower:
            return "Pour vous proposer un devis précis, j'ai besoin de quelques détails. Souhaitez-vous souscrire une assurance auto ?"
        elif "merci" in message_lower:
            return "Avec plaisir ! N'hésitez pas si vous avez d'autres questions."
        else:
            return "Je comprends votre question. En tant que conseiller d'assurance, je vous recommande d'examiner nos garanties auto. Souhaitez-vous démarrer une simulation ?"
