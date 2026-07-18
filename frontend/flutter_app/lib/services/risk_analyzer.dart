/// Analyse les risques du client et retourne un score
class RiskAnalyzer {
  Map<String, dynamic> calculateRisk(Map<String, dynamic> profile) {
    int score = 0;
    final factors = <String>[];

    // 1. Âge
    final age = profile['age'] as int?;
    if (age != null) {
      if (age < 22) {
        score += 25;
        factors.add('Jeune conducteur (moins de 22 ans)');
      } else if (age < 25) {
        score += 20;
        factors.add('Jeune conducteur (moins de 25 ans)');
      } else if (age > 70) {
        score += 15;
        factors.add('Conducteur senior (plus de 70 ans)');
      }
    }

    // 2. Kilométrage
    final km = profile['annual_km'] as int?;
    if (km != null) {
      if (km > 30000) {
        score += 20;
        factors.add('Kilométrage très élevé (+30000 km/an)');
      } else if (km > 20000) {
        score += 15;
        factors.add('Kilométrage élevé (+20000 km/an)');
      } else if (km > 15000) {
        score += 10;
        factors.add('Kilométrage moyen');
      }
    }

    // 3. Utilisation
    final usage = profile['vehicle_usage'] as String?;
    if (usage != null) {
      if (usage.contains('quotidien')) {
        score += 15;
        factors.add('Utilisation quotidienne');
      }
    }

    // 4. Ville (Tunis, Sfax, Sousse = plus de risques)
    final city = profile['city'] as String?;
    if (city != null) {
      final highRiskCities = ['Tunis', 'Sfax', 'Sousse', 'Ariana'];
      if (highRiskCities.any((c) => city.contains(c))) {
        score += 10;
        factors.add('Zone à fort trafic');
      }
    }

    // 5. Âge du véhicule
    final year = profile['vehicle_year'] as int?;
    if (year != null) {
      final ageVehicle = DateTime.now().year - year;
      if (ageVehicle > 15) {
        score += 10;
        factors.add('Véhicule ancien (+15 ans)');
      } else if (ageVehicle > 10) {
        score += 5;
        factors.add('Véhicule de plus de 10 ans');
      }
    }

    // Déterminer le niveau de risque
    String level;
    if (score < 30) {
      level = 'Faible';
    } else if (score < 60) {
      level = 'Moyen';
    } else {
      level = 'Élevé';
    }

    return {
      'score': score,
      'level': level,
      'factors': factors,
      'max_score': 100,
      'recommendation': _getRecommendation(level, factors)
    };
  }

  String _getRecommendation(String level, List<String> factors) {
    if (level == 'Faible') {
      return 'Vous présentez un profil à faible risque. Vous pouvez bénéficier des meilleurs tarifs.';
    } else if (level == 'Moyen') {
      return 'Vous présentez un profil à risque modéré. Une couverture complète est recommandée.';
    } else {
      return 'Vous présentez un profil à risque élevé. Il est recommandé d\'opter pour une couverture renforcée.';
    }
  }

  Map<String, String> getRiskBreakdown(Map<String, dynamic> profile) {
    // ✅ CORRIGÉ : Cast explicite en String avec ?? pour les valeurs null
    final ageValue = profile['age'] as int?;
    final kmValue = profile['annual_km'] as int?;
    final usageValue = profile['vehicle_usage'] as String?;
    final cityValue = profile['city'] as String?;

    return {
      'Âge': ageValue != null ? '$ageValue ans' : 'Non renseigné',
      'Kilométrage': kmValue != null ? '$kmValue km/an' : 'Non renseigné',
      'Utilisation': usageValue ?? 'Non renseignée',
      'Ville': cityValue ?? 'Non renseignée',
    };
  }
}