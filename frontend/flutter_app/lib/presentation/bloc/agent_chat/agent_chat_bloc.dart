// lib/presentation/bloc/agent_chat/agent_chat_bloc.dart

import 'dart:typed_data';

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
    on<AgentUploadPhotoEvent>(_onUploadPhoto);
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
      claimId: state.claimId,
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
    // Once set, a claim_id never goes away for this conversation (the
    // backend session keeps reusing the same draft Claim row — see
    // _dispatch_tool/_maybe_generate_constat in platform/backend's
    // routers/chat.py), so fall back to whatever we already had rather than
    // letting a turn that didn't touch the claim clobber it with null.
    final claimId = response['claim_id'] as String? ?? state.claimId;

    final assistantMessage = AgentChatMessage(
      content: replyText,
      isUser: false,
      constatPdfUrl: constatPdfUrl,
    );

    emit(AgentChatLoaded(
      messages: [...updatedMessages, assistantMessage],
      conversationId: conversationId ?? state.conversationId,
      escalationFlag: escalationFlag,
      claimId: claimId,
    ));
  }

  Future<void> _onUploadPhoto(
    AgentUploadPhotoEvent event,
    Emitter<AgentChatState> emit,
  ) async {
    final claimId = state.claimId;
    if (claimId == null) {
      // Shouldn't happen — the composer's photo button is disabled/prompts
      // instead of dispatching this without a claim id — but guard anyway
      // rather than uploading to a nonsense URL.
      emit(AgentChatError(
        error: "Décrivez d'abord l'accident pour créer le dossier avant d'ajouter une photo.",
        messages: state.messages,
        conversationId: state.conversationId,
        escalationFlag: state.escalationFlag,
        claimId: state.claimId,
      ));
      return;
    }

    final localPreview = AgentChatMessage(
      content: '📷 Photo ajoutée au dossier',
      isUser: true,
      localImageBytes: event.bytes,
    );
    final withPreview = [...state.messages, localPreview];

    emit(AgentChatLoading(
      messages: withPreview,
      conversationId: state.conversationId,
      escalationFlag: state.escalationFlag,
      claimId: state.claimId,
    ));

    try {
      await _repository.uploadPhoto(
        claimId: claimId,
        bytes: event.bytes,
        filename: event.filename,
      );
      final confirmation = AgentChatMessage(
        content: 'Photo enregistrée sur votre dossier.',
        isUser: false,
      );
      emit(AgentChatLoaded(
        messages: [...withPreview, confirmation],
        conversationId: state.conversationId,
        escalationFlag: state.escalationFlag,
        claimId: state.claimId,
      ));
    } catch (e) {
      final failure = AgentChatMessage(
        content: "❌ Échec de l'envoi de la photo. Réessayez dans un instant.",
        isUser: false,
      );
      emit(AgentChatLoaded(
        messages: [...withPreview, failure],
        conversationId: state.conversationId,
        escalationFlag: state.escalationFlag,
        claimId: state.claimId,
      ));
    }
  }

  void _onReset(AgentResetChatEvent event, Emitter<AgentChatState> emit) {
    emit(const AgentChatInitial());
  }
}
