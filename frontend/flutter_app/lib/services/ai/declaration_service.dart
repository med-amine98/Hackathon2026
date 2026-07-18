// lib/services/ai/declaration_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

      // POST /declarations/ requires auth (Depends(get_current_user) on the
      // backend — see backend/app/api/routes/declaration.py) and the
      // trailing slash matters: without it FastAPI 307-redirects, which is
      // fragile for a cross-origin POST from Flutter web. This call used a
      // bare, unauthenticated http.post (bypassing ApiClient's Dio
      // interceptor entirely), so every submission was silently failing
      // with 401 — fixed to attach the stored bearer token directly.
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Sauvegarder la déclaration
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/declarations/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
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