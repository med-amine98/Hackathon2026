// lib/presentation/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/profile/profile_bloc.dart';
// ✅ Supprimer les imports de profile_event et profile_state
// car ils sont déjà inclus via profile_bloc.dart
// ✅ Supprimer les imports unused

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Charger le profil
    context.read<ProfileBloc>().add(const LoadProfileEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erreur: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ProfileBloc>().add(const LoadProfileEvent());
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (state is ProfileLoaded) {
            final profile = state.profile;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard('Informations personnelles', [
                    _buildInfoRow(
                      'Âge', 
                      (profile['age'] as int?)?.toString() ?? 'Non renseigné'
                    ),
                    _buildInfoRow(
                      'Ville', 
                      profile['city'] as String? ?? 'Non renseigné'
                    ),
                    _buildInfoRow(
                      'Profession', 
                      profile['occupation'] as String? ?? 'Non renseigné'
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoCard('Véhicule', [
                    _buildInfoRow(
                      'Marque', 
                      profile['vehicle_make'] as String? ?? 'Non renseigné'
                    ),
                    _buildInfoRow(
                      'Modèle', 
                      profile['vehicle_model'] as String? ?? 'Non renseigné'
                    ),
                    _buildInfoRow(
                      'Année', 
                      (profile['vehicle_year'] as int?)?.toString() ?? 'Non renseigné'
                    ),
                    _buildInfoRow(
                      'Kilométrage', 
                      (profile['annual_km'] as int?)?.toString() ?? 'Non renseigné'
                    ),
                    _buildInfoRow(
                      'Utilisation', 
                      profile['vehicle_usage'] as String? ?? 'Non renseigné'
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoCard('Budget', [
                    _buildInfoRow(
                      'Budget mensuel', 
                      profile['budget_monthly'] != null 
                        ? '${profile['budget_monthly']} TND' 
                        : 'Non renseigné'
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildRiskCard(profile),
                ],
              ),
            );
          }

          return const Center(child: Text('Aucune donnée de profil'));
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
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
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildRiskCard(Map<String, dynamic> profile) {
    final riskScore = profile['risk_score'] as double?;
    final riskLevel = profile['risk_level'] as String? ?? 'Non évalué';
    final riskFactors = (profile['risk_factors'] as List<dynamic>?)?.cast<String>() ?? [];

    Color getRiskColor(String level) {
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

    return Card(
      color: getRiskColor(riskLevel).withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '📊 Score de risque',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: getRiskColor(riskLevel),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    riskScore != null ? '${riskScore.toInt()}/100' : 'N/A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Niveau : $riskLevel',
              style: TextStyle(
                color: getRiskColor(riskLevel),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (riskFactors.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Facteurs de risque :',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              ...riskFactors.map((factor) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(factor)),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}