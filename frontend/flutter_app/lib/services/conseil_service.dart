// lib/services/conseil_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ai_insurance_advisor/core/constants/api_constants.dart';
import 'package:ai_insurance_advisor/models/user_model.dart';
import 'package:ai_insurance_advisor/models/vehicle_model.dart';

class ConseilService {
  static const String _openAIUrl = 'https://api.openai.com/v1/chat/completions';

  static Future<Map<String, dynamic>> getPersonalizedAdvice({
    required UserModel user,
    required VehicleModel vehicle,
    required String usage,
    required int annualKm,
  }) async {
    try {
      final apiKey = ApiConstants.openAIApiKey;
      
      if (apiKey == 'VOTRE_CLE_OPENAI') {
        throw Exception('⚠️ Clé OpenAI non configurée');
      }

      final prompt = '''
Tu es un expert en assurance automobile en Tunisie.

Analyse ce profil conducteur et donne des conseils personnalisés:

**Informations du conducteur:**
- Âge: ${user.age} ans
- Expérience: ${user.experienceYears} ans
- Ville: ${user.city}

**Informations du véhicule:**
- Marque/Modèle: ${vehicle.fullName}
- Kilométrage annuel: $annualKm km
- Utilisation: $usage

**Questions à traiter:**
1. Quel type d'assurance est le plus adapté (Tous risques, Tiers, Intermédiaire)?
2. Quelles garanties sont essentielles?
3. Quels sont les facteurs de risque?
4. Estimation du coût mensuel
5. Recommandations spécifiques

Réponds en français, de manière structurée et professionnelle.
''';

      final response = await http.post(
        Uri.parse(_openAIUrl),
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
          'max_tokens': 600,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final advice = data['choices'][0]['message']['content'] as String;
        return _parseAdvice(advice, user, vehicle, usage, annualKm);
      } else {
        throw Exception('Erreur OpenAI: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ ConseilService error: $e');
      rethrow;
    }
  }

  static Map<String, dynamic> _parseAdvice(
    String advice,
    UserModel user,
    VehicleModel vehicle,
    String usage,
    int annualKm,
  ) {
    String insuranceType = 'Intermédiaire';
    if (user.age < 25 || annualKm > 20000) {
      insuranceType = 'Tous risques';
    } else if (user.age > 60 || annualKm < 5000) {
      insuranceType = 'Tiers';
    }

    int riskScore = 0;
    final factors = <String>[];
    
    if (user.age < 25) {
      riskScore += 20;
      factors.add('Jeune conducteur');
    }
    if (user.experienceYears < 3) {
      riskScore += 15;
      factors.add('Expérience limitée');
    }
    if (annualKm > 20000) {
      riskScore += 15;
      factors.add('Kilométrage élevé');
    }
    if (usage == 'quotidiennement') {
      riskScore += 10;
      factors.add('Utilisation quotidienne');
    }
    if (user.city == 'Tunis' || user.city == 'Sfax' || user.city == 'Sousse') {
      riskScore += 10;
      factors.add('Zone urbaine dense');
    }

    final garanties = _getGaranties(user, vehicle, annualKm);

    double baseCost = 80.0;
    if (insuranceType == 'Tous risques') baseCost += 40;
    if (riskScore > 50) baseCost += 20;
    if (annualKm > 20000) baseCost += 15;
    final monthlyCost = baseCost + (riskScore * 0.5);

    return {
      'insurance_type': insuranceType,
      'risk_score': riskScore,
      'risk_factors': factors,
      'garanties': garanties,
      'estimated_cost': monthlyCost.toStringAsFixed(0),
      'advice': advice,
      'summary': _generateSummary(insuranceType, riskScore, monthlyCost),
    };
  }

  static List<Map<String, dynamic>> _getGaranties(
    UserModel user,
    VehicleModel vehicle,
    int annualKm,
  ) {
    final garanties = <Map<String, dynamic>>[];
    
    garanties.add({
      'title': 'Responsabilité Civile',
      'description': 'Couverture des dommages causés à autrui',
      'icon': 'Icons.shield',
      'color': '#2563EB',
      'essential': true,
    });
    
    garanties.add({
      'title': 'Protection Juridique',
      'description': 'Assistance en cas de litige',
      'icon': 'Icons.gavel',
      'color': '#7C3AED',
      'essential': true,
    });

    if (user.age < 25) {
      garanties.add({
        'title': 'Protection Conducteur',
        'description': 'Couverture spécifique jeune conducteur',
        'icon': 'Icons.people',
        'color': '#F59E0B',
        'essential': true,
      });
    }

    if (annualKm > 15000) {
      garanties.add({
        'title': 'Assistance Dépannage',
        'description': 'Dépannage et remorquage 24/7',
        'icon': 'Icons.construction',
        'color': '#EF4444',
        'essential': true,
      });
    }

    if (user.age > 30 && user.experienceYears > 5) {
      garanties.add({
        'title': 'Bonus Conducteur',
        'description': 'Réduction pour bon conducteur',
        'icon': 'Icons.star',
        'color': '#10B981',
        'essential': false,
      });
    }

    return garanties;
  }

  static String _generateSummary(String type, int riskScore, double cost) {
    return '''
Recommandation : Assurance $type
Score de risque : $riskScore/100
Coût estimé : ${cost.toStringAsFixed(0)} TND/mois

Cette offre est adaptée à votre profil.
''';
  }
}