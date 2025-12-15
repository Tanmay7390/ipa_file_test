import 'package:flutter/cupertino.dart';
import 'package:axlmed/router.dart';
import 'package:axlmed/theme_provider.dart'; // Add this import
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axlmed/apis/core/dio_provider.dart';
import 'package:axlmed/providers/home_data_provider.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  TextStyle _applyFontFamily(TextStyle style) {
    return style.copyWith(fontFamily: 'SF Pro Display', letterSpacing: 0.25);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize token from storage on app startup
    ref.watch(tokenInitializerProvider);

    // Pre-load home page data on app startup
    ref.watch(homePageDataKeepaliveProvider);

    return CupertinoApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'Wareozo',
      builder: (context, child) {
        // Get system brightness from MediaQuery
        final systemBrightness = MediaQuery.of(context).platformBrightness;

        // Get the resolved brightness based on theme mode and system brightness
        final brightness = ref.watch(brightnessProvider(systemBrightness));
        final defaultTextTheme = const CupertinoTextThemeData();

        return CupertinoTheme(
          data: CupertinoThemeData(
            brightness: brightness,
            textTheme: CupertinoTextThemeData(
              textStyle: _applyFontFamily(defaultTextTheme.textStyle),
              actionTextStyle: _applyFontFamily(
                defaultTextTheme.actionTextStyle,
              ),
              tabLabelTextStyle: _applyFontFamily(
                defaultTextTheme.tabLabelTextStyle,
              ),
              navTitleTextStyle: _applyFontFamily(
                defaultTextTheme.navTitleTextStyle,
              ),
              navLargeTitleTextStyle: _applyFontFamily(
                defaultTextTheme.navLargeTitleTextStyle,
              ),
              pickerTextStyle: _applyFontFamily(
                defaultTextTheme.pickerTextStyle,
              ),
              dateTimePickerTextStyle: _applyFontFamily(
                defaultTextTheme.dateTimePickerTextStyle,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
