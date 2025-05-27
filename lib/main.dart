import 'package:flutter/cupertino.dart';
import 'package:flutter_test_22/router.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  TextStyle _applyFontFamily(TextStyle style) {
    return style.copyWith(fontFamily: 'SF Pro Display', letterSpacing: 0.25);
  }

  @override
  Widget build(BuildContext context) {
    final defaultTextTheme = const CupertinoTextThemeData();
    return CupertinoApp.router(
      routerConfig: appRouter,
      title: 'Wareozo',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
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
