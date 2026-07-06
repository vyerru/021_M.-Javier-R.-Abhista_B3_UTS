import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class EmptyTickets extends StatelessWidget {
  final bool isDark;

  const EmptyTickets({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 48,
              color: isDark ? const Color(0xFF334155) : AppTheme.iconSubtle),
          const SizedBox(height: 10),
          Text('Belum ada tiket',
              style: TextStyle(color: isDark ? AppTheme.iconDarkMuted : AppTheme.textMuted,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
