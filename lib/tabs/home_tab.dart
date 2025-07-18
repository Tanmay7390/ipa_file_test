import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme_provider.dart';
import '../Inventory/inventory_form.dart';
import 'package:Wareozo/drawer.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with logo and briefcase icon
                _buildHeader(colors, context),
                const SizedBox(height: 20),

                // Hero card
                _buildHeroCard(colors),
                const SizedBox(height: 30),

                // Explore section
                _buildExploreSection(colors, context),
                const SizedBox(height: 30),

                // Quick Actions section
                _buildQuickActionsSection(colors, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(WareozeColorScheme colors, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Menu icon button - now functional
        GestureDetector(
          onTap: () {
            // Open drawer using the static method from DrawerMixin
            DrawerMixin.openDrawerFromContext(context);
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              CupertinoIcons.line_horizontal_3,
              color: colors.textPrimary,
              size: 20,
            ),
          ),
        ),

        // Logo
        Row(
          children: [
            Container(
              height: 80,
              child: Center(
                child: Image.asset(
                  'assets/logos/wareozo-half-black.png',
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),

        // Briefcase icon
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            context.push('/business-profile');
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              CupertinoIcons.briefcase,
              color: colors.textPrimary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(WareozeColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GROW\nYOUR\nBUSINESS',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'make your way to grow your business',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'SEE MORE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'www.wareozo.com',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  CupertinoIcons.device_phone_portrait,
                  size: 40,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreSection(WareozeColorScheme colors, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate responsive sizing
            double itemWidth =
                (constraints.maxWidth - 48) / 4; // 48 = 3 gaps * 16
            double iconSize = itemWidth * 0.4; // 40% of item width
            double containerSize = iconSize + 20; // Add padding

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85, // Adjust height ratio
              children: [
                _buildExploreItem(
                  colors,
                  context,
                  CupertinoIcons.person_2,
                  'Employee',
                  containerSize,
                  iconSize,
                  '/employee',
                ),
                _buildExploreItem(
                  colors,
                  context,
                  CupertinoIcons.calendar,
                  'Attendance',
                  containerSize,
                  iconSize,
                  null, // Coming soon
                ),
                _buildExploreItem(
                  colors,
                  context,
                  CupertinoIcons.doc_text,
                  'Credit Note',
                  containerSize,
                  iconSize,
                  null, // Coming soon
                ),
                _buildExploreItem(
                  colors,
                  context,
                  CupertinoIcons.cube_box,
                  'Inventory',
                  containerSize,
                  iconSize,
                  '/inventory-list',
                ),
                _buildExploreItem(
                  colors,
                  context,
                  CupertinoIcons.cart,
                  'Purchases',
                  containerSize,
                  iconSize,
                  '/purchases',
                ),
                _buildExploreItem(
                  colors,
                  context,
                  CupertinoIcons.chart_bar,
                  'Sales',
                  containerSize,
                  iconSize,
                  '/sales',
                ),

                _buildExploreItem(
                  colors,
                  context,
                  Icons.currency_rupee,
                  'Payments',
                  containerSize,
                  iconSize,
                  '/payments',
                ),
                _buildExploreItem(
                  colors,
                  context,
                  CupertinoIcons.doc,
                  'Invoice',
                  containerSize,
                  iconSize,
                  '/invoice',
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildExploreItem(
    WareozeColorScheme colors,
    BuildContext context,
    IconData icon,
    String label,
    double containerSize,
    double iconSize,
    String? route,
  ) {
    return GestureDetector(
      onTap: () {
        if (route != null) {
          context.go(route);
        } else {
          _showComingSoonDialog(context, label);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: containerSize.clamp(50.0, 70.0), // Min 50, Max 70
            height: containerSize.clamp(50.0, 70.0),
            decoration: BoxDecoration(
              color: route != null
                  ? colors.primary.withOpacity(0.1)
                  : colors.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: route != null ? colors.primary : colors.textSecondary,
              size: iconSize.clamp(20.0, 28.0), // Min 20, Max 28
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: route != null
                    ? colors.textPrimary
                    : colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(
    WareozeColorScheme colors,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            double itemWidth = (constraints.maxWidth - 48) / 4;
            double buttonSize = (itemWidth * 0.8).clamp(50.0, 70.0);

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionItem(
                  colors,
                  context,
                  CupertinoIcons.plus_circle,
                  'Dashboard',
                  buttonSize,
                  '/dashboard',
                ),
                _buildQuickActionItem(
                  colors,
                  context,
                  CupertinoIcons.doc_text,
                  'Add\nExpense',
                  buttonSize,
                  null, // Coming soon
                ),
                _buildQuickActionItem(
                  colors,
                  context,
                  CupertinoIcons.doc_append,
                  'Create\nInvoice',
                  buttonSize,
                  '/invoice', // Navigate to invoice list
                ),
                _buildQuickActionItem(
                  colors,
                  context,
                  CupertinoIcons.cube_box_fill,
                  'Add\nProduct',
                  buttonSize,
                  '/inventory-form',
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(
    WareozeColorScheme colors,
    BuildContext context,
    IconData icon,
    String label,
    double buttonSize,
    String? route,
  ) {
    return Flexible(
      child: GestureDetector(
        onTap: () {
          if (route != null) {
            context.go(route);
          } else {
            _showComingSoonDialog(context, label.replaceAll('\n', ' '));
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: route != null ? colors.primary : colors.textSecondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: (buttonSize * 0.45).clamp(20.0, 32.0),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: route != null
                    ? colors.textPrimary
                    : colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Coming Soon'),
        content: Text('$feature feature will be available in a future update.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
