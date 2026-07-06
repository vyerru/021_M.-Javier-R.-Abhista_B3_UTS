import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  const SectionLabel({
    super.key,
    required this.label,
    required this.isDark,
    this.trailing,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkText : AppTheme.primaryNavy,
                letterSpacing: -0.2)),
        if (trailing != null && onTrailingTap != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(trailing!,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppTheme.accentCyan)),
          ),
      ],
    );
  }
}
