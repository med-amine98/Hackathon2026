// lib/data/repositories/agent_chat_repository.dart

import 'dart:typed_data';

import 'package:ai_insurance_advisor/data/datasources/remote/agent_api_client.dart';

class AgentChatRepository {
  final AgentApiClient _apiClient;

  AgentChatRepository(this._apiClient);

  /// Returns the raw JSON body from POST /chat/message:
  /// { conversation_id, message, claim_id?, escalation_flag }.
  /// Never throws — network/agent failures degrade to a friendly fallback
  /// message so a flaky connection doesn't crash the chat bubble.
  ///
  /// userId/firstName/lastName/email/phone identify the logged-in mobile
  /// user (see AgentChatBloc._currentUser) — sent so the agent backend can
  /// prefill Vehicle A's identity instead of asking for it again.
  Future<Map<String, dynamic>> sendMessage(
    String message, {
    String? conversationId,
    int? userId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    try {
      return await _apiClient.sendMessage(
        message,
        conversationId: conversationId,
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
      );
    } catch (e) {
      print('❌ AgentChatRepository error: $e');
      return {
        'message': "Je n'arrive pas à joindre l'agent pour le moment. Réessayez dans un instant.",
        'conversation_id': conversationId,
        'escalation_flag': false,
      };
    }
  }

  /// Attaches a photo to the claim the current conversation has already
  /// drafted. Throws on failure — unlike sendMessage, the caller here
  /// (AgentChatBloc._onUploadPhoto) needs to know it failed so it can tell
  /// the user the photo wasn't saved, rather than degrading silently.
  Future<void> uploadPhoto({
    required String claimId,
    required Uint8List bytes,
    required String filename,
    String vehicleLabel = 'A',
  }) {
    return _apiClient.uploadPhoto(
      claimId: claimId,
      vehicleLabel: vehicleLabel,
      bytes: bytes,
      filename: filename,
    );
  }
}
