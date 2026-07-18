// lib/presentation/widgets/assistant_personal_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_insurance_advisor/presentation/bloc/weather/weather_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/traffic/traffic_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/profile/profile_bloc.dart';

class AssistantPersonalWidget extends StatefulWidget {
  const AssistantPersonalWidget({super.key});

  @override
  State<AssistantPersonalWidget> createState() => _AssistantPersonalWidgetState();
}

class _AssistantPersonalWidgetState extends State<AssistantPersonalWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _HeaderWidget(),
            SizedBox(height: 12),
            _MainContentWidget(),
            SizedBox(height: 12),
            _ActionButtonsWidget(),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HEADER WIDGET
// ═══════════════════════════════════════════════════════════════════════

class _HeaderWidget extends StatelessWidget {
  const _HeaderWidget();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar IA animé
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
          ),
          child: Stack(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(
                  'https://ui-avatars.com/api/?name=AI&background=ffffff&color=667eea&size=50',
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mon Assistant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              BlocBuilder<WeatherBloc, WeatherState>(
                builder: (context, state) {
                  if (state is WeatherLoaded) {
                    return Text(
                      'Bonjour ! Il fait ${state.temperature.toStringAsFixed(0)}°C aujourd\'hui',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    );
                  }
                  return Text(
                    'Prêt à vous assister',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// MAIN CONTENT WIDGET
// ═══════════════════════════════════════════════════════════════════════

class _MainContentWidget extends StatelessWidget {
  const _MainContentWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: const Column(
        children: [
          _ConseilDuJourWidget(),
          SizedBox(height: 10),
          _StatsRealtimeWidget(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CONSEIL DU JOUR WIDGET
// ═══════════════════════════════════════════════════════════════════════

class _ConseilDuJourWidget extends StatelessWidget {
  const _ConseilDuJourWidget();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeatherBloc, WeatherState>(
      builder: (context, weatherState) {
        String conseil = 'Vérifiez vos pneus avant de prendre la route';
        IconData icon = Icons.check_circle_outline;
        Color iconColor = Colors.green;

        if (weatherState is WeatherLoaded) {
          final temp = weatherState.temperature;
          final condition = weatherState.condition.toLowerCase();

          if (temp > 35) {
            conseil = '🌡️ Chaleur extrême : Vérifiez le liquide de refroidissement';
            icon = Icons.warning_amber_rounded;
            iconColor = Colors.orange;
          } else if (temp < 5) {
            conseil = '❄️ Température basse : Pensez à l\'antigel';
            icon = Icons.ac_unit;
            iconColor = Colors.blue;
          } else if (condition.contains('pluie') || condition.contains('averse')) {
            conseil = '🌧️ Pluie : Réduisez votre vitesse et allumez vos feux';
            icon = Icons.grain;
            iconColor = Colors.blue;
          } else if (condition.contains('brouillard') || condition.contains('brume')) {
            conseil = '🌫️ Brouillard : Allumez vos feux de brouillard';
            icon = Icons.cloud;
            iconColor = Colors.grey;
          }
        }

        return Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                conseil,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.3,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// STATS REALTIME WIDGET
// ═══════════════════════════════════════════════════════════════════════

class _StatsRealtimeWidget extends StatelessWidget {
  const _StatsRealtimeWidget();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _StatItemWidget(
            icon: Icons.thermostat_rounded,
            label: 'Météo',
          ),
        ),
        const VerticalDivider(color: Colors.white24, width: 16),
        const Expanded(
          child: _StatItemWidget(
            icon: Icons.traffic_rounded,
            label: 'Trafic',
          ),
        ),
        const VerticalDivider(color: Colors.white24, width: 16),
        const Expanded(
          child: _StatItemWidget(
            icon: Icons.shield_rounded,
            label: 'Protection',
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// STAT ITEM WIDGET - Version corrigée avec BlocBuilder intégré
// ═══════════════════════════════════════════════════════════════════════

class _StatItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatItemWidget({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.6)),
        const SizedBox(height: 4),
        _buildValueWidget(),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildValueWidget() {
    // Déterminer quel BlocBuilder utiliser en fonction du label
    if (label == 'Météo') {
      return BlocBuilder<WeatherBloc, WeatherState>(
        builder: (context, state) {
          if (state is WeatherLoaded) {
            return Text(
              '${state.temperature.toStringAsFixed(0)}°C',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }
          return const Text(
            '--',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        },
      );
    } else if (label == 'Trafic') {
      return BlocBuilder<TrafficBloc, TrafficState>(
        builder: (context, state) {
          if (state is TrafficLoaded) {
            return Text(
              state.isCongested ? 'Dense' : 'Fluide',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }
          return const Text(
            '--',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        },
      );
    } else if (label == 'Protection') {
      return BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoaded) {
            return const Text(
              'Active',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }
          return const Text(
            '--',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        },
      );
    } else {
      return const Text(
        '--',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ACTION BUTTONS WIDGET
// ═══════════════════════════════════════════════════════════════════════

class _ActionButtonsWidget extends StatelessWidget {
  const _ActionButtonsWidget();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.go('/dashboard/conseil_chat'),
            icon: const Icon(Icons.chat_rounded, size: 18),
            label: const Text('Poser une question'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF667eea),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () => context.go('/dashboard/prevention'),
            icon: const Icon(Icons.notifications_active_rounded, color: Colors.white),
            tooltip: 'Alertes',
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () => context.go('/dashboard/declaration_chat'),
            icon: const Icon(Icons.description_rounded, color: Colors.white),
            tooltip: 'Déclaration',
          ),
        ),
      ],
    );
  }
}