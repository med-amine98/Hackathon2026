// lib/presentation/widgets/quick_actions.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚡ Actions rapides',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.camera_alt,
                  label: 'Analyser photo',
                  color: Colors.blue,
                  onTap: () => _analyzePhoto(context),
                ),
                _buildActionButton(
                  context,
                  icon: Icons.local_taxi, // ✅ Remplacé Icons.tow_truck (n'existe pas)
                  label: 'Remorquage',
                  color: Colors.orange,
                  onTap: () => _callTowTruck(context),
                ),
                _buildActionButton(
                  context,
                  icon: Icons.health_and_safety,
                  label: 'Diagnostic',
                  color: Colors.green,
                  onTap: () => _runDiagnostic(context),
                ),
                _buildActionButton(
                  context,
                  icon: Icons.map,
                  label: 'Garage proche',
                  color: Colors.purple,
                  onTap: () => _findGarage(context),
                ),
                _buildActionButton(
                  context,
                  icon: Icons.assistant,
                  label: 'Assistance IA',
                  color: Colors.teal,
                  onTap: () => _assistanceIA(context),
                ),
                _buildActionButton(
                  context,
                  icon: Icons.notifications,
                  label: 'Alertes',
                  color: Colors.red,
                  onTap: () => _showAlerts(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 48) / 3,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Actions
  Future<void> _analyzePhoto(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null && context.mounted) {
      // ✅ Vérification context.mounted avant d'utiliser le contexte
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📸 Photo envoyée pour analyse')),
      );
    }
  }

  void _callTowTruck(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚛 Remorquage'),
        content: const Text('Voulez-vous contacter un service de remorquage ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📞 Remorquage contacté !')),
              );
            },
            child: const Text('Appeler'),
          ),
        ],
      ),
    );
  }

  void _runDiagnostic(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔧 Diagnostic en cours...')),
    );
  }

  void _findGarage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📍 Recherche des garages à proximité...')),
    );
  }

  void _assistanceIA(BuildContext context) {
    // Aller à l'onglet Chat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🤖 Assistant IA en ligne')),
    );
  }

  void _showAlerts(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔔 Alertes'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ⚠️ Entretien dans 500 km'),
            Text('• 🌧️ Pluie attendue ce soir'),
            Text('• 🚧 Bouchon sur l\'autoroute A1'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}