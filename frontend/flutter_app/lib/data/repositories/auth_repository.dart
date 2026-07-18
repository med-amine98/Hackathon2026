// lib/data/repositories/auth_repository.dart

import 'package:ai_insurance_advisor/data/datasources/remote/api_client.dart';
import 'package:ai_insurance_advisor/data/datasources/local/storage_service.dart';
import 'package:ai_insurance_advisor/data/models/user.dart';

class AuthRepository {
  final StorageService _storage;
  final ApiClient _apiClient;

  AuthRepository(this._storage, this._apiClient);

  bool get isLoggedIn => _storage.isLoggedIn;

  Future<User> login(String email, String password) async {
    try {
      print('📤 AuthRepository.login: email=$email');
      
      final data = await _apiClient.login(email, password);
      print('📥 AuthRepository.login response: $data');
      
      final token = data['token'] as String;
      final userData = data['user'] as Map<String, dynamic>;
      
      // ✅ Sauvegarder toutes les infos utilisateur
      await _storage.saveToken(token);
      await _storage.saveUserId(userData['id'] as int);
      await _storage.saveUserEmail(userData['email'] as String);
      await _storage.saveUserFirstName(userData['first_name'] as String);
      await _storage.saveUserLastName(userData['last_name'] as String);
      await _storage.saveUserPhone(userData['phone'] as String?);
      
      print('✅ AuthRepository.login successful, user: ${userData['email']}');
      
      return User.fromJson(userData);
    } catch (e) {
      print('❌ AuthRepository.login error: $e');
      rethrow;
    }
  }

  Future<User> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      print('📤 AuthRepository.register: email=$email');
      
      final data = await _apiClient.register({
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        if (phone != null) 'phone': phone,
      });
      
      print('📥 AuthRepository.register response: $data');
      
      final token = data['token'] as String;
      final userData = data['user'] as Map<String, dynamic>;
      
      await _storage.saveToken(token);
      await _storage.saveUserId(userData['id'] as int);
      await _storage.saveUserEmail(userData['email'] as String);
      await _storage.saveUserFirstName(userData['first_name'] as String);
      await _storage.saveUserLastName(userData['last_name'] as String);
      await _storage.saveUserPhone(userData['phone'] as String?);
      
      print('✅ AuthRepository.register successful, user: ${userData['email']}');
      
      return User.fromJson(userData);
    } catch (e) {
      print('❌ AuthRepository.register error: $e');
      rethrow;
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final token = _storage.token;
      if (token == null) {
        throw Exception('Non authentifié');
      }
      final data = await _apiClient.getMe();
      return User.fromJson(data);
    } catch (e) {
      print('❌ AuthRepository.getCurrentUser error: $e');
      rethrow;
    }
  }

  Future<User?> getStoredUser() async {
    try {
      final firstName = _storage.userFirstName;
      final lastName = _storage.userLastName;
      final email = _storage.userEmail;
      final id = _storage.userId;
      final phone = _storage.userPhone;
      
      if (firstName == null || lastName == null || email == null || id == null) {
        return null;
      }
      
      return User(
        id: id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        isActive: true,
        isVerified: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('❌ AuthRepository.getStoredUser error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _storage.clearAll();
      print('✅ AuthRepository.logout successful');
    } catch (e) {
      print('❌ AuthRepository.logout error: $e');
      rethrow;
    }
  }
}