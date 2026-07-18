/// Templates de prompts pour l'assistant IA
class AssistantPrompts {
  static String getWelcomeMessage(String intent) {
    switch (intent) {
      case 'buy_car_insurance':
        return '''
Bonjour et bienvenue.

Je suis ravi de vous accueillir. Mon rôle est de vous accompagner dans le choix de votre assurance automobile, en toute simplicité et transparence.

Pour que je puisse vous proposer des options réellement adaptées à votre situation, je vais vous poser quelques questions. Cela ne vous prendra que quelques minutes, et vous pourrez modifier vos réponses à tout moment.

Nous pouvons commencer quand vous êtes prêt.
''';
      case 'get_quote':
        return '''
Bonjour et merci de faire confiance à notre service.

Je vais vous aider à obtenir un devis personnalisé, basé sur votre profil et vos besoins réels. Plus les informations que vous me donnerez seront précises, plus les offres que je vous proposeront seront pertinentes.

Alors, par quoi souhaitez-vous commencer ?
''';
      case 'compare_products':
        return '''
Bonjour.

Vous souhaitez comparer différentes offres d'assurance, c'est une excellente démarche. Pour vous aider à y voir plus clair, je vais analyser plusieurs critères importants : le niveau de couverture, le prix, les garanties incluses et les options disponibles.

Pouvez-vous me donner quelques informations sur votre véhicule et votre utilisation ?
''';
      default:
        return '''
Bonjour, je suis votre conseiller IA.

Je suis là pour vous écouter et vous aider à trouver l'assurance qui vous convient le mieux, sans pression et avec des conseils clairs.

Comment puis-je vous être utile aujourd'hui ?
''';
    }
  }

  static String getProfileCompleteMessage(Map<String, dynamic> profile) {
    final age = profile['age'] ?? 'Non renseigné';
    final city = profile['city'] ?? 'Non renseignée';
    final vehicleMake = profile['vehicle_make'] ?? 'Non renseignée';
    final vehicleModel = profile['vehicle_model'] ?? 'Non renseigné';
    final vehicleYear = profile['vehicle_year'] ?? 'Non renseigné';
    final annualKm = profile['annual_km'] ?? 'Non renseigné';
    final vehicleUsage = profile['vehicle_usage'] ?? 'Non renseignée';
    final budget = profile['budget_monthly'] ?? 'Non renseigné';

    return '''
Merci d'avoir pris le temps de répondre à mes questions. J'ai maintenant une bonne vision de votre profil.

Voici ce que j'ai retenu :

Vous avez $age ans et vous habitez à $city.
Votre véhicule est une $vehicleMake $vehicleModel de $vehicleYear.
Vous parcourez environ $annualKm kilomètres par an.
Vous l'utilisez $vehicleUsage.
Votre budget mensuel est d'environ $budget TND.

Je vais maintenant analyser ces informations pour identifier les offres les plus adaptées à votre situation. Je prends en compte à la fois votre profil, vos habitudes de conduite et votre budget.

Je vous propose de découvrir les recommandations ci-dessous.
''';
  }

  static String getQuestionPrompt(String field, String question) {
    // Questions plus humaines et variées selon le champ
    final contextPhrases = {
      'age': 'Pour adapter les offres à votre profil, j\'ai besoin de connaître votre âge.',
      'city': 'La ville où vous habitez peut influencer le coût de l\'assurance. Où résidez-vous ?',
      'vehicle_make': 'Quelle est la marque de votre véhicule ? Cela m\'aide à évaluer les risques.',
      'vehicle_model': 'Et le modèle exact ?',
      'vehicle_year': 'Quelle est l\'année de mise en circulation ?',
      'annual_km': 'Le kilométrage annuel est un facteur important. Combien de kilomètres parcourez-vous en moyenne par an ?',
      'budget_monthly': 'Avez-vous une idée du budget que vous souhaitez consacrer chaque mois à votre assurance ?',
      'vehicle_usage': 'Comment utilisez-vous votre véhicule au quotidien ?',
    };

    final context = contextPhrases[field] ?? '';

    return '''
$question

$context

Je vous invite à répondre simplement et honnêtement, cela me permettra de vous proposer les meilleures options.
''';
  }

