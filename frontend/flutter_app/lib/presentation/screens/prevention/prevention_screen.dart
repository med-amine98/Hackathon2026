// lib/presentation/screens/prevention/prevention_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_insurance_advisor/presentation/bloc/prevention/prevention_bloc.dart';
import 'package:ai_insurance_advisor/presentation/widgets/notification_card.dart';

class PreventionScreen extends StatefulWidget {
  const PreventionScreen({super.key});

  @override
  State<PreventionScreen> createState() => _PreventionScreenState();
}

class _PreventionScreenState extends State<PreventionScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PreventionBloc>().add(const LoadPreventionDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prévention intelligente'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocConsumer<PreventionBloc, PreventionState>(
        listener: (context, state) {
          if (state is PreventionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PreventionLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Récupération des alertes...'),
                ],
              ),
            );
          }

          if (state is PreventionLoaded) {
            final allNotifications = <Map<String, dynamic>>[];
            
            final weatherAlerts = state.weather['alerts'] as List? ?? [];
            for (var alert in weatherAlerts) {
              allNotifications.add({
                'icon': Icons.wb_sunny,
                'title': 'Alerte météo',
                'message': alert.toString(),
                'color': Colors.orange,
                'type': 'weather',
                'time': DateTime.now(),
              });
            }

            for (var traffic in state.traffic) {
              allNotifications.add({
                'icon': Icons.traffic,
                'title': 'Alerte trafic',
                'message': '${traffic['description']} - ${traffic['location']}',
                'color': Colors.red,
                'type': 'traffic',
                'time': DateTime.now(),
              });
            }

            for (var maintenance in state.maintenances) {
              allNotifications.add({
                'icon': Icons.build,
                'title': maintenance['title'] as String? ?? 'Maintenance',
                'message': maintenance['description'] as String? ?? '',
                'color': (maintenance['urgent'] as bool? ?? false) ? Colors.red : Colors.blue,
                'type': 'maintenance',
                'time': DateTime.now(),
              });
            }

            final aiAlerts = state.aiAlerts ?? [];
            for (var alert in aiAlerts) {
              allNotifications.add({
                'icon': Icons.auto_awesome,
                'title': 'Conseil IA',
                'message': alert,
                'color': Colors.purple,
                'type': 'ia',
                'time': DateTime.now(),
              });
            }

            if (allNotifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune notification',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tout est sous contrôle !',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allNotifications.length,
              itemBuilder: (context, index) {
                final notif = allNotifications[index];
                return NotificationCard(
                  icon: notif['icon'] as IconData,
                  title: notif['title'] as String,
                  message: notif['message'] as String,
                  color: notif['color'] as Color,
                  time: notif['time'] as DateTime,
                  type: notif['type'] as String,
                );
              },
            );
          }

          return const Center(child: Text('Aucune donnée disponible'));
        },
      ),
    );
  }
}