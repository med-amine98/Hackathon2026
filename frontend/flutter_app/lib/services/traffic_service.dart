// lib/services/traffic_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:ai_insurance_advisor/core/constants/api_constants.dart';

class TrafficService {
  static const String _baseUrl = 'https://api.tomtom.com/traffic/services/4';

  static Future<Map<String, dynamic>> getTrafficIncidents({
    required double lat,
    required double lon,
    int radius = 5000,
  }) async {
    try {
      final apiKey = ApiConstants.tomtomApiKey;
      
      if (apiKey == 'VOTRE_CLE_TOMTOM') {
        print('⚠️ Clé TomTom non configurée');
        return _getMockTrafficData();
      }

      final bbox = _getBoundingBox(lat, lon, radius);
      
      final url = Uri.parse(
        '$_baseUrl/incidentDetails'
        '?key=$apiKey'
        '&bbox=$bbox'
        '&language=fr-FR'
        '&fields={incidents{geometry{coordinates},properties{category,from,to,delay}}}'
        '&categoryFilter=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14'
      );

      print('🚦 Traffic URL: $url');
      
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏰ Timeout - API TomTom');
          return http.Response('{"error": "timeout"}', 408);
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ Traffic data received');
        return _parseTrafficData(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('❌ Clé TomTom invalide ou non activée pour Traffic API');
        return _getMockTrafficData();
      } else {
        print('❌ Traffic API error: ${response.statusCode}');
        return _getMockTrafficData();
      }
    } catch (e) {
      print('❌ TrafficService error: $e');
      return _getMockTrafficData();
    }
  }

  static Map<String, dynamic> _parseTrafficData(Map<String, dynamic> data) {
    final incidents = data['incidents'] as List<dynamic>? ?? <dynamic>[];
    
    final trafficIncidents = incidents.map((incident) {
      final props = incident['properties'] as Map<String, dynamic>? ?? {};
      final category = props['category'] as int? ?? 0;
      
      return <String, dynamic>{
        'type': _getCategoryName(category),
        'category': category,
        'description': props['from'] as String? ?? 'Incident de circulation',
        'location': props['to'] as String? ?? 'Route',
        'delay': props['delay'] as int? ?? 0,
        'icon': _getCategoryIcon(category),
      };
    }).toList();

    final totalDelay = trafficIncidents.fold<int>(
      0, 
      (sum, item) => sum + (item['delay'] as int? ?? 0)
    );

    return {
      'isCongested': trafficIncidents.isNotEmpty || totalDelay > 10,
      'incidentCount': trafficIncidents.length,
      'totalDelay': totalDelay,
      'incidents': trafficIncidents,
      'trafficLevel': _getTrafficLevel(totalDelay),
      'lastUpdate': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> _getMockTrafficData() {
    return {
      'isCongested': false,
      'incidentCount': 0,
      'totalDelay': 0,
      'incidents': <dynamic>[],
      'trafficLevel': 'Fluide',
      'lastUpdate': DateTime.now().toIso8601String(),
    };
  }

  static String _getTrafficLevel(int delay) {
    if (delay > 30) return 'Très dense';
    if (delay > 15) return 'Dense';
    if (delay > 5) return 'Modéré';
    return 'Fluide';
  }

  static String _getCategoryName(int category) {
    switch (category) {
      case 0: return 'Accident';
      case 1: return 'Congestion';
      case 2: return 'Incident';
      case 3: return 'Météo';
      case 4: return 'Route barrée';
      case 5: return 'Chantier';
      case 8: return 'Information';
      case 11: return 'Animal';
      case 12: return 'Véhicule en panne';
      default: return 'Incident';
    }
  }

  static String _getCategoryIcon(int category) {
    switch (category) {
      case 0: return '🚗';
      case 1: return '🚦';
      case 2: return '⚠️';
      case 3: return '🌧️';
      case 4: return '🚧';
      case 5: return '🔧';
      case 8: return 'ℹ️';
      case 11: return '🐕';
      case 12: return '🛑';
      default: return '⚠️';
    }
  }

  static String _getBoundingBox(double lat, double lon, int radius) {
    final latOffset = radius / 111000.0;
    final lonOffset = radius / (111000.0 * cos(lat * 3.14159 / 180));
    
    final minLat = lat - latOffset;
    final maxLat = lat + latOffset;
    final minLon = lon - lonOffset;
    final maxLon = lon + lonOffset;
    
    return '$minLon,$minLat,$maxLon,$maxLat';
  }
}