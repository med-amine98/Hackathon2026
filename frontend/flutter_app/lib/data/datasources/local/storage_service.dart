// lib/data/datasources/local/storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userFirstNameKey = 'user_first_name';
  static const String _userLastNameKey = 'user_last_name';
  static const String _userPhoneKey = 'user_phone';
  static const String _userDataKey = 'user_data';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // ─── Token ───────────────────────────────────────────────────────────────
  String? get token => _prefs.getString(_tokenKey);
  bool get isLoggedIn => _prefs.containsKey(_tokenKey);
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  // ─── User ID ────────────────────────────────────────────────────────────
  int? get userId => _prefs.getInt(_userIdKey);
  Future<void> saveUserId(int userId) async {
    await _prefs.setInt(_userIdKey, userId);
  }

  // ─── User Email ─────────────────────────────────────────────────────────
  String? get userEmail => _prefs.getString(_userEmailKey);
  Future<void> saveUserEmail(String email) async {
    await _prefs.setString(_userEmailKey, email);
  }

  // ─── User First Name ────────────────────────────────────────────────────
  String? get userFirstName => _prefs.getString(_userFirstNameKey);
  Future<void> saveUserFirstName(String firstName) async {
    await _prefs.setString(_userFirstNameKey, firstName);
  }

  // ─── User Last Name ────────────────────────────────────────────────────
  String? get userLastName => _prefs.getString(_userLastNameKey);
  Future<void> saveUserLastName(String lastName) async {
    await _prefs.setString(_userLastNameKey, lastName);
  }

  // ─── User Phone ────────────────────────────────────────────────────────
  String? get userPhone => _prefs.getString(_userPhoneKey);
  Future<void> saveUserPhone(String? phone) async {
    if (phone != null) {
      await _prefs.setString(_userPhoneKey, phone);
    }
  }

  // ─── User Data (JSON) ──────────────────────────────────────────────────
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _prefs.setString(_userDataKey, jsonEncode(userData));
  }

  /// Retourne les données utilisateur décodées, ou null si absentes/invalides.
  Map<String, dynamic>? get userData {
    final raw = _prefs.getString(_userDataKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ─── Getters combinés ──────────────────────────────────────────────────
  String get userFullName {
    final firstName = userFirstName ?? '';
    final lastName = userLastName ?? '';
    return '$firstName $lastName'.trim();
  }

  String get userInitials {
    final firstName = userFirstName ?? '';
    final lastName = userLastName ?? '';
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}';
  }

  // ─── Clear ──────────────────────────────────────────────────────────────
  Future<void> clearAll() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_userEmailKey);
    await _prefs.remove(_userFirstNameKey);
    await _prefs.remove(_userLastNameKey);
    await _prefs.remove(_userPhoneKey);
    await _prefs.remove(_userDataKey);
    print('✅ Toutes les données effacées');
  }
}