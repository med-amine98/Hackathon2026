/// Détecte l'intention de l'utilisateur à partir de son message
class IntentDetector {
  static const Map<String, List<String>> _patterns = {
    'buy_car_insurance': [
      'assurance auto', 'assurer ma voiture', 'acheter assurance',
      'nouvelle voiture', 'véhicule', 'automobile',
      'je veux assurer', 'protection auto'
    ],
    'get_quote': [
      'devis', 'combien coûte', 'prix assurance', 'tarif',
      'estimation', 'coût'
    ],
    'compare_products': [
      'comparer', 'quelle assurance', 'meilleure offre',
      'comparatif', 'différence'
    ],
    'general_question': [
      'comment fonctionne', 'explique', 'aide', 'bonjour', 'salut'
    ]
  };

  String detectIntent(String message) {
    final lower = message.toLowerCase();
    
    for (var entry in _patterns.entries) {
      for (var pattern in entry.value) {
        if (lower.contains(pattern)) {
          return entry.key;
        }
      }
    }
    return 'general_question';
  }

  Map<String, dynamic>? extractEntities(String message) {
    final entities = <String, dynamic>{};
    final lower = message.toLowerCase();

    // Extraire l'âge
    final ageMatch = RegExp(r'(\d+)\s*ans').firstMatch(lower);
    if (ageMatch != null) {
      entities['age'] = int.parse(ageMatch.group(1)!);
    }

    // Extraire le budget
    final budgetMatch = RegExp(r'(\d+)\s*(?:dt|tnd|dinars)').firstMatch(lower);
    if (budgetMatch != null) {
      entities['budget'] = int.parse(budgetMatch.group(1)!);
    }

    // Extraire la voiture
    final carMatch = RegExp(r'(voiture|véhicule|auto)\s+(\w+)').firstMatch(lower);
    if (carMatch != null) {
      entities['vehicle'] = carMatch.group(2)!;
    }

    return entities.isEmpty ? null : entities;
  }
}