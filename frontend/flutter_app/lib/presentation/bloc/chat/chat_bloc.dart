// lib/presentation/bloc/chat/chat_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_insurance_advisor/data/repositories/chat_repository.dart';
import 'package:ai_insurance_advisor/ai/intent_detector.dart';
import 'package:ai_insurance_advisor/ai/conversation_manager.dart';
import 'package:ai_insurance_advisor/services/risk_analyzer.dart';
import 'package:ai_insurance_advisor/services/recommendation_engine.dart';
import 'package:ai_insurance_advisor/ai/prompts.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository? _chatRepository;
  final IntentDetector _intentDetector = IntentDetector(); // ✅ Retiré const
  final ConversationManager _conversationManager = ConversationManager(); // ✅ Retiré const
  final RiskAnalyzer _riskAnalyzer = RiskAnalyzer(); // ✅ Retiré const
  final RecommendationEngine _recommendationEngine = RecommendationEngine(); // ✅ Retiré const

  ChatBloc({ChatRepository? chatRepository})
      : _chatRepository = chatRepository,
        super(const ChatInitial()) {
    on<SendMessageEvent>(_onSendMessage);
    on<ResetChatEvent>(_onResetChat);
    on<StartNewConversationEvent>(_onStartNewConversation);
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final currentMessages = _getCurrentMessages();
    final userMessage = ChatMessage(
      content: event.message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    final updatedMessages = [...currentMessages, userMessage];
    
    emit(ChatLoading(messages: updatedMessages, conversationId: null));

    try {
      // 🔥 1. Détecter l'intention
      final intent = _intentDetector.detectIntent(event.message);
      print('🎯 Intent: $intent');

      // 🔥 2. Si premier message, démarrer la conversation
      if (currentMessages.isEmpty) {
        _conversationManager.startConversation(intent);
        final welcome = AssistantPrompts.getWelcomeMessage(intent);
        final assistantMessage = ChatMessage(
          content: welcome,
          isUser: false,
          timestamp: DateTime.now(),
        );
        emit(ChatLoaded(
          messages: [...updatedMessages, assistantMessage],
          conversationId: null,
          nextStep: 'collecting_info',
        ));
        return;
      }

      // 🔥 3. Ajouter le message et traiter
      _conversationManager.addUserMessage(event.message);
      final nextQuestion = _conversationManager.processMessage(event.message);

      // 🔥 4. Vérifier si le profil est complet
      if (_conversationManager.isProfileComplete()) {
        final profile = _conversationManager.getProfileData();
        final riskResult = _riskAnalyzer.calculateRisk(profile);
        final recommendations = _recommendationEngine.getRecommendations(
          profile, 
          riskResult
        );
        final bestMatch = _recommendationEngine.getBestMatch(recommendations);
        
        final response = '''
${AssistantPrompts.getProfileCompleteMessage(profile)}

📊 **Analyse des risques :**
• Score : ${riskResult['score']}/100
• Niveau : ${riskResult['level']}
• Facteurs : ${(riskResult['factors'] as List).join(', ')}

${riskResult['recommendation']}

${_recommendationEngine.generateRecommendationText(bestMatch)}
''';

        final assistantMessage = ChatMessage(
          content: response,
          isUser: false,
          timestamp: DateTime.now(),
          recommendations: recommendations.take(3).toList(),
        );
        
        emit(ChatLoaded(
          messages: [...updatedMessages, assistantMessage],
          conversationId: null,
          nextStep: 'recommendations_done',
        ));
        return;
      }

      // 🔥 5. Poser la question suivante
      if (nextQuestion != null) {
        final response = '''
❓ **${nextQuestion}**

Veuillez me donner une réponse précise.
''';
        final assistantMessage = ChatMessage(
          content: response,
          isUser: false,
          timestamp: DateTime.now(),
        );
        emit(ChatLoaded(
          messages: [...updatedMessages, assistantMessage],
          conversationId: null,
          nextStep: 'collecting_info',
        ));
        return;
      }

      // 🔥 6. Fallback - utiliser OpenAI si disponible
      if (_chatRepository != null) {
        final apiResponse = await _chatRepository!.sendMessage(
          event.message,
          conversationId: null,
        );
        final messageContent = apiResponse['message'] as String? ?? 'Je n\'ai pas compris votre demande.';
        final conversationId = apiResponse['conversation_id'] as int?;
        
        final assistantMessage = ChatMessage(
          content: messageContent,
          isUser: false,
          timestamp: DateTime.now(),
        );
        emit(ChatLoaded(
          messages: [...updatedMessages, assistantMessage],
          conversationId: conversationId,
          nextStep: null,
        ));
        return;
      }

      // 🔥 7. Fallback simple
      final fallbackMessage = ChatMessage(
        content: AssistantPrompts.getFallbackMessage(),
        isUser: false,
        timestamp: DateTime.now(),
      );
      emit(ChatLoaded(
        messages: [...updatedMessages, fallbackMessage],
        conversationId: null,
        nextStep: null,
      ));

    } catch (e) {
      print('❌ Chat error: $e');
      emit(ChatError(
        message: 'Erreur: ${e.toString()}',
        messages: updatedMessages,
      ));
    }
  }

  void _onResetChat(ResetChatEvent event, Emitter<ChatState> emit) {
    _conversationManager.startConversation('general_question');
    emit(const ChatInitial());
  }

  void _onStartNewConversation(
    StartNewConversationEvent event,
    Emitter<ChatState> emit,
  ) {
    _conversationManager.startConversation(event.intent ?? 'general_question');
    final welcome = AssistantPrompts.getWelcomeMessage(event.intent ?? 'general_question');
    emit(ChatLoaded(
      messages: [
        ChatMessage(content: welcome, isUser: false, timestamp: DateTime.now()) // ✅ Retiré const
      ],
      conversationId: null,
      nextStep: 'collecting_info',
    ));
  }

  List<ChatMessage> _getCurrentMessages() {
    final s = state;
    if (s is ChatLoaded) return s.messages;
    if (s is ChatLoading) return s.messages;
    if (s is ChatError) return s.messages;
    return [];
  }
}