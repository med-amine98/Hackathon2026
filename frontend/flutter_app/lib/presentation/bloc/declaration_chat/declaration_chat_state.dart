// lib/presentation/bloc/declaration_chat/declaration_chat_state.dart

part of 'declaration_chat_bloc.dart';

abstract class DeclarationChatState extends Equatable {
  const DeclarationChatState();
  
  @override
  List<Object?> get props => [];
}

class DeclarationChatInitial extends DeclarationChatState {
  const DeclarationChatInitial();
}

class DeclarationChatLoading extends DeclarationChatState {
  const DeclarationChatLoading();
}

class DeclarationChatLoaded extends DeclarationChatState {
  final List<Map<String, dynamic>> messages;
  final Map<String, dynamic> constatData;
  final String currentStep;

  const DeclarationChatLoaded({
    required this.messages,
    required this.constatData,
    required this.currentStep,
  });

  @override
  List<Object?> get props => [messages, constatData, currentStep];
}

class DeclarationChatCompleted extends DeclarationChatState {
  final List<Map<String, dynamic>> messages;
  final Map<String, dynamic> constatData;
  final bool isSigned;

  const DeclarationChatCompleted({
    required this.messages,
    required this.constatData,
    this.isSigned = false,
  });

  @override
  List<Object?> get props => [messages, constatData, isSigned];
}