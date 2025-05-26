import 'package:flutter/cupertino.dart';

import '../tabs/home_tab.dart';
import '../tabs/employee_tab.dart';

// Custom route that uses CupertinoPageTransition
class CustomCupertinoPageRoute<T> extends PageRoute<T> {
  CustomCupertinoPageRoute({
    required this.builder,
    this.title,
    super.settings,
    this.maintainState = true,
    super.fullscreenDialog = false,
  });

  final WidgetBuilder builder;
  final String? title;

  @override
  final bool maintainState;

  @override
  bool get fullscreenDialog => false;

  @override
  bool get popGestureEnabled {
    // Fullscreen dialogs aren't dismissible by back swipe.
    return !fullscreenDialog && super.popGestureEnabled;
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get opaque => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Use CupertinoPageTransition for the animation
    return CupertinoPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: false,
      child: child,
    );
  }
}

class TabScaffoldExample extends StatefulWidget {
  const TabScaffoldExample({super.key});

  @override
  State<TabScaffoldExample> createState() => _TabScaffoldExampleState();
}

class _TabScaffoldExampleState extends State<TabScaffoldExample> {
  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.search_circle_fill),
            label: 'Employee',
          ),
        ],
        backgroundColor: CupertinoColors.systemBackground.withOpacity(0.8),
        activeColor: CupertinoColors.activeBlue,
        inactiveColor: CupertinoColors.inactiveGray,
        border: const Border(
          top: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5),
        ),
      ),
      tabBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return const HomeTab();
        } else {
          return const EmployeeTab();
        }
      },
    );
  }
}
