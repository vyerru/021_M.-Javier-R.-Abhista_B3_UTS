import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/ticket_history.dart';

class TicketTimeline extends StatelessWidget {
  final List<TicketHistory> history;
  final VoidCallback? onViewAllTap;

  const TicketTimeline({super.key, required this.history, this.onViewAllTap});

  String _formatDateTime(DateTime dt) {
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month]} ${dt.year}, $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 2),
          child: Text('Riwayat Tiket',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.2)),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: history.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('Belum ada riwayat.',
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                    ),
                  )
                : Column(
                    children: List.generate(history.length, (i) {
                      final entry = history[i];
                      final isLast = i == history.length - 1;
                      final dotColor = entry.toStatus != null
                          ? AppTheme.statusForegroundColor(entry.toStatus!.label)
                          : AppTheme.accentCyan;

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              child: Column(
                                children: [
                                  Container(
                                    width: 12, height: 12,
                                    margin: const EdgeInsets.only(top: 2),
                                    decoration: BoxDecoration(
                                      color: dotColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: dotColor.withValues(alpha: 0.3), width: 3),
                                    ),
                                  ),
                                  if (!isLast)
                                    Expanded(
                                      child: Center(
                                        child: Container(width: 2, color: theme.dividerColor),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(entry.action,
                                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text('${entry.changedBy.fullName} · ${_formatDateTime(entry.timestamp)}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
          ),
        ),
        if (onViewAllTap != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onViewAllTap,
                icon: const Icon(Icons.history_rounded, size: 16),
                label: const Text('Lihat Riwayat Lengkap'),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ),
          ),
      ],
    );
  }
}
