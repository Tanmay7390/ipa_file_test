import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aesurg26/theme_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));
    final textPrimary = isDarkMode
        ? CupertinoColors.white.withValues(alpha: 0.9)
        : CupertinoColors.black.withValues(alpha: 0.9);
    final textSecondary = isDarkMode
        ? CupertinoColors.white.withValues(alpha: 0.6)
        : CupertinoColors.black.withValues(alpha: 0.6);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Profile'),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated icon container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFEC4899).withValues(alpha: 0.2),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.person_circle_fill,
                    size: 72,
                    color: isDarkMode
                        ? const Color(0xFFF472B6)
                        : const Color(0xFFEC4899),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF Pro Display',
                    color: textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    color: isDarkMode
                        ? const Color(0xFFF472B6)
                        : const Color(0xFFEC4899),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your personal profile page with account details and preferences is under development.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                    fontFamily: 'SF Pro Display',
                    height: 1.5,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFEC4899).withValues(alpha: 0.15),
                        const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.sparkles,
                        size: 16,
                        color: isDarkMode
                            ? const Color(0xFFF472B6)
                            : const Color(0xFFEC4899),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Stay tuned for updates',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? const Color(0xFFF472B6)
                              : const Color(0xFFEC4899),
                          fontFamily: 'SF Pro Display',
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
