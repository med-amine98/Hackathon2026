// lib/presentation/bloc/declaration_chat/declaration_chat_event.dart

part of 'declaration_chat_bloc.dart';

abstract class DeclarationChatEvent extends Equatable {
  const DeclarationChatEvent();
  
  @override
  List<Object?> get props => [];
}

class StartDeclarationConversation extends DeclarationChatEvent {
  const StartDeclarationConversation();
}

class SendDeclarationMessageEvent extends DeclarationChatEvent {
  final String message;
  
  const SendDeclarationMessageEvent(this.message);
  
  @override
  List<Object?> get props => [message];
}

class SignConstatEvent extends DeclarationChatEvent {
  const SignConstatEvent();
}