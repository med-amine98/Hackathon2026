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
  // Local preview of a photo the user just attached via AgentUploadPhotoEvent
  // (see _buildMessageList) — never sent anywhere, just so the chat shows
  // what was captured instead of only a "photo saved" text confirmation.
  final Uint8List? localImageBytes;

  AgentChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.constatPdfUrl,
    this.localImageBytes,
  }) : timestamp = timestamp ?? DateTime.now();
}

abstract class AgentChatState {
  final List<AgentChatMessage> messages;
  final String? conversationId;
  final bool escalationFlag;
  // The draft/confirmed Claim this conversation is attached to (see
  // ChatMessageOut.claim_id in platform/backend/app/schemas.py) — null until
  // the assistant has recorded enough for a draft constat to exist. This is
  // what gates the photo-attach button: without a claim id there's no
  // {claim_id} to upload a photo against (POST /claims/{claim_id}/photos).
  final String? claimId;

  const AgentChatState({
    required this.messages,
    this.conversationId,
    this.escalationFlag = false,
    this.claimId,
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
    super.claimId,
  });
}

class AgentChatLoaded extends AgentChatState {
  const AgentChatLoaded({
    required super.messages,
    super.conversationId,
    super.escalationFlag,
    super.claimId,
  });
}

class AgentChatError extends AgentChatState {
  final String error;

  const AgentChatError({
    required this.error,
    required super.messages,
    super.conversationId,
    super.escalationFlag,
    super.claimId,
  });
}
