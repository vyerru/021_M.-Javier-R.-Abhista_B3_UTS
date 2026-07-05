import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/entities.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import 'ticket_detail_screen.dart';
import 'create_ticket_screen.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  TicketStatus? _selectedStatus;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().loadTickets();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TicketProvider>().loadMore();
    }
  }

  void _refresh() {
    context.read<TicketProvider>().loadTickets(statusFilter: _selectedStatus);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ticketProvider = context.watch<TicketProvider>();
    final authProvider = context.watch<AuthProvider>();
    final tickets = ticketProvider.tickets;
    final error = ticketProvider.error;

    return Scaffold(
      body: Column(
        children: [
          Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daftar Tiket', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFFE2E8F0) : AppTheme.primaryNavy, letterSpacing: -0.5)),
                  const SizedBox(height: 12),
                  _buildStatusFilter(isDark),
                ],
              ),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7F1D1D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(error, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12)),
              ),
            ),
          Expanded(
            child: ticketProvider.isLoading && tickets.isEmpty
                ? _buildLoading(isDark)
                : RefreshIndicator(
                    onRefresh: () async => _refresh(),
                    child: tickets.isEmpty
                        ? _buildEmpty(isDark)
                        : _buildList(tickets, isDark),
                  ),
          ),
        ],
      ),
      floatingActionButton: authProvider.currentUser?.role == UserRole.user ||
              authProvider.currentUser?.role == UserRole.admin ||
              authProvider.currentUser?.role == UserRole.helpdesk
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTicketScreen())).then((_) => _refresh()),
              backgroundColor: AppTheme.accentCyan,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Buat Tiket'),
            )
          : null,
    );
  }

  Widget _buildStatusFilter(bool isDark) {
    final statuses = <TicketStatus?>[null, TicketStatus.open, TicketStatus.assign, TicketStatus.inprogress, TicketStatus.closed];
    final labels = ['Semua', 'Open', 'Assign', 'In Progress', 'Closed'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(statuses.length, (i) {
          final selected = _selectedStatus == statuses[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(labels[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : AppTheme.primaryNavy))),
              selected: selected,
              onSelected: (_) {
                setState(() => _selectedStatus = statuses[i]);
                context.read<TicketProvider>().loadTickets(statusFilter: statuses[i]);
              },
              selectedColor: AppTheme.accentCyan,
              checkmarkColor: Colors.white,
              backgroundColor: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: _SkeletonCard(isDark: isDark),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox_rounded, size: 64, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
        const SizedBox(height: 16),
        Text('Belum ada tiket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
        const SizedBox(height: 8),
        Text('Buat tiket baru untuk memulai', style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))),
      ]),
    );
  }

  Widget _buildList(List<Ticket> tickets, bool isDark) {
    final provider = context.watch<TicketProvider>();
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
      itemCount: tickets.length + (provider.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= tickets.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))),
          );
        }
        final ticket = tickets[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _TicketCard(ticket: ticket, isDark: isDark, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailScreen(ticketId: ticket.id))).then((_) => _refresh());
          }),
        );
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final bool isDark;
  final VoidCallback onTap;

  const _TicketCard({required this.ticket, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.statusForegroundColor(ticket.status.label);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight, width: 1),
          ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppTheme.accentCyan.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(ticket.createdBy.fullName.isNotEmpty ? ticket.createdBy.fullName[0].toUpperCase() : '?', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.accentCyan)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ticket.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFCBD5E1) : AppTheme.primaryNavy), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(children: [
                _Tag(label: ticket.status.label, color: statusColor),
                const SizedBox(width: 6),
                _Tag(label: ticket.priority.label, color: AppTheme.priorityColor(ticket.priority.label)),
                if (ticket.attachmentUrls.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.attach_file_rounded, size: 14, color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                ],
                const Spacer(),
                Icon(Icons.access_time_rounded, size: 11, color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight),
                const SizedBox(width: 3),
                Text(_formatDate(ticket.createdAt), style: TextStyle(fontSize: 11, color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight)),
              ]),
            ]),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), size: 20),
        ])),
      ),
    );
  }

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
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.2)),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  final bool isDark;
  const _SkeletonCard({required this.isDark});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: 72,
        decoration: BoxDecoration(
          color: Color.lerp(
            widget.isDark ? const Color(0xFF162436) : const Color(0xFFE2E8F0),
            widget.isDark ? const Color(0xFF1E3554) : const Color(0xFFF1F5F9),
            _anim.value,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
