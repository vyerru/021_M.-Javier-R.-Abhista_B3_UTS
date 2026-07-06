import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/ticket.dart';
import 'tag.dart';

class DashboardTicketCard extends StatelessWidget {
  final Ticket ticket;
  final bool isDark;

  const DashboardTicketCard({super.key, required this.ticket, required this.isDark});

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    final relative = diff.inMinutes < 60
        ? '${diff.inMinutes}m lalu'
        : diff.inHours < 24
            ? '${diff.inHours}j lalu'
            : '${diff.inDays}h lalu';
    final absolute =
        '${dt.day} ${['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'][dt.month]} ${dt.year}';
    return '$relative · $absolute';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.statusForegroundColor(ticket.status.label);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight, width: 1),
      ),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          margin: const EdgeInsets.only(right: 12, top: 2),
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ticket.title,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.iconSubtle : AppTheme.primaryNavy),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(children: [
            Tag(label: ticket.status.label, color: statusColor),
            const SizedBox(width: 6),
            Tag(label: ticket.priority.label, color: AppTheme.priorityColor(ticket.priority.label)),
            const Spacer(),
            Icon(Icons.access_time_rounded, size: 11, color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight),
            const SizedBox(width: 3),
            Text(_formatDate(ticket.updatedAt),
                style: TextStyle(fontSize: 11, color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight)),
          ]),
        ])),
      ]),
    );
  }
}
