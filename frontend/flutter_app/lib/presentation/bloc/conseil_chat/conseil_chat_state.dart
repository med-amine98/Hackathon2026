// lib/presentation/bloc/conseil_chat/conseil_chat_state.dart

part of 'conseil_chat_bloc.dart';

abstract class ConseilChatState extends Equatable {
  const ConseilChatState();
  
  @override
  List<Object?> get props => [];
}

class ConseilChatInitial extends ConseilChatState {
  const ConseilChatInitial();
}

class ConseilChatLoading extends ConseilChatState {
  const ConseilChatLoading();
}

class ConseilChatLoaded extends ConseilChatState {
  final List<Map<String, dynamic>> messages;
  final String currentStep;

  const ConseilChatLoaded({
    required this.messages,
    required this.currentStep,
  });

  @override
  List<Object?> get props => [messages, currentStep];
}