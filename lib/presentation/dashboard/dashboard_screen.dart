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
import 'widgets/greeting_section.dart';
import 'widgets/section_label.dart';
import 'widgets/statistics_grid.dart';
import 'widgets/dashboard_ticket_card.dart';
import 'widgets/empty_tickets.dart';
import 'widgets/skeleton_card.dart';

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
          NotificationScreen(onCountChanged: (count) {}),
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
            decoration: BoxDecoration(
                color: AppTheme.accentCyan.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8)),
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
              color: isDark ? AppTheme.iconSubtle : Colors.white.withValues(alpha: 0.9),
              size: 22,
            ),
          ),
          tooltip: widget.isDarkMode ? 'Mode Terang' : 'Mode Gelap',
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: _handleLogout,
          icon: Icon(Icons.logout_rounded,
              color: isDark ? AppTheme.iconSubtle : Colors.white.withValues(alpha: 0.9),
              size: 22),
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
                    GreetingSection(user: user, isDark: isDark),
                    const SizedBox(height: 28),
                    SectionLabel(label: 'Statistik Tiket', isDark: isDark),
                    const SizedBox(height: 14),
                    StatisticsGrid(
                      stats: ticketProvider.statistics,
                      isDark: isDark,
                      isLoading: ticketProvider.isLoading,
                    ),
                    const SizedBox(height: 28),
                    SectionLabel(
                      label: 'Tiket Terbaru',
                      isDark: isDark,
                      trailing: 'Lihat Semua',
                      onTrailingTap: () => setState(() => _selectedNavIndex = 2),
                    ),
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

  Widget _buildRecentTicketsSliver(bool isDark, TicketProvider ticketProvider) {
    if (ticketProvider.isLoading && ticketProvider.tickets.isEmpty) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: SkeletonCard(isDark: isDark, height: 80),
          ),
          childCount: 3,
        ),
      );
    }

    final tickets = ticketProvider.tickets;
    if (tickets.isEmpty) {
      return SliverToBoxAdapter(child: EmptyTickets(isDark: isDark));
    }

    final recent = tickets.take(5).toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final ticket = recent[index];
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: DashboardTicketCard(ticket: ticket, isDark: isDark),
          );
        },
        childCount: recent.length,
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
