// lib/presentation/bloc/conseil_chat/conseil_chat_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'conseil_chat_event.dart';
part 'conseil_chat_state.dart';

class ConseilChatBloc extends Bloc<ConseilChatEvent, ConseilChatState> {
  ConseilChatBloc() : super(const ConseilChatInitial()) {
    on<StartConseilConversation>(_onStart);
    on<SendConseilMessageEvent>(_onSendMessage);
  }

  void _onStart(
    StartConseilConversation event,
    Emitter<ConseilChatState> emit,
  ) {
    final messages = <Map<String, dynamic>>[
      {'content': 'Bonjour ! Je suis votre conseiller IA pour l\'assurance automobile.', 'isUser': false, 'type': 'text'},
      {'content': 'Pour commencer, quel type d\'assurance recherchez-vous ? (Tous risques, Tiers, Intermédiaire)', 'isUser': false, 'type': 'text'},
    ];

    emit(ConseilChatLoaded(
      messages: messages,
      currentStep: 'ask_type',
    ));
  }

  void _onSendMessage(
    SendConseilMessageEvent event,
    Emitter<ConseilChatState> emit,
  ) {
    final state = this.state;
    if (state is! ConseilChatLoaded) return;

    final newMessages = List<Map<String, dynamic>>.from(state.messages);
    newMessages.add({
      'content': event.message,
      'isUser': true,
      'type': 'text',
    });

    final lower = event.message.toLowerCase();
    String response;
    String nextStep;
    String type;

    if (state.currentStep == 'ask_type') {
      if (lower.contains('tous risques')) {
        response = 'Excellent choix ! Donnez-moi des infos sur votre véhicule (marque, modèle, année)';
        nextStep = 'ask_vehicle';
        type = 'text';
      } else if (lower.contains('tiers')) {
        response = 'L\'assurance Tiers est économique. Donnez-moi des infos sur votre véhicule';
        nextStep = 'ask_vehicle';
        type = 'text';
      } else {
        response = 'Choisissez entre Tous risques, Tiers ou Intermédiaire. Quelle formule vous intéresse ?';
        nextStep = 'ask_type';
        type = 'text';
      }
    } else if (state.currentStep == 'ask_vehicle') {
      response = '🔹 **Assurance Tous risques Premium**\n• Couverture vol et incendie\n• Protection juridique\n• Assistance 24/7\n• 95 TND/mois\n\nSouhaitez-vous souscrire ?';
      nextStep = 'offer';
      type = 'offer';
    } else if (state.currentStep == 'offer') {
      if (lower.contains('oui')) {
        response = 'Félicitations ! Votre contrat est en préparation. Vous recevrez un email avec les détails.';
        nextStep = 'done';
        type = 'text';
      } else {
        response = '🔹 **Intermédiaire Plus** - 65 TND/mois\n🔹 **Tiers Essentiel** - 45 TND/mois\n\nLaquelle vous intéresse ?';
        nextStep = 'offer';
        type = 'offer';
      }
    } else {
      response = 'Je suis là pour vous aider. Que puis-je faire ?';
      nextStep = 'ask_type';
      type = 'text';
    }

    newMessages.add({
      'content': response,
      'isUser': false,
      'type': type,
    });

    emit(ConseilChatLoaded(
      messages: newMessages,
      currentStep: nextStep,
    ));
  }
}