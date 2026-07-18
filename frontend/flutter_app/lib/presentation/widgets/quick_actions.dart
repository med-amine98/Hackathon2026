// lib/presentation/widgets/quick_actions.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_insurance_advisor/app/theme.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.camera_alt_rounded,
        label: 'Analyser photo',
        color: Colors.blue,
        onTap: () => _showComingSoon(context, 'Analyse photo'),
      ),
      _QuickAction(
        icon: Icons.local_taxi_rounded,
        label: 'Remorquage',
        color: Colors.orange,
        onTap: () => _showComingSoon(context, 'Remorquage'),
      ),
      _QuickAction(
        icon: Icons.health_and_safety_rounded,
        label: 'Diagnostic',
        color: Colors.green,
        onTap: () => _showComingSoon(context, 'Diagnostic'),
      ),
      _QuickAction(
        icon: Icons.map_rounded,
        label: 'Garage proche',
        color: Colors.purple,
        onTap: () => _showComingSoon(context, 'Garage proche'),
      ),
      _QuickAction(
        icon: Icons.assistant_rounded,
        label: 'Assistance IA',
        color: Colors.teal,
        onTap: () => context.go('/dashboard/conseil_chat'),
      ),
      _QuickAction(
        icon: Icons.notifications_active_rounded,
        label: 'Alertes',
        color: Colors.red,
        onTap: () => context.go('/dashboard/prevention'),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.flash_on_rounded,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Actions rapides',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions.map((action) {
                return _buildActionButton(
                  context,
                  action: action,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required _QuickAction action,
  }) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 56) / 3,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: action.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: action.color.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    action.icon,
                    size: 20,
                    color: action.color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  action.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔄 $feature - Fonctionnalité à venir'),
        backgroundColor: Colors.grey[800],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}