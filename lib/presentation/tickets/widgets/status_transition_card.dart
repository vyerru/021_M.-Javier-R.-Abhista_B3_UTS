import 'package:flutter/material.dart';

class StatusTransitionCard extends StatelessWidget {
  final String label;
  final String statusLabel;
  final Color fg;
  final Color bg;
  final IconData icon;

  const StatusTransitionCard({
    super.key,
    required this.label,
    required this.statusLabel,
    required this.fg,
    required this.bg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        spacing: 12,
        children: [
          Icon(icon, color: fg, size: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                const SizedBox(height: 2),
                Text(statusLabel,
                    style: TextStyle(fontWeight: FontWeight.w700, color: fg, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
