import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../../services/services.dart';
import '../auth/login_screen.dart';
import '../notifications/notification_screen.dart';
import '../tickets/ticket_list_screen.dart';

/// Data model ringan untuk satu kartu statistik.
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

/// Halaman Dashboard — FR-008.
///
/// Menampilkan ringkasan statistik tiket menggunakan [FutureBuilder].
/// Future diinisialisasi di [initState] untuk mencegah rebuild loop.
///
/// Menerima [onThemeToggle] callback dari root widget agar toggle
/// tema bekerja secara global tanpa state management eksternal.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  /// Callback untuk toggle light/dark theme di level MaterialApp.
  final VoidCallback onThemeToggle;

  /// State tema saat ini dari parent.
  final bool isDarkMode;

  static const routeName = '/dashboard';

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ─── Future harus diinisialisasi di initState, bukan di build() ──────────
  late Future<Map<String, int>> _statisticsFuture;
  late Future<List<Ticket>> _recentTicketsFuture;

  // ─── State ───────────────────────────────────────────────────────────────
  int _selectedNavIndex = 0;
  int _unreadCount = 0;

  // ─── Kartu statistik (urutan & warna) ────────────────────────────────────
  static const List<_StatCard> _statCards = [
    _StatCard(
      label: 'Total Tiket',
      key: 'total',
      icon: Icons.confirmation_number_rounded,
      color: AppTheme.accentCyan,
    ),
    _StatCard(
      label: 'Open',
      key: 'open',
      icon: Icons.radio_button_unchecked_rounded,
      color: AppTheme.statusOpen,
    ),
    _StatCard(
      label: 'In Progress',
      key: 'inProgress',
      icon: Icons.autorenew_rounded,
      color: AppTheme.statusInProgress,
    ),
    _StatCard(
      label: 'Resolved',
      key: 'resolved',
      icon: Icons.check_circle_outline_rounded,
      color: AppTheme.statusResolved,
    ),
    _StatCard(
      label: 'Closed',
      key: 'closed',
      icon: Icons.archive_outlined,
      color: AppTheme.statusClosed,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // ✅ BENAR: Future diinisialisasi sekali di initState,
    //    bukan di dalam build() yang akan membuat loop rebuild.
    _refreshData();
  }

  /// Memuat ulang semua data. Dipanggil saat pull-to-refresh.
  void _refreshData() {
    setState(() {
      _statisticsFuture = MockService.getTicketStatistics();
      _recentTicketsFuture = MockService.getTicketsByRole();
    });
    _loadUnreadCount();
  }

  void _loadUnreadCount() {
    MockService.getUnreadCount().then((count) {
      if (mounted) setState(() => _unreadCount = count);
    });
  }

  // ─── Logout ──────────────────────────────────────────────────────────────

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Logout',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(80, 40),
              backgroundColor: AppTheme.statusOpen,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await MockService.logout();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = MockService.currentUser;

    return Scaffold(
      appBar: _selectedNavIndex == 0 ? _buildAppBar(isDark) : null,
      body: IndexedStack(
        index: _selectedNavIndex,
        children: [
          // Index 0: Tampilan Dashboard
          _buildDashboardContent(isDark, user),
          
          // Index 1: Tampilan List Tiket (Fase 3)
          const TicketListScreen(),
          
          // Index 2: Notifikasi
          const NotificationScreen(),
          
          // Index 3: Profil
          const Center(child: Text('Fitur Profil Belum Tersedia')),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  // ─── Dashboard Content ────────────────────────────────────────────────────

  Widget _buildDashboardContent(bool isDark, User? user) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _refreshData(),
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
                    // ── Salam ──────────────────────────────────────────
                    _buildGreetingSection(user, isDark),
                    const SizedBox(height: 28),

                    // ── Label Statistik ────────────────────────────────
                    _buildSectionLabel('Statistik Tiket', isDark),
                    const SizedBox(height: 14),

                    // ── Grid Statistik ─────────────────────────────────
                    _buildStatisticsSection(isDark),
                    const SizedBox(height: 28),

                    // ── Label Tiket Terbaru ────────────────────────────
                    _buildSectionLabel('Tiket Terbaru', isDark,
                        trailing: 'Lihat Semua'),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // ── List Tiket Terbaru ──────────────────────────────────────
            _buildRecentTicketsSliver(isDark),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.accentCyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.confirmation_number_outlined,
                color: AppTheme.accentCyan, size: 16),
          ),
          const SizedBox(width: 10),
          const Text('HelpDesk'),
        ],
      ),
      actions: [
        // Toggle tema
        IconButton(
          onPressed: widget.onThemeToggle,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) =>
                RotationTransition(turns: anim, child: child),
            child: Icon(
              widget.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              key: ValueKey(widget.isDarkMode),
              color: isDark
                  ? const Color(0xFFCBD5E1)
                  : Colors.white.withOpacity(0.9),
              size: 22,
            ),
          ),
          tooltip: widget.isDarkMode ? 'Mode Terang' : 'Mode Gelap',
        ),
        const SizedBox(width: 4),
        // Logout
        IconButton(
          onPressed: _handleLogout,
          icon: Icon(
            Icons.logout_rounded,
            color: isDark
                ? const Color(0xFFCBD5E1)
                : Colors.white.withOpacity(0.9),
            size: 22,
          ),
          tooltip: 'Logout',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ─── Greeting ─────────────────────────────────────────────────────────────

  Widget _buildGreetingSection(User? user, bool isDark) {
    final hour = DateTime.now().hour;
    final greeting = hour < 11
        ? 'Selamat Pagi'
        : hour < 15
            ? 'Selamat Siang'
            : hour < 18
                ? 'Selamat Sore'
                : 'Selamat Malam';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user?.fullName ?? 'Pengguna',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? const Color(0xFFE2E8F0)
                      : AppTheme.primaryNavy,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  user?.role.label ?? '',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentCyan,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Avatar
        CircleAvatar(
          radius: 26,
          backgroundColor: AppTheme.accentCyan.withOpacity(0.15),
          backgroundImage: user?.avatarUrl != null
              ? NetworkImage(user!.avatarUrl)
              : null,
          child: user?.avatarUrl == null
              ? Text(
                  user?.fullName.substring(0, 1).toUpperCase() ?? '?',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentCyan),
                )
              : null,
        ),
      ],
    );
  }

  // ─── Section Label ────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label, bool isDark, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFE2E8F0) : AppTheme.primaryNavy,
            letterSpacing: -0.2,
          ),
        ),
        if (trailing != null)
          GestureDetector(
            onTap: () {}, // Navigasi ke list screen di Langkah berikutnya.
            child: Text(
              trailing,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentCyan,
              ),
            ),
          ),
      ],
    );
  }

  // ─── Statistics Grid ──────────────────────────────────────────────────────

  Widget _buildStatisticsSection(bool isDark) {
    return FutureBuilder<Map<String, int>>(
      future: _statisticsFuture,
      builder: (context, snapshot) {
        // ── Loading ──
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatLoadingSkeleton(isDark);
        }

        // ── Error ──
        if (snapshot.hasError) {
          return _buildErrorWidget(
            'Gagal memuat statistik',
            snapshot.error.toString(),
            _refreshData,
            isDark,
          );
        }

        // ── Data ──
        final stats = snapshot.data ?? {};

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
          ),
          itemCount: _statCards.length,
          itemBuilder: (context, index) {
            final card = _statCards[index];
            final value = stats[card.key] ?? 0;
            return _StatisticCard(
              card: card,
              value: value,
              isDark: isDark,
            );
          },
        );
      },
    );
  }

  /// Skeleton loading untuk area statistik.
  Widget _buildStatLoadingSkeleton(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => _SkeletonCard(isDark: isDark),
    );
  }

  // ─── Recent Tickets Sliver ────────────────────────────────────────────────

  Widget _buildRecentTicketsSliver(bool isDark) {
    return FutureBuilder<List<Ticket>>(
      future: _recentTicketsFuture,
      builder: (context, snapshot) {
        // ── Loading ──
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: _SkeletonCard(isDark: isDark, height: 80),
              ),
              childCount: 3,
            ),
          );
        }

        // ── Error ──
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildErrorWidget(
                'Gagal memuat tiket',
                snapshot.error.toString(),
                _refreshData,
                isDark,
              ),
            ),
          );
        }

        // ── Kosong ──
        final tickets = snapshot.data ?? [];
        if (tickets.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyTickets(isDark),
          );
        }

        // ── Data — tampilkan 5 tiket terbaru ──
        final recent =
            tickets.take(5).toList()
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

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
      },
    );
  }

  // ─── Helper Widgets ───────────────────────────────────────────────────────

  Widget _buildErrorWidget(
    String title,
    String detail,
    VoidCallback onRetry,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.statusOpen.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppTheme.statusOpen.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded,
              color: AppTheme.statusOpen.withOpacity(0.6), size: 36),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color:
                  isDark ? const Color(0xFFE2E8F0) : AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon:
                const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Coba Lagi'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(120, 38),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTickets(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded,
              size: 48,
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFCBD5E1)),
          const SizedBox(height: 10),
          Text(
            'Belum ada tiket',
            style: TextStyle(
              color: isDark
                  ? const Color(0xFF475569)
                  : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Nav ───────────────────────────────────────────────────────────

  Widget _buildBottomNav(bool isDark) {
    return NavigationBar(
      selectedIndex: _selectedNavIndex,
      onDestinationSelected: (i) {
        setState(() => _selectedNavIndex = i);
        if (i == 2) _loadUnreadCount();
      },
      backgroundColor:
          isDark ? AppTheme.cardDark : AppTheme.cardLight,
      indicatorColor: AppTheme.accentCyan.withOpacity(0.15),
      surfaceTintColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded,
              color: AppTheme.accentCyan),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.confirmation_number_outlined),
          selectedIcon: Icon(Icons.confirmation_number_rounded,
              color: AppTheme.accentCyan),
          label: 'Tiket',
        ),
        NavigationDestination(
          icon: _unreadCount > 0
              ? Badge(
                  label: Text(
                    _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  child: const Icon(Icons.notifications_outlined),
                )
              : const Icon(Icons.notifications_outlined),
          selectedIcon: _unreadCount > 0
              ? Badge(
                  label: Text(
                    _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  child: const Icon(Icons.notifications_rounded,
                      color: AppTheme.accentCyan),
                )
              : const Icon(Icons.notifications_rounded,
                  color: AppTheme.accentCyan),
          label: 'Notifikasi',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon:
              Icon(Icons.person_rounded, color: AppTheme.accentCyan),
          label: 'Profil',
        ),
      ],
    );
  }
}

