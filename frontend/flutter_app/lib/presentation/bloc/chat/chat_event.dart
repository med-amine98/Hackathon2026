// lib/presentation/bloc/chat/chat_event.dart

part of 'chat_bloc.dart';

abstract class ChatEvent {
  const ChatEvent();
}

class SendMessageEvent extends ChatEvent {
  final String message;
  final int? conversationId;
  
  const SendMessageEvent({
    required this.message,
    this.conversationId,
  });
}

class ResetChatEvent extends ChatEvent {
  const ResetChatEvent();
}

class StartNewConversationEvent extends ChatEvent {
  final String? intent;
  
  const StartNewConversationEvent({this.intent});
}