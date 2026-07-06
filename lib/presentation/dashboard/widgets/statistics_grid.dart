import 'package:flutter/material.dart';
import 'stat_card.dart';
import 'statistic_card.dart';
import 'skeleton_card.dart';

class StatisticsGrid extends StatelessWidget {
  final Map<String, int>? stats;
  final bool isDark;
  final bool isLoading;

  const StatisticsGrid({
    super.key,
    required this.stats,
    required this.isDark,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && stats == null) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.55),
        itemCount: 4,
        itemBuilder: (_, __) => SkeletonCard(isDark: isDark),
      );
    }

    final data = stats ?? {};
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.55),
      itemCount: StatCard.defaults.length,
      itemBuilder: (context, index) {
        final card = StatCard.defaults[index];
        return StatisticCard(card: card, value: data[card.key] ?? 0, isDark: isDark);
      },
    );
  }
}
