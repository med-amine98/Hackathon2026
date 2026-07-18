// lib/presentation/screens/prevention/prevention_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/profile/profile_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/traffic/traffic_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/weather/weather_bloc.dart';

class PreventionScreen extends StatelessWidget {
  const PreventionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Prévention intelligente'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: () {
              context.read<WeatherBloc>().add(const LoadWeatherEvent(
                latitude: 36.8065,
                longitude: 10.1815,
              ));
              context.read<TrafficBloc>().add(const LoadTrafficEvent(
                lat: 36.8065,
                lon: 10.1815,
              ));
              context.read<ProfileBloc>().add(const LoadProfileEvent());
            },
          ),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _WeatherCard(),
            SizedBox(height: 16),
            _RiskCard(),
            SizedBox(height: 16),
            _RecommendationsCard(),
            SizedBox(height: 16),
            _TipsCard(),
            SizedBox(height: 16),
            _TrafficCard(),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// MÉTÉO
// ═══════════════════════════════════════════════════════════════════════

class _WeatherCard extends StatelessWidget {
  const _WeatherCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeatherBloc, WeatherState>(
      builder: (context, state) {
        if (state is WeatherLoading) {
          return _cardLoading('Chargement de la météo...');
        }
        if (state is WeatherError) {
          return _cardError('Météo indisponible');
        }
        if (state is WeatherLoaded) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                const Icon(Icons.wb_sunny, size: 40, color: Colors.orange),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${state.temperature.toStringAsFixed(0)}°C',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        state.condition,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(state.humidity * 100).toInt()}%',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SCORE DE RISQUE AVEC RANDOM FOREST
// ═══════════════════════════════════════════════════════════════════════

class _RiskCard extends StatelessWidget {
  const _RiskCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return _cardLoading('Analyse du profil en cours...');
        }
        if (state is ProfileError) {
          return _cardError('Score indisponible');
        }
        if (state is ProfileLoaded) {
          final profile = state.profile;
          final score = profile['risk_score'] as double? ?? 0;
          final level = profile['risk_level'] as String? ?? 'Non évalué';
          final factors = (profile['risk_factors'] as List<dynamic>?)?.cast<String>() ?? [];
          
          final color = _getRiskColor(level);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.science_rounded, size: 40, color: color),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            score == 0 ? 'Analyse en cours' : 'Score: ${score.toInt()}%',
                            style: TextStyle(
                              fontSize: score == 0 ? 16 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Niveau: $level',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getRiskEmoji(level),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        level,
                        style: TextStyle(color: color, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (score > 0) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      color: color,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _getRiskDescription(level),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                if (factors.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  const Text(
                    '🎯 Facteurs analysés :',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...factors.map((factor) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            factor,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  String _getRiskLevelName(String level) {
    switch (level) {
      case 'Faible':
        return 'Faible';
      case 'Moyen':
        return 'Moyen';
      case 'Élevé':
        return 'Élevé';
      default:
        return 'Non évalué';
    }
  }

  String _getRiskEmoji(String level) {
    switch (level) {
      case 'Faible':
        return '🟢';
      case 'Moyen':
        return '🟡';
      case 'Élevé':
        return '🔴';
      default:
        return '⚪';
    }
  }

  Color _getRiskColor(String level) {
    switch (level) {
      case 'Faible':
        return Colors.green;
      case 'Moyen':
        return Colors.orange;
      case 'Élevé':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getRiskDescription(String level) {
    switch (level) {
      case 'Faible':
        return 'Excellent ! Votre profil présente un faible risque. Vous bénéficiez des meilleurs tarifs.';
      case 'Moyen':
        return 'Votre profil présente un risque modéré. Quelques ajustements peuvent améliorer votre score.';
      case 'Élevé':
        return 'Votre profil présente un risque élevé. Nous vous recommandons de consulter nos conseils de sécurité.';
      default:
        return 'Complétez votre profil pour obtenir une évaluation personnalisée de votre risque.';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// RECOMMANDATIONS PERSONNALISÉES
// ═══════════════════════════════════════════════════════════════════════

class _RecommendationsCard extends StatelessWidget {
  const _RecommendationsCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is! ProfileLoaded) {
          return const SizedBox.shrink();
        }

        final recommendations = (state.profile['recommendations'] as List<dynamic>?)?.cast<String>() ?? [];

        if (recommendations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    '💡 Recommandations personnalisées',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...recommendations.map((rec) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.arrow_right_rounded, color: Colors.blue),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        rec,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CONSEILS DE SÉCURITÉ
// ═══════════════════════════════════════════════════════════════════════

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔒 Conseils de sécurité',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _tipItem(Icons.car_repair, 'Vérifiez vos pneus et freins régulièrement'),
          _tipItem(Icons.document_scanner, 'Assurez-vous que vos papiers sont à jour'),
          _tipItem(Icons.emergency, 'Ayez toujours un gilet et triangle dans votre véhicule'),
          _tipItem(Icons.speed, 'Respectez les limitations de vitesse'),
          _tipItem(Icons.phone, 'Ayez les numéros d\'urgence à portée de main'),
        ],
      ),
    );
  }

  Widget _tipItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TRAFIC
// ═══════════════════════════════════════════════════════════════════════

class _TrafficCard extends StatelessWidget {
  const _TrafficCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrafficBloc, TrafficState>(
      builder: (context, state) {
        if (state is TrafficLoading) {
          return _cardLoading('Chargement du trafic...');
        }
        if (state is TrafficError) {
          return _cardError('Trafic indisponible');
        }
        if (state is TrafficLoaded) {
          final count = state.incidents.length;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                Icon(
                  count == 0 ? Icons.check_circle : Icons.warning,
                  size: 40,
                  color: count == 0 ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    count == 0
                        ? '✅ Trafic fluide - Aucun incident signalé'
                        : '⚠️ $count incident(s) signalé(s) sur votre trajet',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// FONCTIONS UTILITAIRES
// ═══════════════════════════════════════════════════════════════════════

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.shade300,
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

Widget _cardLoading(String text) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(),
    child: Row(
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text(text),
      ],
    ),
  );
}

Widget _cardError(String text) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade400),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: Colors.red.shade700)),
      ],
    ),
  );
}