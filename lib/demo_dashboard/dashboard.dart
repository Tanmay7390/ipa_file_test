import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../theme_provider.dart';
import 'package:Wareozo/drawer.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  PageController? _carouselController;
  Timer? _carouselTimer;
  int _currentCarouselIndex = 0;
  final int _totalCarouselItems = 3;

  @override
  void initState() {
    super.initState();
    _initializeCarousel();
  }

  void _initializeCarousel() {
    // Start from a high number to simulate infinite scroll
    const int initialPage = 1000;
    _carouselController = PageController(
      initialPage: initialPage,
      viewportFraction: 0.85, // Show partial cards on sides
    );
    _currentCarouselIndex = initialPage;

    // Start auto-scroll after widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startCarouselAutoScroll();
      }
    });
  }

  void _startCarouselAutoScroll() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted ||
          _carouselController == null ||
          !_carouselController!.hasClients) {
        return;
      }

      _currentCarouselIndex++;
      _carouselController!.animateToPage(
        _currentCarouselIndex,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              // New Header with logo and business profile button (like home_tab)
              _buildNewHeader(colors, context),

              // Enhanced Welcome section with infinite carousel
              _buildEnhancedWelcomeCarousel(colors),

              // Core Business Operations (Outline Style - 4 columns)
              _buildOutlineSection(
                'Core Business',
                _getCoreBusinessItems(colors),
                colors,
              ),

              // Business Management Tools (Outline Style - 4 columns)
              _buildOutlineSection(
                'Business Management',
                _getBusinessManagementItems(colors),
                colors,
              ),

              // Reports & Analytics (Simple Box Style - 2x2 grid)
              _buildSimpleBoxSection(
                'Reports & Analytics',
                _getReportsItems(colors),
                colors,
              ),

              // Business Growth & Tools (Simple Box Style - 2x2 grid)
              _buildSimpleBoxSection(
                'Business Tools',
                _getBusinessToolsItems(colors),
                colors,
              ),

              // Enhanced Quick Actions
              _buildEnhancedQuickActions(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewHeader(WareozeColorScheme colors, BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Menu/Drawer button
          GestureDetector(
            onTap: () {
              // Open drawer using the static method from DrawerMixin
              DrawerMixin.openDrawerFromContext(context);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: colors.textPrimary.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                CupertinoIcons.line_horizontal_3,
                color: colors.primary,
                size: 24,
              ),
            ),
          ),

          // Logo
          Container(
            height: 50,
            child: Center(
              child: Image.asset(
                'assets/logos/wareozo-half-black.png',
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Business profile button
          GestureDetector(
            onTap: () {
              context.push('/business-profile');
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
                boxShadow: [
                  BoxShadow(
                    color: colors.textPrimary.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                CupertinoIcons.briefcase,
                color: colors.primary,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedWelcomeCarousel(WareozeColorScheme colors) {
    final carouselItems = [
      {
        'title': 'Welcome back!',
        'subtitle':
            'Manage your business efficiently with our comprehensive tools',
        'icon': Icons.waving_hand,
      },
      {
        'title': 'Track Performance',
        'subtitle': 'Monitor your business growth with detailed analytics',
        'icon': Icons.trending_up,
      },
      {
        'title': 'Stay Organized',
        'subtitle': 'Keep everything in one place with smart organization',
        'icon': Icons.folder,
      },
    ];

    if (_carouselController == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        height: 140,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 140,
      child: PageView.builder(
        controller: _carouselController!,
        onPageChanged: (index) {
          // Remove setState to avoid build-during-frame issues
          _currentCarouselIndex = index;
        },
        itemBuilder: (context, index) {
          final itemIndex = index % _totalCarouselItems;
          final item = carouselItems[itemIndex];

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primary,
                  colors.primary.withOpacity(0.8),
                  colors.primaryLight,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['subtitle'] as String,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Outline Section (4 columns for Core Business and Business Management)
  Widget _buildOutlineSection(
    String title,
    List<Map<String, dynamic>> items,
    WareozeColorScheme colors,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: items.length > 4 ? 4 : items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildOutlineBox(
                item['title'] as String,
                item['icon'] as IconData,
                colors.primary,
                item['route'] as String,
                colors,
              );
            },
          ),
        ],
      ),
    );
  }

  // Simple Box Section (2x2 grid for Reports & Business Tools)
  Widget _buildSimpleBoxSection(
    String title,
    List<Map<String, dynamic>> items,
    WareozeColorScheme colors,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (items.length > 4)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.7,
            ),
            itemCount: items.length > 4 ? 4 : items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildSimpleBox(
                item['title'] as String,
                item['icon'] as IconData,
                colors.primary,
                item['route'] as String,
                colors,
              );
            },
          ),
        ],
      ),
    );
  }

  // Outline box style (for Core Business and Business Management)
  Widget _buildOutlineBox(
    String title,
    IconData icon,
    Color iconColor,
    String route,
    WareozeColorScheme colors,
  ) {
    return GestureDetector(
      onTap: () => _handleNavigation(route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: colors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border.withOpacity(0.3), width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Simple box style with thin border (for Reports & Business Tools)
  Widget _buildSimpleBox(
    String title,
    IconData icon,
    Color iconColor,
    String route,
    WareozeColorScheme colors,
  ) {
    return GestureDetector(
      onTap: () => _handleNavigation(route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border.withOpacity(0.3), width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage & View',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: iconColor.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedQuickActions(WareozeColorScheme colors) {
    final quickActions = [
      {
        'title': 'Add Employee',
        'icon': Icons.person_add,
        'route': '/employee/add',
      },
      {
        'title': 'Add Customer',
        'icon': Icons.person_add_alt,
        'route': '/customersuppliers/add',
      },
      {
        'title': 'Create Invoice',
        'icon': Icons.receipt_long,
        'route': '/invoice/add',
      },
      {
        'title': 'Add Inventory',
        'icon': Icons.add_box,
        'route': '/inventory-list/add',
      },
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border.withOpacity(0.3), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.flash_on, color: colors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Actions',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: quickActions.map((action) {
              return _buildEnhancedQuickActionButton(
                action['title'] as String,
                action['icon'] as IconData,
                colors.primary,
                action['route'] as String,
                colors,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedQuickActionButton(
    String title,
    IconData icon,
    Color color,
    String route,
    WareozeColorScheme colors,
  ) {
    return GestureDetector(
      onTap: () => _handleNavigation(route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.15), color.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Data methods for different sections
  List<Map<String, dynamic>> _getCoreBusinessItems(WareozeColorScheme colors) {
    return [
      {'title': 'Home', 'icon': Icons.home_rounded, 'route': '/home'},
      {
        'title': 'Inventory',
        'icon': Icons.inventory_2_rounded,
        'route': '/inventory-list',
      },
      {
        'title': 'Customers',
        'icon': Icons.people_rounded,
        'route': '/customersuppliers',
      },
      {
        'title': 'Invoices',
        'icon': Icons.receipt_long_rounded,
        'route': '/invoice',
      },
    ];
  }

  List<Map<String, dynamic>> _getBusinessManagementItems(
    WareozeColorScheme colors,
  ) {
    return [
      {'title': 'Employees', 'icon': Icons.badge_rounded, 'route': '/employee'},
      {
        'title': 'Payments',
        'icon': Icons.payment_rounded,
        'route': '/payments',
      },
      {'title': 'Sales', 'icon': Icons.trending_up_rounded, 'route': '/sales'},
      {
        'title': 'Purchases',
        'icon': Icons.shopping_cart_rounded,
        'route': '/purchases',
      },
    ];
  }

  List<Map<String, dynamic>> _getReportsItems(WareozeColorScheme colors) {
    return [
      {
        'title': 'Sales Reports',
        'icon': Icons.bar_chart_rounded,
        'route': '/reports/sales',
      },
      {
        'title': 'Inventory Reports',
        'icon': Icons.inventory_rounded,
        'route': '/reports/inventory',
      },
      {
        'title': 'Financial Reports',
        'icon': Icons.pie_chart_rounded,
        'route': '/reports/financial',
      },
      {
        'title': 'Employee Reports',
        'icon': Icons.people_outline_rounded,
        'route': '/reports/employee',
      },
    ];
  }

  List<Map<String, dynamic>> _getBusinessToolsItems(WareozeColorScheme colors) {
    return [
      {
        'title': 'Categories',
        'icon': Icons.category_rounded,
        'route': '/categories',
      },
      {
        'title': 'Business Profile',
        'icon': Icons.business_center_rounded,
        'route': '/business-profile',
      },
      {
        'title': 'Settings',
        'icon': Icons.settings_rounded,
        'route': '/settings',
      },
      {
        'title': 'Help & Support',
        'icon': Icons.help_center_rounded,
        'route': '/help-support',
      },
    ];
  }

  void _handleNavigation(String route) {
    final existingRoutes = [
      '/home',
      '/inventory-list',
      '/customersuppliers',
      '/invoice',
      '/employee',
      '/payments',
      '/sales',
      '/purchases',
      '/categories',
      '/business-profile',
      '/employee/add',
      '/customersuppliers/add',
      '/invoice/add',
      '/inventory-list/add',
    ];

    if (existingRoutes.contains(route)) {
      context.go(route);
    } else {
      _showComingSoon();
    }
  }

  void _showComingSoon() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: const Text(
          'This feature is under development and will be available soon.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
