// lib/presentation/bloc/agent_chat/agent_chat_event.dart

part of 'agent_chat_bloc.dart';

abstract class AgentChatEvent {
  const AgentChatEvent();
}

class AgentSendMessageEvent extends AgentChatEvent {
  final String message;

  const AgentSendMessageEvent(this.message);
}

/// Dispatched once, right when the bubble is opened by a logged-in user
/// (see AgentChatBubble), so every message sent afterwards can carry the
/// user's id/name/phone to the backend without asking them to type it in
/// chat — see AgentChatBloc._onSendMessage and
/// platform/backend/app/routers/chat.py's "known identity" handling.
class AgentSetUserEvent extends AgentChatEvent {
  final User user;

  const AgentSetUserEvent(this.user);
}

class AgentResetChatEvent extends AgentChatEvent {
  const AgentResetChatEvent();
}
