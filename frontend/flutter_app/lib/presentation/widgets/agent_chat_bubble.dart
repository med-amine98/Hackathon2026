// lib/presentation/widgets/agent_chat_bubble.dart
//
// App-wide floating chat bubble linked to the agent (platform/backend's
// accident-intake chat, see AgentChatBloc / AgentChatRepository). Mounted
// once in app/app.dart's MaterialApp.router `builder`, so it floats above
// whichever screen go_router is currently showing.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ai_insurance_advisor/app/routes.dart';
import 'package:ai_insurance_advisor/app/theme.dart';
import 'package:ai_insurance_advisor/core/constants/api_constants.dart';
import 'package:ai_insurance_advisor/data/models/user.dart';
import 'package:ai_insurance_advisor/presentation/bloc/agent_chat/agent_chat_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/auth/auth_bloc.dart';
import 'package:ai_insurance_advisor/presentation/widgets/chat_bubble.dart';

/// Only visible to a logged-in user — watches AuthBloc directly rather than
/// requiring app.dart to conditionally mount it, since AgentChatBubble is
/// always in the widget tree (see app/app.dart's MaterialApp.router
/// builder). Renders nothing at all pre-login instead of just hiding the
/// button, so an unauthenticated visitor can't reach the agent chat by any
/// route (deep link, dev tools, etc.).
///
/// Draggable: starts bottom-right but can be dragged anywhere on screen so
/// it never permanently blocks content underneath it (a FAB fixed in one
/// corner can sit on top of a button/field on some screens). Position is
/// kept in State, not persisted — resets to the default corner on a full
/// app restart, which is fine for a floating helper like this.
class AgentChatBubble extends StatefulWidget {
  const AgentChatBubble({super.key});

  @override
  State<AgentChatBubble> createState() => _AgentChatBubbleState();
}

class _AgentChatBubbleState extends State<AgentChatBubble> {
  static const double _size = 56;
  static const double _margin = 16;

  Offset? _offset; // top-left corner; null until first build sets the default

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return const SizedBox.shrink();
    }
    final user = authState.user;

    final size = MediaQuery.of(context).size;
    final safePadding = MediaQuery.of(context).padding;
    final minDx = _margin;
    final maxDx = math.max(minDx, size.width - _size - _margin);
    final minDy = safePadding.top + _margin;
    final maxDy = math.max(minDy, size.height - _size - _margin - safePadding.bottom);

    _offset ??= Offset(maxDx, math.max(minDy, maxDy - 24));

    double clamp(double value, double min, double max) => value < min ? min : (value > max ? max : value);

    return Positioned(
      left: clamp(_offset!.dx, minDx, maxDx),
      top: clamp(_offset!.dy, minDy, maxDy),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final newDx = clamp(_offset!.dx + details.delta.dx, minDx, maxDx);
            final newDy = clamp(_offset!.dy + details.delta.dy, minDy, maxDy);
            _offset = Offset(newDx, newDy);
          });
        },
        child: FloatingActionButton(
          heroTag: 'agent-chat-bubble',
          backgroundColor: AppTheme.secondaryColor,
          onPressed: () => _openAgentChat(context, user),
          child: const Icon(Icons.support_agent, color: Colors.white),
        ),
      ),
    );
  }

  void _openAgentChat(BuildContext context, User user) {
    final bloc = context.read<AgentChatBloc>()..add(AgentSetUserEvent(user));

    // `context` here comes from MaterialApp.router's `builder`, which sits
    // above/outside go_router's own Navigator (the bubble is a Stack
    // sibling of `child`, not a descendant of it — see app/app.dart) — so
    // Navigator.of(context) can't find one and showModalBottomSheet throws
    // "context does not include a Navigator". Use the router's own root
    // navigator context instead (see AppRouter.rootNavigatorKey).
    final navigatorContext = AppRouter.rootNavigatorKey.currentContext;
    if (navigatorContext == null) return;

    showModalBottomSheet(
      context: navigatorContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const _AgentChatSheet(),
      ),
    );
  }
}

class _AgentChatSheet extends StatefulWidget {
  const _AgentChatSheet();

  @override
  State<_AgentChatSheet> createState() => _AgentChatSheetState();
}

class _AgentChatSheetState extends State<_AgentChatSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // Tracks the last constat URL we already auto-opened, so a rebuild (or
  // the assistant regenerating the SAME draft again) doesn't keep popping
  // a new tab open every time — only a genuinely new/changed URL triggers it.
  String? _lastOpenedConstatUrl;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<AgentChatBloc>().add(AgentSendMessageEvent(text));
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final height = MediaQuery.of(context).size.height * 0.82;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildMessageList()),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.support_agent, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agent constat',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Déclarez votre accident en discutant',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return BlocConsumer<AgentChatBloc, AgentChatState>(
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        // Auto-open the constat the moment the assistant produces/updates
        // one, instead of making the user hunt for and tap the small link.
        // The "Voir le constat" button (see _buildConstatLink) stays as a
        // manual fallback/re-open — some browsers block a tab opened from
        // an async callback like this one (not a direct click) unless
        // pop-ups are allowed for this site, so the button is the reliable
        // path if the automatic open gets silently blocked.
        if (state.messages.isNotEmpty) {
          final latestUrl = state.messages.last.constatPdfUrl;
          if (latestUrl != null && latestUrl != _lastOpenedConstatUrl) {
            _lastOpenedConstatUrl = latestUrl;
            _openConstatPdf(latestUrl);
          }
        }
      },
      builder: (context, state) {
        if (state.messages.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                "Bonjour 👋 Racontez-moi ce qui s'est passé, je vous aide à remplir le constat.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ),
          );
        }
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: state.messages.length + (state is AgentChatLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= state.messages.length) {
              return const Padding(
                padding: EdgeInsets.only(left: 44, top: 4),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            final m = state.messages[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChatBubble(message: m.content, isUser: m.isUser, timestamp: m.timestamp),
                if (m.constatPdfUrl != null) _buildConstatLink(m.constatPdfUrl!),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildConstatLink(String relativeUrl) {
    return Padding(
      padding: const EdgeInsets.only(left: 44, bottom: 8, top: 2),
      child: OutlinedButton.icon(
        onPressed: () => _openConstatPdf(relativeUrl),
        icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
        label: const Text('Voir le constat (brouillon)'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.secondaryColor,
          side: BorderSide(color: AppTheme.secondaryColor.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  Future<void> _openConstatPdf(String relativeUrl) async {
    final uri = Uri.parse('${ApiConstants.agentBaseUrl}$relativeUrl');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Écrivez votre message…',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppTheme.secondaryColor,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
