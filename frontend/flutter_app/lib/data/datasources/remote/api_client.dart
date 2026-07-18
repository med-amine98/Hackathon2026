// lib/data/datasources/remote/api_client.dart

import 'package:dio/dio.dart';
import 'package:ai_insurance_advisor/core/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  late final Dio _dio;
  final SharedPreferences? _prefs;

  ApiClient({SharedPreferences? prefs, String? token}) : _prefs = prefs {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // ✅ Ajouter un intercepteur pour ajouter le token automatiquement
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Si un token est passé en paramètre, l'utiliser
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            return handler.next(options);
          }
          
          // Sinon, essayer de récupérer le token depuis SharedPreferences
          if (_prefs != null) {
            final savedToken = _prefs!.getString('auth_token');
            if (savedToken != null && savedToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $savedToken';
              print('✅ Token ajouté à la requête: ${options.path}');
            } else {
              print('❌ Aucun token trouvé pour: ${options.path}');
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            print('❌ Erreur 401: Token invalide ou expiré');
            // Optionnel: déclencher un événement de déconnexion
          }
          handler.next(e);
        },
      ),
    );
  }

  // ── Auth ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    print('📤 Login: email=$email');
    
    final Response<Map<String, dynamic>> response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    print('📤 Register: $userData');
    
    final Response<Map<String, dynamic>> response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.register, 
      data: userData,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe() async {
    final Response<Map<String, dynamic>> response = await _dio.get<Map<String, dynamic>>(
      ApiConstants.me,
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProfile() async {
    final Response<Map<String, dynamic>> response = await _dio.get<Map<String, dynamic>>(
      ApiConstants.profile,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    final Response<Map<String, dynamic>> response = await _dio.put<Map<String, dynamic>>(
      ApiConstants.profile, 
      data: profileData,
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Chat ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> sendMessage(String message, {int? conversationId}) async {
    final Response<Map<String, dynamic>> response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.chatMessage,
      data: {
        'message': message,
        if (conversationId != null) 'conversation_id': conversationId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Products ──────────────────────────────────────────────────────────────

  Future<List<dynamic>> getProducts({String? category}) async {
    final Response<List<dynamic>> response = await _dio.get<List<dynamic>>(
      ApiConstants.products,
      queryParameters: category != null ? {'category': category} : null,
    );
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getProduct(String id) async {
    final Response<Map<String, dynamic>> response = await _dio.get<Map<String, dynamic>>(
      '${ApiConstants.products}/$id',
    );
    return response.data as Map<String, dynamic>;
  }

  // ── Recommendations ───────────────────────────────────────────────────────

  Future<List<dynamic>> getRecommendations() async {
    final Response<List<dynamic>> response = await _dio.get<List<dynamic>>(
      ApiConstants.recommendations,
    );
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> acceptRecommendation(int id) async {
    final Response<Map<String, dynamic>> response = await _dio.post<Map<String, dynamic>>(
      '${ApiConstants.recommendations}/$id/accept',
    );
    return response.data as Map<String, dynamic>;
  }
}