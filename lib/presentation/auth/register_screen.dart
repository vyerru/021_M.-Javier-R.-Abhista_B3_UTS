import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const routeName = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

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

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      email: _emailController.text.trim(),
      username: _usernameController.text.trim(),
      fullName: _fullNameController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      await auth.logout();
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: Color(0xFF86EFAC), size: 18),
                SizedBox(width: 10),
                Expanded(
                    child: Text('Registrasi berhasil! Silakan masuk.')),
              ],
            ),
            backgroundColor: const Color(0xFF14532D),
            duration: const Duration(seconds: 4),
          ),
        );

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } else {
      _showErrorSnackBar(auth.error ?? 'Registrasi gagal. Silakan coba lagi.');
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
                      SizedBox(height: size.height * 0.06),

                      _buildHeader(isDark),

                      const SizedBox(height: 28),

                      _buildFormCard(theme, isDark),

                      const SizedBox(height: 16),

                      _buildLoginLink(isDark),

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

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.accentCyan.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppTheme.accentCyan.withValues(alpha: 0.3), width: 1),
          ),
          child: const Icon(
            Icons.person_add_outlined,
            color: AppTheme.accentCyan,
            size: 28,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Buat Akun\nBaru',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: isDark ? AppTheme.darkText : AppTheme.primaryNavy,
            height: 1.2,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Daftar untuk membuat tiket bantuan',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppTheme.textSecondary
                : AppTheme.textSecondary,
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
                  color: Colors.black.withValues(alpha: 0.04),
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
            _buildLabel('Email', isDark),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                hintText: 'Masukkan email',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Email tidak boleh kosong';
                }
                if (!val.contains('@')) {
                  return 'Format email tidak valid';
                }
                final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                if (!emailRegex.hasMatch(val)) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            _buildLabel('Username', isDark),
            const SizedBox(height: 8),
            TextFormField(
              controller: _usernameController,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                hintText: 'Masukkan username',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Username tidak boleh kosong';
                }
                if (val.trim().length < 3) {
                  return 'Username minimal 3 karakter';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            _buildLabel('Nama Lengkap', isDark),
            const SizedBox(height: 8),
            TextFormField(
              controller: _fullNameController,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                hintText: 'Masukkan nama lengkap',
                prefixIcon: Icon(Icons.badge_outlined, size: 20),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nama lengkap tidak boleh kosong';
                }
                if (val.trim().length < 3) {
                  return 'Nama lengkap minimal 3 karakter';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            _buildLabel('Password', isDark),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: 'Minimal 6 karakter',
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

            const SizedBox(height: 20),

            _buildLabel('Konfirmasi Password', isDark),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              enabled: !_isLoading,
              onFieldSubmitted: (_) => _handleRegister(),
              decoration: InputDecoration(
                hintText: 'Ulangi password',
                prefixIcon:
                    const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Konfirmasi password tidak boleh kosong';
                }
                if (val != _passwordController.text) {
                  return 'Password tidak cocok';
                }
                return null;
              },
            ),

            const SizedBox(height: 28),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isLoading
                  ? _buildLoadingButton(isDark)
                  : ElevatedButton(
                      key: const ValueKey('register-btn'),
                      onPressed: _handleRegister,
                      child: const Text('Daftar'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark
            ? AppTheme.textMuted
            : AppTheme.iconDarkMuted,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildLoadingButton(bool isDark) {
    return Container(
      key: const ValueKey('loading-btn'),
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.accentCyan.withValues(alpha: 0.6),
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

  Widget _buildLoginLink(bool isDark) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Sudah punya akun? ',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppTheme.textSecondary
                  : AppTheme.textSecondary,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (_, animation, __) => const LoginScreen(),
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 350),
                ),
              );
            },
            child: Text(
              'Masuk',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.accentCyan.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
