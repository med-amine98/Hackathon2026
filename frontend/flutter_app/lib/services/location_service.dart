// lib/services/location_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Le service de localisation est désactivé');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permission de localisation refusée');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permission de localisation refusée définitivement');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static Future<Map<String, String>> getCityFromPosition(Position position) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?'
        'lat=${position.latitude}&'
        'lon=${position.longitude}&'
        'format=json&'
        'accept-language=fr'
      );
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        // ✅ Cast explicite en Map<String, dynamic>
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        
        // ✅ Cast explicite pour les valeurs
        final city = address?['city'] as String? ?? 
                     address?['town'] as String? ?? 
                     address?['village'] as String? ?? 
                     'Tunis';
        final country = address?['country'] as String? ?? 'Tunisie';
        
        return {
          'city': city,
          'country': country,
        };
      }
    } catch (e) {
      print('❌ Geocoding error: $e');
    }
    return {'city': 'Tunis', 'country': 'Tunisie'};
  }
}