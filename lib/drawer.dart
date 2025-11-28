import 'dart:ui' show ImageFilter;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Add this import for kIsWeb
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aesurg26/theme_provider.dart'; // Add this import
import 'package:go_router/go_router.dart';
import 'package:aesurg26/services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
      'Schedule': '/agenda',
      'Speakers': '/speakers',
      'Attendees': '/attendees',
      'Exhibitors': '/exhibitors',
      'More': '/more',
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
          '/more',
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
    if (location.startsWith('/agenda')) return 'Schedule';
    if (location.startsWith('/speakers')) return 'Speakers';
    if (location.startsWith('/attendees')) return 'Attendees';
    if (location.startsWith('/exhibitors')) return 'Exhibitors';
    if (location.startsWith('/more')) return 'More';
    if (location.startsWith('/settings')) return 'Settings';
    if (location.startsWith('/notifications')) return 'Notifications';
    if (location.startsWith('/profile')) return 'Profile';
    return 'Home';
  }

  Widget buildDrawer() {
    return Consumer(
      builder: (context, ref, child) {
        final systemBrightness = MediaQuery.of(context).platformBrightness;
        final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));

        return Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? CupertinoColors.systemFill
                : CupertinoTheme.of(context).scaffoldBackgroundColor,
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
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
                              'Hi, iJustine',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'SF Pro Display',
                                letterSpacing: 0.2,
                                color: CupertinoTheme.of(
                                  context,
                                ).textTheme.textStyle.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Logout button
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemRed.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            // Show confirmation dialog
                            final shouldLogout =
                                await showCupertinoDialog<bool>(
                                  context: context,
                                  builder: (context) => CupertinoAlertDialog(
                                    title: Text('Logout'),
                                    content: Text(
                                      'Are you sure you want to logout?',
                                    ),
                                    actions: [
                                      CupertinoDialogAction(
                                        child: Text('Cancel'),
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                      ),
                                      CupertinoDialogAction(
                                        isDestructiveAction: true,
                                        child: Text('Logout'),
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
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
                          child: Icon(
                            CupertinoIcons.arrow_right_square,
                            color: CupertinoColors.systemRed,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(vertical: 0, horizontal: 5),
                    children:
                        [
                              (
                                CupertinoIcons.house_fill,
                                CupertinoIcons.house,
                                'Home',
                              ),
                              (
                                CupertinoIcons.calendar_today,
                                CupertinoIcons.calendar,
                                'Schedule',
                              ),
                              (
                                CupertinoIcons.mic_fill,
                                CupertinoIcons.mic,
                                'Speakers',
                              ),
                              (
                                CupertinoIcons.person_2_fill,
                                CupertinoIcons.person_2,
                                'Attendees',
                              ),
                              (
                                CupertinoIcons.briefcase_fill,
                                CupertinoIcons.briefcase,
                                'Exhibitors',
                              ),
                              (
                                CupertinoIcons.ellipsis_circle_fill,
                                CupertinoIcons.ellipsis_circle,
                                'More',
                              ),
                              (
                                CupertinoIcons.gear_alt_fill,
                                CupertinoIcons.gear_alt,
                                'Settings',
                              ),
                              (
                                CupertinoIcons.bell_fill,
                                CupertinoIcons.bell,
                                'Notifications',
                              ),
                              (
                                CupertinoIcons.person_circle_fill,
                                CupertinoIcons.person_circle,
                                'Profile',
                              ),
                            ]
                            .map(
                              (item) => drawerItem(item.$1, item.$2, item.$3),
                            )
                            .toList(),
                  ),
                ),
                // Bottom section with logo and controls side by side
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: CupertinoColors.separator.resolveFrom(context),
                        width: 0.1,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Left column: Logo and social icons
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo
                          Image.asset(
                            isDarkMode
                                ? 'assets/images/logo-dark-no-bg.png'
                                : 'assets/images/logo-light-no-bg.png',
                            height: 110,
                          ),
                          SizedBox(height: 12),
                          // Social media icons row
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Facebook
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Color(0xFF1877F2),
                                  shape: BoxShape.circle,
                                ),
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    // TODO: Open Facebook link
                                  },
                                  child: FaIcon(
                                    FontAwesomeIcons.facebookF,
                                    color: CupertinoColors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              // Instagram
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Color(0xFFE4405F),
                                  shape: BoxShape.circle,
                                ),
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    // TODO: Open Instagram link
                                  },
                                  child: FaIcon(
                                    FontAwesomeIcons.instagram,
                                    color: CupertinoColors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              // LinkedIn
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Color(0xFF0A66C2),
                                  shape: BoxShape.circle,
                                ),
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    // TODO: Open LinkedIn link
                                  },
                                  child: FaIcon(
                                    FontAwesomeIcons.linkedinIn,
                                    color: CupertinoColors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Spacer(),
                      // Dark mode icon button on bottom right
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          ref.read(themeModeProvider.notifier).toggleTheme();
                        },
                        child: Icon(
                          isDarkMode
                              ? CupertinoIcons.moon_fill
                              : CupertinoIcons.sun_max_fill,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget drawerItem(IconData filledIcon, IconData outlinedIcon, String title) {
    return Consumer(
      builder: (context, ref, child) {
        bool isSelected = getCurrentPageName() == title;
        final systemBrightness = MediaQuery.of(context).platformBrightness;
        final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Container(
            decoration: isSelected
                ? BoxDecoration(
                    color: isDarkMode ? Color(0xFF23C061) : Color(0xFF21AA62),
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            child: CupertinoButton(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              alignment: Alignment.centerLeft,
              borderRadius: BorderRadius.circular(12),
              color: Colors.transparent,
              onPressed: () => navigateToPage(title),
              child: Row(
                children: [
                  Icon(
                    isSelected ? filledIcon : outlinedIcon,
                    color: isSelected
                        ? Color(0xFFFFFFFF)
                        : CupertinoColors.secondaryLabel.resolveFrom(context),
                    size: 24,
                  ),
                  SizedBox(width: 16),
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? Color(0xFFFFFFFF)
                          : CupertinoColors.secondaryLabel.resolveFrom(context),
                      fontSize: 17,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
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
        final systemBrightness = MediaQuery.of(context).platformBrightness;
        final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));

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
                        ? CupertinoColors.black.withValues(alpha: 0.2)
                        : CupertinoColors.systemGrey.withValues(alpha: 0.15),
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
                    label: 'Schedule',
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
                  _TabBarButton(
                    label: 'More',
                    isSelected: currentIndex == 5,
                    onTap: () => onTap(5),
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // If drawer is open, just close it and stay on current tab
        if (drawerOpen) {
          toggleDrawer(false);
          return;
        }

        // If drawer is closed and not on home tab, navigate to home tab
        if (widget.navigationShell.currentIndex != 0) {
          widget.navigationShell.goBranch(0);
          return;
        }

        // If on home tab and drawer is closed, exit the app
        context.pop();
      },
      child: CupertinoPageScaffold(
        resizeToAvoidBottomInset: false,
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
                    initialLocation:
                        index == widget.navigationShell.currentIndex,
                  ),
                  onMenuTap: () => toggleDrawer(),
                ),
            ],
          ),
          checkMainRoute: true,
        ),
      ),
    );
  }
}

