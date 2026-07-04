import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../providers/ticket_provider.dart';
import 'ticket_history_screen.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  String _selectedFilter = 'all';

  final List<_FilterOption> _filters = const [
    _FilterOption('all', 'Semua'),
    _FilterOption('active', 'Aktif'),
    _FilterOption('closed', 'Selesai'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTickets();
    });
  }

  void _loadTickets() {
    if (_selectedFilter == 'closed') {
      context.read<TicketProvider>().loadTickets(statusFilter: TicketStatus.closed);
    } else if (_selectedFilter == 'active') {
      context.read<TicketProvider>().loadActiveTickets();
    } else {
      context.read<TicketProvider>().loadTickets();
    }
  }

  void _refresh() {
    _loadTickets();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TicketProvider>();
    final tickets = _selectedFilter == 'active' ? provider.activeTickets : provider.tickets;
    final isLoading = provider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Tiket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 8,
                children: _filters.map((f) {
                  final selected = _selectedFilter == f.key;
                  return FilterChip(
                    label: Text(f.label),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedFilter = f.key);
                      _loadTickets();
                    },
                    selectedColor: AppTheme.accentCyan.withValues(alpha: 0.15),
                    checkmarkColor: AppTheme.accentCyan,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppTheme.accentCyan : null,
                    ),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // List
          Expanded(
            child: isLoading && tickets.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : tickets.isEmpty
                    ? RefreshIndicator(
                        onRefresh: () async => _refresh(),
                        child: ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.3,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.history_rounded,
                                        size: 48,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.15)),
                                    const SizedBox(height: 12),
                                    Text(
                                      _emptyText(),
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
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
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: tickets.length,
                          itemBuilder: (context, index) {
                            final ticket = tickets[index];
                            return _RiwayatCard(
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
          ),
        ],
      ),
    );
  }

  String _emptyText() {
    switch (_selectedFilter) {
      case 'active':
        return 'Tidak ada tiket aktif';
      case 'closed':
        return 'Belum ada tiket selesai';
      default:
        return 'Belum ada riwayat tiket';
    }
  }
}

class _FilterOption {
  final String key;
  final String label;
  const _FilterOption(this.key, this.label);
}

class _RiwayatCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;

  const _RiwayatCard({required this.ticket, required this.onTap});

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
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
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
              // Mini progress dots
              Row(
                spacing: 3,
                children: List.generate(steps.length, (i) {
                  return Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: i == currentIdx ? 10 : 8,
                          height: i == currentIdx ? 10 : 8,
                          decoration: BoxDecoration(
                            color: i <= currentIdx
                                ? AppTheme.statusForegroundColor(steps[i].label)
                                : AppTheme.accentCyan.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (i < steps.length - 1)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: i < currentIdx
                                  ? AppTheme.statusClosed
                                  : AppTheme.accentCyan.withValues(alpha: 0.1),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Row(
                spacing: 6,
                children: [
                  Icon(Icons.person_outline_rounded,
                      size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
                  Expanded(
                    child: Text(
                      ticket.assignedTo?.fullName ?? 'Belum diassign',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
                    ),
                  ),
                  Text(
                    _formatDate(ticket.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}
