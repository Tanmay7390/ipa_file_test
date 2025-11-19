import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Theme mode enum
enum ThemeMode {
  light,
  dark,
  system,
}

// Theme state notifier
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system); // Default to system theme

  void toggleTheme() {
    // Cycle through light -> dark -> system
    state = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      ThemeMode.system => ThemeMode.light,
    };
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  void setLight() => state = ThemeMode.light;
  void setDark() => state = ThemeMode.dark;
  void setSystem() => state = ThemeMode.system;

  bool get isSystemMode => state == ThemeMode.system;
}

// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

// Brightness provider that resolves based on theme mode and system brightness
final brightnessProvider = Provider.family<Brightness, Brightness>((ref, systemBrightness) {
  final themeMode = ref.watch(themeModeProvider);

  return switch (themeMode) {
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
    ThemeMode.system => systemBrightness, // Use system brightness
  };
});

// Convenience provider for checking if dark mode is active
final isDarkModeProvider = Provider.family<bool, Brightness>((ref, systemBrightness) {
  final brightness = ref.watch(brightnessProvider(systemBrightness));
  return brightness == Brightness.dark;
});
