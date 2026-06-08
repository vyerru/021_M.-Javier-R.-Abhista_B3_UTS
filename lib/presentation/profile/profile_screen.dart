import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const ProfileScreen({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    if (_isEditing) {
      final user = context.read<AuthProvider>().currentUser;
      setState(() {
        _nameController.text = user?.fullName ?? '';
        _usernameController.text = user?.username ?? '';
        _isEditing = false;
      });
    } else {
      setState(() => _isEditing = true);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      fullName: _nameController.text.trim(),
      username: _usernameController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isEditing = false;
    });

    if (success) {
      _showSnackbar('Profil berhasil diperbarui');
    } else {
      _showSnackbar(auth.error ?? 'Gagal memperbarui profil', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFDC2626) : AppTheme.primaryNavy,
      ),
    );
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
    final user = auth.currentUser;
    final ticketProvider = context.watch<TicketProvider>();
    final stats = ticketProvider.statistics ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          else
            TextButton(
              onPressed: _toggleEdit,
              child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _buildProfileHeader(user, isDark),
          const SizedBox(height: 24),
          if (_isEditing)
            _buildEditForm(isDark)
          else
            _buildInfoSection(user, isDark),
          const SizedBox(height: 24),
          _buildStatisticsSection(isDark, stats),
          const SizedBox(height: 24),
          _buildActionsSection(isDark),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(User? user, bool isDark) {
    return Column(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: AppTheme.accentCyan.withValues(alpha: 0.15),
          backgroundImage: user?.avatarUrl.isNotEmpty == true ? NetworkImage(user!.avatarUrl) : null,
          child: user?.avatarUrl.isNotEmpty != true
              ? Text(
                  (user?.fullName ?? '?').substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppTheme.accentCyan),
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          user?.fullName ?? 'Pengguna',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFFE2E8F0) : AppTheme.primaryNavy, letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        Text(
          '@${user?.username ?? ''}',
          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.accentCyan.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            user?.role.label ?? '',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.accentCyan, letterSpacing: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(User? user, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Nama Lengkap',
              value: user?.fullName ?? '-',
            ),
            const Divider(height: 20),
            _buildInfoRow(
              icon: Icons.alternate_email_rounded,
              label: 'Username',
              value: user?.username ?? '-',
            ),
            const Divider(height: 20),
            _buildInfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user?.email ?? '-',
            ),
            const Divider(height: 20),
            _buildInfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Bergabung',
              value: user != null ? _formatDate(user.createdAt) : '-',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm(bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nama Lengkap', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                enabled: !_isSaving,
                decoration: const InputDecoration(hintText: 'Nama lengkap'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),
              Text('Username', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                enabled: !_isSaving,
                decoration: const InputDecoration(hintText: 'Username', prefixText: '@'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Username tidak boleh kosong' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(bool isDark, Map<String, int> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 2),
          child: Text(
            'Statistik Akun',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFE2E8F0) : AppTheme.primaryNavy),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildStatItem(
                      isDark: isDark,
                      icon: Icons.confirmation_number_rounded,
                      label: 'Total Tiket',
                      value: stats['total'] ?? 0,
                      color: AppTheme.accentCyan,
                    ),
                    const SizedBox(width: 16),
                    _buildStatItem(
                      isDark: isDark,
                      icon: Icons.radio_button_unchecked_rounded,
                      label: 'Open',
                      value: stats['open'] ?? 0,
                      color: AppTheme.statusOpen,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatItem(
                      isDark: isDark,
                      icon: Icons.autorenew_rounded,
                      label: 'In Progress',
                      value: stats['inProgress'] ?? 0,
                      color: AppTheme.statusInProgress,
                    ),
                    const SizedBox(width: 16),
                    _buildStatItem(
                      isDark: isDark,
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Resolved',
                      value: stats['resolved'] ?? 0,
                      color: AppTheme.statusResolved,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required bool isDark,
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.toString(),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFFE2E8F0) : AppTheme.primaryNavy, height: 1),
              ),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 2),
          child: Text(
            'Pengaturan',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFE2E8F0) : AppTheme.primaryNavy),
          ),
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  widget.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: AppTheme.accentCyan,
                ),
                title: const Text('Mode Gelap', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  widget.isDarkMode ? 'Aktif' : 'Nonaktif',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Switch(
                  value: widget.isDarkMode,
                  onChanged: (_) => widget.onThemeToggle(),
                  activeThumbColor: AppTheme.accentCyan,
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                onTap: _handleLogout,
                leading: const Icon(Icons.logout_rounded, color: AppTheme.statusOpen),
                title: const Text('Logout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.statusOpen)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
        const SizedBox(width: 10),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}