// ─── Stat Card Widget ─────────────────────────────────────────────────────────

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.card,
    required this.value,
    required this.isDark,
  });

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
        border: Border.all(
          color: card.color.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: card.color.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon Badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: card.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(card.icon, color: card.color, size: 19),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color:
                      isDark ? const Color(0xFFE2E8F0) : AppTheme.primaryNavy,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                card.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Ticket List Item ─────────────────────────────────────────────────────────

class _TicketListItem extends StatelessWidget {
  const _TicketListItem({required this.ticket, required this.isDark});

  final Ticket ticket;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        AppTheme.statusForegroundColor(ticket.status.label);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Status dot
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 12, top: 2),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : AppTheme.primaryNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Tag(
                        label: ticket.status.label,
                        color: statusColor),
                    const SizedBox(width: 6),
                    _Tag(
                        label: ticket.priority.label,
                        color: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFF94A3B8)),
                    const Spacer(),
                    Text(
                      _formatDate(ticket.updatedAt),
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─── Skeleton Card ────────────────────────────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard({required this.isDark, this.height});

  final bool isDark;
  final double? height;

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
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
            widget.isDark
                ? const Color(0xFF162436)
                : const Color(0xFFE2E8F0),
            widget.isDark
                ? const Color(0xFF1E3554)
                : const Color(0xFFF1F5F9),
            _anim.value,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}