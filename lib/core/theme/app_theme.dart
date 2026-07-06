import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Konfigurasi tema global aplikasi E-Ticketing Helpdesk.
///
/// Mendukung [lightTheme] dan [darkTheme] dengan palet warna korporat
/// biru navy. Semua komponen utama (Button, TextField, Card, AppBar)
/// sudah dikonfigurasi agar konsisten tanpa perlu style ulang di setiap halaman.
abstract final class AppTheme {
  // ─── Color Palette ────────────────────────────────────────────────────────

  /// Biru navy korporat — warna primer utama.
  static const Color primaryNavy = Color(0xFF0D2137);

  /// Biru terang — aksen & highlight interaktif.
  static const Color accentCyan = Color(0xFF0EA5E9);

  /// Biru medium — hover & secondary action.
  static const Color secondaryBlue = Color(0xFF1E4D8C);

  // Status tiket
  static const Color statusOpen = Color(0xFFEF4444);       // Merah
  static const Color statusAssign = Color(0xFF8B5CF6);     // Ungu
  static const Color statusInProgress = Color(0xFFF59E0B); // Amber
  static const Color statusClosed = Color(0xFF6B7280);     // Abu

  // Priority tiket
  static const Color priorityLow = Color(0xFF10B981);      // Hijau
  static const Color priorityMedium = Color(0xFFF59E0B);   // Amber
  static const Color priorityHigh = Color(0xFFEF4444);     // Merah
  static const Color priorityCritical = Color(0xFF7C3AED); // Ungu

  // Neutral
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFF0F1D2E);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF0D2137);
  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF1E3554);

  // Text & Icon netral (sering dipakai)
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color iconSubtle = Color(0xFFCBD5E1);
  static const Color iconDarkMuted = Color(0xFF475569);
  static const Color darkText = Color(0xFFE2E8F0);

  // ─── Light Theme ──────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: accentCyan,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE0F2FE),
      onPrimaryContainer: primaryNavy,
      secondary: secondaryBlue,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFDBEAFE),
      onSecondaryContainer: primaryNavy,
      error: Color(0xFFDC2626),
      onError: Colors.white,
      surface: surfaceLight,
      onSurface: Color(0xFF0F172A),
      surfaceContainerHighest: Color(0xFFEEF2F7),
      outline: Color(0xFFCBD5E1),
      outlineVariant: dividerLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceLight,
      fontFamily: 'SF Pro Display', // Fallback ke system sans-serif

      appBarTheme: const AppBarTheme(
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: dividerLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentCyan,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? Colors.white.withValues(alpha: 0.15)
                : null,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentCyan,
          side: const BorderSide(color: accentCyan, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: const BorderSide(color: accentCyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 14,
        ),
        prefixIconColor: const Color(0xFF64748B),
        suffixIconColor: const Color(0xFF64748B),
        floatingLabelStyle: const TextStyle(
          color: accentCyan,
          fontWeight: FontWeight.w600,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: dividerLight,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryNavy,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentCyan,
      ),
    );
  }

  // ─── Dark Theme ───────────────────────────────────────────────────────────

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: accentCyan,
      onPrimary: primaryNavy,
      primaryContainer: Color(0xFF0C2D4A),
      onPrimaryContainer: Color(0xFFBAE6FD),
      secondary: Color(0xFF60A5FA),
      onSecondary: primaryNavy,
      secondaryContainer: Color(0xFF1E3A5F),
      onSecondaryContainer: Color(0xFFBFDBFE),
      error: Color(0xFFF87171),
      onError: Color(0xFF7F1D1D),
      surface: surfaceDark,
      onSurface: Color(0xFFE2E8F0),
      surfaceContainerHighest: Color(0xFF1A3045),
      outline: Color(0xFF2A4A6B),
      outlineVariant: dividerDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaceDark,
      fontFamily: 'SF Pro Display',

      appBarTheme: AppBarTheme(
        backgroundColor: cardDark,
        foregroundColor: const Color(0xFFE2E8F0),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE2E8F0),
          letterSpacing: -0.3,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.3),
      ),

      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: dividerDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentCyan,
          foregroundColor: primaryNavy,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentCyan,
          side: const BorderSide(color: accentCyan, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A3045),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: dividerDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: dividerDark, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: accentCyan, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFF87171), width: 1.5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFF87171), width: 2),
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 14,
        ),
        prefixIconColor: const Color(0xFF64748B),
        suffixIconColor: const Color(0xFF64748B),
        floatingLabelStyle: const TextStyle(
          color: accentCyan,
          fontWeight: FontWeight.w600,
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: dividerDark,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1E3554),
        contentTextStyle:
            const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentCyan,
      ),
    );
  }

  // ─── Status Color Helpers ─────────────────────────────────────────────────

  /// Mengembalikan warna latar untuk label status tiket.
  static Color statusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return statusOpen.withValues(alpha: 0.12);
      case 'assign':
        return statusAssign.withValues(alpha: 0.12);
      case 'inprogress':
      case 'in progress':
        return statusInProgress.withValues(alpha: 0.12);
      case 'closed':
        return statusClosed.withValues(alpha: 0.12);
      default:
        return Colors.transparent;
    }
  }

  static Color statusForegroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return statusOpen;
      case 'assign':
        return statusAssign;
      case 'inprogress':
      case 'in progress':
        return statusInProgress;
      case 'closed':
        return statusClosed;
      default:
        return Colors.grey;
    }
  }

  static Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return priorityLow;
      case 'medium':
        return priorityMedium;
      case 'high':
        return priorityHigh;
      case 'critical':
        return priorityCritical;
      default:
        return Colors.grey;
    }
  }
}