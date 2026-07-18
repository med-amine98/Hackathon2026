// lib/presentation/widgets/notification_banner.dart

import 'package:flutter/material.dart';

class NotificationBanner extends StatefulWidget {
  const NotificationBanner({super.key});

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'icon': Icons.warning,
      'color': Colors.orange,
      'title': 'Entretien recommandé',
      'message': 'Votre véhicule a parcouru 15 000 km depuis la dernière révision',
    },
    {
      'icon': Icons.cloud,
      'color': Colors.blue,
      'title': 'Météo aujourd\'hui',
      'message': '🌤️ 28°C - Beau temps toute la journée',
    },
    {
      'icon': Icons.traffic,
      'color': Colors.red,
      'title': 'Circulation',
      'message': '🟢 Trafic fluide sur l\'autoroute A1',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Notifications',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Voir toutes les notifications
                  },
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._notifications.map((notif) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: notif['color'] as Color,
                    child: Icon(
                      notif['icon'] as IconData,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif['title'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          notif['message'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}