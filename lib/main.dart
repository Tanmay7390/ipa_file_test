import 'package:flutter/cupertino.dart';
import 'package:flutter_test_22/router.dart';
import 'package:flutter_test_22/theme_provider.dart'; // Add this import
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  TextStyle _applyFontFamily(TextStyle style) {
    return style.copyWith(fontFamily: 'SF Pro Display', letterSpacing: 0.25);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = ref.watch(themeProvider);
    final defaultTextTheme = const CupertinoTextThemeData();

    return CupertinoApp.router(
      routerConfig: appRouter,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'Wareozo',
      theme: CupertinoThemeData(
        brightness: brightness,
        textTheme: CupertinoTextThemeData(
          textStyle: _applyFontFamily(defaultTextTheme.textStyle),
          actionTextStyle: _applyFontFamily(defaultTextTheme.actionTextStyle),
          tabLabelTextStyle: _applyFontFamily(
            defaultTextTheme.tabLabelTextStyle,
          ),
          navTitleTextStyle: _applyFontFamily(
            defaultTextTheme.navTitleTextStyle,
          ),
          navLargeTitleTextStyle: _applyFontFamily(
            defaultTextTheme.navLargeTitleTextStyle,
          ),
          pickerTextStyle: _applyFontFamily(defaultTextTheme.pickerTextStyle),
          dateTimePickerTextStyle: _applyFontFamily(
            defaultTextTheme.dateTimePickerTextStyle,
          ),
        ),
      ),
    );
  }
}
