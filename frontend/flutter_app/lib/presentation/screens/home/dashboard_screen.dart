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
import 'package:ai_insurance_advisor/presentation/widgets/map_traffic_widget.dart';
import 'package:ai_insurance_advisor/presentation/widgets/reminder_card.dart';
import 'package:ai_insurance_advisor/presentation/widgets/assistant_personal_widget.dart';
import 'package:ai_insurance_advisor/presentation/bloc/notifications/notifications_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/profile/profile_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/auth/auth_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/weather/weather_bloc.dart';
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
    // Charger la météo avec des coordonnées par défaut (Tunis)
    context.read<WeatherBloc>().add(const LoadWeatherEvent(
      latitude: 36.8065,
      longitude: 10.1815,
    ));
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
              onPressed: () {},
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
// DASHBOARD HOME - DESIGN DYNAMIQUE ET INNOVANT
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
              _buildWeatherBanner().animate().fadeIn(duration: 500.ms, delay: 100.ms),
              const SizedBox(height: 14),
              _buildQuickStats().animate().fadeIn(duration: 500.ms, delay: 150.ms),
              const SizedBox(height: 14),
              _buildAssistantWidget().animate().fadeIn(duration: 500.ms, delay: 200.ms),
              const SizedBox(height: 14),
              _buildSmartCards().animate().fadeIn(duration: 500.ms, delay: 250.ms),
              const SizedBox(height: 14),
              _buildSectionTitle('Activité en temps réel', Icons.trending_up)
                  .animate().fadeIn(duration: 400.ms, delay: 300.ms),
              const SizedBox(height: 6),
              _buildActivityCards().animate().fadeIn(duration: 500.ms, delay: 350.ms),
              const SizedBox(height: 14),
              _buildSectionTitle('Trafic en temps réel', Icons.traffic)
                  .animate().fadeIn(duration: 400.ms, delay: 400.ms),
              const SizedBox(height: 6),
              const MapTrafficWidget().animate().fadeIn(duration: 500.ms, delay: 450.ms),
              const SizedBox(height: 14),
              _buildSectionTitle('Rappels et Notifications', Icons.notifications_active)
                  .animate().fadeIn(duration: 400.ms, delay: 500.ms),
              const SizedBox(height: 6),
              const ReminderCard().animate().fadeIn(duration: 500.ms, delay: 550.ms),
              const SizedBox(height: 16),
              _buildFooter().animate().fadeIn(duration: 400.ms, delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    context.read<NotificationsBloc>().add(const LoadNotificationsEvent());
    context.read<ProfileBloc>().add(const LoadProfileEvent());
    context.read<WeatherBloc>().add(const LoadWeatherEvent(
      latitude: 36.8065,
      longitude: 10.1815,
    ));
    await Future<void>.delayed(const Duration(seconds: 1));
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HEADER AVEC MÉTÉO INTÉGRÉE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    final theme = Theme.of(context);
    
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String userName = 'Utilisateur';
        String userInitials = 'U';
        
        if (authState is AuthAuthenticated) {
          userName = authState.user.fullName;
          userInitials = authState.user.initials;
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
                      'Votre assurance intelligente',
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
                    context.go('/dashboard/notifications');
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
  // BANNER MÉTÉO UNIFIÉ
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildWeatherBanner() {
    return BlocBuilder<WeatherBloc, WeatherState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.blue.shade600,
                Colors.blue.shade400,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              if (state is WeatherLoaded) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getWeatherIcon(state.condition),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${state.temperature.toStringAsFixed(0)}°C',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        state.condition,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.umbrella,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(state.humidity * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (state is WeatherLoading) ...[
                const Expanded(
                  child: Row(
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Chargement...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.wb_sunny,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Météo disponible',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  IconData _getWeatherIcon(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains('soleil') || cond.contains('ensoleillé')) return Icons.wb_sunny;
    if (cond.contains('pluie') || cond.contains('averse')) return Icons.grain;
    if (cond.contains('nuage')) return Icons.cloud;
    if (cond.contains('brouillard') || cond.contains('brume')) return Icons.cloud_queue;
    if (cond.contains('neige')) return Icons.ac_unit;
    if (cond.contains('orage')) return Icons.flash_on;
    return Icons.wb_sunny;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STATS RAPIDES - DESIGN MODERNE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildQuickStats() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return _buildLoadingStats();
        }

        String assuranceStatus = 'En attente';
        String primeValue = '-- TND';
        String scoreValue = '--%';
        Color assuranceColor = const Color(0xFF667eea);
        Color primeColor = const Color(0xFF667eea);
        Color scoreColor = const Color(0xFF667eea);

        if (state is ProfileLoaded) {
          final profile = state.profile;
          final insuranceStatus = profile['insurance_status'] as String? ?? 'active';
          assuranceStatus = insuranceStatus == 'active' ? 'Active ✓' : 'Inactive ✗';
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
              child: _buildStatCard(
                icon: Icons.verified_rounded,
                label: 'Assurance',
                value: assuranceStatus,
                color: assuranceColor,
                gradient: [assuranceColor.withValues(alpha: 0.1), Colors.white],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                icon: Icons.attach_money_rounded,
                label: 'Prime',
                value: primeValue,
                color: primeColor,
                gradient: [primeColor.withValues(alpha: 0.1), Colors.white],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                icon: Icons.star_rounded,
                label: 'Score',
                value: scoreValue,
                color: scoreColor,
                gradient: [scoreColor.withValues(alpha: 0.1), Colors.white],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingStats() {
    return Row(
      children: List.generate(3, (index) => 
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: _buildCardShadow(),
            ),
            child: Column(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
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
              ],
            ),
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: _buildCardShadow(),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ASSISTANT PERSONAL WIDGET
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildAssistantWidget() {
    return const AssistantPersonalWidget();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SMART CARDS - SERVICES INNOVANTS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSmartCards() {
    final cards = [
      _SmartCardData(
        icon: Icons.description_rounded,
        title: 'Déclaration IA',
        subtitle: 'Constat intelligent',
        color: Colors.blue,
        route: '/dashboard/declaration_chat',
        gradient: [Colors.blue.shade400, Colors.blue.shade600],
      ),
      _SmartCardData(
        icon: Icons.chat_rounded,
        title: 'Assistant IA',
        subtitle: 'Conseils personnalisés',
        color: Colors.purple,
        route: '/dashboard/conseil_chat',
        gradient: [Colors.purple.shade400, Colors.purple.shade600],
      ),
      _SmartCardData(
        icon: Icons.shield_rounded,
        title: 'Prévention',
        subtitle: 'Alertes sécurité',
        color: Colors.green,
        route: '/dashboard/prevention',
        gradient: [Colors.green.shade400, Colors.green.shade600],
      ),
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return GestureDetector(
            onTap: () => context.go(card.route),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.3,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: card.gradient,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: card.color.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(card.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    card.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    card.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 9,
                    ),
                    maxLines: 1,
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
  // ACTIVITY CARDS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildActivityCards() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final activities = [
          _ActivityData(
            icon: Icons.directions_car_rounded,
            label: 'Véhicules',
            value: state is ProfileLoaded 
                ? (state.profile['vehicles_count'] as int? ?? 1).toString()
                : '0',
            color: const Color(0xFF667eea),
          ),
          _ActivityData(
            icon: Icons.assignment_rounded,
            label: 'Contrats',
            value: state is ProfileLoaded
                ? (state.profile['contracts_count'] as int? ?? 2).toString()
                : '0',
            color: Colors.green,
          ),
          _ActivityData(
            icon: Icons.notifications_rounded,
            label: 'Alertes',
            value: state is ProfileLoaded
                ? (state.profile['alerts_count'] as int? ?? 5).toString()
                : '0',
            color: Colors.orange,
          ),
        ];

        return Row(
          children: activities.map((activity) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade100,
                    width: 1,
                  ),
                  boxShadow: _buildCardShadow(),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: activity.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        activity.icon,
                        size: 18,
                        color: activity.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      activity.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
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
              'AssurIA v2.0',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Intelligent • Sécurisé • Innovant',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[400],
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Votre assurance nouvelle génération',
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[400],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
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

// ═══════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════════════

class _SmartCardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;
  final List<Color> gradient;

  _SmartCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
    required this.gradient,
  });
}

class _ActivityData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  _ActivityData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}