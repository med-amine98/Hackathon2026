// lib/services/prevention_service.dart

import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ai_insurance_advisor/core/constants/api_constants.dart';
import 'package:ai_insurance_advisor/models/vehicle_model.dart';

class PreventionService {
  static const String _openWeatherUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _tomTomUrl = 'https://api.tomtom.com/traffic/services/4';
  static const String _openAIUrl = 'https://api.openai.com/v1/chat/completions';

  static Future<Map<String, dynamic>> getWeatherAlerts({
    required double latitude,
    required double longitude,
  }) async {
    final apiKey = ApiConstants.openWeatherApiKey;
    
    if (apiKey == 'VOTRE_CLE_OPENWEATHER' || apiKey.isEmpty) {
      throw Exception('⚠️ Clé OpenWeather non configurée');
    }

    final url = Uri.parse(
      '$_openWeatherUrl/weather'
      '?lat=$latitude'
      '&lon=$longitude'
      '&appid=$apiKey'
      '&units=metric'
      '&lang=fr'
    );

    print('🌤️ Weather Alert URL: $url');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseWeatherAlerts(data);
    } else {
      throw Exception('⚠️ Erreur météo: ${response.statusCode}');
    }
  }

  static Map<String, dynamic> _parseWeatherAlerts(Map<String, dynamic> data) {
    final main = data['main'] as Map<String, dynamic>;
    final weather = (data['weather'] as List<dynamic>).first as Map<String, dynamic>;
    final wind = data['wind'] as Map<String, dynamic>;
    
    final temp = (main['temp'] as num).toDouble();
    final description = weather['description'] as String? ?? 'Variable';
    final humidity = (main['humidity'] as num).toDouble();
    final windSpeed = (wind['speed'] as num).toDouble();
    
    final alerts = <String>[];
    
    if (temp > 35) {
      alerts.add('🌡️ Alerte chaleur: ${temp.toStringAsFixed(0)}°C - Risque de surchauffe moteur');
    }
    
    final descLower = description.toLowerCase();
    if (descLower.contains('pluie') || descLower.contains('averse')) {
      alerts.add('🌧️ Alerte pluie: Réduisez votre vitesse, risque d\'aquaplaning');
    }
    
    if (windSpeed > 50) {
      alerts.add('💨 Alerte vent fort: ${windSpeed.toStringAsFixed(0)} km/h - Conduite dangereuse');
    }
    
    if (descLower.contains('brouillard') || descLower.contains('brume')) {
      alerts.add('🌫️ Alerte brouillard: Visibilité réduite, allumez vos feux');
    }
    
    if (descLower.contains('neige')) {
      alerts.add('❄️ Alerte neige: Routes glissantes, équipement recommandé');
    }

    if (humidity > 80 && temp > 25) {
      alerts.add('💧 Humidité élevée: Risque de buée sur les vitres');
    }

    return {
      'temperature': temp.toStringAsFixed(0),
      'condition': description,
      'humidity': humidity.toStringAsFixed(0),
      'wind_speed': windSpeed.toStringAsFixed(0),
      'alerts': alerts,
      'city': data['name'] as String? ?? 'Tunis',
    };
  }

  static Future<List<Map<String, dynamic>>> getTrafficAlerts({
    required double latitude,
    required double longitude,
  }) async {
    final apiKey = ApiConstants.tomtomApiKey;
    
    if (apiKey == 'VOTRE_CLE_TOMTOM' || apiKey.isEmpty) {
      throw Exception('⚠️ Clé TomTom non configurée');
    }

    final bbox = _getBoundingBox(latitude, longitude, 5000);
    
    final url = Uri.parse(
      '$_tomTomUrl/incidentDetails'
      '?key=$apiKey'
      '&bbox=$bbox'
      '&language=fr-FR'
      '&fields={incidents{properties{category,from,to,delay}}}'
      '&categoryFilter=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14'
    );

    print('🚦 Traffic Alert URL: $url');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseTrafficAlerts(data);
    } else {
      throw Exception('⚠️ Erreur trafic: ${response.statusCode}');
    }
  }

  static List<Map<String, dynamic>> _parseTrafficAlerts(Map<String, dynamic> data) {
    final incidents = data['incidents'] as List<dynamic>? ?? [];
    
    return incidents.map((incident) {
      final props = incident['properties'] as Map<String, dynamic>? ?? {};
      final category = props['category'] as int? ?? 0;
      final delay = props['delay'] as int? ?? 0;
      
      return {
        'type': _getCategoryName(category),
        'description': props['from'] as String? ?? 'Incident de circulation',
        'location': props['to'] as String? ?? 'Route',
        'delay': delay,
        'icon': _getCategoryIcon(category),
        'severity': delay > 15 ? 'élevée' : delay > 5 ? 'moyenne' : 'faible',
      };
    }).toList();
  }

  static Future<List<String>> getAIAlerts({
    required VehicleModel vehicle,
    required Map<String, dynamic> weather,
    required List<Map<String, dynamic>> traffic,
  }) async {
    final apiKey = ApiConstants.openAIApiKey;
    
    if (apiKey == 'VOTRE_CLE_OPENAI') {
      throw Exception('⚠️ Clé OpenAI non configurée');
    }

    final prompt = '''
Analyse la situation suivante et génère 3 à 5 alertes de sécurité personnalisées:

**Véhicule:** ${vehicle.fullName} (${vehicle.year})
**Kilométrage annuel:** ${vehicle.annualKm} km
**Météo:** ${weather['condition']} - ${weather['temperature']}°C
**Trafic:** ${traffic.length} incident(s) signalé(s)

Génère des alertes concrètes pour aider le conducteur à:
1. Adapter sa conduite
2. Vérifier son véhicule
3. Anticiper les risques
4. Planifier son trajet

Réponds en français, sous forme de liste numérotée, avec des conseils pratiques et précis.
''';

    final response = await http.post(
      Uri.parse(_openAIUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': 'Tu es un expert en sécurité routière.'},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.5,
        'max_tokens': 300,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['choices'][0]['message']['content'] as String;
      return content.split('\n').where((line) => line.trim().isNotEmpty).toList();
    } else {
      throw Exception('⚠️ Erreur OpenAI: ${response.statusCode}');
    }
  }

  static String _getCategoryName(int category) {
    switch (category) {
      case 0: return 'Accident';
      case 1: return 'Congestion';
      case 2: return 'Incident divers';
      case 3: return 'Conditions météo';
      case 4: return 'Route barrée';
      case 5: return 'Chantier';
      case 8: return 'Information';
      case 11: return 'Animal sur la route';
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

  static List<Map<String, dynamic>> getMaintenanceAlerts(VehicleModel vehicle) {
    final alerts = <Map<String, dynamic>>[];
    
    final currentKm = vehicle.annualKm;
    
    final lastOilChange = currentKm ~/ 15000 * 15000;
    final nextOilChange = lastOilChange + 15000;
    final kmToOilChange = nextOilChange - currentKm;
    
    if (kmToOilChange < 1000) {
      alerts.add({
        'title': 'Vidange d\'huile',
        'description': kmToOilChange < 500 
            ? 'URGENT: Vidange à faire immédiatement'
            : 'Vidange à prévoir dans ${kmToOilChange} km',
        'icon': 'Icons.oil_barrel',
        'color': kmToOilChange < 500 ? '#EF4444' : '#F59E0B',
        'urgent': kmToOilChange < 500,
        'date': DateTime.now().add(Duration(days: kmToOilChange ~/ 30)).toString(),
      });
    }
    
    alerts.add({
      'title': 'Contrôle des pneus',
      'description': 'Vérification de la pression et de l\'usure',
      'icon': 'Icons.speed',
      'color': '#3B82F6',
      'urgent': false,
      'date': DateTime.now().add(const Duration(days: 30)).toString(),
    });
    
    if (currentKm > 10000) {
      alerts.add({
        'title': 'Plaquettes de frein',
        'description': currentKm > 20000 
            ? 'URGENT: Plaquettes à remplacer' 
            : 'Contrôle des freins recommandé',
        'icon': 'Icons.car_repair',
        'color': currentKm > 20000 ? '#EF4444' : '#F59E0B',
        'urgent': currentKm > 20000,
        'date': DateTime.now().add(const Duration(days: 45)).toString(),
      });
    }
    
    alerts.add({
      'title': 'Batterie',
      'description': 'Contrôle recommandé avant l\'hiver',
      'icon': 'Icons.battery_full',
      'color': '#10B981',
      'urgent': false,
      'date': DateTime.now().add(const Duration(days: 60)).toString(),
    });
    
    return alerts;
  }
}