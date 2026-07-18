// lib/presentation/screens/assistant/assistant_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _addInitialMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addInitialMessages() {
    _messages.addAll([
      ChatMessage(
        text: 'Bonjour ! Je suis votre assistant IA AssurIA. 🚗✨',
        isUser: false,
        timestamp: DateTime.now(),
      ),
      ChatMessage(
        text: 'Je peux vous aider à :\n'
            '• Choisir la meilleure assurance pour vous\n'
            '• Comprendre vos contrats\n'
            '• Réaliser un constat en ligne\n'
            '• Obtenir un devis personnalisé\n'
            '• Générer vos documents en PDF',
        isUser: false,
        timestamp: DateTime.now(),
      ),
      ChatMessage(
        text: 'Par quoi souhaitez-vous commencer ? 😊',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ]);
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          text: _getAIResponse(text),
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _scrollToBottom();
      });
    });
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

  String _getAIResponse(String userMessage) {
    final msg = userMessage.toLowerCase().trim();
    
    if (msg.contains('bonjour') || msg.contains('salut') || msg.contains('hey')) {
      return 'Bonjour ! 👋 Comment puis-je vous aider aujourd\'hui ? N\'hésitez pas à me poser vos questions sur les assurances.';
    }
    
    if (msg.contains('auto') || msg.contains('voiture') || msg.contains('véhicule')) {
      return '🚗 Pour votre assurance auto, je vous recommande notre formule **"Conduite Sereine"** :\n\n'
          '✅ Protection tous risques\n'
          '✅ Assistance 24/7 et dépannage\n'
          '✅ Prise en charge rapide des sinistres\n'
          '✅ Rabais de 15% la première année\n'
          'Souhaitez-vous un devis personnalisé ? 📄';
    }
    
    if (msg.contains('maison') || msg.contains('habitation') || msg.contains('appartement')) {
      return '🏠 Notre formule **"Home Secure"** vous offre :\n\n'
          '• Couverture multi-risques complète\n'
          '• Protection des biens mobiliers\n'
          '• Responsabilité civile\n'
          '• Assistance en cas de sinistre\n'
          'Puis-je vous envoyer un devis détaillé ? 📊';
    }
    
    if (msg.contains('santé') || msg.contains('medical') || msg.contains('médecine')) {
      return '🏥 Notre assurance santé **"Bien-Être"** propose :\n\n'
          '• Couverture médicale complète\n'
          '• Tiers payant généralisé\n'
          '• Remboursement rapide sous 48h\n'
          '• Accès à un large réseau de soins\n'
          'Souhaitez-vous en savoir plus sur les garanties ?';
    }
    
    if (msg.contains('constat') || msg.contains('sinistre') || msg.contains('accident')) {
      return '📋 Je comprends, je vais vous guider pour votre constat :\n\n'
          '1️⃣ Remplissez le constat amiable avec l\'autre conducteur\n'
          '2️⃣ Prenez des photos des dégâts\n'
          '3️⃣ Contactez notre service sinistre au 📞 1234\n'
          '4️⃣ Transmettez les documents via notre application\n\n'
          '💡 Astuce : Plus vite vous déclarez, plus vite vous êtes remboursé !';
    }
    
    if (msg.contains('prix') || msg.contains('tarif') || msg.contains('coût') || msg.contains('devis')) {
      return '💰 Pour vous faire un devis personnalisé, j\'ai besoin de quelques informations :\n\n'
          '• Type d\'assurance recherché (Auto, Habitation, Santé)\n'
          '• Montant des biens à assurer\n'
          '• Votre situation (conducteur, propriétaire, locataire)\n'
          'Remplissons ensemble un devis rapide ? 🚀';
    }
    
    if (msg.contains('document') || msg.contains('pdf') || msg.contains('contrat')) {
      return '📄 Pour générer vos documents, je vous guide :\n\n'
          '1️⃣ Choisissez le type de document\n'
          '2️⃣ Vérifiez vos informations personnelles\n'
          '3️⃣ Validez et téléchargez en PDF\n\n'
          'Souhaitez-vous générer un document maintenant ? 📎';
    }
    
    if (msg.contains('merci')) {
      return 'Avec plaisir ! 🌟 N\'hésitez pas si vous avez d\'autres questions. Je suis là pour vous accompagner.\n\n'
          'Bonne journée et roulez prudemment ! 🚗';
    }
    
    return 'Je comprends votre demande. 🤔 Pour mieux vous aider, pourriez-vous me préciser :\n\n'
        '• Quel type d\'assurance vous intéresse ? (Auto, Habitation, Santé)\n'
        '• Souhaitez-vous un devis ?\n'
        '• Avez-vous besoin d\'aide pour un constat ?\n\n'
        'Je suis là pour vous guider ! 💪';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Assistant IA',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1F2937)),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF3B82F6)),
            onPressed: () {
              setState(() {
                _messages.clear();
                _addInitialMessages();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔄 Conversation actualisée'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Color(0xFF3B82F6),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: () {
              setState(() {
                _messages.clear();
                _addInitialMessages();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🗑️ Historique effacé'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Messages
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isLoading) {
                      return _buildLoadingIndicator();
                    }
                    final message = _messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Barre d'entrée
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser ? null : const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                ),
                color: isUser ? const Color(0xFF1F2937) : null,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                ),
                boxShadow: isUser ? null : [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 46),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Assistant réfléchit...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📎 Fonctionnalité à venir'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(
              Icons.attach_file_rounded,
              color: Colors.grey,
              size: 22,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Écrivez votre message...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}