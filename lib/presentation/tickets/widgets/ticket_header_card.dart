import 'package:flutter/material.dart';

class TicketHeaderCard extends StatelessWidget {
  final String statusLabel;
  final Color statusColor;
  final String priorityLabel;
  final Color priorityColor;
  final String ticketId;
  final String title;
  final String description;

  const TicketHeaderCard({
    super.key,
    required this.statusLabel,
    required this.statusColor,
    required this.priorityLabel,
    required this.priorityColor,
    required this.ticketId,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(priorityLabel,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: priorityColor)),
                ),
                const Spacer(),
                Flexible(
                  child: Text('#$ticketId',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(title,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800, height: 1.3)),
            const SizedBox(height: 10),
            Text(description,
                maxLines: 6, overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75))),
          ],
        ),
      ),
    );
  }
}
