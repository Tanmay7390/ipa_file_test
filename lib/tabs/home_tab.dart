import 'dart:async';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axlmed/theme_provider.dart';
import 'package:axlmed/drawer.dart';
import 'package:axlmed/components/page_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:axlmed/providers/home_data_provider.dart';
import 'package:axlmed/providers/user_data_provider.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  bool _isRefreshing = false;

  // Static content data for each category
  final List<Map<String, dynamic>> _vcContent = [
    {
      'title': 'Series B Funding Round Closes at \$50M',
      'description':
          'Healthcare startup secures major investment for expansion',
      'date': 'Dec 12, 2024',
      'tag': 'Funding',
    },
    {
      'title': 'New VC Fund Targets Digital Health',
      'description': 'Leading investors launch \$200M healthcare-focused fund',
      'date': 'Dec 10, 2024',
      'tag': 'Investment',
    },
  ];

  final List<Map<String, dynamic>> _maContent = [
    {
      'title': 'Major Pharma Acquires Biotech Firm',
      'description': 'Deal valued at \$3.2B expands oncology portfolio',
      'date': 'Dec 11, 2024',
      'tag': 'Acquisition',
    },
    {
      'title': 'Hospital Systems Announce Merger',
      'description': 'Combined entity to serve 5M+ patients annually',
      'date': 'Dec 9, 2024',
      'tag': 'Merger',
    },
  ];

  final List<Map<String, dynamic>> _drugsContent = [
    {
      'title': 'FDA Approves New Cancer Treatment',
      'description': 'Breakthrough therapy shows 40% improvement in outcomes',
      'date': 'Dec 12, 2024',
      'tag': 'Approval',
    },
    {
      'title': 'Phase 3 Trial Results Published',
      'description': 'Novel diabetes drug exceeds efficacy endpoints',
      'date': 'Dec 8, 2024',
      'tag': 'Clinical Trial',
    },
  ];

  final List<Map<String, dynamic>> _devicesContent = [
    {
      'title': 'AI-Powered Diagnostic Device Launched',
      'description': 'New imaging system reduces diagnosis time by 60%',
      'date': 'Dec 11, 2024',
      'tag': 'Launch',
    },
    {
      'title': 'Wearable Health Monitor Gets CE Mark',
      'description': 'Continuous glucose monitoring for diabetes management',
      'date': 'Dec 7, 2024',
      'tag': 'Regulatory',
    },
  ];

  final List<Map<String, dynamic>> _dxContent = [
    {
      'title': 'Liquid Biopsy Test Gains Traction',
      'description': 'Non-invasive cancer detection now available nationwide',
      'date': 'Dec 10, 2024',
      'tag': 'Diagnostics',
    },
    {
      'title': 'Point-of-Care Testing Revolution',
      'description': 'Rapid testing solutions transform patient care delivery',
      'date': 'Dec 6, 2024',
      'tag': 'Innovation',
    },
  ];

  Future<void> _onRefresh() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    log('🔄 [$timestamp] _onRefresh() ENTRY - _isRefreshing=$_isRefreshing');

    if (_isRefreshing) {
      log('⚠️ [$timestamp] Already refreshing, BLOCKED duplicate call');
      return;
    }

    _isRefreshing = true;

    try {
      await ref.read(homePageDataProvider.notifier).refresh();
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      log('❌ [$timestamp] _onRefresh() ERROR: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeDataAsync = ref.watch(homePageDataProvider);
    final homeData = homeDataAsync.valueOrNull;

    return _buildHomeContent(context, ref, homeData);
  }

  Widget _buildHomeContent(
    BuildContext context,
    WidgetRef ref,
    HomePageData? homeData,
  ) {
    final eventTitle = homeData?.event?.title ?? 'Home';

    return CustomPageScaffold(
      heading: eventTitle,
      hideLargeTitle: true,
      hideSearch: true,
      showSearchField: false,
      isLoading: false,
      leading: _buildLeading(context, ref),
      trailing: _buildTrailing(context, ref),
      onRefresh: _onRefresh,
      sliverList: SliverList(
        delegate: SliverChildListDelegate([
          const SizedBox(height: 24),
          // Hero Banner
          _buildHeroBanner(context, ref),

          const SizedBox(height: 24),

          // VC Section
          _buildSection(
            context,
            ref,
            title: 'VC',
            subtitle: 'Venture Capital & Funding',
            icon: CupertinoIcons.money_dollar_circle,
            color: const Color(0xFF6366F1),
            items: _vcContent,
          ),

          const SizedBox(height: 24),

          // M&A Section
          _buildSection(
            context,
            ref,
            title: 'M&A',
            subtitle: 'Mergers & Acquisitions',
            icon: CupertinoIcons.arrow_right_arrow_left,
            color: const Color(0xFF8B5CF6),
            items: _maContent,
          ),

          const SizedBox(height: 24),

          // Drugs Section
          _buildSection(
            context,
            ref,
            title: 'Drugs',
            subtitle: 'Pharmaceuticals & Treatments',
            icon: CupertinoIcons.capsule,
            color: const Color(0xFF10B981),
            items: _drugsContent,
          ),

          const SizedBox(height: 24),

          // Devices Section
          _buildSection(
            context,
            ref,
            title: 'Devices',
            subtitle: 'Medical Devices & Equipment',
            icon: CupertinoIcons.device_phone_portrait,
            color: const Color(0xFFF59E0B),
            items: _devicesContent,
          ),

          const SizedBox(height: 24),

          // DX Section
          _buildSection(
            context,
            ref,
            title: 'DX',
            subtitle: 'Diagnostics & Testing',
            icon: CupertinoIcons.lab_flask,
            color: const Color(0xFFEF4444),
            items: _dxContent,
          ),

          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, WidgetRef ref) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFF3B82F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.bolt_fill,
                      color: Colors.yellow[300],
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Latest Updates',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Healthcare Industry Insights',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Stay updated with the latest news in VC funding, M&A deals, drug approvals, medical devices, and diagnostics.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatPill('152', 'Articles'),
              const SizedBox(width: 12),
              _buildStatPill('28', 'This Week'),
              const SizedBox(width: 12),
              _buildStatPill('5', 'Categories'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Map<String, dynamic>> items,
  }) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));
    final textColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDarkMode ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  // Navigate to full section
                },
                child: Row(
                  children: [
                    Text(
                      'See All',
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(CupertinoIcons.chevron_right, color: color, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Content Cards - Horizontal Scroll
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index == items.length - 1 ? 0 : 12,
                ),
                child: _buildContentCard(
                  context,
                  ref,
                  item: items[index],
                  color: color,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard(
    BuildContext context,
    WidgetRef ref, {
    required Map<String, dynamic> item,
    required Color color,
  }) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));

    final cardBg = isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white;
    final textColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.95)
        : const Color(0xFF1F2937);

    return GestureDetector(
      onTap: () {
        // Navigate to detail
      },
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.06),
          ),
          boxShadow: isDarkMode
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDarkMode ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item['tag'],
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              item['title'],
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Description
            Expanded(
              child: Text(
                item['description'],
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.7),
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Date
            Row(
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  color: textColor.withValues(alpha: 0.5),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  item['date'],
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context, WidgetRef ref) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));
    final iconColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.8);

    void toggleDrawer() {
      context.visitAncestorElements((element) {
        if (element.widget is HomeScreenWithDrawer ||
            element.widget is StandaloneDrawerWrapper) {
          final state = element as StatefulElement;
          (state.state as dynamic).toggleDrawer();
          return false;
        }
        return true;
      });
    }

    return Transform(
      transform: Matrix4.translationValues(-10, 0, 0),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: toggleDrawer,
        child: Icon(CupertinoIcons.sidebar_left, color: iconColor, size: 24),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context, WidgetRef ref) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));
    final iconColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.8);

    final userDataAsync = ref.watch(userDataProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 0),
          onPressed: () => context.go('/notifications'),
          child: Icon(CupertinoIcons.bell, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 0),
          onPressed: () => context.go('/profile'),
          child: userDataAsync.when(
            data: (userData) {
              final photo = userData?.photo ?? '';

              return Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                  color: CupertinoColors.systemGrey5,
                ),
                child: ClipOval(
                  child: photo.isNotEmpty
                      ? Image.network(
                          photo,
                          width: 35,
                          height: 35,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              CupertinoIcons.person_fill,
                              size: 20,
                              color: CupertinoColors.systemGrey,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CupertinoActivityIndicator(radius: 8),
                            );
                          },
                        )
                      : Icon(
                          CupertinoIcons.person_fill,
                          size: 20,
                          color: CupertinoColors.systemGrey,
                        ),
                ),
              );
            },
            loading: () => Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 1.5,
                ),
                color: CupertinoColors.systemGrey5,
              ),
              child: Center(child: CupertinoActivityIndicator(radius: 8)),
            ),
            error: (error, stack) => Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 1.5,
                ),
                color: CupertinoColors.systemGrey5,
              ),
              child: Icon(
                CupertinoIcons.person_fill,
                size: 20,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
