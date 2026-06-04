import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/services.dart';
import '../dashboard/dashboard_screen.dart';
import '../../main.dart';

/// Halaman Login — FR-001.
///
/// Menangani autentikasi pengguna dengan memanggil [MockService.login].
/// Menampilkan loading state dan error via [SnackBar] saat terjadi [AuthException].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ─── Controllers & Keys ──────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // ─── State ───────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _obscurePassword = true;

  // ─── Animation ───────────────────────────────────────────────────────────
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    // Jalankan animasi masuk saat halaman dibuka.
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── Logic ───────────────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    // Tutup keyboard.
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await MockService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      final themeProvider = ThemeToggleProvider.of(context);

      // Navigasi ke Dashboard, hapus semua route sebelumnya.
      Navigator.of(context).pushReplacement(
         PageRouteBuilder(
           pageBuilder: (_, animation, __) => DashboardScreen(
             onThemeToggle: themeProvider?.toggleTheme ?? () {},
             isDarkMode: themeProvider?.isDarkMode ?? false,
           ),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.message);
    } catch (_) {
      if (!mounted) return;
      _showErrorSnackBar('Terjadi kesalahan. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFFCA5A5), size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: const Color(0xFF7F1D1D),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: size.height * 0.08),

                      // ── Logo & Header ───────────────────────────────────
                      _buildHeader(isDark),

                      const SizedBox(height: 40),

                      // ── Form Card ───────────────────────────────────────
                      _buildFormCard(theme, isDark),

                      const SizedBox(height: 16),

                      // ── Hint Akun Demo ──────────────────────────────────
                      _buildDemoHint(theme, isDark),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Sub-Widgets ──────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon badge
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.accentCyan.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppTheme.accentCyan.withOpacity(0.3), width: 1),
          ),
          child: const Icon(
            Icons.confirmation_number_outlined,
            color: AppTheme.accentCyan,
            size: 28,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Selamat\nDatang Kembali',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFE2E8F0) : AppTheme.primaryNavy,
            height: 1.2,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Masuk ke akun E-Ticketing Helpdesk Anda',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? const Color(0xFF64748B)
                : const Color(0xFF64748B),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Username
            Text(
              'Username',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF475569),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _usernameController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                hintText: 'Masukkan username',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Username tidak boleh kosong';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Password
            Text(
              'Password',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF475569),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              enabled: !_isLoading,
              onFieldSubmitted: (_) => _handleLogin(),
              decoration: InputDecoration(
                hintText: 'Masukkan password',
                prefixIcon:
                    const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  tooltip:
                      _obscurePassword ? 'Tampilkan password' : 'Sembunyikan',
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Password tidak boleh kosong';
                }
                if (val.length < 6) {
                  return 'Password minimal 6 karakter';
                }
                return null;
              },
            ),

            const SizedBox(height: 28),

            // Tombol Login
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isLoading
                  ? _buildLoadingButton(isDark)
                  : ElevatedButton(
                      key: const ValueKey('login-btn'),
                      onPressed: _handleLogin,
                      child: const Text('Masuk'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingButton(bool isDark) {
    return Container(
      key: const ValueKey('loading-btn'),
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.accentCyan.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDemoHint(ThemeData theme, bool isDark) {
    final hintColor = isDark
        ? const Color(0xFF475569)
        : const Color(0xFF94A3B8);
    final accounts = [
      ('admin', 'admin123', 'Admin'),
      ('helpdesk1', 'helpdesk123', 'Helpdesk'),
      ('user1', 'user123', 'User'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.accentCyan.withOpacity(0.05)
            : const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentCyan.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 15, color: AppTheme.accentCyan.withOpacity(0.8)),
              const SizedBox(width: 6),
              Text(
                'Akun Demo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentCyan.withOpacity(0.9),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...accounts.map(
            (acc) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 12, color: hintColor, height: 1.5),
                  children: [
                    TextSpan(
                      text: '${acc.$3}: ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: '${acc.$1} / ${acc.$2}'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}