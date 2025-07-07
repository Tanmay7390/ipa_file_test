import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Wareozo/theme_provider.dart';
import 'dart:async';
import 'dart:io' show Platform;

class ExitConfirmationUtils {
  /// Shows a professional exit confirmation dialog
  /// Returns true if user confirmed exit, false otherwise
  static Future<bool> showExitConfirmationDialog(BuildContext context) async {
    try {
      if (!context.mounted) {
        print('⚠️ Context not mounted when showing exit dialog');
        return false;
      }

      print('🔄 Showing exit confirmation dialog');

      final result = await showCupertinoDialog<bool>(
        context: context,
        barrierDismissible: false, // Prevent dismissing by tapping outside
        builder: (BuildContext context) => const _ExitConfirmationDialog(),
      );

      final shouldExit =
          result ?? false; // Default to false if dialog is dismissed
      print('   - User choice: ${shouldExit ? "Exit" : "Cancel"}');

      return shouldExit;
    } catch (e) {
      print('⚠️ Error showing exit confirmation dialog: $e');
      // If dialog fails to show, default to not exiting to be safe
      return false;
    }
  }

  /// Handle app exit with confirmation and robust error handling
  static Future<bool> handleAppExit(BuildContext context) async {
    try {
      if (!context.mounted) {
        print('⚠️ Context not mounted when handling app exit');
        return false;
      }

      print('🔄 Handling app exit request');

      final shouldExit = await showExitConfirmationDialog(context);

      if (shouldExit && context.mounted) {
        print('   - Proceeding with app exit');
        await _performSafeExit();
        return true;
      } else {
        print('   - App exit cancelled or context unmounted');
        return false;
      }
    } catch (e) {
      print('⚠️ Error in handleAppExit: $e');
      return false;
    }
  }

  /// Perform safe app exit with multiple fallback methods
  static Future<void> _performSafeExit() async {
    try {
      print('   - Adding delay for better UX');
      await Future.delayed(const Duration(milliseconds: 100));

      // Try native exit method first on Android
      if (Platform.isAndroid) {
        print('   - Attempting native exit method');
        try {
          // Import and use the native back handler service
          // await NativeBackHandlerService.exitApp();
          // For now, we'll use the standard method
          SystemNavigator.pop();
        } catch (e) {
          print('   - Native exit failed, trying alternatives: $e');
          await _alternativeExit();
        }
      } else {
        print('   - Attempting primary exit method: SystemNavigator.pop()');
        SystemNavigator.pop();

        // Add a small delay to see if the primary method worked
        await Future.delayed(const Duration(milliseconds: 500));

        // If we reach here, the primary method might not have worked
        print(
          '   - Primary exit method may not have worked, trying alternative',
        );
        await _alternativeExit();
      }
    } catch (e) {
      print('⚠️ Error in _performSafeExit: $e');
      await _alternativeExit();
    }
  }

  /// Alternative exit methods if primary fails
  static Future<void> _alternativeExit() async {
    try {
      print('   - Attempting alternative exit method: platform channel');
      await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    } catch (e) {
      print('⚠️ Alternative exit method also failed: $e');
      try {
        print(
          '   - Attempting final exit method: platform channel with different approach',
        );
        await SystemChannels.platform.invokeMethod('SystemNavigator.pop', true);
      } catch (e2) {
        print('⚠️ All exit methods failed: $e2');
        // At this point, we've tried all available methods
        // The system will handle the app lifecycle
      }
    }
  }
}

/// Professional exit confirmation dialog widget with error handling
class _ExitConfirmationDialog extends ConsumerWidget {
  const _ExitConfirmationDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final colors = ref.watch(colorProvider);

      return CupertinoAlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: CupertinoColors.systemOrange,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Exit App',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'Are you sure you want to exit the app?',
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              height: 1.3,
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => _safePopDialog(context, false),
            child: Text(
              'No',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => _safePopDialog(context, true),
            child: const Text(
              'Yes',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    } catch (e) {
      print('⚠️ Error building exit confirmation dialog: $e');
      // Return a fallback dialog if the themed one fails
      return _buildFallbackDialog(context);
    }
  }

  /// Safely pop the dialog with error handling
  void _safePopDialog(BuildContext context, bool result) {
    try {
      if (context.mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      print('⚠️ Error popping dialog: $e');
    }
  }

  /// Fallback dialog if the main one fails to build
  Widget _buildFallbackDialog(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Exit App'),
      content: const Text('Are you sure you want to exit the app?'),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => _safePopDialog(context, false),
          child: const Text('No'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => _safePopDialog(context, true),
          child: const Text('Yes'),
        ),
      ],
    );
  }
}
