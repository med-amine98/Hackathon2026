// lib/presentation/widgets/car_health_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/car_health/car_health_bloc.dart';

class CarHealthCard extends StatefulWidget {
  const CarHealthCard({super.key});

  @override
  State<CarHealthCard> createState() => _CarHealthCardState();
}

class _CarHealthCardState extends State<CarHealthCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Santé du véhicule',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    context.read<CarHealthBloc>().add(const RefreshCarHealthEvent());
                  },
                  child: const Text('Actualiser'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            BlocBuilder<CarHealthBloc, CarHealthState>(
              builder: (context, state) {
                if (state is CarHealthLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is CarHealthError) {
                  return Center(
                    child: Text('Erreur: ${state.message}'),
                  );
                }

                if (state is CarHealthLoaded) {
                  final data = state.data;
                  return Column(
                    children: [
                      _buildHealthItem(
                        icon: Icons.opacity,
                        label: 'Niveau d\'eau',
                        // ✅ CORRIGÉ : Cast explicite en String
                        value: (data['water_level'] as String?) ?? 'Ok',
                        status: (data['water_status'] as String?) ?? 'good',
                      ),
                      _buildHealthItem(
                        icon: Icons.oil_barrel,
                        label: 'Niveau d\'huile',
                        value: (data['oil_level'] as String?) ?? 'Ok',
                        status: (data['oil_status'] as String?) ?? 'good',
                      ),
                      _buildHealthItem(
                        icon: Icons.battery_full,
                        label: 'Batterie',
                        value: (data['battery'] as String?) ?? '12.4V',
                        status: (data['battery_status'] as String?) ?? 'good',
                      ),
                      _buildHealthItem(
                        icon: Icons.speed,
                        label: 'Pression pneus',
                        value: (data['tire_pressure'] as String?) ?? '2.4 bar',
                        status: (data['tire_status'] as String?) ?? 'good',
                      ),
                      _buildHealthItem(
                        icon: Icons.thermostat,
                        label: 'Température moteur',
                        value: (data['engine_temp'] as String?) ?? '85°C',
                        status: (data['temp_status'] as String?) ?? 'good',
                      ),
                      _buildHealthItem(
                        icon: Icons.cleaning_services,
                        label: 'État de la rouille',
                        value: (data['rust_status'] as String?) ?? 'Aucune trace',
                        status: (data['rust_status'] as String?) ?? 'good',
                      ),
                    ],
                  );
                }

                return const Center(child: Text('Aucune donnée disponible'));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthItem({
    required IconData icon,
    required String label,
    required String value,
    required String status,
  }) {
    Color getStatusColor(String status) {
      switch (status) {
        case 'good':
          return Colors.green;
        case 'warning':
          return Colors.orange;
        case 'danger':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: getStatusColor(status),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}