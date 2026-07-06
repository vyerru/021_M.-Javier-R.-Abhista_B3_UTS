import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'stat_card.dart';

class StatisticCard extends StatelessWidget {
  final StatCard card;
  final int value;
  final bool isDark;

  const StatisticCard({super.key, required this.card, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: card.color.withValues(alpha: 0.25), width: 1),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: card.color.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: card.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(card.icon, color: card.color, size: 19),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value.toString(),
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.darkText : AppTheme.primaryNavy,
                    height: 1, letterSpacing: -0.5)),
            const SizedBox(height: 3),
            Text(card.label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.textSecondary : AppTheme.textMuted)),
          ]),
        ],
      ),
    );
  }
}
