// lib/presentation/bloc/conseil_chat/conseil_chat_event.dart

part of 'conseil_chat_bloc.dart';

abstract class ConseilChatEvent extends Equatable {
  const ConseilChatEvent();
  
  @override
  List<Object?> get props => [];
}

class StartConseilConversation extends ConseilChatEvent {
  const StartConseilConversation();
}

class SendConseilMessageEvent extends ConseilChatEvent {
  final String message;
  
  const SendConseilMessageEvent(this.message);
  
  @override
  List<Object?> get props => [message];
}