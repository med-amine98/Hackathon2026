/// Gère la conversation, l'état et le flux de questions
class ConversationManager {
  final Map<String, dynamic> _state = {};
  final List<Map<String, String>> _messages = [];
  String _currentIntent = 'general_question';

  // Questions pour le profiling
  static const List<Map<String, dynamic>> _profileQuestions = [
    {
      'field': 'age',
      'question': 'Quel âge avez-vous ?',
      'type': 'number',
      'validation': {'min': 18, 'max': 100}
    },
    {
      'field': 'city',
      'question': 'Dans quelle ville habitez-vous ?',
      'type': 'text'
    },
    {
      'field': 'vehicle_make',
      'question': 'Quelle est la marque de votre véhicule ?',
      'type': 'text'
    },
    {
      'field': 'vehicle_model',
      'question': 'Quel est le modèle ?',
      'type': 'text'
    },
    {
      'field': 'vehicle_year',
      'question': 'Quelle année ?',
      'type': 'number'
    },
    {
      'field': 'annual_km',
      'question': 'Combien de kilomètres faites-vous par an ?',
      'type': 'number'
    },
    {
      'field': 'budget_monthly',
      'question': 'Quel est votre budget mensuel pour l\'assurance (en TND) ?',
      'type': 'number'
    },
    {
      'field': 'vehicle_usage',
      'question': 'Utilisez-vous votre véhicule : quotidiennement, le week-end ou occasionnellement ?',
      'type': 'choice',
      'options': ['quotidiennement', 'le week-end', 'occasionnellement']
    }
  ];

  String get currentIntent => _currentIntent;
  List<Map<String, String>> get messages => List.unmodifiable(_messages);
  Map<String, dynamic> get profile => Map.unmodifiable(_state);

  void startConversation(String intent) {
    _currentIntent = intent;
    _state.clear();
    _messages.clear();
  }

  String? processMessage(String message) {
    // On ne tente d'extraire la réponse que pour la question actuellement
    // posée (la première non répondue) : essayer toutes les questions
    // restantes ferait retomber une réponse mal reconnue sur un mauvais
    // champ (ex: une ville tapée en réponse à "quel âge ?" serait alors
    // silencieusement enregistrée comme ville, en sautant l'âge).
    Map<String, dynamic>? currentQuestion;
    for (var question in _profileQuestions) {
      final field = question['field'] as String;
      if (!_state.containsKey(field)) {
        currentQuestion = question;
        break;
      }
    }

    if (currentQuestion != null) {
      final field = currentQuestion['field'] as String;
      final value = _extractValue(message, currentQuestion);
      if (value != null) {
        _state[field] = value;
        _messages.add({
          'role': 'assistant',
          'content': '✅ J\'ai bien enregistré votre réponse'
        });
        return _getNextQuestion();
      }
    }

    // Si aucune info valide n'a été extraite, reposer la question actuelle
    return _getNextQuestion();
  }

  String? _getNextQuestion() {
    for (var question in _profileQuestions) {
      final field = question['field'] as String;
      if (!_state.containsKey(field)) {
        return question['question'] as String;
      }
    }
    return null; // Toutes les questions ont été répondues
  }

  dynamic _extractValue(String message, Map<String, dynamic> question) {
    final type = question['type'] as String;
    final lower = message.toLowerCase();

    switch (type) {
      case 'number':
        final match = RegExp(r'(\d+)').firstMatch(lower);
        if (match != null) {
          final value = int.parse(match.group(1)!);
          final validation = question['validation'] as Map<String, dynamic>?;
          if (validation != null) {
            final min = validation['min'] as int?;
            final max = validation['max'] as int?;
            if (min != null && max != null && (value < min || value > max)) {
              // Hors des bornes autorisées : on rejette la valeur.
              return null;
            }
          }
          return value;
        }
        break;

      case 'choice':
        final options = question['options'] as List<dynamic>?;
        if (options != null) {
          for (var option in options) {
            if (lower.contains(option.toString().toLowerCase())) {
              return option.toString();
            }
          }
        }
        break;

      case 'text':
        if (message.length > 3) {
          return message.trim();
        }
        break;
    }
    return null;
  }

  bool isProfileComplete() {
    for (var question in _profileQuestions) {
      final field = question['field'] as String;
      if (!_state.containsKey(field)) {
        return false;
      }
    }
    return true;
  }

  Map<String, dynamic> getProfileData() {
    return {
      'age': _state['age'],
      'city': _state['city'] as String?,
      'vehicle_make': _state['vehicle_make'] as String?,
      'vehicle_model': _state['vehicle_model'] as String?,
      'vehicle_year': _state['vehicle_year'],
      'annual_km': _state['annual_km'],
      'budget_monthly': _state['budget_monthly'],
      'vehicle_usage': _state['vehicle_usage'] as String?,
    };
  }

  void addUserMessage(String content) {
    _messages.add({'role': 'user', 'content': content});
  }

  void addAssistantMessage(String content) {
    _messages.add({'role': 'assistant', 'content': content});
  }
}