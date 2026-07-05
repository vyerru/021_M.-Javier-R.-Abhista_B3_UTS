import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../providers/notification_provider.dart';
import '../auth/login_screen.dart';
import '../notifications/notification_screen.dart';
import '../profile/profile_screen.dart';
import '../tickets/ticket_list_screen.dart';
import '../tickets/riwayat_screen.dart';

class _StatCard {
  final String label;
  final String key;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.key,
    required this.icon,
    required this.color,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedNavIndex = 0;

  static const List<_StatCard> _statCards = [
    _StatCard(label: 'Total Tiket', key: 'total', icon: Icons.confirmation_number_rounded, color: AppTheme.accentCyan),
    _StatCard(label: 'Open', key: 'open', icon: Icons.radio_button_unchecked_rounded, color: AppTheme.statusOpen),
    _StatCard(label: 'In Progress', key: 'inprogress', icon: Icons.autorenew_rounded, color: AppTheme.statusInProgress),
    _StatCard(label: 'Assign', key: 'assign', icon: Icons.assignment_return_rounded, color: AppTheme.statusAssign),
    _StatCard(label: 'Closed', key: 'closed', icon: Icons.archive_outlined, color: AppTheme.statusClosed),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final ticketProvider = context.read<TicketProvider>();
    final notifProvider = context.read<NotificationProvider>();
    final auth = context.read<AuthProvider>();

    ticketProvider.loadTickets();
    ticketProvider.loadStatistics();
    if (auth.currentUser != null) {
      notifProvider.loadNotifications(auth.currentUser!.id);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Logout', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40), backgroundColor: AppTheme.statusOpen),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final ticketProvider = context.watch<TicketProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: _selectedNavIndex == 0 ? _buildAppBar(isDark) : null,
      body: IndexedStack(
        index: _selectedNavIndex,
        children: [
          _buildDashboardContent(isDark, ticketProvider, user),
          const RiwayatScreen(),
          const TicketListScreen(),
          NotificationScreen(
            onCountChanged: (count) {},
          ),
          ProfileScreen(
            onThemeToggle: widget.onThemeToggle,
            isDarkMode: widget.isDarkMode,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(isDark, notifProvider.unreadCount),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: AppTheme.accentCyan.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.confirmation_number_outlined, color: AppTheme.accentCyan, size: 16),
          ),
          const SizedBox(width: 10),
          const Text('HelpDesk'),
        ],
      ),
      actions: [
        IconButton(
          onPressed: widget.onThemeToggle,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => RotationTransition(turns: anim, child: child),
            child: Icon(
              widget.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey(widget.isDarkMode),
              color: isDark ? const Color(0xFFCBD5E1) : Colors.white.withValues(alpha: 0.9), size: 22,
            ),
          ),
          tooltip: widget.isDarkMode ? 'Mode Terang' : 'Mode Gelap',
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: _handleLogout,
          icon: Icon(Icons.logout_rounded, color: isDark ? const Color(0xFFCBD5E1) : Colors.white.withValues(alpha: 0.9), size: 22),
          tooltip: 'Logout',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDashboardContent(bool isDark, TicketProvider ticketProvider, User? user) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _loadData(),
        color: AppTheme.accentCyan,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreetingSection(user, isDark),
                    const SizedBox(height: 28),
                    _buildSectionLabel('Statistik Tiket', isDark),
                    const SizedBox(height: 14),
                    _buildStatisticsSection(isDark, ticketProvider),
                    const SizedBox(height: 28),
                    _buildSectionLabel('Tiket Terbaru', isDark, trailing: 'Lihat Semua'),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
            _buildRecentTicketsSliver(isDark, ticketProvider),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingSection(User? user, bool isDark) {
    final hour = DateTime.now().hour;
    final greeting = hour < 11 ? 'Selamat Pagi' : hour < 15 ? 'Selamat Siang' : hour < 18 ? 'Selamat Sore' : 'Selamat Malam';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$greeting,', style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B), fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(user?.fullName ?? 'Pengguna', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFFE2E8F0) : AppTheme.primaryNavy, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.accentCyan.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(user?.role.label ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.accentCyan, letterSpacing: 0.5)),
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 26,
          backgroundColor: AppTheme.accentCyan.withValues(alpha: 0.15),
          backgroundImage: user?.avatarUrl.isNotEmpty == true ? NetworkImage(user!.avatarUrl) : null,
          child: user?.avatarUrl.isNotEmpty != true
               ? Text(user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.accentCyan))
              : null,
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label, bool isDark, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFE2E8F0) : AppTheme.primaryNavy, letterSpacing: -0.2)),
        if (trailing != null)
          GestureDetector(
            onTap: () => setState(() => _selectedNavIndex = 2),
            child: Text(trailing, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.accentCyan)),
          ),
      ],
    );
  }

  Widget _buildStatisticsSection(bool isDark, TicketProvider ticketProvider) {
    if (ticketProvider.isLoading && ticketProvider.statistics == null) {
      return _buildStatLoadingSkeleton(isDark);
    }

    final stats = ticketProvider.statistics ?? {};

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.55),
      itemCount: _statCards.length,
      itemBuilder: (context, index) {
        final card = _statCards[index];
        return _StatisticCard(card: card, value: stats[card.key] ?? 0, isDark: isDark);
      },
    );
  }

  Widget _buildStatLoadingSkeleton(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.55),
      itemCount: 4,
      itemBuilder: (_, __) => _SkeletonCard(isDark: isDark),
    );
  }

  Widget _buildRecentTicketsSliver(bool isDark, TicketProvider ticketProvider) {
    if (ticketProvider.isLoading && ticketProvider.tickets.isEmpty) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6), child: _SkeletonCard(isDark: isDark, height: 80)),
          childCount: 3,
        ),
      );
    }

    final tickets = ticketProvider.tickets;
    if (tickets.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyTickets(isDark));
    }

    final recent = tickets.take(5).toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final ticket = recent[index];
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: _TicketListItem(ticket: ticket, isDark: isDark),
          );
        },
        childCount: recent.length,
      ),
    );
  }

  Widget _buildEmptyTickets(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          const SizedBox(height: 10),
          Text('Belum ada tiket', style: TextStyle(color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isDark, int unreadCount) {
    return NavigationBar(
      selectedIndex: _selectedNavIndex,
      onDestinationSelected: (i) => setState(() => _selectedNavIndex = i),
      backgroundColor: isDark ? AppTheme.cardDark : AppTheme.cardLight,
      indicatorColor: AppTheme.accentCyan.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.accentCyan),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: const Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history_rounded, color: AppTheme.accentCyan),
          label: 'Riwayat',
        ),
        NavigationDestination(
          icon: const Icon(Icons.confirmation_number_outlined),
          selectedIcon: Icon(Icons.confirmation_number_rounded, color: AppTheme.accentCyan),
          label: 'Tiket',
        ),
        NavigationDestination(
          icon: unreadCount > 0
              ? Badge(label: Text(unreadCount > 99 ? '99+' : unreadCount.toString(), style: const TextStyle(fontSize: 10)), child: const Icon(Icons.notifications_outlined))
              : const Icon(Icons.notifications_outlined),
          selectedIcon: unreadCount > 0
              ? Badge(label: Text(unreadCount > 99 ? '99+' : unreadCount.toString(), style: const TextStyle(fontSize: 10)), child: const Icon(Icons.notifications_rounded, color: AppTheme.accentCyan))
              : const Icon(Icons.notifications_rounded, color: AppTheme.accentCyan),
          label: 'Notifikasi',
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded, color: AppTheme.accentCyan),
          label: 'Profil',
        ),
      ],
    );
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({required this.card, required this.value, required this.isDark});
  final _StatCard card;
  final int value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: card.color.withValues(alpha: 0.25), width: 1),
        boxShadow: isDark ? null : [BoxShadow(color: card.color.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: card.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: Icon(card.icon, color: card.color, size: 19)),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value.toString(), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFFE2E8F0) : AppTheme.primaryNavy, height: 1, letterSpacing: -0.5)),
          const SizedBox(height: 3),
          Text(card.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
        ]),
      ]),
    );
  }
}

class _TicketListItem extends StatelessWidget {
  const _TicketListItem({required this.ticket, required this.isDark});
  final Ticket ticket;
  final bool isDark;

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
        Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 12, top: 2), decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ticket.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFCBD5E1) : AppTheme.primaryNavy), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(children: [
            _Tag(label: ticket.status.label, color: statusColor),
            const SizedBox(width: 6),
            _Tag(label: ticket.priority.label, color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
            const Spacer(),
            Text(_formatDate(ticket.updatedAt), style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ]),
        ])),
      ]),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    return '${diff.inDays}h lalu';
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
  const _SkeletonCard({required this.isDark, this.height});
  final bool isDark;
  final double? height;

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
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(
            widget.isDark ? const Color(0xFF162436) : const Color(0xFFE2E8F0),
            widget.isDark ? const Color(0xFF1E3554) : const Color(0xFFF1F5F9),
            _anim.value,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
