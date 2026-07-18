// lib/presentation/widgets/assistant_personal_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_insurance_advisor/presentation/bloc/weather/weather_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/traffic/traffic_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/profile/profile_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/auth/auth_bloc.dart';

class AssistantPersonalWidget extends StatefulWidget {
  const AssistantPersonalWidget({super.key});

  @override
  State<AssistantPersonalWidget> createState() => _AssistantPersonalWidgetState();
}

class _AssistantPersonalWidgetState extends State<AssistantPersonalWidget> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addInitialMessage();
  }

  void _addInitialMessage() {
    _messages.add(ChatMessage(
      text: 'Bonjour ! Je suis votre assistant IA. Comment puis-je vous aider aujourd\'hui ?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
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

    // Simuler une réponse de l'IA
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          text: _getAIResponse(text),
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    });
  }

  String _getAIResponse(String userMessage) {
    final msg = userMessage.toLowerCase();
    
    if (msg.contains('bonjour') || msg.contains('salut')) {
      return 'Bonjour ! Je suis ravi de vous aider. Que puis-je faire pour vous aujourd\'hui ?';
    }
    
    if (msg.contains('assurance') || msg.contains('contrat')) {
      return 'Je peux vous aider à choisir l\'assurance qui vous correspond le mieux. Avez-vous déjà une idée du type de couverture que vous recherchez ? (Auto, Habitation, Santé, etc.)';
    }
    
    if (msg.contains('auto') || msg.contains('voiture') || msg.contains('véhicule')) {
      return 'Pour votre véhicule, je vous recommande notre formule "Conduite Sereine" qui inclut :\n• Protection tous risques\n• Assistance 24/7\n• Prise en charge rapide\n• Rabais de 15% la première année\nSouhaitez-vous plus de détails ?';
    }
    
    if (msg.contains('maison') || msg.contains('habitation') || msg.contains('appartement')) {
      return 'Pour votre habitation, notre formule "Home Secure" vous offre :\n• Couverture multi-risques\n• Protection des biens\n• Responsabilité civile\n• Assistance en cas de sinistre\nPuis-je vous envoyer un devis ?';
    }
    
    if (msg.contains('santé') || msg.contains('medical')) {
      return 'Notre assurance santé "Bien-Être" propose :\n• Couverture médicale complète\n• Tiers payant\n• Remboursement rapide\n• Accès à un réseau de soins\nAvez-vous besoin d\'informations spécifiques ?';
    }
    
    if (msg.contains('constat') || msg.contains('sinistre') || msg.contains('accident')) {
      return 'Je comprends que vous ayez besoin d\'aide pour votre constat. Voici les étapes à suivre :\n\n1. Remplissez le constat amiable avec l\'autre conducteur\n2. Prenez des photos des dégâts\n3. Contactez notre service sinistre au 1234\n4. Transmettez-nous les documents via notre application\n\nPuis-je vous guider dans cette démarche ?';
    }
    
    if (msg.contains('prix') || msg.contains('tarif') || msg.contains('coût')) {
      return 'Nos tarifs varient selon le type de couverture et votre profil. Pour vous donner une estimation précise, j\'aurais besoin de quelques informations. Souhaitez-vous un devis personnalisé ?';
    }
    
    if (msg.contains('document') || msg.contains('pdf') || msg.contains('contrat')) {
      return 'Je peux vous aider à générer vos documents. Pour un contrat d\'assurance, j\'ai besoin de :\n• Vos informations personnelles\n• Le type de couverture souhaité\n• La période d\'assurance\n• Les biens à assurer\nVoulez-vous commencer ?';
    }
    
    if (msg.contains('merci') || msg.contains('merci beaucoup')) {
      return 'Avec plaisir ! N\'hésitez pas si vous avez d\'autres questions. Je suis là pour vous aider. 😊';
    }
    
    if (msg.contains('aide') || msg.contains('help')) {
      return 'Je suis là pour vous aider ! Voici ce que je peux faire :\n\n• 💬 Vous conseiller sur le choix d\'une assurance\n• 📋 Vous aider avec le constat\n• 📊 Vous donner des devis\n• 📄 Générer des documents\n• 🔔 Vous alerter sur les risques\nQue souhaitez-vous explorer ?';
    }
    
    return 'Je comprends votre demande. Pour mieux vous aider, pourriez-vous me donner plus de détails ? Que recherchez-vous exactement ? (Assurance auto, habitation, santé, aide au constat, etc.)';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6),
            const Color(0xFF60A5FA),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildChatMessages(),
            const SizedBox(height: 8),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.chat_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assistant IA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '🟢 En ligne - Réponse instantanée',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                color: Colors.green,
                size: 8,
              ),
              SizedBox(width: 4),
              Text(
                'En ligne',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatMessages() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.3,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(12),
        itemCount: _messages.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _messages.length && _isLoading) {
            return _buildLoadingIndicator();
          }
          final message = _messages[index];
          return _buildMessageBubble(message);
        },
      ),
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
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Center(
                child: Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFF3B82F6),
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser 
                    ? const Color(0xFF3B82F6) 
                    : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(
                  isUser ? 16 : 16,
                ).copyWith(
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.white,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 16,
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
          SizedBox(width: 36),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white70,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Assistant écrit...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _messageController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Poser une question...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: IconButton(
            onPressed: _sendMessage,
            icon: const Icon(
              Icons.send_rounded,
              color: Color(0xFF3B82F6),
              size: 22,
            ),
            padding: const EdgeInsets.all(10),
          ),
        ),
      ],
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