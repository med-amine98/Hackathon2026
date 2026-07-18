// lib/data/datasources/remote/agent_api_client.dart
//
// Talks to the agent's accident-intake chat (platform/backend/app/routers/
// chat.py), NOT the mobile backend's own /chat/message. Separate Dio
// instance because it's a separate service/base URL and — unlike
// ApiClient — the agent has no user-auth model to attach a bearer token
// for, so no interceptor is needed here.

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ai_insurance_advisor/core/constants/api_constants.dart';

class AgentApiClient {
  late final Dio _dio;

  AgentApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.agentBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        // The agent's turn can involve several tool-calling round-trips to
        // the LLM before it replies — give it more room than a normal API call.
        receiveTimeout: const Duration(seconds: 45),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  Future<Map<String, dynamic>> sendMessage(
    String message, {
    String? conversationId,
    int? userId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    final Response<Map<String, dynamic>> response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.agentChatMessage,
      data: {
        'message': message,
        if (conversationId != null) 'conversation_id': conversationId,
        // Backend only actually uses these on the first turn of a new
        // conversation (see routers/chat.py's "known identity" handling),
        // but it's harmless/idempotent to send them every turn — simpler
        // than tracking "have we sent this yet" here too.
        if (userId != null) 'user_id': userId,
        if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
        if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Uploads one photo to platform/backend's POST /claims/{claim_id}/photos
  /// (see app/routers/photos.py) — this is the only client-side path that
  /// ever populates the `photos` table; nothing else in the app calls it.
  /// [claimId] only exists once the agent chat has recorded enough for
  /// _maybe_generate_constat to have upserted a draft Claim (see
  /// platform/backend/app/routers/chat.py) — the caller is responsible for
  /// not invoking this before ChatMessageOut.claim_id has come back non-null.
  Future<Map<String, dynamic>> uploadPhoto({
    required String claimId,
    required String vehicleLabel,
    required Uint8List bytes,
    required String filename,
  }) async {
    final formData = FormData.fromMap({
      'vehicle_label': vehicleLabel,
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final Response<Map<String, dynamic>> response = await _dio.post<Map<String, dynamic>>(
      '/claims/$claimId/photos',
      data: formData,
    );
    return response.data as Map<String, dynamic>;
  }
}
