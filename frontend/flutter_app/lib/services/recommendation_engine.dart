/// Recommande les meilleures assurances en fonction du profil
class RecommendationEngine {
  static const List<Map<String, dynamic>> _products = [
    {
      'id': 'auto_protect_premium',
      'name': 'Auto Protect Premium',
      'provider': 'Assurance Tunisie',
      'monthly_premium': 85,
      'coverage': 150000,
      'features': [
        'Protection vol',
        'Assistance 24/7',
        'Protection juridique',
        'Véhicule de remplacement',
        'Bris de glace',
        'Dommages collision'
      ],
      'recommended_for': ['risk_high', 'budget_high']
    },
    {
      'id': 'auto_safe_plus',
      'name': 'Auto Safe Plus',
      'provider': 'Maghreb Assurance',
      'monthly_premium': 65,
      'coverage': 100000,
      'features': [
        'Protection vol',
        'Assistance 24/7',
        'Protection juridique',
        'Bris de glace'
      ],
      'recommended_for': ['risk_medium', 'budget_medium']
    },
    {
      'id': 'auto_essential',
      'name': 'Auto Essential',
      'provider': 'Assurance Tunisie',
      'monthly_premium': 45,
      'coverage': 50000,
      'features': [
        'Responsabilité civile',
        'Protection juridique',
        'Assistance de base'
      ],
      'recommended_for': ['risk_low', 'budget_low']
    },
    {
      'id': 'auto_super_protect',
      'name': 'Auto Super Protect',
      'provider': 'Star Assurance',
      'monthly_premium': 120,
      'coverage': 200000,
      'features': [
        'Protection vol',
        'Assistance 24/7',
        'Protection juridique',
        'Véhicule de remplacement',
        'Bris de glace',
        'Dommages collision',
        'Protection conducteur',
        'Rachat de franchise'
      ],
      'recommended_for': ['risk_high', 'budget_high', 'premium']
    }
  ];

  List<Map<String, dynamic>> getRecommendations(
    Map<String, dynamic> profile,
    Map<String, dynamic> riskResult
  ) {
    final level = riskResult['level'] as String? ?? 'Moyen';
    final budget = profile['budget_monthly'] as int?;

    var scored = _products.map((product) {
      var matchScore = 0;
      final reasons = <String>[];

      // ✅ Score basé sur le risque - CORRIGÉ avec cast explicite
      final recommendedFor = product['recommended_for'] as List<dynamic>? ?? [];
      
      if (level == 'Faible' && recommendedFor.contains('risk_low')) {
        matchScore += 25;
        reasons.add('✅ Adapté à votre profil à faible risque');
      } else if (level == 'Moyen' && recommendedFor.contains('risk_medium')) {
        matchScore += 25;
        reasons.add('✅ Adapté à votre profil à risque modéré');
      } else if (level == 'Élevé' && recommendedFor.contains('risk_high')) {
        matchScore += 30;
        reasons.add('✅ Couverture renforcée recommandée pour votre profil');
      }

      // ✅ Score basé sur le budget
      if (budget != null) {
        final premium = product['monthly_premium'] as int? ?? 0;
        if (premium <= budget) {
          matchScore += 30;
          reasons.add('✅ Dans votre budget ($premium TND/mois)');
        } else if (premium <= budget * 1.2) {
          matchScore += 15;
          reasons.add('⚠️ Légèrement au-dessus du budget ($premium TND/mois)');
        } else {
          reasons.add('❌ Au-dessus du budget ($premium TND/mois)');
        }
      }

      // ✅ Score basé sur les features - CORRIGÉ
      final features = product['features'] as List<dynamic>? ?? [];
      if (features.length > 5) {
        matchScore += 10;
        reasons.add('✅ Couverture complète');
      }

      return {
        ...product,
        'match_score': matchScore.clamp(0, 100),
        'match_reasons': reasons,
        'is_best': matchScore >= 70
      };
    }).toList();

    // Trier par score
    scored.sort((a, b) => (b['match_score'] as int).compareTo(a['match_score'] as int));

    return scored;
  }

  Map<String, dynamic> getBestMatch(List<Map<String, dynamic>> recommendations) {
    return recommendations.firstWhere(
      (r) => r['is_best'] == true,
      orElse: () => recommendations.first
    );
  }

  String generateRecommendationText(Map<String, dynamic> bestMatch) {
    final features = (bestMatch['features'] as List<dynamic>? ?? []).join('\n• ');
    final reasons = (bestMatch['match_reasons'] as List<dynamic>? ?? []).join('\n');
    
    return '''
🌟 **${bestMatch['name']}** par ${bestMatch['provider']}

💰 ${bestMatch['monthly_premium']} TND/mois
📋 Couverture : ${bestMatch['coverage']} TND

**Pourquoi ce choix ?**
$reasons

**Ce que ça couvre :**
• $features

✨ **Recommandation :** Cette offre est parfaitement adaptée à votre profil ! 🎯
''';
  }
}