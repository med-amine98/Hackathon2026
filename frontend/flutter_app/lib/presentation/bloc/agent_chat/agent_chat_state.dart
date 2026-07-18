// lib/presentation/bloc/agent_chat/agent_chat_state.dart

part of 'agent_chat_bloc.dart';

class AgentChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  // Relative path (e.g. "/chat/<id>/constat.pdf") to the draft/final constat
  // PDF, set on the assistant message of whichever turn (re)generated it —
  // null on user messages and on turns that didn't touch the constat.
  final String? constatPdfUrl;

  AgentChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.constatPdfUrl,
  }) : timestamp = timestamp ?? DateTime.now();
}

abstract class AgentChatState {
  final List<AgentChatMessage> messages;
  final String? conversationId;
  final bool escalationFlag;

  const AgentChatState({
    required this.messages,
    this.conversationId,
    this.escalationFlag = false,
  });
}

class AgentChatInitial extends AgentChatState {
  const AgentChatInitial() : super(messages: const []);
}

class AgentChatLoading extends AgentChatState {
  const AgentChatLoading({
    required super.messages,
    super.conversationId,
    super.escalationFlag,
  });
}

class AgentChatLoaded extends AgentChatState {
  const AgentChatLoaded({
    required super.messages,
    super.conversationId,
    super.escalationFlag,
  });
}

class AgentChatError extends AgentChatState {
  final String error;

  const AgentChatError({
    required this.error,
    required super.messages,
    super.conversationId,
    super.escalationFlag,
  });
}
