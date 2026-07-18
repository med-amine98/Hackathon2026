// lib/presentation/screens/declaration/declaration_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/declaration_chat/declaration_chat_bloc.dart';
import 'package:ai_insurance_advisor/services/pdf_service.dart';

class DeclarationChatScreen extends StatefulWidget {
  const DeclarationChatScreen({super.key});

  @override
  State<DeclarationChatScreen> createState() => _DeclarationChatScreenState();
}

class _DeclarationChatScreenState extends State<DeclarationChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<DeclarationChatBloc>().add(const StartDeclarationConversation());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Déclaration - Constat'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          BlocBuilder<DeclarationChatBloc, DeclarationChatState>(
            builder: (context, state) {
              if (state is DeclarationChatCompleted) {
                return IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: () => _downloadPDF(context, state.constatData),
                  tooltip: 'Télécharger le constat',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<DeclarationChatBloc, DeclarationChatState>(
              builder: (context, state) {
                if (state is DeclarationChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is DeclarationChatLoaded) {
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final msg = state.messages[index];
                      return _buildMessage(
                        msg['content'] as String,
                        msg['isUser'] as bool,
                        msg['type'] as String? ?? 'text',
                      );
                    },
                  );
                }

                if (state is DeclarationChatCompleted) {
                  return _buildConstatPreview(state.constatData, state.isSigned);
                }

                return const Center(child: Text('Démarrage de la déclaration...'));
              },
            ),
          ),
          BlocBuilder<DeclarationChatBloc, DeclarationChatState>(
            builder: (context, state) {
              if (state is DeclarationChatCompleted) {
                return _buildActionsBar(state.constatData, state.isSigned);
              }
              return _buildInputBar();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String content, bool isUser, String type) {
    if (type == 'constat') {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  '📄 Constat pré-rempli',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.orange.shade100,
              child: const Icon(Icons.assistant, size: 18, color: Colors.orange),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.orange : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isUser ? const Radius.circular(12) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(12),
                ),
              ),
              child: Text(
                content,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.orange.shade100,
              child: const Icon(Icons.person, size: 18, color: Colors.orange),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ CORRIGÉ : avec paramètre isSigned et casts explicites
  Widget _buildConstatPreview(Map<String, dynamic> constatData, bool isSigned) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '📋 CONSTAT AMIABLE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (isSigned)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'SIGNÉ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const Divider(),
              // ✅ Casts explicites
              _buildInfoRow('Date', constatData['date']?.toString() ?? 'Non renseigné'),
              _buildInfoRow('Heure', constatData['time']?.toString() ?? 'Non renseigné'),
              _buildInfoRow('Lieu', constatData['location']?.toString() ?? 'Non renseigné'),
              _buildInfoRow('Véhicule', constatData['vehicle']?.toString() ?? 'Non renseigné'),
              _buildInfoRow('Conducteur', constatData['driver']?.toString() ?? 'Non renseigné'),
              _buildInfoRow('Description', constatData['description']?.toString() ?? 'Non renseigné'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSigned ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSigned ? Colors.green.shade200 : Colors.orange.shade200,
                  ),
                ),
                child: Text(
                  isSigned ? '✅ Constat signé avec succès' : '📝 Constat complet - Prêt à être signé',
                  style: TextStyle(
                    color: isSigned ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // ✅ CORRIGÉ : avec paramètre isSigned
  Widget _buildActionsBar(Map<String, dynamic> constatData, bool isSigned) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isSigned ? null : () => _signConstat(context),
              icon: const Icon(Icons.edit_document),
              label: Text(isSigned ? 'Déjà signé' : 'Signer le constat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSigned ? Colors.grey : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _downloadPDF(context, constatData),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Décrivez l\'accident...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send_rounded, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    context.read<DeclarationChatBloc>().add(SendDeclarationMessageEvent(text));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ✅ CORRIGÉ : showDialog<void> et suppression du paramètre inutilisé
  void _signConstat(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signer le constat'),
        content: const Text('Voulez-vous signer électroniquement ce constat ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Constat signé avec succès !'),
                  backgroundColor: Colors.green,
                ),
              );
              context.read<DeclarationChatBloc>().add(const SignConstatEvent());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Signer'),
          ),
        ],
      ),
    );
  }

  // ✅ CORRIGÉ : implémentation complète du PDF
  void _downloadPDF(BuildContext context, Map<String, dynamic> constatData) async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Génération du PDF en cours...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Générer et partager le PDF
      await PdfService.sharePDF(constatData);

      // Fermer le dialogue de chargement
      if (mounted) {
        Navigator.pop(context);

        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PDF généré et partagé avec succès !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Fermer le dialogue de chargement en cas d'erreur
      if (mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}