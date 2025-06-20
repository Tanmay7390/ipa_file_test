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
