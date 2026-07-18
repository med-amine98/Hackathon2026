import re
from typing import Dict, Any, Optional
import json
from openai import AsyncOpenAI
from app.core.config import settings

class IntentDetector:
    def __init__(self):
        self.api_key = settings.openai_api_key
        self.client = None
        if self.api_key and "your-openai-api-key" not in self.api_key:
            self.client = AsyncOpenAI(api_key=self.api_key)
        
    async def detect_intent(self, message: str, conversation_context: Optional[Dict] = None) -> Dict[str, Any]:
        """Detect intent from user message using pattern matching and GPT"""
        
        # Clean and normalize message
        message_lower = message.lower().strip()
        
        # Pattern-based intent detection
        intents = {
            "buy_car_insurance": [
                r"acheter.*assurance.*voiture",
                r"assurance.*automobile",
                r"nouvelle.*voiture",
                r"je.*veux.*assurer.*voiture",
                r"assurance.*véhicule",
                r"assurer.*voiture",
                r"achat.*voiture"
            ],
            "get_quote": [
                r"devis",
                r"combien.*coûte",
                r"prix.*assurance",
                r"tarif",
                r"obtenir.*tarif",
                r"simulation"
            ],
            "general_question": [
                r"comment.*fonctionne",
                r"qu'est-ce que",
                r"explique",
                r"aide",
                r"bonjour",
                r"salut"
            ]
        }
        
        for intent, patterns in intents.items():
            for pattern in patterns:
                if re.search(pattern, message_lower):
                    return {
                        "intent": intent,
                        "entities": self._extract_entities(message),
                        "confidence": 0.9
                    }
        
        # Use GPT for complex intent detection if key is available
        if self.client:
            try:
                response = await self.client.chat.completions.create(
                    model="gpt-4",
                    messages=[
                        {"role": "system", "content": """
                        You are an intent detection system for insurance.
                        Classify the user's intent and extract entities.
                        Available intents: buy_car_insurance, get_quote, general_question, compare_products
                        Return JSON format only, like: {"intent": "...", "entities": {}, "confidence": 0.85}
                        """},
                        {"role": "user", "content": message}
                    ],
                    response_format={"type": "json_object"}
                )
                
                result = json.loads(response.choices[0].message.content)
                # Ensure entities are populated
                if "entities" not in result or not result["entities"]:
                    result["entities"] = self._extract_entities(message)
                return result
            except Exception:
                pass
                
        return {
            "intent": "general_question",
            "entities": self._extract_entities(message),
            "confidence": 0.5
        }
    
    def _extract_entities(self, message: str) -> Dict[str, Any]:
        """Extract entities from message"""
        entities = {}
        message_lower = message.lower()
        
        # Extract age
        age_match = re.search(r'(\d+)\s*ans', message_lower)
        if age_match:
            entities["age"] = int(age_match.group(1))
        
        # Extract budget
        budget_match = re.search(r'(\d+)\s*(?:dt|tnd|dinars|euros|usd|chf|cf|dh|da)', message_lower)
        if budget_match:
            entities["budget"] = int(budget_match.group(1))
        
        # Extract vehicle model
        vehicle_keywords = ["voiture", "véhicule", "auto", "clio", "peugeot", "golf", "toyota", "kia", "bmw", "mercedes", "fiat"]
        for keyword in vehicle_keywords:
            if keyword in message_lower:
                # Try to extract the word after vehicle keyword
                model_match = re.search(rf'{keyword}\s+(\w+)', message_lower)
                if model_match:
                    entities["vehicle"] = model_match.group(1).capitalize()
                else:
                    entities["vehicle"] = "Auto"
                break
        
        return entities
