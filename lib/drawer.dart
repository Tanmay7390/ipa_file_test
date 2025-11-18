import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Add this import for kIsWeb
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test_22/theme_provider.dart'; // Add this import
import 'package:go_router/go_router.dart';
import 'package:flutter_test_22/services/auth_service.dart';

// Helper function to check if device is tablet
bool isTablet(BuildContext context) {
  return MediaQuery.of(context).size.shortestSide >= 600;
}

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
      'Agenda': '/agenda',
      'Speakers': '/speakers',
      'Attendees': '/attendees',
      'Exhibitors': '/exhibitors',
      'Bookmarks': '/bookmarks',
      'Settings': '/settings',
      'Notifications': '/notifications',
      'Profile': '/profile',
    };
    context.go(routes[pageName]!);
  }

  void handlePan(
    DragUpdateDetails? update,
    DragEndDetails? end, {
    bool checkMainRoute = false,
  }) {
    // Disable left swipe on tablets
    if (isTablet(context)) {
      return;
    }

    if (checkMainRoute &&
        ![
          '/home',
          '/agenda',
          '/speakers',
          '/attendees',
          '/exhibitors',
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
    if (location.startsWith('/agenda')) return 'Agenda';
    if (location.startsWith('/speakers')) return 'Speakers';
    if (location.startsWith('/attendees')) return 'Attendees';
    if (location.startsWith('/exhibitors')) return 'Exhibitors';
    if (location.startsWith('/bookmarks')) return 'Bookmarks';
    if (location.startsWith('/settings')) return 'Settings';
    if (location.startsWith('/notifications')) return 'Notifications';
    if (location.startsWith('/profile')) return 'Profile';
    return 'Home';
  }

  Widget buildDrawer() {
    return Consumer(
      builder: (context, ref, child) {
        final isDarkMode = ref.watch(isDarkModeProvider);

        return Container(
          decoration: BoxDecoration(
            color: CupertinoTheme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Color.fromRGBO(0, 0, 0, 0.3)
                    : Color.fromRGBO(0, 0, 0, 0.1),
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
                          color: CupertinoTheme.of(
                            context,
                          ).textTheme.textStyle.color,
                        ),
                      ),
                      Text(
                        '@ijustine',
                        style: TextStyle(
                          fontSize: 15,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
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
                              color: CupertinoTheme.of(
                                context,
                              ).textTheme.textStyle.color,
                            ),
                          ),
                          Text(
                            'Following  ',
                            style: TextStyle(
                              fontSize: 15,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                          Text(
                            '1.8M ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: CupertinoTheme.of(
                                context,
                              ).textTheme.textStyle.color,
                            ),
                          ),
                          Text(
                            'Followers',
                            style: TextStyle(
                              fontSize: 15,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
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
                      (CupertinoIcons.calendar, 'Agenda'),
                      (CupertinoIcons.mic_fill, 'Speakers'),
                      (CupertinoIcons.person_2_fill, 'Attendees'),
                      (CupertinoIcons.building_2_fill, 'Exhibitors'),
                      (CupertinoIcons.bookmark, 'Bookmarks'),
                      (CupertinoIcons.settings, 'Settings'),
                      (CupertinoIcons.bell, 'Notifications'),
                      (CupertinoIcons.person_circle, 'Profile'),
                    ].map((item) => drawerItem(item.$1, item.$2)).toList(),
                  ),
                ),
                // Dark mode toggle section
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: CupertinoColors.separator.resolveFrom(context),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isDarkMode
                                ? CupertinoIcons.moon_fill
                                : CupertinoIcons.sun_max_fill,
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                            size: 24,
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Dark Mode',
                            style: TextStyle(
                              color: CupertinoTheme.of(
                                context,
                              ).textTheme.textStyle.color,
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      CupertinoSwitch(
                        value: isDarkMode,
                        onChanged: (value) {
                          ref.read(themeProvider.notifier).toggleTheme();
                        },
                        activeTrackColor: CupertinoColors.systemBlue,
                      ),
                    ],
                  ),
                ),
                // Logout button
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: CupertinoColors.separator.resolveFrom(context),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: CupertinoColors.systemRed,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () async {
                      // Show confirmation dialog
                      final shouldLogout = await showCupertinoDialog<bool>(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: Text('Logout'),
                          content: Text('Are you sure you want to logout?'),
                          actions: [
                            CupertinoDialogAction(
                              child: Text('Cancel'),
                              onPressed: () => Navigator.of(context).pop(false),
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              child: Text('Logout'),
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true) {
                        await AuthService.logout();
                        if (context.mounted) {
                          context.go('/onboarding');
                        }
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.arrow_right_square,
                          color: CupertinoColors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Logout',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget drawerItem(IconData icon, String title) {
    return Consumer(
      builder: (context, ref, child) {
        bool isSelected = getCurrentPageName() == title;
        // final isDarkMode = ref.watch(isDarkModeProvider);

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: CupertinoButton(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            alignment: Alignment.centerLeft,
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? CupertinoColors.systemBlue
                      .resolveFrom(context)
                      .withOpacity(0.1)
                : null,
            onPressed: () => navigateToPage(title),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? CupertinoColors.systemBlue.resolveFrom(context)
                      : CupertinoColors.secondaryLabel.resolveFrom(context),
                  size: 24,
                ),
                SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? CupertinoColors.systemBlue.resolveFrom(context)
                        : CupertinoTheme.of(context).textTheme.textStyle.color,
                    fontSize: 17,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildDrawerLayout(Widget child, {bool checkMainRoute = false}) {
    final isTabletView = isTablet(context);

    return AnimatedBuilder(
      animation: slideAnimation,
      builder: (context, _) {
        final slideOffset = slideAnimation.value * drawerWidth;
        return Stack(
          children: [
            // Drawer sliding in from left (same for both mobile and tablet)
            Positioned(
              left: -drawerWidth + slideOffset,
              top: 0,
              bottom: 0,
              width: drawerWidth,
              child: buildDrawer(),
            ),
            // Main content - different behavior for tablet vs mobile
            Positioned(
              left: isTabletView ? slideOffset : 0,
              top: 0,
              right: 0,
              bottom: 0,
              child: Transform.translate(
                offset: Offset(isTabletView ? 0 : slideOffset, 0),
                child: Container(
                  width: isTabletView
                      ? MediaQuery.of(context).size.width - slideOffset
                      : MediaQuery.of(context).size.width,
                  child: AbsorbPointer(
                    absorbing: drawerOpen && !isTabletView,
                    child: Opacity(
                      // Full opacity on tablet, dimmed on mobile
                      opacity: isTabletView
                          ? 1.0
                          : (1.0 - (slideAnimation.value * 0.3)),
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
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Tap to close overlay (only for mobile)
            if (drawerOpen && !isTabletView)
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

// New widget for floating tab bar
class FloatingTabBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onMenuTap;

  const FloatingTabBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.onMenuTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final isDarkMode = ref.watch(isDarkModeProvider);

        return Positioned(
          top: MediaQuery.of(context).padding.top + 20,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? CupertinoColors.systemGrey6.darkColor
                    : CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? CupertinoColors.black.withOpacity(0.2)
                        : CupertinoColors.systemGrey.withOpacity(0.15),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Menu button for tablet
                  if (onMenuTap != null)
                    Container(
                      margin: EdgeInsets.only(right: 8),
                      child: CupertinoButton(
                        padding: EdgeInsets.only(
                          left: 12,
                          right: 8,
                          top: 8,
                          bottom: 8,
                        ),
                        minSize: 0,
                        onPressed: onMenuTap!,
                        child: Icon(
                          CupertinoIcons.sidebar_left,
                          size: 18,
                          color: CupertinoColors.systemBlue.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ),
                  _TabBarButton(
                    label: 'Home',
                    isSelected: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _TabBarButton(
                    label: 'Agenda',
                    isSelected: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  _TabBarButton(
                    label: 'Speakers',
                    isSelected: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                  _TabBarButton(
                    label: 'Attendees',
                    isSelected: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                  _TabBarButton(
                    label: 'Exhibitors',
                    isSelected: currentIndex == 4,
                    onTap: () => onTap(4),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TabBarButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabBarButton({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      onPressed: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? CupertinoColors.white
              : CupertinoColors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? CupertinoColors.systemBlue.resolveFrom(context)
                : CupertinoColors.label.resolveFrom(context),
          ),
        ),
      ),
    );
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
    // Auto-open drawer on web view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb) {
        // Changed from isWeb(context) to kIsWeb
        setState(() => drawerOpen = true);
        controller.value = 1.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTabletView = isTablet(context);

    return CupertinoPageScaffold(
      child: buildDrawerLayout(
        Stack(
          children: [
            ScaffoldWithNavBar(
              navigationShell: widget.navigationShell,
              showBottomNav: !isTabletView,
            ),
            // Show floating tab bar only on tablets
            if (isTabletView)
              FloatingTabBar(
                currentIndex: widget.navigationShell.currentIndex,
                onTap: (index) => widget.navigationShell.goBranch(
                  index,
                  initialLocation: index == widget.navigationShell.currentIndex,
                ),
                onMenuTap: () => toggleDrawer(),
              ),
          ],
        ),
        checkMainRoute: true,
      ),
    );
  }
}

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    this.showBottomNav = true,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final bool showBottomNav;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Column(
        children: [
          Expanded(child: navigationShell),
          // Only show bottom navigation if showBottomNav is true (mobile)
          if (showBottomNav)
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
                  icon: Icon(CupertinoIcons.calendar),
                  label: 'Agenda',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.mic_fill),
                  label: 'Speakers',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.person_2_fill),
                  label: 'Attendees',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.building_2_fill),
                  label: 'Exhibitors',
                ),
              ],
              backgroundColor: CupertinoTheme.of(
                context,
              ).scaffoldBackgroundColor.withOpacity(0.8),
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

  // Helper method to check if current route should show bottom navigation
  bool shouldShowBottomNavigation() {
    final location = GoRouterState.of(context).matchedLocation;
    return location.startsWith('/home') ||
           location.startsWith('/agenda') ||
           location.startsWith('/speakers') ||
           location.startsWith('/attendees') ||
           location.startsWith('/exhibitors');
  }

  @override
  Widget build(BuildContext context) {
    final isTabletView = isTablet(context);
    final showBottomNav = shouldShowBottomNavigation();

    return CupertinoPageScaffold(
      child: buildDrawerLayout(
        Stack(
          children: [
            widget.child,
            // Show floating tab bar only on tablets AND only on routes that would have bottom tabs
            if (isTabletView && showBottomNav)
              FloatingTabBar(
                currentIndex: 0, // Default to first tab for standalone pages
                onTap: (index) {
                  // Handle navigation for standalone pages
                  switch (index) {
                    case 0:
                      context.go('/home');
                      break;
                    case 1:
                      context.go('/agenda');
                      break;
                    case 2:
                      context.go('/speakers');
                      break;
                    case 3:
                      context.go('/attendees');
                      break;
                    case 4:
                      context.go('/exhibitors');
                      break;
                  }
                },
                onMenuTap: () => toggleDrawer(),
              ),
          ],
        ),
      ),
    );
  }
}
