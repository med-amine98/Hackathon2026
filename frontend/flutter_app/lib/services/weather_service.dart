// lib/services/weather_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ai_insurance_advisor/core/constants/api_constants.dart';

class WeatherService {
  static Future<Map<String, dynamic>> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final apiKey = ApiConstants.openWeatherApiKey;
      final baseUrl = ApiConstants.openWeatherBaseUrl;
      
      if (apiKey == 'VOTRE_CLE_OPENWEATHER') {
        throw Exception('❌ OpenWeather API key not configured. Veuillez ajouter votre clé dans le fichier .env');
      }

      final url = Uri.parse(
        '$baseUrl/weather'
        '?lat=$latitude'
        '&lon=$longitude'
        '&appid=$apiKey'
        '&units=metric'
        '&lang=fr'
      );

      print('🌤️ OpenWeather URL: $url');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ OpenWeather data received');
        return _parseWeatherData(data);
      } else if (response.statusCode == 401) {
        throw Exception('❌ Clé OpenWeather invalide. Vérifiez votre clé API dans le fichier .env');
      } else if (response.statusCode == 404) {
        throw Exception('❌ Ville non trouvée. Vérifiez les coordonnées');
      } else {
        throw Exception('❌ OpenWeather error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ WeatherService error: $e');
      rethrow;
    }
  }

  static Map<String, dynamic> _parseWeatherData(Map<String, dynamic> data) {
    try {
      final main = data['main'] as Map<String, dynamic>;
      final weather = (data['weather'] as List<dynamic>).first as Map<String, dynamic>;
      final wind = data['wind'] as Map<String, dynamic>;
      final sys = data['sys'] as Map<String, dynamic>;
      
      final weatherCode = weather['id'] as int? ?? 800;

      return {
        'temperature': (main['temp'] as num).toDouble(),
        'feels_like': (main['feels_like'] as num).toDouble(),
        'humidity': (main['humidity'] as num).toDouble(),
        'pressure': (main['pressure'] as num).toDouble(),
        'weathercode': weatherCode,
        'condition': _getWeatherCondition(weatherCode),
        'description': weather['description'] as String? ?? 'Variable',
        'icon': weather['icon'] as String? ?? '01d',
        'wind_speed': (wind['speed'] as num).toDouble(),
        'wind_deg': (wind['deg'] as num).toDouble(),
        'city': data['name'] as String? ?? 'Inconnue',
        'country': sys['country'] as String? ?? 'TN',
        'lastUpdate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Parse weather error: $e');
      throw Exception('Erreur lors du parsing des données météo: $e');
    }
  }

  static String _getWeatherCondition(int code) {
    if (code >= 200 && code < 300) return '⛈️ Orage';
    if (code >= 300 && code < 400) return '🌧️ Bruine';
    if (code >= 500 && code < 600) return '🌧️ Pluie';
    if (code >= 600 && code < 700) return '❄️ Neige';
    if (code >= 700 && code < 800) return '🌫️ Brouillard';
    if (code == 800) return '☀️ Ciel dégagé';
    if (code > 800 && code < 900) return '⛅ Partiellement nuageux';
    return '🌤️ Variable';
  }

  static String getWeatherIcon(String iconCode) {
    return 'https://openweathermap.org/img/wn/${iconCode}@2x.png';
  }

  static Map<String, Map<String, double>> get tunisianCities {
    return {
      'Tunis': {'lat': 36.8065, 'lon': 10.1815},
      'Sfax': {'lat': 34.7400, 'lon': 10.7600},
      'Sousse': {'lat': 35.8250, 'lon': 10.6360},
      'Ariana': {'lat': 36.8600, 'lon': 10.1900},
      'Bizerte': {'lat': 37.2700, 'lon': 9.8700},
      'Gabès': {'lat': 33.8800, 'lon': 10.1200},
      'Kairouan': {'lat': 35.6700, 'lon': 10.0900},
      'Gafsa': {'lat': 34.4200, 'lon': 8.7800},
    };
  }
}