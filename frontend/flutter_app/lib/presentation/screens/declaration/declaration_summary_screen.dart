// lib/presentation/screens/declaration/declaration_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:ai_insurance_advisor/models/declaration_model.dart';

class DeclarationSummaryScreen extends StatelessWidget {
  final DeclarationModel declaration;

  const DeclarationSummaryScreen({
    super.key,
    required this.declaration,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résumé de la déclaration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildInfoCard('Véhicule', [
              'Marque/Modèle: ${declaration.vehicleName}',
            ]),
            const SizedBox(height: 16),
            _buildInfoCard('Conducteur', [
              'Nom: ${declaration.driverName}',
            ]),
            const SizedBox(height: 16),
            _buildInfoCard('Accident', [
              'Date: ${declaration.date}',
              'Heure: ${declaration.time}',
              'Lieu: ${declaration.location}',
              'Description: ${declaration.description}',
            ]),
            if (declaration.analysis != null) ...[
              const SizedBox(height: 16),
              _buildAnalysisCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange.shade100),
      ),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.pending, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statut: En attente',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Votre déclaration est en cours de traitement',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<String> items) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(item, style: TextStyle(color: Colors.grey[700])),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard() {
    final analysis = declaration.analysis!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Analyse IA',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              analysis['analysis'] as String? ?? 'Analyse en cours...',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              '🔄 ${analysis['timestamp']}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}