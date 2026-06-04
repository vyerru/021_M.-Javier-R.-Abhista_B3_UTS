import 'package:flutter/material.dart';
import '../../domain/entities/entities.dart';
import '../../services/mock_service.dart';
import '../../core/theme/app_theme.dart';
import 'ticket_detail_screen.dart';
import 'create_ticket_screen.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  late Future<List<Ticket>> _ticketFuture;
  TicketStatus? _selectedStatus; // null = Semua

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  void _loadTickets() {
    _ticketFuture = MockService.getTicketsByRole();
  }

  void _refresh() {
    setState(() {
      _loadTickets();
    });
  }

  List<Ticket> _applyFilter(List<Ticket> tickets) {
    if (_selectedStatus == null) return tickets;
    return tickets.where((t) => t.status == _selectedStatus).toList();
  }

  Color _priorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return const Color(0xFF10B981);
      case TicketPriority.medium:
        return const Color(0xFFF59E0B);
      case TicketPriority.high:
        return const Color(0xFFEF4444);
      case TicketPriority.critical:
        return const Color(0xFF7C3AED);
    }
  }

  IconData _priorityIcon(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.low:
        return Icons.arrow_downward_rounded;
      case TicketPriority.medium:
        return Icons.remove_rounded;
      case TicketPriority.high:
        return Icons.arrow_upward_rounded;
      case TicketPriority.critical:
        return Icons.priority_high_rounded;
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final chipBg = isLight ? const Color(0xFFEEF2F7) : const Color(0xFF1A3045);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tiket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
          );
          _refresh();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Tiket'),
        backgroundColor: AppTheme.accentCyan,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── Filter Chips ──────────────────────────────────────────────────
          Container(
            color: theme.scaffoldBackgroundColor,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 8,
                children: [
                  _FilterChip(
                    label: 'Semua',
                    selected: _selectedStatus == null,
                    backgroundColor: chipBg,
                    onSelected: (_) => setState(() => _selectedStatus = null),
                  ),
                  ...TicketStatus.values.map((status) => _FilterChip(
                        label: status.label,
                        selected: _selectedStatus == status,
                        backgroundColor: chipBg,
                        selectedColor: AppTheme.statusBackgroundColor(status.label),
                        selectedTextColor: AppTheme.statusForegroundColor(status.label),
                        onSelected: (_) =>
                            setState(() => _selectedStatus = status),
                      )),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // ── Ticket List ───────────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<Ticket>>(
              future: _ticketFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _refresh,
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final filtered = _applyFilter(snapshot.data ?? []);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_rounded,
                            size: 64,
                            color: theme.colorScheme.onSurface.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada tiket ditemukan',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  color: AppTheme.accentCyan,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final ticket = filtered[index];
                      final statusBg = AppTheme.statusBackgroundColor(
                          ticket.status.label);
                      final statusFg = AppTheme.statusForegroundColor(
                          ticket.status.label);
                      final priorityColor = _priorityColor(ticket.priority);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TicketDetailScreen(
                                      ticketId: ticket.id),
                                ),
                              );
                              _refresh();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Row: Status + Priority ──────────────
                                  Row(
                                    children: [
                                      // Status badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusBg,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          ticket.status.label,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: statusFg,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Priority badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color:
                                              priorityColor.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          spacing: 4,
                                          children: [
                                            Icon(
                                              _priorityIcon(ticket.priority),
                                              size: 11,
                                              color: priorityColor,
                                            ),
                                            Text(
                                              ticket.priority.label,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: priorityColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      // Category chip
                                      Text(
                                        ticket.category,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.45),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // ── Title ──────────────────────────────
                                  Text(
                                    ticket.title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  const SizedBox(height: 10),

                                  // ── Row: Author + Date ──────────────────
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 10,
                                        backgroundImage: NetworkImage(
                                            ticket.createdBy.avatarUrl),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          ticket.createdBy.fullName,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.6),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Row(
                                        spacing: 4,
                                        children: [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            size: 12,
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.4),
                                          ),
                                          Text(
                                            _formatDate(ticket.createdAt),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: theme
                                                  .colorScheme.onSurface
                                                  .withOpacity(0.45),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widget: Filter Chip ─────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color backgroundColor;
  final Color? selectedColor;
  final Color? selectedTextColor;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.backgroundColor,
    required this.onSelected,
    this.selectedColor,
    this.selectedTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSelectedBg =
        selectedColor ?? AppTheme.accentCyan.withOpacity(0.15);
    final effectiveSelectedFg =
        selectedTextColor ?? AppTheme.accentCyan;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected
              ? effectiveSelectedFg
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: backgroundColor,
      selectedColor: effectiveSelectedBg,
      checkmarkColor: effectiveSelectedFg,
      side: BorderSide(
        color: selected
            ? effectiveSelectedFg.withOpacity(0.4)
            : Colors.transparent,
        width: 1.5,
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}
