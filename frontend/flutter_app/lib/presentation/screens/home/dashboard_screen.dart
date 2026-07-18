// lib/presentation/screens/home/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_insurance_advisor/presentation/screens/chat/chat_screen.dart';
import 'package:ai_insurance_advisor/presentation/screens/profile/profile_screen.dart';
import 'package:ai_insurance_advisor/presentation/screens/declaration/declaration_screen.dart';
import 'package:ai_insurance_advisor/presentation/screens/conseil/conseil_screen.dart';
import 'package:ai_insurance_advisor/presentation/screens/prevention/prevention_screen.dart';
import 'package:ai_insurance_advisor/presentation/screens/conseil/conseil_chat_screen.dart';
import 'package:ai_insurance_advisor/presentation/screens/declaration/declaration_chat_screen.dart';
import 'package:ai_insurance_advisor/presentation/widgets/weather_traffic_widget.dart';
import 'package:ai_insurance_advisor/presentation/widgets/map_traffic_widget.dart';
import 'package:ai_insurance_advisor/presentation/widgets/quick_actions.dart';
import 'package:ai_insurance_advisor/presentation/widgets/reminder_card.dart';
import 'package:ai_insurance_advisor/presentation/bloc/notifications/notifications_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/profile/profile_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/auth/auth_bloc.dart';
import 'package:ai_insurance_advisor/app/theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardHome(),
    ChatScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    context.read<NotificationsBloc>().add(const LoadNotificationsEvent());
    context.read<ProfileBloc>().add(const LoadProfileEvent());
  }

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final routeName = route?.settings.name ?? '';
    final isSubRoute = routeName.contains('declaration') ||
                       routeName.contains('conseil') ||
                       routeName.contains('prevention') ||
                       routeName.contains('conseil_chat') ||
                       routeName.contains('declaration_chat');

    return Scaffold(
      body: SafeArea(
        child: isSubRoute
            ? _buildSubRouteContent(context, routeName)
            : IndexedStack(
                index: _selectedIndex,
                children: _screens,
              ),
      ),
      bottomNavigationBar: isSubRoute
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) => setState(() => _selectedIndex = index),
                type: BottomNavigationBarType.fixed,
                selectedItemColor: AppTheme.primaryColor,
                unselectedItemColor: Colors.grey,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_outlined),
                    activeIcon: Icon(Icons.dashboard),
                    label: 'Accueil',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.chat_outlined),
                    activeIcon: Icon(Icons.chat),
                    label: 'Assistant',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profil',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSubRouteContent(BuildContext context, String routeName) {
    Widget child;
    if (routeName.contains('declaration_chat')) {
      child = const DeclarationChatScreen();
    } else if (routeName.contains('conseil_chat')) {
      child = const ConseilChatScreen();
    } else if (routeName.contains('declaration')) {
      child = const DeclarationScreen();
    } else if (routeName.contains('conseil')) {
      child = const ConseilScreen();
    } else if (routeName.contains('prevention')) {
      child = const PreventionScreen();
    } else {
      child = const DashboardHome();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle(routeName)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          if (routeName.contains('declaration_chat') || routeName.contains('conseil_chat'))
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Rafraîchir la conversation
              },
              tooltip: 'Nouvelle conversation',
            ),
        ],
      ),
      body: child,
    );
  }

  String _getAppBarTitle(String routeName) {
    if (routeName.contains('declaration_chat')) return 'Déclaration - Constat';
    if (routeName.contains('conseil_chat')) return 'Conseiller IA';
    if (routeName.contains('declaration')) return 'Déclaration guidée';
    if (routeName.contains('conseil')) return 'Conseils personnalisés';
    if (routeName.contains('prevention')) return 'Prévention intelligente';
    return 'Tableau de bord';
  }
}

