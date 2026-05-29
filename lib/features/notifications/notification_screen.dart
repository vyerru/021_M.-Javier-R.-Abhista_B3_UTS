import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../tickets/ticket_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<AppNotification>> _notifFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _notifFuture = MockService.getNotifications();
    });
  }

  Future<void> _handleTap(AppNotification notif) async {
    if (!notif.isRead) {
      await MockService.markNotificationAsRead(notif.id);
      _loadData();
    }
    if (notif.ticketId != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TicketDetailScreen(ticketId: notif.ticketId!),
        ),
      );
    }
  }

  Future<void> _handleMarkAllRead() async {
    await MockService.markAllNotificationsAsRead();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<List<AppNotification>>(
      future: _notifFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.accentCyan,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 40,
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFF94A3B8)),
                const SizedBox(height: 12),
                const Text('Gagal memuat notifikasi'),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_off_rounded,
                    size: 48,
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1)),
                const SizedBox(height: 12),
                Text(
                  'Tidak ada notifikasi',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
              child: Row(
                children: [
                  Text(
                    '${notifications.length} Notifikasi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _handleMarkAllRead,
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Tandai Semua Dibaca'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.accentCyan,
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _loadData(),
                color: AppTheme.accentCyan,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return _NotificationCard(
                      notification: notif,
                      isDark: isDark,
                      onTap: () => _handleTap(notif),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final bool isDark;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.isDark,
    required this.onTap,
  });

  IconData get _icon {
    if (notification.title == 'Tiket Baru') {
      return Icons.add_circle_outline_rounded;
    }
    return Icons.swap_horiz_rounded;
  }

  Color get _iconColor {
    if (notification.title == 'Tiket Baru') {
      return AppTheme.statusResolved;
    }
    return AppTheme.accentCyan;
  }

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead
              ? (isDark ? AppTheme.cardDark : AppTheme.cardLight)
              : (isDark
                  ? AppTheme.accentCyan.withOpacity(0.06)
                  : AppTheme.accentCyan.withOpacity(0.04)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead
                ? (isDark ? AppTheme.dividerDark : AppTheme.dividerLight)
                : AppTheme.accentCyan.withOpacity(0.15),
            width: isRead ? 1 : 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: _iconColor, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6, top: 2),
                          decoration: const BoxDecoration(
                            color: AppTheme.accentCyan,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isRead ? FontWeight.w600 : FontWeight.w700,
                            color: isDark
                                ? const Color(0xFFE2E8F0)
                                : AppTheme.primaryNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF64748B),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        _timeAgo(notification.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      if (notification.ticketTitle != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF475569)
                                : const Color(0xFFCBD5E1),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notification.ticketTitle!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.accentCyan,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
