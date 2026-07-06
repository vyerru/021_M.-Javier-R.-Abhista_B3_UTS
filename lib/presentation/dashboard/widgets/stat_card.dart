import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class StatCard {
  final String label;
  final String key;
  final IconData icon;
  final Color color;

  const StatCard({
    required this.label,
    required this.key,
    required this.icon,
    required this.color,
  });

  static const List<StatCard> defaults = [
    StatCard(label: 'Total Tiket', key: 'total', icon: Icons.confirmation_number_rounded, color: AppTheme.accentCyan),
    StatCard(label: 'Open', key: 'open', icon: Icons.radio_button_unchecked_rounded, color: AppTheme.statusOpen),
    StatCard(label: 'In Progress', key: 'inprogress', icon: Icons.autorenew_rounded, color: AppTheme.statusInProgress),
    StatCard(label: 'Assign', key: 'assign', icon: Icons.assignment_return_rounded, color: AppTheme.statusAssign),
    StatCard(label: 'Closed', key: 'closed', icon: Icons.archive_outlined, color: AppTheme.statusClosed),
  ];
}