  static String getFallbackMessage() {
    return '''
Je suis désolé, je n\'ai pas bien compris votre réponse.

Peut-être pourriez-vous reformuler ou répondre à la question posée différemment ?

Je suis là pour vous aider, et parfois il faut simplement essayer autrement. N\'hésitez pas à me poser des questions si quelque chose n\'est pas clair.
''';
  }

  static String getGoodbyeMessage() {
    return '''
Merci d\'avoir pris le temps de discuter avec moi.

J\'espère que les informations que je vous ai partagées vous seront utiles.

Si vous avez d\'autres questions ou souhaitez revenir plus tard, je serai ravi de vous retrouver.

Prenez soin de vous et bonne route.
''';
  }

  static String getRecommendationIntro(Map<String, dynamic> bestMatch) {
    final provider = bestMatch['provider'] ?? 'notre partenaire';
    final name = bestMatch['name'] ?? 'offre recommandée';
    final premium = bestMatch['monthly_premium'] ?? 'un prix compétitif';

    return '''
Après analyse de votre profil, j'ai sélectionné une offre qui me semble particulièrement adaptée.

Il s'agit de $name, proposée par $provider, avec une prime mensuelle d'environ $premium TND.

Je vais vous expliquer pourquoi cette offre correspond à vos besoins.
''';
  }

  static String getRiskExplanation(Map<String, dynamic> riskResult) {
    final level = riskResult['level'] ?? 'modéré';
    final factors = riskResult['factors'] as List<String>? ?? [];
    final score = riskResult['score'] ?? 0;

    String levelDescription;
    switch (level) {
      case 'Faible':
        levelDescription = 'votre profil présente un risque faible, ce qui est très favorable pour bénéficier de tarifs avantageux.';
        break;
      case 'Moyen':
        levelDescription = 'votre profil présente un risque modéré, ce qui est courant pour la plupart des conducteurs.';
        break;
      case 'Élevé':
        levelDescription = 'votre profil présente un risque plus élevé, ce qui signifie qu\'une couverture renforcée est recommandée.';
        break;
      default:
        levelDescription = 'votre profil a été analysé avec soin.';
    }

    final factorsText = factors.isNotEmpty
        ? 'Voici les éléments qui ont été pris en compte : ${factors.join(', ')}.'
        : 'Tous les aspects de votre profil ont été examinés attentivement.';

    return '''
Concernant l\'évaluation des risques, $levelDescription

$factorsText

Le score global est de $score sur 100, ce qui me permet d\'orienter mes recommandations vers les offres les plus cohérentes avec votre situation.
''';
  }

  static String getAdviceOnBudget(int budget, int premium) {
    if (premium <= budget) {
      return '''
Cette offre entre dans votre budget, ce qui est un bon point. Vous bénéficiez d'une couverture solide sans dépasser le montant que vous aviez prévu.
''';
    } else if (premium <= budget * 1.2) {
      return '''
Cette offre est légèrement au-dessus de votre budget initial, mais elle apporte des garanties supplémentaires qui pourraient valoir cet écart. Je vous invite à peser le rapport qualité-prix.
''';
    } else {
      return '''
Cette offre dépasse votre budget, mais je l'ai incluse car elle offre une couverture très complète. Si vous le souhaitez, je peux chercher des alternatives mieux alignées avec votre budget.
''';
    }
  }

  static String getClosingMessage() {
    return '''
J'espère que ces recommandations vous seront utiles.

Si vous avez des questions sur une offre en particulier, ou si vous souhaitez ajuster certains critères, je suis là pour vous.

N'hésitez pas à me dire ce que vous en pensez.
''';
  }

  static String getHelpMessage() {
    return '''
Je suis là pour vous guider.

Vous pouvez me poser des questions sur :
- Les types de garanties proposées
- Les conditions générales des contrats
- Les démarches en cas de sinistre
- Les comparatifs entre différentes offres
- Les économies possibles

Dites-moi simplement ce qui vous intéresse.
''';
  }

  static String getThankYouMessage() {
    return '''
Merci pour votre confiance.

C'est un plaisir de vous accompagner dans cette étape importante.

Si vous avez besoin de revenir sur certains points, je reste disponible.
''';
  }
}