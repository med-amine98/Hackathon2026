// lib/presentation/widgets/assistant_chat_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_insurance_advisor/presentation/bloc/weather/weather_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/traffic/traffic_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/profile/profile_bloc.dart';

class AssistantChatWidget extends StatefulWidget {
  const AssistantChatWidget({super.key});

  @override
  State<AssistantChatWidget> createState() => _AssistantChatWidgetState();
}

class _AssistantChatWidgetState extends State<AssistantChatWidget> {
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

    // Simuler une réponse de l'IA
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
    
    // ===== SALUTATIONS =====
    if (msg.contains('bonjour') || msg.contains('salut') || msg.contains('hey')) {
      return 'Bonjour ! 👋 Comment puis-je vous aider aujourd\'hui ? N\'hésitez pas à me poser vos questions sur les assurances.';
    }
    
    // ===== ASSURANCE AUTO =====
    if (msg.contains('auto') || msg.contains('voiture') || msg.contains('véhicule') || msg.contains('car')) {
      return '🚗 Pour votre assurance auto, je vous recommande notre formule **"Conduite Sereine"** :\n\n'
          '✅ Protection tous risques\n'
          '✅ Assistance 24/7 et dépannage\n'
          '✅ Prise en charge rapide des sinistres\n'
          '✅ Rabais de 15% la première année\n'
          '✅ Bonus-Malus avantageux\n\n'
          'Souhaitez-vous un devis personnalisé ? 📄';
    }
    
    // ===== ASSURANCE HABITATION =====
    if (msg.contains('maison') || msg.contains('habitation') || msg.contains('appartement') || msg.contains('home')) {
      return '🏠 Notre formule **"Home Secure"** vous offre :\n\n'
          '• Couverture multi-risques complète\n'
          '• Protection des biens mobiliers\n'
          '• Responsabilité civile\n'
          '• Assistance en cas de sinistre\n'
          '• Protection juridique incluse\n\n'
          'Puis-je vous envoyer un devis détaillé ? 📊';
    }
    
    // ===== ASSURANCE SANTÉ =====
    if (msg.contains('santé') || msg.contains('medical') || msg.contains('médecine') || msg.contains('health')) {
      return '🏥 Notre assurance santé **"Bien-Être"** propose :\n\n'
          '• Couverture médicale complète\n'
          '• Tiers payant généralisé\n'
          '• Remboursement rapide sous 48h\n'
          '• Accès à un large réseau de soins\n'
          '• Téléconsultation 24/7\n\n'
          'Souhaitez-vous en savoir plus sur les garanties ?';
    }
    
    // ===== CONSTAT / SINISTRE =====
    if (msg.contains('constat') || msg.contains('sinistre') || msg.contains('accident') || msg.contains('dommage')) {
      return '📋 Je comprends, je vais vous guider pour votre constat :\n\n'
          '1️⃣ Remplissez le constat amiable avec l\'autre conducteur\n'
          '2️⃣ Prenez des photos des dégâts (véhicules et environnement)\n'
          '3️⃣ Contactez notre service sinistre au 📞 1234\n'
          '4️⃣ Transmettez les documents via notre application\n\n'
          '💡 Astuce : Plus vite vous déclarez, plus vite vous êtes remboursé !\n\n'
          'Voulez-vous que je vous aide à remplir le constat ?';
    }
    
    // ===== DEVIS / PRIX =====
    if (msg.contains('prix') || msg.contains('tarif') || msg.contains('coût') || msg.contains('devis') || msg.contains('estimateur')) {
      return '💰 Pour vous faire un devis personnalisé, j\'ai besoin de quelques informations :\n\n'
          '• Type d\'assurance recherché (Auto, Habitation, Santé)\n'
          '• Montant des biens à assurer\n'
          '• Votre situation (conducteur, propriétaire, locataire)\n'
          '• Vos antécédents (bonus-malus, sinistres)\n\n'
          'Remplissons ensemble un devis rapide ? 🚀';
    }
    
    // ===== DOCUMENT / PDF =====
    if (msg.contains('document') || msg.contains('pdf') || msg.contains('contrat') || msg.contains('attestation')) {
      return '📄 Pour générer vos documents, je vous guide :\n\n'
          '1️⃣ Choisissez le type de document :\n'
          '   • Contrat d\'assurance\n'
          '   • Attestation d\'assurance\n'
          '   • Devis\n'
          '   • Constat amiable\n\n'
          '2️⃣ Vérifiez vos informations personnelles\n'
          '3️⃣ Validez et téléchargez en PDF\n\n'
          'Souhaitez-vous générer un document maintenant ? 📎';
    }
    
    // ===== PROTECTION / SECURITE =====
    if (msg.contains('protection') || msg.contains('sécurité') || msg.contains('security') || msg.contains('safe')) {
      return '🛡️ La sécurité est notre priorité ! Voici nos conseils :\n\n'
          '✅ Vérifiez régulièrement vos contrats\n'
          '✅ Signalez tout changement de situation\n'
          '✅ Utilisez l\'authentification biométrique\n'
          '✅ Conservez vos documents en lieu sûr\n'
          '✅ Activez les notifications d\'alerte\n\n'
          'Votre sécurité est notre engagement ! 🔒';
    }
    
    // ===== CONTACT / URGENCE =====
    if (msg.contains('contact') || msg.contains('urgence') || msg.contains('help') || msg.contains('assistance')) {
      return '📞 En cas d\'urgence, voici nos contacts :\n\n'
          '🚑 Assistance 24/7 : **1234**\n'
          '📱 Application mobile : Assistance instantanée\n'
          '💬 Chat en ligne : Disponible 24/24\n'
          '📧 Email : support@assuria.com\n\n'
          'Nous sommes là pour vous ! 🤝';
    }
    
    // ===== MERCI =====
    if (msg.contains('merci') || msg.contains('thank you') || msg.contains('thx')) {
      return 'Avec plaisir ! 🌟 N\'hésitez pas si vous avez d\'autres questions. Je suis là pour vous accompagner dans vos démarches.\n\n'
          'Bonne journée et roulez prudemment ! 🚗';
    }
    
    // ===== RÉPONSE GÉNÉRIQUE =====
    return 'Je comprends votre demande. 🤔 Pour mieux vous aider, pourriez-vous me préciser :\n\n'
        '• Quel type d\'assurance vous intéresse ? (Auto, Habitation, Santé)\n'
        '• Souhaitez-vous un devis ?\n'
        '• Avez-vous besoin d\'aide pour un constat ?\n'
        '• Voulez-vous générer des documents ?\n\n'
        'Je suis là pour vous guider ! 💪';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
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
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser ? null : const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                ),
                color: isUser ? const Color(0xFF1F2937) : null,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: isUser ? null : [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
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
              width: 32,
              height: 32,
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
                  size: 18,
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
          SizedBox(width: 42),
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
            onPressed: () {},
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