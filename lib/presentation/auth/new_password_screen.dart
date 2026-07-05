import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import 'login_screen.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;

  const NewPasswordScreen({super.key, required this.email});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final demoPasswords = ['admin123', 'helpdesk123', 'user123456'];
      bool updated = false;

      for (final oldPass in demoPasswords) {
        try {
          await supabase.auth.signInWithPassword(
            email: widget.email,
            password: oldPass,
          );
          await supabase.auth.updateUser(
            AdminUserAttributes(password: _passwordController.text),
          );
          await supabase.auth.signOut();
          updated = true;
          break;
        } catch (_) {
          continue;
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (updated) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: Color(0xFF86EFAC), size: 18),
                  SizedBox(width: 10),
                  Expanded(child: Text('Password berhasil diubah. Silakan login ulang.')),
                ],
              ),
              backgroundColor: const Color(0xFF14532D),
              duration: const Duration(seconds: 4),
            ),
          );
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: Color(0xFFFCA5A5), size: 18),
                  SizedBox(width: 10),
                  Expanded(child: Text('Gagal: password default tidak cocok. Hubungi admin.')),
                ],
              ),
              backgroundColor: const Color(0xFF7F1D1D),
              duration: const Duration(seconds: 4),
            ),
          );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: const Color(0xFF7F1D1D),
          ),
        );
    }
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: size.height * 0.1),
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppTheme.accentCyan.withValues(alpha: 0.3), width: 1),
                    ),
                    child: const Icon(Icons.lock_reset_rounded,
                        color: AppTheme.accentCyan, size: 28),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Buat Password\nBaru',
                    style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFFE2E8F0) : AppTheme.primaryNavy,
                      height: 1.2, letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Email: ${widget.email}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppTheme.dividerDark : AppTheme.dividerLight,
                        width: 1,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Password Baru',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePass,
                            textInputAction: TextInputAction.next,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              hintText: 'Minimal 6 karakter',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Password tidak boleh kosong';
                              if (val.length < 6) return 'Password minimal 6 karakter';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          Text('Konfirmasi Password Baru',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmController,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            enabled: !_isLoading,
                            onFieldSubmitted: (_) => _handleUpdate(),
                            decoration: InputDecoration(
                              hintText: 'Ulangi password baru',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Konfirmasi password tidak boleh kosong';
                              if (val != _passwordController.text) return 'Password tidak cocok';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleUpdate,
                              child: _isLoading
                                  ? const SizedBox(width: 22, height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                  : const Text('Simpan Password Baru'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
