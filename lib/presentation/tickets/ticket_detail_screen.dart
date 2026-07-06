import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/entities.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import 'ticket_history_screen.dart';
import 'widgets/ticket_header_card.dart';
import 'widgets/ticket_info_card.dart';
import 'widgets/ticket_attachments.dart';
import 'widgets/staff_actions_card.dart';
import 'widgets/ticket_timeline.dart';
import 'widgets/comments_section.dart';
import 'widgets/comment_input.dart';
import 'widgets/status_transition_card.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().loadTicketDetail(widget.ticketId);
      context.read<TicketProvider>().loadHelpdeskUsers();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _refresh() {
    context.read<TicketProvider>().loadTicketDetail(widget.ticketId);
  }

  // ── Submit komentar ──────────────────────────────────────────────────────────

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    final ok = await context.read<TicketProvider>().addComment(
          widget.ticketId,
          user.id,
          text,
        );
    if (ok) {
      _commentController.clear();
    } else {
      if (mounted) {
        _showSnackbar(
          context.read<TicketProvider>().error ?? 'Gagal menambahkan komentar',
          isError: true,
        );
      }
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  // ── Update status (admin/helpdesk) ───────────────────────────────────────────

  Future<void> _showUpdateStatusSheet(Ticket ticket) async {
    final currentUser = context.read<AuthProvider>().currentUser;
    final isHelpdesk = currentUser?.role == UserRole.helpdesk;
    final available = ticket.availableStatusesFor(currentUser?.role ?? UserRole.user);

    if (available.isEmpty) return;

    final targetStatus = available.first;

    final theme = Theme.of(context);
    final currentFg = AppTheme.statusForegroundColor(ticket.status.label);
    final currentBg = AppTheme.statusBackgroundColor(ticket.status.label);
    final targetFg = AppTheme.statusForegroundColor(targetStatus.label);
    final targetBg = AppTheme.statusBackgroundColor(targetStatus.label);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  isHelpdesk ? 'Selesaikan Tiket' : 'Ubah Status Tiket',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),

                // Current status
                StatusTransitionCard(
                  label: 'Status Saat Ini',
                  statusLabel: ticket.status.label,
                  fg: currentFg,
                  bg: currentBg,
                  icon: Icons.radio_button_unchecked_rounded,
                ),

                // Arrow down
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),

                // Target status
                StatusTransitionCard(
                  label: isHelpdesk
                      ? 'Tandai selesai'
                      : 'Tandai untuk diassign',
                  statusLabel: targetStatus.label,
                  fg: targetFg,
                  bg: targetBg,
                  icon: Icons.check_circle_outline_rounded,
                ),

                // Description
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  child: Text(
                    isHelpdesk
                        ? 'Tiket akan ditutup dan admin akan mendapat notifikasi'
                        : 'Helpdesk akan dapat mengerjakan tiket ini setelah diassign',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const Divider(height: 1),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(ctx, true),
                        icon: Icon(
                          isHelpdesk
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                        label: Text(
                          isHelpdesk ? 'Selesaikan' : 'Konfirmasi',
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: targetFg,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    final provider = context.read<TicketProvider>();
    final ok = await provider.updateStatus(
      widget.ticketId,
      targetStatus,
    );
    if (ok) {
      _showSnackbar('Status berhasil diubah ke ${targetStatus.label}');
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  // ── Assign tiket (admin/helpdesk) ────────────────────────────────────────────

  Future<void> _showAssignSheet(Ticket ticket) async {
    final helpdeskUsers = context.read<TicketProvider>().helpdeskUsers;

    if (!mounted) return;

    final selected = await showModalBottomSheet<User>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Assign ke Petugas',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                ...helpdeskUsers.map((user) {
                  final isCurrent = ticket.assignedTo?.id == user.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => Navigator.pop(ctx, user),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      tileColor: isCurrent
                          ? AppTheme.accentCyan.withValues(alpha: 0.1)
                          : Colors.transparent,
                      leading: CircleAvatar(
                        backgroundImage: user.avatarUrl.isNotEmpty
                            ? NetworkImage(user.avatarUrl)
                            : null,
                        radius: 20,
                        child: user.avatarUrl.isEmpty
                            ? Text(user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : '?')
                            : null,
                      ),
                      title: Text(
                        user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(user.role.label,
                          style: const TextStyle(fontSize: 12)),
                      trailing: isCurrent
                          ? const Icon(Icons.check_rounded,
                              color: AppTheme.accentCyan)
                          : null,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    setState(() => _isSubmitting = true);
    final ok = await context.read<TicketProvider>().assignTicket(
          widget.ticketId,
          selected.id,
        );
    if (ok) {
      _showSnackbar('Tiket berhasil di-assign ke ${selected.fullName}');
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFDC2626) : AppTheme.primaryNavy,
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _formatDateTime(DateTime dt) {
    final months = [
      '',
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month]} ${dt.year}, $h:$m';
  }

  void _showImagePreview(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            title: const Text('Preview Gambar'),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.white, size: 48)),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ticketProvider = context.watch<TicketProvider>();
    final currentUser = context.watch<AuthProvider>().currentUser;
    final isAdmin = currentUser?.role == UserRole.admin;
    final isHelpdesk = currentUser?.role == UserRole.helpdesk;
    final isStaff = isAdmin || isHelpdesk;
    final ticket = ticketProvider.selectedTicket;
    final isLoading = ticketProvider.isLoading && ticket == null;
    final error = ticketProvider.error;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tiket'),
        actions: [
          if (isStaff && ticket != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (val) {
                if (val == 'status') _showUpdateStatusSheet(ticket);
                if (val == 'assign') _showAssignSheet(ticket);
              },
              itemBuilder: (_) => [
                if (ticket.canChangeStatusBy(currentUser?.role ?? UserRole.user))
                  const PopupMenuItem(
                    value: 'status',
                    child: Row(
                      spacing: 12,
                      children: [
                        Icon(Icons.swap_horiz_rounded),
                        Text('Ubah Status'),
                      ],
                    ),
                  ),
                if (ticket.canBeAssignedBy(currentUser?.role ?? UserRole.user))
                  const PopupMenuItem(
                    value: 'assign',
                    child: Row(
                      spacing: 12,
                      children: [
                        Icon(Icons.person_add_alt_1_rounded),
                        Text('Assign Tiket'),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null && ticket == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(
                          error,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _refresh,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : ticket == null
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            children: [
                              TicketHeaderCard(
                                statusLabel: ticket.status.label,
                                statusColor: AppTheme.statusForegroundColor(ticket.status.label),
                                priorityLabel: ticket.priority.label,
                                priorityColor: AppTheme.priorityColor(ticket.priority.label),
                                ticketId: ticket.id,
                                title: ticket.title,
                                description: ticket.description,
                              ),
                              const SizedBox(height: 12),
                              TicketInfoCard(
                                category: ticket.category,
                                createdBy: ticket.createdBy.fullName,
                                assignedTo: ticket.assignedTo?.fullName,
                                assignedToColor: ticket.assignedTo == null
                                    ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                                    : null,
                                createdAt: _formatDateTime(ticket.createdAt),
                                updatedAt: _formatDateTime(ticket.updatedAt),
                              ),
                              const SizedBox(height: 12),
                              if (ticket.attachmentUrls.isNotEmpty) ...[
                                TicketAttachments(
                                  urls: ticket.attachmentUrls,
                                  onImageTap: (url) => _showImagePreview(url),
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (isStaff) ...[
                                StaffActionsCard(
                                  showStatusButton: ticket.canChangeStatusBy(currentUser?.role ?? UserRole.user),
                                  statusButtonLabel: isHelpdesk ? 'Selesaikan Tiket' : 'Ubah Status',
                                  onStatusTap: () => _showUpdateStatusSheet(ticket),
                                  showAssignButton: ticket.canBeAssignedBy(currentUser?.role ?? UserRole.user),
                                  onAssignTap: () => _showAssignSheet(ticket),
                                  isSubmitting: _isSubmitting,
                                ),
                                const SizedBox(height: 12),
                              ],
                              TicketTimeline(
                                history: ticket.history,
                                onViewAllTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TicketHistoryScreen(ticketId: ticket.id),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              CommentsSection(comments: ticket.comments, currentUser: currentUser),
                            ],
                          ),
                        ),
                        CommentInput(
                          isClosed: ticket.status == TicketStatus.closed,
                          isSubmitting: _isSubmitting,
                          controller: _commentController,
                          onSubmit: _submitComment,
                        ),
                      ],
                    ),
    );
  }
}
