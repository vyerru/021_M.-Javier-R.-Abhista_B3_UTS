import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/splash/splash_screen.dart';

void main() {
  runApp(const ETicketingApp());
}

/// Root widget aplikasi.
///
/// Menyimpan state [_isDarkMode] di sini agar toggle tema bisa
/// dipropagasi ke seluruh widget tree tanpa state management eksternal.
class ETicketingApp extends StatefulWidget {
  const ETicketingApp({super.key});

  @override
  State<ETicketingApp> createState() => _ETicketingAppState();
}

class _ETicketingAppState extends State<ETicketingApp> {
  bool _isDarkMode = false;

  void _toggleTheme() => setState(() => _isDarkMode = !_isDarkMode);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Ticketing Helpdesk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
      builder: (context, child) {
        // Inject ThemeToggleCallback ke widget tree lewat InheritedWidget ringan.
        return ThemeToggleProvider(
          toggleTheme: _toggleTheme,
          isDarkMode: _isDarkMode,
          child: child!,
        );
      },
    );
  }
}

// ─── InheritedWidget ringan untuk propagasi callback toggle tema ──────────────

/// Menyediakan [toggleTheme] callback ke seluruh widget tree.
/// Lebih ringan dari Provider dan tidak memerlukan dependency eksternal.
class ThemeToggleProvider extends InheritedWidget {
  const ThemeToggleProvider({
    required this.toggleTheme,
    required this.isDarkMode,
    required super.child,
  });

  final VoidCallback toggleTheme;
  final bool isDarkMode;

  /// Mengakses provider dari context manapun.
  static ThemeToggleProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeToggleProvider>();
  }

  @override
  bool updateShouldNotify(ThemeToggleProvider old) =>
      isDarkMode != old.isDarkMode;
}