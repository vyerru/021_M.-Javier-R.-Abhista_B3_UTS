import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import 'ticket_history_screen.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().loadActiveTickets();
    });
  }

  void _refresh() {
    context.read<TicketProvider>().loadActiveTickets();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = context.watch<AuthProvider>().currentUser;
    final provider = context.watch<TicketProvider>();
    final tickets = provider.activeTickets;
    final isLoading = provider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Tiket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: isLoading && tickets.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : tickets.isEmpty
              ? RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  child: ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.route_rounded,
                                  size: 48,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.15)),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak ada tiket aktif',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _emptySubtitle(currentUser),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return _TrackingCard(
                        ticket: ticket,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TicketHistoryScreen(ticketId: ticket.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }

  String _emptySubtitle(User? currentUser) {
    if (currentUser == null) return '';
    switch (currentUser.role) {
      case UserRole.user:
        return 'Buat tiket baru untuk mulai tracking';
      case UserRole.helpdesk:
        return 'Tunggu admin mengassign tiket';
      case UserRole.admin:
        return 'Semua tiket sudah tertangani';
    }
  }
}

class _TrackingCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;

  const _TrackingCard({required this.ticket, required this.onTap});

  Widget _buildMiniDot(Color color, {bool filled = false}) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = TicketStatus.values;
    final currentIdx = steps.indexOf(ticket.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: Text(
                      ticket.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.statusBackgroundColor(ticket.status.label),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      ticket.status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.statusForegroundColor(ticket.status.label),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                spacing: 4,
                children: List.generate(steps.length, (i) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMiniDot(
                        i <= currentIdx
                            ? AppTheme.statusForegroundColor(steps[i].label)
                            : AppTheme.accentCyan.withValues(alpha: 0.25),
                        filled: i <= currentIdx,
                      ),
                      if (i < steps.length - 1)
                        Container(
                          width: 20,
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i < currentIdx
                                ? AppTheme.statusClosed
                                : AppTheme.accentCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 8),
              Row(
                spacing: 6,
                children: [
                  Icon(Icons.person_outline_rounded,
                      size: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
                  Text(
                    ticket.assignedTo?.fullName ?? 'Belum diassign',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
