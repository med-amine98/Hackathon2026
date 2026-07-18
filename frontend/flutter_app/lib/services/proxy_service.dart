// lib/services/proxy_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ProxyService {
  static const String corsProxy = 'https://cors-anywhere.herokuapp.com/';

  static Future<Map<String, dynamic>> proxyRequest(String url) async {
    try {
      final proxyUrl = '$corsProxy$url';
      print('🔄 Proxy URL: $proxyUrl');
      
      final response = await http.get(
        Uri.parse(proxyUrl),
        headers: {
          'Origin': 'http://localhost',
          'User-Agent': 'Mozilla/5.0',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('⏰ Timeout - Le serveur proxy ne répond pas');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data as Map<String, dynamic>;
      } else {
        throw Exception('⚠️ Erreur proxy: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Proxy error: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> proxyRequestList(String url) async {
    try {
      final proxyUrl = '$corsProxy$url';
      print('🔄 Proxy URL: $proxyUrl');
      
      final response = await http.get(
        Uri.parse(proxyUrl),
        headers: {
          'Origin': 'http://localhost',
          'User-Agent': 'Mozilla/5.0',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('⏰ Timeout - Le serveur proxy ne répond pas');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data as List<dynamic>;
      } else {
        throw Exception('⚠️ Erreur proxy: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Proxy error: $e');
      rethrow;
    }
  }
}