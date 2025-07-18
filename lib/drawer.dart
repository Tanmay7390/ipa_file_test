import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:Wareozo/theme_provider.dart';
import 'package:Wareozo/apis/providers/auth_provider.dart';
import 'package:Wareozo/apis/providers/business_commonprofile_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:Wareozo/components/exit_confirmation_utils.dart';

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

  static void openDrawerFromContext(BuildContext context) {
    final homeDrawerState = context
        .findAncestorStateOfType<_HomeScreenWithDrawerState>();
    if (homeDrawerState != null) {
      homeDrawerState.toggleDrawer(true);
      return;
    }

    final standaloneDrawerState = context
        .findAncestorStateOfType<_StandaloneDrawerWrapperState>();
    if (standaloneDrawerState != null) {
      standaloneDrawerState.toggleDrawer(true);
    }
  }

  void navigateToPage(String pageName) {
    toggleDrawer(false);
    final routes = {
      'Home': '/home',
      'Bookmarks': '/bookmarks',
      'Employee': '/employee',
      'Global Home': '/global-home',
      'Inventory': '/inventory-list',
      'Invoice': '/invoice',
      'Item Categories': '/categories',
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
          '/inventory-list',
          '/invoice',
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
    if (location.startsWith('/inventory-list')) return 'Inventory';
    if (location.startsWith('/invoice')) return 'Invoice';
    if (location.startsWith('/categories')) return 'Item Categories';
    return 'Home';
  }

  //  logout functionality
  void _handleLogout(WidgetRef ref) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              toggleDrawer(false);
              await ref.read(authProvider.notifier).signOut();

              // Add explicit navigation to onboarding after logout
              if (mounted) {
                context.go('/onboarding');
              }
            },
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget buildDrawer() {
    return Consumer(
      builder: (context, ref, child) {
        final colors = ref.watch(
          colorProvider,
        ); // Use color provider instead of theme

        return Container(
          decoration: BoxDecoration(
            color: colors.surface, // Use theme colors
            boxShadow: [
              BoxShadow(
                color: colors.textPrimary.withOpacity(0.1),
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
                      Builder(
                        builder: (context) {
                          final businessState = ref.watch(
                            businessProfileProvider,
                          );
                          final profile = businessState.profile;

                          // Handle loading state
                          if (businessState.isLoading) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: colors.primary,
                                  child: Icon(
                                    CupertinoIcons.building_2_fill,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Container(
                                  width: 120,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: colors.textSecondary.withOpacity(
                                      0.3,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Container(
                                  width: 80,
                                  height: 15,
                                  decoration: BoxDecoration(
                                    color: colors.textSecondary.withOpacity(
                                      0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            );
                          }

                          // Handle error state
                          if (businessState.error != null) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: colors.primary,
                                  child: Icon(
                                    CupertinoIcons.building_2_fill,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Company',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '@company',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            );
                          }

                          // Handle success state with profile data
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: profile?['logo'] != null
                                    ? NetworkImage(profile!['logo'])
                                    : null,
                                backgroundColor: colors.primary,
                                child: profile?['logo'] == null
                                    ? Text(
                                        profile?['legalName']
                                                ?.substring(0, 1)
                                                .toUpperCase() ??
                                            profile?['name']
                                                ?.substring(0, 1)
                                                .toUpperCase() ??
                                            'C',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              SizedBox(height: 12),
                              Text(
                                profile?['legalName'] ??
                                    profile?['name'] ??
                                    'Company',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              Text(
                                profile?['displayName'] ?? '@company',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: colors.textSecondary,
                                ),
                              ),
                              Text(
                                profile?['email'] ?? '@user',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          );
                        },
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
                      (CupertinoIcons.bag, 'Inventory'),
                      (CupertinoIcons.doc, 'Invoice'),
                      (CupertinoIcons.list_bullet, 'Item Categories'),
                    ].map((item) => drawerItem(item.$1, item.$2)).toList(),
                  ),
                ),
                // Dark mode toggle section
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: colors.border, width: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            ref.watch(isDarkModeProvider)
                                ? CupertinoIcons.moon_fill
                                : CupertinoIcons.sun_max_fill,
                            color: colors.textSecondary,
                            size: 24,
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Dark Mode',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      CupertinoSwitch(
                        value: ref.watch(isDarkModeProvider),
                        onChanged: (value) {
                          ref.read(themeProvider.notifier).toggleTheme();
                        },
                        activeTrackColor: colors.primary,
                      ),
                    ],
                  ),
                ),
                // Logout button section
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: colors.border, width: 0.5),
                    ),
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    onPressed: () => _handleLogout(ref),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.square_arrow_right,
                          color: colors.error,
                          size: 24,
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Logout',
                          style: TextStyle(
                            color: colors.error,
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
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
        final colors = ref.watch(colorProvider); // Use color provider

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: CupertinoButton(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            alignment: Alignment.centerLeft,
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? colors.primary.withOpacity(0.1) : null,
            onPressed: () => navigateToPage(title),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? colors.primary : colors.textSecondary,
                  size: 24,
                ),
                SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? colors.primary : colors.textPrimary,
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

// Simplified HomeScreenWithDrawer - PopScope handling moved to UniversalPageWrapper
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
        checkMainRoute: true,
      ),
    );
  }
}

class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  void _showBottomSheet(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey4.resolveFrom(context),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              // Browse title
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Browse',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              // Grid items
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // First row
                      Row(
                        children: [
                          Expanded(
                            child: _buildGridItem(
                              context,
                              colors,
                              CupertinoIcons.cube_box,
                              'Products',
                              () => context.go('/inventory-list'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildGridItem(
                              context,
                              colors,
                              CupertinoIcons.tag,
                              'Categories',
                              () {},
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildGridItem(
                              context,
                              colors,
                              CupertinoIcons.person,
                              'Suppliers',
                              () => context.go('/customersuppliers'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Second row
                      Row(
                        children: [
                          Expanded(
                            child: _buildGridItem(
                              context,
                              colors,
                              CupertinoIcons.square_stack,
                              'Stock',
                              () {},
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildGridItem(
                              context,
                              colors,
                              CupertinoIcons.cart,
                              'Orders',
                              () {},
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildGridItem(
                              context,
                              colors,
                              CupertinoIcons.chart_bar,
                              'Reports',
                              () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Wareozo section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'wareozo',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildListItem(
                              context,
                              colors,
                              CupertinoIcons.download_circle,
                              'employee',
                              () => context.go('/employee'),
                            ),
                            _buildListItem(
                              context,
                              colors,
                              CupertinoIcons.chart_bar_square,
                              'sales',
                              () {},
                            ),
                            _buildListItem(
                              context,
                              colors,
                              CupertinoIcons.gift,
                              'purchase',
                              () {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    WareozeColorScheme colors,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: colors.textPrimary),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context,
    WareozeColorScheme colors,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colors.textSecondary),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: colors.textPrimary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);

    return CupertinoPageScaffold(
      child: Column(
        children: [
          Expanded(child: navigationShell),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: colors.border, width: 0.5)),
            ),
            child: SafeArea(
              top: false,
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      context,
                      colors,
                      CupertinoIcons.home,
                      'Home',
                      '/home',
                      GoRouterState.of(
                        context,
                      ).matchedLocation.startsWith('/home'),
                      () => context.go('/home'),
                    ),
                    _buildNavItem(
                      context,
                      colors,
                      CupertinoIcons.cube_box,
                      'Items',
                      '/inventory-list',
                      GoRouterState.of(
                        context,
                      ).matchedLocation.startsWith('/inventory-list'),
                      () => context.go('/inventory-list'),
                    ),
                    // Middle arrow button
                    GestureDetector(
                      onTap: () => _showBottomSheet(context, ref),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          CupertinoIcons.chevron_up,
                          color: CupertinoColors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    _buildNavItem(
                      context,
                      colors,
                      CupertinoIcons.group,
                      'Parties',
                      '/customersuppliers',
                      GoRouterState.of(
                        context,
                      ).matchedLocation.startsWith('/customersuppliers'),
                      () => context.go('/customersuppliers'),
                    ),
                    _buildNavItem(
                      context,
                      colors,
                      CupertinoIcons.doc_text_search,
                      'Reports',
                      '', // No route for reports yet
                      false,
                      () => showCupertinoDialog<void>(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('Coming Soon'),
                          content: const Text(
                            'Reports feature is coming soon!',
                          ),
                          actions: [
                            CupertinoDialogAction(
                              isDefaultAction: true,
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    WareozeColorScheme colors,
    IconData icon,
    String label,
    String route, // Changed from int index to String route
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? colors.primary : colors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? colors.primary : colors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simplified StandaloneDrawerWrapper - PopScope handling moved to UniversalPageWrapper
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
