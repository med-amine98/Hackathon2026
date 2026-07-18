// lib/services/ai/ai_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ai_insurance_advisor/core/constants/api_constants.dart';
import 'package:ai_insurance_advisor/models/user_model.dart';
import 'package:ai_insurance_advisor/models/vehicle_model.dart';

class AIService {
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  static Future<String> getPersonalizedAdvice({
    required UserModel user,
    required VehicleModel vehicle,
  }) async {
    try {
      final apiKey = ApiConstants.openAIApiKey;
      
      if (apiKey == 'VOTRE_CLE_OPENAI') {
        return _getFallbackAdvice(user, vehicle);
      }

      final prompt = '''
Tu es un expert en assurance automobile en Tunisie. 
Donne des conseils personnalisés à un conducteur de ${user.age} ans avec ${user.experienceYears} ans d'expérience.
Il possède une ${vehicle.fullName} qu'il utilise ${vehicle.usage}.

Propose :
1. Les garanties recommandées
2. Les facteurs de risque
3. Des conseils de sécurité
4. Une estimation du coût mensuel

Réponse en français, structurée et professionnelle.
''';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': 'Tu es un expert en assurance automobile.'},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['choices'][0]['message']['content'] as String? ?? _getFallbackAdvice(user, vehicle);
      } else {
        return _getFallbackAdvice(user, vehicle);
      }
    } catch (e) {
      print('❌ AIService error: $e');
      return _getFallbackAdvice(user, vehicle);
    }
  }

  static String _getFallbackAdvice(UserModel user, VehicleModel vehicle) {
    return '''
📋 **Conseils personnalisés pour ${user.fullName}**

Basé sur votre profil (${user.age} ans, ${vehicle.fullName}) :

**1. Garanties recommandées :**
• Protection vol et incendie
• Protection juridique
• Assistance 24/7
• Bris de glace

**2. Facteurs de risque :**
• Conducteur de ${user.age} ans avec ${user.experienceYears} ans d'expérience
• Utilisation ${vehicle.usage}
• ${vehicle.annualKm} km par an

**3. Conseils de sécurité :**
• Entretenez régulièrement votre véhicule
• Adaptez votre vitesse aux conditions de circulation
• Vérifiez la pression des pneus mensuellement

**4. Coût estimé :** entre 80 et 120 TND/mois
''';
  }

  static Future<Map<String, dynamic>> analyzeDeclaration({
    required String description,
    required UserModel user,
    required VehicleModel vehicle,
  }) async {
    try {
      final apiKey = ApiConstants.openAIApiKey;
      
      if (apiKey == 'VOTRE_CLE_OPENAI') {
        return _getFallbackAnalysis(description);
      }

      final prompt = '''
Analyse cette déclaration d'accident automobile:
"$description"

Informations:
- Conducteur: ${user.fullName} (${user.age} ans)
- Véhicule: ${vehicle.fullName}
- Expérience: ${user.experienceYears} ans

Donne:
1. Type d'accident probable
2. Gravité estimée
3. Garanties concernées
4. Démarches recommandées

Réponse en JSON:
{
  "type": "string",
  "severity": "string (faible/moyenne/élevée)",
  "garanties": ["string"],
  "demarches": ["string"]
}
''';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': 'Tu es un expert en sinistres automobiles.'},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.3,
          'max_tokens': 300,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['choices'][0]['message']['content'] as String? ?? '{}';
        return jsonDecode(content) as Map<String, dynamic>;
      } else {
        return _getFallbackAnalysis(description);
      }
    } catch (e) {
      print('❌ AIAnalyze error: $e');
      return _getFallbackAnalysis(description);
    }
  }

  static Map<String, dynamic> _getFallbackAnalysis(String description) {
    return {
      'type': 'Accident de la route',
      'severity': 'moyenne',
      'garanties': ['Protection juridique', 'Assistance dépannage'],
      'demarches': ['Contacter votre assurance', 'Faire un constat amiable'],
    };
  }

  static Future<Map<String, dynamic>> getPreventionTips({
    required VehicleModel vehicle,
    required String city,
  }) async {
    try {
      final apiKey = ApiConstants.openAIApiKey;
      
      if (apiKey == 'VOTRE_CLE_OPENAI') {
        return _getFallbackPrevention();
      }

      final prompt = '''
Donne des conseils de prévention pour un véhicule ${vehicle.fullName} à $city.

Inclus:
1. Entretien recommandé (kilométrage)
2. Alertes météo pour la région
3. Conseils de conduite sécuritaire
4. Points à vérifier régulièrement

Réponse en JSON:
{
  "maintenance": {"km": "int", "items": ["string"]},
  "weather_alerts": ["string"],
  "driving_tips": ["string"],
  "check_points": ["string"]
}
''';

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': 'Tu es un expert en maintenance automobile.'},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.5,
          'max_tokens': 400,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['choices'][0]['message']['content'] as String? ?? '{}';
        return jsonDecode(content) as Map<String, dynamic>;
      } else {
        return _getFallbackPrevention();
      }
    } catch (e) {
      print('❌ Prevention error: $e');
      return _getFallbackPrevention();
    }
  }

  static Map<String, dynamic> _getFallbackPrevention() {
    return {
      'maintenance': {
        'km': 15000,
        'items': ['Vidange d\'huile', 'Filtres à air', 'Plaquettes de frein'],
      },
      'weather_alerts': ['Vérifier la météo avant de prendre la route'],
      'driving_tips': ['Respecter les limitations de vitesse', 'Maintenir une distance de sécurité'],
      'check_points': ['Pression des pneus', 'Niveau d\'huile', 'Feux de signalisation'],
    };
  }
}