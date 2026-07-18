// lib/data/repositories/profile_repository.dart

import 'package:ai_insurance_advisor/data/datasources/remote/api_client.dart';

class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository(this._apiClient);

  Future<Map<String, dynamic>> getProfile() async {
    try {
      print('📤 ProfileRepository.getProfile - appel API');
      final data = await _apiClient.getProfile();
      print('📥 ProfileRepository.getProfile - réponse reçue');
      return data;
    } catch (e) {
      print('❌ ProfileRepository.getProfile error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      print('📤 ProfileRepository.updateProfile');
      final data = await _apiClient.updateProfile(profileData);
      return data;
    } catch (e) {
      print('❌ ProfileRepository.updateProfile error: $e');
      rethrow;
    }
  }
}