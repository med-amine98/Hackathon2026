// lib/data/repositories/chat_repository.dart

import 'package:ai_insurance_advisor/data/datasources/remote/api_client.dart';

class ChatRepository {
  final ApiClient _apiClient;

  ChatRepository(this._apiClient);

  Future<Map<String, dynamic>> sendMessage(
    String message, {
    int? conversationId,
  }) async {
    try {
      return await _apiClient.sendMessage(message, conversationId: conversationId);
    } catch (e) {
      print('❌ ChatRepository error: $e');
      return {
        'message': 'Je suis désolé, je rencontre un problème technique.',
        'conversation_id': null,
      };
    }
  }
}