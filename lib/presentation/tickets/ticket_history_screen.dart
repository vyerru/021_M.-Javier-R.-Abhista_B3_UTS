import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../providers/ticket_provider.dart';

class TicketHistoryScreen extends StatefulWidget {
  final String ticketId;

  const TicketHistoryScreen({super.key, required this.ticketId});

  @override
  State<TicketHistoryScreen> createState() => _TicketHistoryScreenState();
}

class _TicketHistoryScreenState extends State<TicketHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().loadTicketDetail(widget.ticketId);
    });
  }

  void _refresh() {
    context.read<TicketProvider>().loadTicketDetail(widget.ticketId);
  }

  Widget _buildProgressStepper(Ticket ticket) {
    final steps = TicketStatus.values;
    final currentIdx = steps.indexOf(ticket.status);

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIdx = i ~/ 2;
          final isCompleted = stepIdx < currentIdx;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted ? AppTheme.statusClosed : AppTheme.accentCyan.withValues(alpha: 0.2),
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final step = steps[stepIdx];
        final isCompleted = stepIdx < currentIdx;
        final isCurrent = stepIdx == currentIdx;

        final fg = isCompleted
            ? AppTheme.statusClosed
            : isCurrent
                ? AppTheme.statusForegroundColor(step.label)
                : AppTheme.accentCyan.withValues(alpha: 0.25);
        final bg = isCompleted
            ? AppTheme.statusClosed
            : isCurrent
                ? AppTheme.statusBackgroundColor(step.label)
                : Colors.transparent;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent ? bg : null,
                shape: BoxShape.circle,
                border: Border.all(
                  color: fg,
                  width: isCurrent ? 2.5 : 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? Icon(Icons.check_rounded, size: 18, color: fg)
                    : Text(
                        '${stepIdx + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              step.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: fg,
              ),
            ),
          ],
        );
      }),
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month]} ${dt.year}, $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ticket = context.watch<TicketProvider>().selectedTicket;
    final isLoading = context.watch<TicketProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ticket?.title ?? 'Riwayat Tiket',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: isLoading && ticket == null
          ? const Center(child: CircularProgressIndicator())
          : ticket == null
              ? const Center(child: Text('Tiket tidak ditemukan'))
              : RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  child: ticket.history.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.history_rounded,
                                      size: 48,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Belum ada riwayat.',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                          children: [
                            // Header info
                            Row(
                              spacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.statusBackgroundColor(
                                        ticket.status.label),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    ticket.status.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.statusForegroundColor(
                                          ticket.status.label),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    ticket.title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (ticket.assignedTo != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  spacing: 6,
                                  children: [
                                    Icon(Icons.support_agent_rounded,
                                        size: 14,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.4)),
                                    Text(
                                      'Ditugaskan ke ${ticket.assignedTo!.fullName}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                spacing: 6,
                                children: [
                                  Icon(Icons.person_outline_rounded,
                                      size: 14,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.4)),
                                  Text(
                                    'oleh ${ticket.createdBy.fullName}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Divider(),
                            const SizedBox(height: 12),

                            // Progress Stepper
                            _buildProgressStepper(ticket),
                            const SizedBox(height: 20),

                            // Timeline section label
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                spacing: 6,
                                children: [
                                  Icon(Icons.history_rounded, size: 16,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                                  Text(
                                    'Riwayat Aktivitas',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Timeline
                            ...List.generate(ticket.history.length, (i) {
                              final entry = ticket.history[i];
                              final isLast = i == ticket.history.length - 1;
                              final dotColor =
                                  entry.toStatus != null
                                      ? AppTheme.statusForegroundColor(
                                          entry.toStatus!.label)
                                      : AppTheme.accentCyan;
                              final statusFg = entry.toStatus != null
                                  ? AppTheme.statusForegroundColor(
                                      entry.toStatus!.label)
                                  : null;
                              final statusBg = entry.toStatus != null
                                  ? AppTheme.statusBackgroundColor(
                                      entry.toStatus!.label)
                                  : null;

                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 14,
                                            height: 14,
                                            margin: const EdgeInsets.only(top: 3),
                                            decoration: BoxDecoration(
                                              color: dotColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: dotColor.withValues(alpha: 0.3),
                                                width: 3,
                                              ),
                                            ),
                                          ),
                                          if (!isLast)
                                            Expanded(
                                              child: Center(
                                                child: Container(
                                                  width: 2,
                                                  color: theme.dividerColor,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                            bottom: isLast ? 0 : 20),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              spacing: 6,
                                              children: [
                                                if (entry.fromStatus != null ||
                                                    entry.toStatus != null)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: statusBg?.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      entry.action,
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 11,
                                                        color: statusFg,
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  Text(
                                                    entry.action,
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              spacing: 4,
                                              children: [
                                                CircleAvatar(
                                                  radius: 8,
                                                  backgroundColor:
                                                      entry.changedBy.avatarUrl.isNotEmpty
                                                          ? null
                                                          : AppTheme.accentCyan.withValues(alpha: 0.15),
                                                  backgroundImage:
                                                      entry.changedBy.avatarUrl.isNotEmpty
                                                          ? NetworkImage(entry.changedBy.avatarUrl)
                                                          : null,
                                                  child: entry.changedBy.avatarUrl.isEmpty
                                                      ? Text(
                                                          entry.changedBy.fullName.isNotEmpty
                                                              ? entry.changedBy.fullName[0].toUpperCase()
                                                              : '?',
                                                          style: const TextStyle(
                                                              fontSize: 8,
                                                              fontWeight: FontWeight.w700),
                                                        )
                                                      : null,
                                                ),
                                                Text(
                                                  entry.changedBy.fullName,
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: theme.colorScheme.onSurface
                                                        .withValues(alpha: 0.6),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 4, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.accentCyan.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(3),
                                                  ),
                                                  child: Text(
                                                    entry.changedBy.role.label,
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                      color: AppTheme.accentCyan,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  _formatDateTime(entry.timestamp),
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    fontSize: 10,
                                                    color: theme.colorScheme.onSurface
                                                        .withValues(alpha: 0.35),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                ),
    );
  }
}