// ============================================================
// DASHBOARD HOME - DESIGN COMPLET ET PROFESSIONNEL
// ============================================================

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF667eea).withValues(alpha: 0.06),
            Colors.white,
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF667eea),
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader().animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
              const SizedBox(height: 14),
              _buildQuickStats().animate().fadeIn(duration: 500.ms, delay: 100.ms),
              const SizedBox(height: 14),
              _buildServiceCards().animate().fadeIn(duration: 500.ms, delay: 150.ms),
              const SizedBox(height: 14),
              const WeatherTrafficWidget().animate().fadeIn(duration: 500.ms, delay: 200.ms),
              const SizedBox(height: 14),
              _buildSectionTitle('Trafic en temps réel', Icons.traffic)
                  .animate().fadeIn(duration: 400.ms, delay: 300.ms),
              const SizedBox(height: 6),
              const MapTrafficWidget().animate().fadeIn(duration: 500.ms, delay: 350.ms),
              const SizedBox(height: 14),
              _buildSectionTitle('Rappels et Notifications', Icons.notifications_active)
                  .animate().fadeIn(duration: 400.ms, delay: 400.ms),
              const SizedBox(height: 6),
              const ReminderCard().animate().fadeIn(duration: 500.ms, delay: 450.ms),
              const SizedBox(height: 14),
              _buildSectionTitle('Actions rapides', Icons.flash_on)
                  .animate().fadeIn(duration: 400.ms, delay: 500.ms),
              const SizedBox(height: 6),
              const QuickActions().animate().fadeIn(duration: 500.ms, delay: 550.ms),
              const SizedBox(height: 14),
              _buildSectionTitle('Statistiques', Icons.trending_up)
                  .animate().fadeIn(duration: 400.ms, delay: 600.ms),
              const SizedBox(height: 6),
              _buildStats().animate().fadeIn(duration: 500.ms, delay: 650.ms),
              const SizedBox(height: 16),
              _buildFooter().animate().fadeIn(duration: 400.ms, delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    context.read<NotificationsBloc>().add(const LoadNotificationsEvent());
    context.read<ProfileBloc>().add(const LoadProfileEvent());
    await Future<void>.delayed(const Duration(seconds: 1));
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    final theme = Theme.of(context);
    
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String userName = 'Utilisateur';
        String userInitials = 'U';
        
        if (state is AuthAuthenticated) {
          userName = state.user.fullName;
          userInitials = state.user.initials;
        }
        
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    userInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour $userName 👋',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bienvenue sur votre tableau de bord',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () {
                    // Naviguer vers les notifications
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔔 Notifications'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Badge(
                    isLabelVisible: true,
                    child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STATS RAPIDES
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildQuickStats() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        String assuranceStatus = 'En attente';
        String primeValue = '-- TND';
        String scoreValue = '--%';
        Color assuranceColor = const Color(0xFF667eea);
        Color primeColor = const Color(0xFF667eea);
        Color scoreColor = const Color(0xFF667eea);

        if (state is ProfileLoading) {
          return Row(
            children: [
              Expanded(child: _buildQuickStatItemLoading()),
              const SizedBox(width: 8),
              Expanded(child: _buildQuickStatItemLoading()),
              const SizedBox(width: 8),
              Expanded(child: _buildQuickStatItemLoading()),
            ],
          );
        }

        if (state is ProfileLoaded) {
          final profile = state.profile;
          
          final insuranceStatus = profile['insurance_status'] as String? ?? 'active';
          assuranceStatus = insuranceStatus == 'active' ? 'Active' : 'Inactive';
          assuranceColor = insuranceStatus == 'active' ? Colors.green : Colors.red;
          
          final monthlyPremium = profile['monthly_premium'] as double? ?? 0;
          primeValue = monthlyPremium > 0 ? '${monthlyPremium.toStringAsFixed(0)} TND' : '-- TND';
          primeColor = monthlyPremium > 0 ? const Color(0xFF667eea) : Colors.grey;
          
          final riskScore = profile['risk_score'] as double? ?? 0;
          scoreValue = riskScore > 0 ? '${riskScore.toInt()}%' : '--%';
          scoreColor = _getScoreColor(riskScore);
        }

        return Row(
          children: [
            Expanded(
              child: _buildQuickStatItem(
                icon: Icons.verified_rounded,
                label: 'Assurance',
                value: assuranceStatus,
                color: assuranceColor,
                iconBgColor: assuranceColor.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickStatItem(
                icon: Icons.attach_money_rounded,
                label: 'Prime',
                value: primeValue,
                color: primeColor,
                iconBgColor: primeColor.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickStatItem(
                icon: Icons.star_rounded,
                label: 'Score',
                value: scoreValue,
                color: scoreColor,
                iconBgColor: scoreColor.withValues(alpha: 0.15),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Widget _buildQuickStatItemLoading() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _buildCardShadow(),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 4),
          Container(
            width: 25,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 15,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color iconBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _buildCardShadow(),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey[500],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SERVICE CARDS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildServiceCards() {
    final services = [
      {
        'icon': Icons.assignment_rounded,
        'title': 'Déclaration guidée',
        'description': 'Déclarez votre sinistre en quelques étapes',
        'color': Colors.blue,
        'route': '/dashboard/declaration',
        'iconColor': Colors.white,
      },
      {
        'icon': Icons.chat_rounded,
        'title': 'Déclaration Chat',
        'description': 'Remplissez le constat avec l\'IA',
        'color': Colors.teal,
        'route': '/dashboard/declaration_chat',
        'iconColor': Colors.white,
      },
      {
        'icon': Icons.lightbulb_rounded,
        'title': 'Conseils personnalisés',
        'description': 'Recommandations adaptées à votre profil',
        'color': const Color(0xFF7C3AED),
        'route': '/dashboard/conseil',
        'iconColor': Colors.white,
      },
      {
        'icon': Icons.chat_rounded,
        'title': 'Conseiller IA',
        'description': 'Chat pour choisir votre assurance',
        'color': Colors.pink,
        'route': '/dashboard/conseil_chat',
        'iconColor': Colors.white,
      },
      {
        'icon': Icons.shield_rounded,
        'title': 'Prévention intelligente',
        'description': 'Alertes et conseils pour votre sécurité',
        'color': Colors.green,
        'route': '/dashboard/prevention',
        'iconColor': Colors.white,
      },
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return GestureDetector(
            onTap: () => context.go(service['route'] as String),
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    service['color'] as Color,
                    (service['color'] as Color).withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (service['color'] as Color).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(service['icon'] as IconData, color: Colors.white, size: 16),
                  ),
                  const Spacer(),
                  Text(
                    service['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    service['description'] as String,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 9,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SECTION TITLE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFF667eea).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: const Color(0xFF667eea)),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STATISTIQUES
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildStats() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        String vehicleCount = '0';
        String contractCount = '0';
        String alertCount = '0';

        if (state is ProfileLoaded) {
          final profile = state.profile;
          vehicleCount = (profile['vehicles_count'] as int? ?? 1).toString();
          contractCount = (profile['contracts_count'] as int? ?? 2).toString();
          alertCount = (profile['alerts_count'] as int? ?? 5).toString();
        }

        final stats = [
          {
            'icon': Icons.directions_car_rounded,
            'value': vehicleCount,
            'label': 'Véhicule',
            'color': const Color(0xFF667eea),
          },
          {
            'icon': Icons.shield_rounded,
            'value': contractCount,
            'label': 'Contrats',
            'color': Colors.green,
          },
          {
            'icon': Icons.help_rounded,
            'value': alertCount,
            'label': 'Alertes',
            'color': Colors.orange,
          },
        ];

        return Row(
          children: stats.map((stat) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _buildCardShadow(),
                ),
                child: Column(
                  children: [
                    Icon(
                      stat['icon'] as IconData,
                      size: 18,
                      color: stat['color'] as Color,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat['value'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      stat['label'] as String,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FOOTER
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_rounded,
              size: 16,
              color: const Color(0xFF667eea).withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              'AssurIA v1.0',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Votre assurance intelligente',
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  List<BoxShadow> _buildCardShadow() {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ];
  }
}