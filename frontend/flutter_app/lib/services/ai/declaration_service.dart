// lib/services/ai/declaration_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ai_insurance_advisor/core/constants/api_constants.dart';
import 'package:ai_insurance_advisor/models/declaration_model.dart';

class DeclarationService {
  static Future<DeclarationModel> submitDeclaration({
    required DeclarationModel declaration,
  }) async {
    try {
      // Analyser la déclaration avec IA (dégrade proprement si la clé
      // OpenAI n'est pas configurée — voir _analyzeWithAI)
      final analysis = await _analyzeWithAI(declaration);
      
      // Sauvegarder la déclaration
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/declarations'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          ...declaration.toJson(),
          'analysis': analysis,
        }),
      );

      if (response.statusCode == 201) {
        // ✅ Cast explicite en Map<String, dynamic>
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return DeclarationModel.fromJson(data);
      } else {
        throw Exception('Erreur déclaration: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ DeclarationService error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> _analyzeWithAI(
    DeclarationModel declaration,
  ) async {
    try {
      final apiKey = ApiConstants.openAIApiKey;

      if (apiKey == 'VOTRE_CLE_OPENAI') {
        return {
          'analysis': 'Analyse en cours... (clé API non configurée)',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

      final prompt = '''
Analyse cette déclaration de sinistre:
- Date: ${declaration.date}
- Lieu: ${declaration.location}
- Description: ${declaration.description}
- Véhicule: ${declaration.vehicleName}
- Conducteur: ${declaration.driverName}

Donne:
- Type de sinistre
- Niveau de gravité
- Documents nécessaires
- Prochaines étapes
''';

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': 'Expert en sinistres automobiles.'},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.3,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        // ✅ Cast explicite en Map<String, dynamic>
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['choices'][0]['message']['content'] as String? ?? '';
        return {
          'analysis': content,
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        throw Exception('Erreur analyse: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ AI Analysis error: $e');
      return {
        'analysis': 'Analyse en cours... (erreur: ${e.toString()})',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}