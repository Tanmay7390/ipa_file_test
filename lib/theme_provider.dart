import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Theme state notifier
class ThemeNotifier extends StateNotifier<Brightness> {
  ThemeNotifier() : super(Brightness.light);

  void toggleTheme() {
    state = state == Brightness.light ? Brightness.dark : Brightness.light;
  }

  void setTheme(Brightness brightness) {
    state = brightness;
  }

  bool get isDarkMode => state == Brightness.dark;
}

// Theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, Brightness>((ref) {
  return ThemeNotifier();
});

// Convenience provider for checking if dark mode is active
final isDarkModeProvider = Provider<bool>((ref) {
  final brightness = ref.watch(themeProvider);
  return brightness == Brightness.dark;
});

// Wareozo Color Theme
class WareozeColors {
  static const Color primary = Color(0xFF4c9656);
  static const Color primaryDark = Color(0xFF3d7a46);
  static const Color primaryLight = Color(0xFF6bb36f);

  // Light theme colors
  static const Color backgroundLight = Color(0xFFF9F9F9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1C1C1E);
  static const Color textSecondaryLight = Color(0xFF8E8E93);
  static const Color borderLight = Color(0xFFE5E5EA);

  // Dark theme colors
  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF8E8E93);
  static const Color borderDark = Color(0xFF38383A);

  // Status colors
  static const Color error = Color(0xFFFF3B30);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
}

// Color provider based on theme
final colorProvider = Provider<WareozeColorScheme>((ref) {
  final isDark = ref.watch(isDarkModeProvider);
  return isDark ? WareozeColorScheme.dark() : WareozeColorScheme.light();
});

class WareozeColorScheme {
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color error;
  final Color success;
  final Color warning;

  const WareozeColorScheme({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.error,
    required this.success,
    required this.warning,
  });

  factory WareozeColorScheme.light() {
    return const WareozeColorScheme(
      primary: WareozeColors.primary,
      primaryDark: WareozeColors.primaryDark,
      primaryLight: WareozeColors.primaryLight,
      background: WareozeColors.backgroundLight,
      surface: WareozeColors.surfaceLight,
      textPrimary: WareozeColors.textPrimaryLight,
      textSecondary: WareozeColors.textSecondaryLight,
      border: WareozeColors.borderLight,
      error: WareozeColors.error,
      success: WareozeColors.success,
      warning: WareozeColors.warning,
    );
  }

  factory WareozeColorScheme.dark() {
    return const WareozeColorScheme(
      primary: WareozeColors.primary,
      primaryDark: WareozeColors.primaryDark,
      primaryLight: WareozeColors.primaryLight,
      background: WareozeColors.backgroundDark,
      surface: WareozeColors.surfaceDark,
      textPrimary: WareozeColors.textPrimaryDark,
      textSecondary: WareozeColors.textSecondaryDark,
      border: WareozeColors.borderDark,
      error: WareozeColors.error,
      success: WareozeColors.success,
      warning: WareozeColors.warning,
    );
  }
}
