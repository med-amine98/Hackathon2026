// lib/presentation/bloc/chat/chat_state.dart

part of 'chat_bloc.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<dynamic>? recommendations;

  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.recommendations,
  }) : timestamp = timestamp ?? DateTime.now();
}

abstract class ChatState {
  const ChatState();
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  final List<ChatMessage> messages;
  final int? conversationId;

  const ChatLoading({
    required this.messages,
    this.conversationId,
  });
}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final int? conversationId;
  final String? nextStep;

  const ChatLoaded({
    required this.messages,
    this.conversationId,
    this.nextStep,
  });
}

class ChatError extends ChatState {
  final String message;
  final List<ChatMessage> messages;

  const ChatError({
    required this.message,
    required this.messages,
  });
}