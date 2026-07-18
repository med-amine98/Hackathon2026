// lib/presentation/bloc/declaration_chat/declaration_chat_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'declaration_chat_event.dart';
part 'declaration_chat_state.dart';

class DeclarationChatBloc extends Bloc<DeclarationChatEvent, DeclarationChatState> {
  DeclarationChatBloc() : super(const DeclarationChatInitial()) {
    on<StartDeclarationConversation>(_onStart);
    on<SendDeclarationMessageEvent>(_onSendMessage);
    on<SignConstatEvent>(_onSignConstat);
  }

  void _onStart(
    StartDeclarationConversation event,
    Emitter<DeclarationChatState> emit,
  ) {
    final messages = <Map<String, dynamic>>[
      {'content': 'Bonjour ! Je vais vous aider à remplir votre constat amiable.', 'isUser': false, 'type': 'text'},
      {'content': 'Décrivez-moi l\'accident en détail. Où et quand a-t-il eu lieu ?', 'isUser': false, 'type': 'text'},
    ];

    emit(DeclarationChatLoaded(
      messages: messages,
      constatData: {},
      currentStep: 'ask_location',
    ));
  }

  void _onSendMessage(
    SendDeclarationMessageEvent event,
    Emitter<DeclarationChatState> emit,
  ) {
    final state = this.state;
    if (state is! DeclarationChatLoaded) return;

    final newMessages = List<Map<String, dynamic>>.from(state.messages);
    newMessages.add({
      'content': event.message,
      'isUser': true,
      'type': 'text',
    });

    final updatedConstat = Map<String, dynamic>.from(state.constatData);
    final nextStep = _updateConstat(updatedConstat, event.message, state.currentStep);

    if (nextStep == 'complete') {
      final constatText = _generateConstatText(updatedConstat);
      newMessages.add({
        'content': constatText,
        'isUser': false,
        'type': 'constat',
      });
      
      emit(DeclarationChatCompleted(
        messages: newMessages,
        constatData: updatedConstat,
      ));
    } else {
      final nextQuestion = _getNextQuestion(nextStep);
      newMessages.add({
        'content': nextQuestion,
        'isUser': false,
        'type': 'text',
      });
      
      emit(DeclarationChatLoaded(
        messages: newMessages,
        constatData: updatedConstat,
        currentStep: nextStep,
      ));
    }
  }

  void _onSignConstat(
    SignConstatEvent event,
    Emitter<DeclarationChatState> emit,
  ) {
    final state = this.state;
    if (state is! DeclarationChatCompleted) return;

    final newMessages = List<Map<String, dynamic>>.from(state.messages);
    newMessages.add({
      'content': '✅ Constat signé électroniquement avec succès !',
      'isUser': false,
      'type': 'text',
    });
    
    emit(DeclarationChatCompleted(
      messages: newMessages,
      constatData: state.constatData,
      isSigned: true,
    ));
  }

  String _updateConstat(Map<String, dynamic> constat, String message, String step) {
    switch (step) {
      case 'ask_location':
        constat['location'] = message;
        return 'ask_date';
      case 'ask_date':
        constat['date'] = message;
        return 'ask_time';
      case 'ask_time':
        constat['time'] = message;
        return 'ask_vehicle';
      case 'ask_vehicle':
        constat['vehicle'] = message;
        return 'ask_driver';
      case 'ask_driver':
        constat['driver'] = message;
        return 'ask_description';
      case 'ask_description':
        constat['description'] = message;
        return 'complete';
      default:
        return 'complete';
    }
  }

  String _getNextQuestion(String step) {
    switch (step) {
      case 'ask_date':
        return 'Quelle est la date de l\'accident ?';
      case 'ask_time':
        return 'À quelle heure ?';
      case 'ask_vehicle':
        return 'Quel est votre véhicule (marque, modèle, immatriculation) ?';
      case 'ask_driver':
        return 'Qui était au volant ? (Nom, prénom, permis)';
      case 'ask_description':
        return 'Décrivez l\'accident en détail.';
      default:
        return 'Pouvez-vous me donner plus de détails ?';
    }
  }

  String _generateConstatText(Map<String, dynamic> constat) {
    return '''
📋 CONSTAT AMIABLE

Date : ${constat['date'] ?? 'Non renseigné'}
Heure : ${constat['time'] ?? 'Non renseigné'}
Lieu : ${constat['location'] ?? 'Non renseigné'}
Véhicule : ${constat['vehicle'] ?? 'Non renseigné'}
Conducteur : ${constat['driver'] ?? 'Non renseigné'}

Description :
${constat['description'] ?? 'Non renseigné'}
''';
  }
}