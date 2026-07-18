// lib/core/services/risk_prediction_service.dart

import 'dart:math';
import 'package:flutter/material.dart'; // ✅ Ajout pour Color et Colors

class RiskPredictionService {
  static final RiskPredictionService _instance = RiskPredictionService._internal();
  factory RiskPredictionService() => _instance;
  RiskPredictionService._internal();

  final Random _random = Random();

  /// Prédit le score de risque (0-100) basé sur plusieurs facteurs
  double predictRiskScore(Map<String, dynamic> profile) {
    final age = profile['age'] as int? ?? 30;
    final vehicleYear = profile['vehicle_year'] as int? ?? 2020;
    final annualKm = profile['annual_km'] as int? ?? 15000;
    final city = profile['city'] as String? ?? 'Tunis';
    final vehicleUsage = profile['vehicle_usage'] as String? ?? 'Personnel';
    final occupation = profile['occupation'] as String? ?? 'Employé';

    // 1. Facteur Âge
    double ageRisk = 0;
    if (age < 25) {
      ageRisk = 0.9;
    } else if (age < 30) {
      ageRisk = 0.6;
    } else if (age < 40) {
      ageRisk = 0.4;
    } else if (age < 50) {
      ageRisk = 0.3;
    } else {
      ageRisk = 0.5;
    }

    // 2. Facteur Véhicule
    final currentYear = DateTime.now().year;
    final vehicleAge = currentYear - vehicleYear;
    double vehicleRisk = 0;
    if (vehicleAge > 10) {
      vehicleRisk = 0.8;
    } else if (vehicleAge > 5) {
      vehicleRisk = 0.5;
    } else {
      vehicleRisk = 0.2;
    }

    // 3. Facteur Kilométrage
    double kmRisk = 0;
    if (annualKm > 30000) {
      kmRisk = 0.9;
    } else if (annualKm > 20000) {
      kmRisk = 0.6;
    } else if (annualKm > 10000) {
      kmRisk = 0.4;
    } else {
      kmRisk = 0.2;
    }

    // 4. Facteur Ville
    final highRiskCities = ['Tunis', 'Sfax', 'Sousse', 'Ariana', 'Ben Arous'];
    double cityRisk = highRiskCities.contains(city) ? 0.5 : 0.3;

    // 5. Facteur Utilisation
    double usageRisk = 0;
    switch (vehicleUsage.toLowerCase()) {
      case 'professionnel':
        usageRisk = 0.7;
        break;
      case 'mixte':
        usageRisk = 0.5;
        break;
      default:
        usageRisk = 0.3;
    }

    // 6. Facteur Profession
    final highRiskProfessions = ['Chauffeur', 'Livreur', 'Commercial', 'VRP'];
    double occupationRisk = highRiskProfessions.any((p) => occupation.contains(p)) ? 0.6 : 0.3;

    // 7. Facteur historique
    final hasHistory = profile['has_history'] as bool? ?? true;
    double historyRisk = hasHistory ? 0.2 : 0.6;

    // Calcul du score pondéré
    final weights = {
      'age': 0.15,
      'vehicle': 0.20,
      'km': 0.15,
      'city': 0.10,
      'usage': 0.15,
      'occupation': 0.10,
      'history': 0.15,
    };

    double weightedScore = 
      (ageRisk * weights['age']!) +
      (vehicleRisk * weights['vehicle']!) +
      (kmRisk * weights['km']!) +
      (cityRisk * weights['city']!) +
      (usageRisk * weights['usage']!) +
      (occupationRisk * weights['occupation']!) +
      (historyRisk * weights['history']!);

    final noise = _random.nextDouble() * 0.05 - 0.025;
    double finalScore = (weightedScore * 100) + (noise * 100);
    
    return finalScore.clamp(0.0, 100.0);
  }

  /// Obtient les facteurs de risque détaillés
  List<String> getRiskFactors(Map<String, dynamic> profile) {
    final factors = <String>[];
    final score = predictRiskScore(profile);
    
    final age = profile['age'] as int? ?? 30;
    if (age < 25) {
      factors.add('Âge jeune (moins de 25 ans)');
    } else if (age > 65) {
      factors.add('Âge avancé (plus de 65 ans)');
    }

    final vehicleYear = profile['vehicle_year'] as int? ?? 2020;
    final currentYear = DateTime.now().year;
    if (currentYear - vehicleYear > 10) {
      factors.add('Véhicule de plus de 10 ans');
    }

    final annualKm = profile['annual_km'] as int? ?? 15000;
    if (annualKm > 30000) {
      factors.add('Kilométrage annuel très élevé (+30 000 km)');
    } else if (annualKm > 20000) {
      factors.add('Kilométrage annuel élevé (+20 000 km)');
    }

    final city = profile['city'] as String? ?? 'Tunis';
    final highRiskCities = ['Tunis', 'Sfax', 'Sousse', 'Ariana', 'Ben Arous'];
    if (highRiskCities.contains(city)) {
      factors.add('Conduite en grande ville ($city)');
    }

    final vehicleUsage = profile['vehicle_usage'] as String? ?? 'Personnel';
    if (vehicleUsage.toLowerCase() == 'professionnel') {
      factors.add('Utilisation professionnelle du véhicule');
    }

    if (score > 70) {
      factors.add('Score de risque élevé');
    }

    return factors;
  }

  /// Obtient des recommandations personnalisées
  List<String> getRecommendations(Map<String, dynamic> profile) {
    final recommendations = <String>[];
    final score = predictRiskScore(profile);

    if (score > 70) {
      recommendations.add('🚗 Réduisez votre kilométrage annuel');
      recommendations.add('🛡️ Souscrivez à une assurance tous risques');
      recommendations.add('📅 Faites vérifier votre véhicule régulièrement');
      recommendations.add('📚 Suivez un stage de conduite défensive');
    } else if (score > 40) {
      recommendations.add('🔧 Entretenez régulièrement votre véhicule');
      recommendations.add('📝 Vérifiez vos garanties d\'assurance');
      recommendations.add('🚦 Adoptez une conduite préventive');
    } else if (score > 0) {
      recommendations.add('✅ Continuez à maintenir de bonnes pratiques');
      recommendations.add('📊 Surveillez votre score régulièrement');
      recommendations.add('🔒 Assurez-vous que vos documents sont à jour');
    } else {
      recommendations.add('📝 Complétez votre profil pour des recommandations personnalisées');
    }

    return recommendations;
  }

  /// Obtient le niveau de risque
  String getRiskLevel(double score) {
    if (score == 0) return 'Non évalué';
    if (score >= 70) return 'Faible';
    if (score >= 40) return 'Moyen';
    return 'Élevé';
  }

  /// Obtient la couleur du risque
  Color getRiskColor(double score) {
    if (score == 0) return Colors.grey;
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  /// Obtient la description du risque
  String getRiskDescription(double score) {
    if (score == 0) {
      return 'Complétez votre profil pour obtenir une évaluation personnalisée de votre risque.';
    }
    if (score >= 70) {
      return 'Excellent ! Votre profil présente un faible risque. Vous bénéficiez des meilleurs tarifs.';
    }
    if (score >= 40) {
      return 'Votre profil présente un risque modéré. Quelques ajustements peuvent améliorer votre score.';
    }
    return 'Votre profil présente un risque élevé. Nous vous recommandons de consulter nos conseils de sécurité.';
  }
}