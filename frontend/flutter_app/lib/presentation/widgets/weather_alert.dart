// lib/presentation/widgets/weather_alert.dart

import 'package:flutter/material.dart';

class WeatherAlert extends StatelessWidget {
  const WeatherAlert({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.thermostat, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  '🌡️ 28°C',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const Icon(Icons.traffic, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  '🚗 Trafic fluide',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sunny, color: Colors.orange, size: 16),
                      SizedBox(width: 4),
                      Text('Ensoleillé'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}