import openai
import json
from app.core.config import settings

class AIService:
    
    @staticmethod
    async def analyze_declaration(description: str, driver_name: str, driver_age: int, vehicle: str) -> dict:
        """Analyser une déclaration avec OpenAI"""
        try:
            client = openai.OpenAI(api_key=settings.openai_api_key)
            
            prompt = f"""
            Analyse cette déclaration de sinistre automobile:
            
            Conducteur: {driver_name} ({driver_age} ans)
            Véhicule: {vehicle}
            Description: {description}
            
            Donne une analyse structurée en JSON:
            - type: type de sinistre
            - severity: niveau de gravité (faible/moyenne/élevée)
            - garanties: liste des garanties concernées
            - demarches: liste des démarches recommandées
            - conseils: conseils supplémentaires
            """
            
            response = client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": "Tu es un expert en sinistres automobiles. Réponds en JSON."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.3,
                max_tokens=300,
                response_format={"type": "json_object"}
            )
            
            return json.loads(response.choices[0].message.content)
            
        except Exception as e:
            print(f"❌ AI error: {e}")
            return {
                "type": "Accident de la route",
                "severity": "moyenne",
                "garanties": ["Protection juridique", "Assistance dépannage"],
                "demarches": ["Contacter votre assurance", "Faire un constat amiable"],
                "conseils": ["Prenez des photos des dégâts"]
            }
    
    @staticmethod
    async def get_personalized_advice(age: int, experience_years: int, vehicle: str, usage: str, annual_km: int) -> str:
        """Obtenir des conseils personnalisés"""
        try:
            client = openai.OpenAI(api_key=settings.openai_api_key)
            
            prompt = f"""
            Donne des conseils personnalisés pour un conducteur de {age} ans avec {experience_years} ans d'expérience.
            Véhicule: {vehicle}
            Utilisation: {usage}
            Kilométrage annuel: {annual_km} km
            
            Structure ta réponse en paragraphes avec:
            1. Les garanties recommandées
            2. Les facteurs de risque
            3. Des conseils de sécurité
            4. Une estimation du coût mensuel
            """
            
            response = client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": "Tu es un expert en assurance automobile. Réponds en français."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.7,
                max_tokens=500
            )
            
            return response.choices[0].message.content
            
        except Exception as e:
            print(f"❌ AI error: {e}")
            return f"""
            📋 **Conseils personnalisés**

            **1. Garanties recommandées :**
            • Protection vol et incendie
            • Protection juridique
            • Assistance 24/7

            **2. Facteurs de risque :**
            • Conducteur de {age} ans avec {experience_years} ans d'expérience
            • Utilisation {usage}
            • {annual_km} km par an

            **3. Conseils de sécurité :**
            • Entretenez régulièrement votre véhicule
            • Adaptez votre vitesse aux conditions

            **4. Coût estimé :** entre 80 et 120 TND/mois
            """