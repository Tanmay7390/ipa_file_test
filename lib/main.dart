import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:Wareozo/router.dart';
import 'package:Wareozo/theme_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Create a global container for router access
final globalContainer = ProviderContainer();

void main() {
  // Add error handling and logging
  print('🚀 Starting Wareozo app...');

  // Handle Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    print('🔥 Flutter Error: ${details.exception}');
    print('   Stack: ${details.stack}');
    FlutterError.presentError(details);
  };

  runApp(
    UncontrolledProviderScope(container: globalContainer, child: const MyApp()),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    print('📱 MyApp initialized');
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    print('📱 MyApp disposing');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('📱 App lifecycle changed to: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        print('   ✅ App resumed');
        break;
      case AppLifecycleState.inactive:
        print('   ⏸️ App inactive');
        break;
      case AppLifecycleState.paused:
        print('   ⏯️ App paused');
        break;
      case AppLifecycleState.detached:
        print('   🔌 App detached');
        break;
      case AppLifecycleState.hidden:
        print('   👻 App hidden');
        break;
    }
  }

  TextStyle _applyFontFamily(TextStyle style) {
    return style.copyWith(fontFamily: 'SF Pro Display', letterSpacing: 0.25);
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 Building MyApp');

    final brightness = ref.watch(themeProvider);
    final defaultTextTheme = const CupertinoTextThemeData();

    return CupertinoApp.router(
      debugShowCheckedModeBanner: false,
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
      builder: (context, child) {
        // Wrap the entire app with error handling
        return _AppErrorBoundary(child: child);
      },
    );
  }
}

/// Error boundary widget to catch and handle errors gracefully
class _AppErrorBoundary extends StatefulWidget {
  final Widget? child;

  const _AppErrorBoundary({this.child});

  @override
  State<_AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<_AppErrorBoundary> {
  bool hasError = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Error')),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 64,
                  color: CupertinoColors.systemRed,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  errorMessage ?? 'An unexpected error occurred',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 30),
                CupertinoButton.filled(
                  onPressed: () {
                    setState(() {
                      hasError = false;
                      errorMessage = null;
                    });
                  },
                  child: const Text('Try Again'),
                ),
                const SizedBox(height: 10),
                CupertinoButton(
                  onPressed: () {
                    SystemNavigator.pop();
                  },
                  child: const Text('Exit App'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child ?? const SizedBox.shrink();
  }

  /// Handle errors that occur in the widget tree
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Listen for errors in the widget tree
    FlutterError.onError = (FlutterErrorDetails details) {
      print('🔥 Widget Error: ${details.exception}');
      print('   Library: ${details.library}');
      print('   Context: ${details.context}');

      if (mounted) {
        setState(() {
          hasError = true;
          errorMessage = details.exception.toString();
        });
      }
    };
  }
}
