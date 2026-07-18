// lib/core/constants/api_constants.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // ── Backend ──────────────────────────────────────────────────────────────
  static String get baseUrl {
    return dotenv.env['BACKEND_URL'] ?? 'http://localhost:8001/api/v1';
  }
  
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String profile = '/profile';
  static const String chatMessage = '/chat/message';
  static const String products = '/products';
  static const String recommendations = '/recommendations';

  // ── Agent (platform/backend — accident-intake chat, same Postgres as
  // above, different service/port) ────────────────────────────────────────
  static String get agentBaseUrl {
    return dotenv.env['AGENT_API_URL'] ?? 'http://localhost:8010';
  }

  static const String agentChatMessage = '/chat/message';

  // ── OpenAI ───────────────────────────────────────────────────────────────
  static String get openAIApiKey {
    return dotenv.env['OPENAI_API_KEY'] ?? 'VOTRE_CLE_OPENAI';
  }

  // ── OpenWeather ──────────────────────────────────────────────────────────
  static String get openWeatherApiKey {
    return dotenv.env['OPENWEATHER_API_KEY'] ?? 'bf0648407d93e7accce0564e0f184f88';
  }
  
  static String get openWeatherBaseUrl {
    return dotenv.env['OPENWEATHER_URL'] ?? 'https://api.openweathermap.org/data/2.5';
  }

  // ── TomTom ──────────────────────────────────────────────────────────────
  static String get tomtomApiKey {
    return dotenv.env['TOMTOM_API_KEY'] ?? 'VOTRE_CLE_TOMTOM';
  }
  
  static String get tomtomBaseUrl {
    return dotenv.env['TOMTOM_BASE_URL'] ?? 'https://api.tomtom.com/traffic/services/4';
  }
}