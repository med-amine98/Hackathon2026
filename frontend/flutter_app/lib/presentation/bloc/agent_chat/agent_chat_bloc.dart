// lib/presentation/bloc/agent_chat/agent_chat_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_insurance_advisor/data/models/user.dart';
import 'package:ai_insurance_advisor/data/repositories/agent_chat_repository.dart';

part 'agent_chat_event.dart';
part 'agent_chat_state.dart';

/// Drives the floating agent chat bubble (see
/// presentation/widgets/agent_chat_bubble.dart). Talks to the agent's own
/// accident-intake chat endpoint via [AgentChatRepository] — a separate
/// conversation/backend from the regular buy-insurance ChatBloc.
class AgentChatBloc extends Bloc<AgentChatEvent, AgentChatState> {
  final AgentChatRepository _repository;
  // Set once via AgentSetUserEvent when the bubble opens (only ever opens
  // for a logged-in user — see AgentChatBubble). Not part of AgentChatState
  // since it doesn't drive any UI rebuild on its own, just tags outgoing
  // messages.
  User? _currentUser;

  AgentChatBloc({required AgentChatRepository repository})
      : _repository = repository,
        super(const AgentChatInitial()) {
    on<AgentSendMessageEvent>(_onSendMessage);
    on<AgentSetUserEvent>(_onSetUser);
    on<AgentResetChatEvent>(_onReset);
  }

  void _onSetUser(AgentSetUserEvent event, Emitter<AgentChatState> emit) {
    _currentUser = event.user;
  }

  Future<void> _onSendMessage(
    AgentSendMessageEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    final userMessage = AgentChatMessage(content: event.message, isUser: true);
    final updatedMessages = [...state.messages, userMessage];

    emit(AgentChatLoading(
      messages: updatedMessages,
      conversationId: state.conversationId,
      escalationFlag: state.escalationFlag,
    ));

    final response = await _repository.sendMessage(
      event.message,
      conversationId: state.conversationId,
      userId: _currentUser?.id,
      firstName: _currentUser?.firstName,
      lastName: _currentUser?.lastName,
      email: _currentUser?.email,
      phone: _currentUser?.phone,
    );

    final replyText = response['message'] as String? ?? '...';
    final conversationId = response['conversation_id'] as String?;
    final escalationFlag = response['escalation_flag'] as bool? ?? false;
    final constatPdfUrl = response['constat_pdf_url'] as String?;

    final assistantMessage = AgentChatMessage(
      content: replyText,
      isUser: false,
      constatPdfUrl: constatPdfUrl,
    );

    emit(AgentChatLoaded(
      messages: [...updatedMessages, assistantMessage],
      conversationId: conversationId ?? state.conversationId,
      escalationFlag: escalationFlag,
    ));
  }

  void _onReset(AgentResetChatEvent event, Emitter<AgentChatState> emit) {
    emit(const AgentChatInitial());
  }
}
