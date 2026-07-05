import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/entities.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import 'ticket_history_screen.dart';

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
    final isAdmin = currentUser?.role == UserRole.admin;
    final isHelpdesk = currentUser?.role == UserRole.helpdesk;
    final available = _availableStatuses(ticket, isAdmin, isHelpdesk);

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
                _StatusTransitionCard(
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
                _StatusTransitionCard(
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

  Color _priorityColor(TicketPriority p) {
    switch (p) {
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

  bool _canChangeStatus(Ticket ticket, bool isAdmin, bool isHelpdesk) {
    if (isAdmin && ticket.status == TicketStatus.open) return true;
    if (isHelpdesk && ticket.status == TicketStatus.inprogress) return true;
    return false;
  }

  bool _canAssign(Ticket ticket) {
    return ticket.status == TicketStatus.assign;
  }

  List<TicketStatus> _availableStatuses(Ticket ticket, bool isAdmin, bool isHelpdesk) {
    if (isAdmin && ticket.status == TicketStatus.open) return [TicketStatus.assign];
    if (isHelpdesk && ticket.status == TicketStatus.inprogress) return [TicketStatus.closed];
    return [];
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
                if (_canChangeStatus(ticket, isAdmin, isHelpdesk))
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
                if (isAdmin && _canAssign(ticket))
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
                              _buildHeaderCard(ticket),
                              const SizedBox(height: 12),
                              _buildInfoCard(ticket),
                              const SizedBox(height: 12),
                              if (ticket.attachmentUrls.isNotEmpty) ...[
                                _buildAttachmentsSection(ticket),
                                const SizedBox(height: 12),
                              ],
                              if (isStaff) ...[
                                _buildStaffActionsCard(ticket),
                                const SizedBox(height: 12),
                              ],
                              _buildTimelineSection(ticket),
                              const SizedBox(height: 12),
                              _buildCommentsSection(ticket, currentUser),
                            ],
                          ),
                        ),
                        _buildCommentInput(ticket),
                      ],
                    ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  SECTION WIDGETS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildHeaderCard(Ticket ticket) {
    final theme = Theme.of(context);
    final statusBg = AppTheme.statusBackgroundColor(ticket.status.label);
    final statusFg = AppTheme.statusForegroundColor(ticket.status.label);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 8,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ticket.status.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusFg,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _priorityColor(ticket.priority).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ticket.priority.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _priorityColor(ticket.priority),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '#${ticket.id}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              ticket.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              ticket.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Ticket ticket) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.folder_outlined,
              label: 'Kategori',
              value: ticket.category,
            ),
            const Divider(height: 20),
            _InfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Dibuat oleh',
              value: ticket.createdBy.fullName,
              avatar: ticket.createdBy.avatarUrl,
            ),
            const Divider(height: 20),
            _InfoRow(
              icon: Icons.support_agent_rounded,
              label: 'Di-assign ke',
              value: ticket.assignedTo?.fullName ?? '— Belum di-assign —',
              avatar: ticket.assignedTo?.avatarUrl,
              valueColor: ticket.assignedTo == null
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                  : null,
            ),
            const Divider(height: 20),
            _InfoRow(
              icon: Icons.schedule_rounded,
              label: 'Dibuat',
              value: _formatDateTime(ticket.createdAt),
            ),
            const Divider(height: 20),
            _InfoRow(
              icon: Icons.update_rounded,
              label: 'Diperbarui',
              value: _formatDateTime(ticket.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection(Ticket ticket) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 6,
              children: [
                Icon(Icons.attach_file_rounded, size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                Text(
                  'Lampiran (${ticket.attachmentUrls.length})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ticket.attachmentUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final url = ticket.attachmentUrls[index];
                  final isImage = RegExp(r'\.(jpg|jpeg|png|gif|webp)(\?|$)').hasMatch(url);

                  return GestureDetector(
                    onTap: isImage ? () => _showImagePreview(url) : null,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: isImage
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(url, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded)),
                            )
                          : Center(
                              child: Icon(
                                url.contains('.pdf')
                                    ? Icons.picture_as_pdf_rounded
                                    : Icons.insert_drive_file_rounded,
                                size: 32,
                                color: AppTheme.accentCyan.withValues(alpha: 0.6),
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildStaffActionsCard(Ticket ticket) {
    final currentUser = context.read<AuthProvider>().currentUser;
    final isAdmin = currentUser?.role == UserRole.admin;
    final isHelpdesk = currentUser?.role == UserRole.helpdesk;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            if (_canChangeStatus(ticket, isAdmin, isHelpdesk))
              OutlinedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () => _showUpdateStatusSheet(ticket),
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: Text(isHelpdesk ? 'Selesaikan Tiket' : 'Ubah Status'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                ),
              ),
            if (isAdmin && _canAssign(ticket))
              ElevatedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () => _showAssignSheet(ticket),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Assign'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection(Ticket ticket) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 2),
          child: Text(
            'Riwayat Tiket',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ticket.history.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Belum ada riwayat.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: List.generate(ticket.history.length, (i) {
                      final entry = ticket.history[i];
                      final isLast = i == ticket.history.length - 1;
                      final dotColor =
                          entry.toStatus != null
                              ? AppTheme.statusForegroundColor(
                                  entry.toStatus!.label)
                              : AppTheme.accentCyan;

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Timeline Gutter ─────────────────────────
                            SizedBox(
                              width: 24,
                              child: Column(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    margin: const EdgeInsets.only(top: 2),
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
                            const SizedBox(width: 12),
                            // ── Content ─────────────────────────────────
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                    bottom: isLast ? 0 : 16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.action,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${entry.changedBy.fullName} · ${_formatDateTime(entry.timestamp)}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketHistoryScreen(ticketId: ticket.id),
                ),
              );
            },
            icon: const Icon(Icons.history_rounded, size: 16),
            label: const Text('Lihat Riwayat Lengkap'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection(Ticket ticket, User? currentUser) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 2),
          child: Text(
            'Komentar (${ticket.comments.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (ticket.comments.isEmpty)
          Card(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 36,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.25)),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada komentar',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...ticket.comments.map((comment) {
            final isMe = comment.author.id == currentUser?.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                color: isMe
                    ? AppTheme.accentCyan.withValues(alpha: 0.07)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        spacing: 8,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: comment.author.avatarUrl.isNotEmpty
                                ? NetworkImage(comment.author.avatarUrl)
                                : null,
                            child: comment.author.avatarUrl.isEmpty
                                ? Text(comment.author.fullName.isNotEmpty
                                    ? comment.author.fullName[0].toUpperCase()
                                    : '?', style: const TextStyle(fontSize: 10))
                                : null,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  spacing: 6,
                                  children: [
                                    Text(
                                      comment.author.fullName,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentCyan
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        comment.author.role.label,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.accentCyan,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  _formatDateTime(comment.createdAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        comment.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCommentInput(Ticket ticket) {
    final theme = Theme.of(context);
    final isResolved = ticket.status == TicketStatus.closed;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 10),
      child: Row(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              enabled: !_isSubmitting && !isResolved,
              maxLines: 4,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: isResolved
                    ? 'Tiket sudah ditutup'
                    : 'Tulis komentar...',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: _isSubmitting
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : IconButton.filled(
                    onPressed: isResolved ? null : _submitComment,
                    icon: const Icon(Icons.send_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: isResolved
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
                          : AppTheme.accentCyan,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widget: Status Transition Card ─────────────────────────────────────

class _StatusTransitionCard extends StatelessWidget {
  final String label;
  final String statusLabel;
  final Color fg;
  final Color bg;
  final IconData icon;

  const _StatusTransitionCard({
    required this.label,
    required this.statusLabel,
    required this.fg,
    required this.bg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: fg.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        spacing: 12,
        children: [
          Icon(icon, color: fg, size: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: fg,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widget: Info Row ──────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? avatar;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.avatar,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveValueColor = valueColor ?? theme.colorScheme.onSurface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        Expanded(
          child: Row(
            spacing: 8,
            children: [
              if (avatar != null)
                CircleAvatar(
                  radius: 10,
                  backgroundImage: NetworkImage(avatar!),
                ),
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: effectiveValueColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