class ScaffoldWithNavBar extends StatefulWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    this.showBottomNav = true,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final bool showBottomNav;

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.value = 1.0;
  }

  @override
  void didUpdateWidget(ScaffoldWithNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      // Trigger fade animation
      _fadeController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define the tab bar height as a constant
    const double tabBarHeight = 55.0;

    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      child: Stack(
        children: [
          // Content fills entire screen and extends behind tab bar
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: MediaQuery.of(context).padding.copyWith(
                    bottom: widget.showBottomNav
                        ? MediaQuery.of(context).padding.bottom + tabBarHeight
                        : MediaQuery.of(context).padding.bottom,
                  ),
                ),
                child: widget.navigationShell,
              ),
            ),
          ),
          // Blurred tab bar positioned at bottom
          if (widget.showBottomNav)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          CupertinoTheme.of(context).brightness ==
                              Brightness.dark
                          ? const Color(0xFF1C1C1E).withValues(alpha: 0.75)
                          : CupertinoColors.systemBackground.withValues(
                              alpha: 0.80,
                            ),
                      border: Border(
                        top: BorderSide(
                          color: CupertinoColors.systemGrey,
                          width: 0.2,
                        ),
                      ),
                    ),
                    child: Builder(
                      builder: (context) {
                        final isDark =
                            CupertinoTheme.of(context).brightness ==
                            Brightness.dark;
                        final currentIndex =
                            widget.navigationShell.currentIndex;

                        Widget buildLabel(String text, int index) {
                          final isActive = currentIndex == index;
                          return Text(
                            text,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.0,
                              color: isActive
                                  ? (isDark
                                        ? Color(0xFF23C061)
                                        : Color(0xFF21AA62))
                                  : CupertinoColors.systemGrey,
                            ),
                          );
                        }

                        return CupertinoTabBar(
                          height: 55,
                          iconSize: 28.0,
                          currentIndex: currentIndex,
                          onTap: (index) => widget.navigationShell.goBranch(
                            index,
                            initialLocation:
                                index == widget.navigationShell.currentIndex,
                          ),
                          items: [
                            BottomNavigationBarItem(
                              icon: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 4.0,
                                      bottom: 4.0,
                                    ),
                                    child: Icon(
                                      currentIndex == 0
                                          ? CupertinoIcons.house_fill
                                          : CupertinoIcons.house,
                                    ),
                                  ),
                                  buildLabel('Home', 0),
                                ],
                              ),
                            ),
                            BottomNavigationBarItem(
                              icon: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 4.0,
                                      bottom: 4.0,
                                    ),
                                    child: Icon(
                                      currentIndex == 1
                                          ? CupertinoIcons.calendar_today
                                          : CupertinoIcons.calendar,
                                    ),
                                  ),
                                  buildLabel('Schedule', 1),
                                ],
                              ),
                            ),
                            BottomNavigationBarItem(
                              icon: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 4.0,
                                      bottom: 4.0,
                                    ),
                                    child: Icon(
                                      currentIndex == 2
                                          ? CupertinoIcons.mic_fill
                                          : CupertinoIcons.mic,
                                    ),
                                  ),
                                  buildLabel('Speakers', 2),
                                ],
                              ),
                            ),
                            BottomNavigationBarItem(
                              icon: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 4.0,
                                      bottom: 4.0,
                                    ),
                                    child: Icon(
                                      currentIndex == 3
                                          ? CupertinoIcons.person_2_fill
                                          : CupertinoIcons.person_2,
                                    ),
                                  ),
                                  buildLabel('Attendees', 3),
                                ],
                              ),
                            ),
                            BottomNavigationBarItem(
                              icon: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 4.0,
                                      bottom: 4.0,
                                    ),
                                    child: Icon(
                                      currentIndex == 4
                                          ? CupertinoIcons.briefcase_fill
                                          : CupertinoIcons.briefcase,
                                    ),
                                  ),
                                  buildLabel('Exhibitors', 4),
                                ],
                              ),
                            ),
                            BottomNavigationBarItem(
                              icon: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 4.0,
                                      bottom: 4.0,
                                    ),
                                    child: Icon(
                                      currentIndex == 5
                                          ? CupertinoIcons.ellipsis_circle_fill
                                          : CupertinoIcons.ellipsis_circle,
                                    ),
                                  ),
                                  buildLabel('More', 5),
                                ],
                              ),
                            ),
                          ],
                          backgroundColor: Colors.transparent,
                          activeColor: isDark
                              ? Color(0xFF23C061)
                              : Color(0xFF21AA62),
                          inactiveColor: CupertinoColors.systemGrey,
                          border: null,
                        );
                      },
                    ),
                  ),
                ),
              ),
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
        location.startsWith('/exhibitors') ||
        location.startsWith('/more');
  }

  @override
  Widget build(BuildContext context) {
    final isTabletView = isTablet(context);
    final showBottomNav = shouldShowBottomNavigation();
    final location = GoRouterState.of(context).matchedLocation;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // If drawer is open, just close it and don't do anything else
        if (drawerOpen) {
          toggleDrawer(false);
          return;
        }

        // If drawer is closed, handle navigation based on current route
        // Check if we're on a detail page (settings, profile, notifications)
        if (location == '/settings' ||
            location == '/notifications' ||
            location == '/profile') {
          // Navigate back to home with reverse animation
          context.go('/home', extra: {'fromDetail': true});
          return;
        }

        // If on a main route, try to pop or exit
        if (Navigator.canPop(context)) {
          context.pop();
        }
      },
      child: CupertinoPageScaffold(
        resizeToAvoidBottomInset: false,
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
                      case 5:
                        context.go('/more');
                        break;
                    }
                  },
                  onMenuTap: () => toggleDrawer(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
