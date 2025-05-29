import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Shared drawer mixin - Fixed to properly constrain the mixin
mixin DrawerMixin<T extends StatefulWidget> on State<T> {
  // Remove TickerProviderStateMixin constraint from mixin declaration
  // This will be handled by the classes that use the mixin
  late AnimationController controller;
  late Animation<double> slideAnimation;
  bool drawerOpen = false;
  static const double drawerWidth = 280;

  void initDrawer() {
    // Cast to TickerProvider since we know the using classes will provide it
    controller = AnimationController(
      vsync: this as TickerProvider,
      duration: Duration(milliseconds: 300),
    );
    slideAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );
  }

  void toggleDrawer([bool? open]) {
    setState(() => drawerOpen = open ?? !drawerOpen);
    drawerOpen ? controller.forward() : controller.reverse();
  }

  void navigateToPage(String pageName) {
    toggleDrawer(false);
    final routes = {
      'Home': '/home',
      'Bookmarks': '/bookmarks',
      'Employee': '/employee',
      'Global Home': '/global-home',
    };
    context.go(routes[pageName]!);
  }

  void handlePan(
    DragUpdateDetails? update,
    DragEndDetails? end, {
    bool checkMainRoute = false,
  }) {
    if (checkMainRoute &&
        ![
          '/home',
          '/employee',
        ].contains(GoRouterState.of(context).matchedLocation)) {
      return;
    }

    if (update != null) {
      final delta = update.delta.dx / MediaQuery.of(context).size.width * 1.5;
      if ((!drawerOpen && update.delta.dx > 0) ||
          (drawerOpen && update.delta.dx < 0)) {
        controller.value = (controller.value + delta).clamp(0.0, 1.0);
      }
    }

    if (end != null) {
      final velocity = end.velocity.pixelsPerSecond.dx;
      toggleDrawer(
        velocity.abs() > 500 ? velocity > 0 : controller.value > 0.3,
      );
    }
  }

  String getCurrentPageName() {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 'Home';
    if (location.startsWith('/employee')) return 'Employee';
    if (location.startsWith('/bookmarks')) return 'Bookmarks';
    if (location.startsWith('/global-home')) return 'Global Home';
    return 'Home';
  }

  Widget buildDrawer() {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                      'https://i.imgur.com/QCNbOAo.png',
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'iJustine',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                    ),
                  ),
                  Text(
                    '@ijustine',
                    style: TextStyle(
                      fontSize: 15,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '3.1K ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                      Text(
                        'Following  ',
                        style: TextStyle(
                          fontSize: 15,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                      Text(
                        '1.8M ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                      Text(
                        'Followers',
                        style: TextStyle(
                          fontSize: 15,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  (CupertinoIcons.home, 'Home'),
                  (CupertinoIcons.search_circle_fill, 'Employee'),
                  (CupertinoIcons.bookmark, 'Bookmarks'),
                  (CupertinoIcons.globe, 'Global Home'),
                ].map((item) => drawerItem(item.$1, item.$2)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget drawerItem(IconData icon, String title) {
    bool isSelected = getCurrentPageName() == title;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: CupertinoButton(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        alignment: Alignment.centerLeft,
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? CupertinoColors.systemBlue.withOpacity(0.1) : null,
        onPressed: () => navigateToPage(title),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? CupertinoColors.systemBlue
                  : CupertinoColors.secondaryLabel,
              size: 24,
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? CupertinoColors.systemBlue
                    : CupertinoColors.label,
                fontSize: 17,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDrawerLayout(Widget child, {bool checkMainRoute = false}) {
    return AnimatedBuilder(
      animation: slideAnimation,
      builder: (context, _) {
        final slideOffset = slideAnimation.value * drawerWidth;
        return Stack(
          children: [
            Positioned(
              left: -drawerWidth + slideOffset,
              top: 0,
              bottom: 0,
              width: drawerWidth,
              child: buildDrawer(),
            ),
            Transform.translate(
              offset: Offset(slideOffset, 0),
              child: AbsorbPointer(
                absorbing: drawerOpen,
                child: Opacity(
                  opacity: 1.0 - (slideAnimation.value * 0.3),
                  child: GestureDetector(
                    onPanUpdate: (checkMainRoute && drawerOpen)
                        ? null
                        : (d) => handlePan(
                            d,
                            null,
                            checkMainRoute: checkMainRoute,
                          ),
                    onPanEnd: (checkMainRoute && drawerOpen)
                        ? null
                        : (d) => handlePan(
                            null,
                            d,
                            checkMainRoute: checkMainRoute,
                          ),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
            if (drawerOpen)
              Positioned(
                left: slideOffset,
                top: 0,
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () => toggleDrawer(false),
                  onPanUpdate: (d) =>
                      handlePan(d, null, checkMainRoute: checkMainRoute),
                  onPanEnd: (d) =>
                      handlePan(null, d, checkMainRoute: checkMainRoute),
                  child: Container(color: CupertinoColors.transparent),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class HomeScreenWithDrawer extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const HomeScreenWithDrawer({required this.navigationShell, super.key});
  @override
  State<HomeScreenWithDrawer> createState() => _HomeScreenWithDrawerState();
}

class _HomeScreenWithDrawerState extends State<HomeScreenWithDrawer>
    with TickerProviderStateMixin, DrawerMixin {
  @override
  void initState() {
    super.initState();
    initDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: buildDrawerLayout(
        ScaffoldWithNavBar(navigationShell: widget.navigationShell),
        checkMainRoute: true, // This parameter is set to true
      ),
    );
  }
}

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Column(
        children: [
          Expanded(child: navigationShell),
          CupertinoTabBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            items: const [
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
          ),
        ],
      ),
    );
  }
}

class StandaloneDrawerWrapper extends StatefulWidget {
  final Widget child;
  const StandaloneDrawerWrapper({required this.child, super.key});
  @override
  State<StandaloneDrawerWrapper> createState() =>
      _StandaloneDrawerWrapperState();
}

class _StandaloneDrawerWrapperState extends State<StandaloneDrawerWrapper>
    with TickerProviderStateMixin, DrawerMixin {
  @override
  void initState() {
    super.initState();
    initDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(child: buildDrawerLayout(widget.child));
  }
}
