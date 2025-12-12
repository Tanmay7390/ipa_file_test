import 'dart:async';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rajapsicon/theme_provider.dart';
import 'package:rajapsicon/drawer.dart';
import 'package:rajapsicon/components/page_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:rajapsicon/providers/home_data_provider.dart';
import 'package:rajapsicon/providers/user_data_provider.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  bool _isRefreshing = false;

  Future<void> _onRefresh() async {
    print('🎯🎯🎯 REFRESH CALLED! 🎯🎯🎯');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    log('🔄 [$timestamp] _onRefresh() ENTRY - _isRefreshing=$_isRefreshing');

    // Prevent multiple refresh calls during pull gesture
    if (_isRefreshing) {
      log('⚠️ [$timestamp] Already refreshing, BLOCKED duplicate call');
      return;
    }

    _isRefreshing = true;
    log('🔄 [$timestamp] _isRefreshing set to TRUE, proceeding with refresh');

    try {
      // Refresh home page data from API
      await ref.read(homePageDataProvider.notifier).refresh();

      log('🔄 [$timestamp] _onRefresh() COMPLETED successfully');

      // Keep the flag true for 500ms to prevent rapid successive calls
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      log('❌ [$timestamp] _onRefresh() ERROR: $e');
    } finally {
      _isRefreshing = false;
      log('🔄 [$timestamp] _isRefreshing set to FALSE');
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeDataAsync = ref.watch(homePageDataProvider);

    // Extract data immediately, or use null if still loading
    final homeData = homeDataAsync.valueOrNull;

    // Always show content immediately, data will update when loaded
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
      hideLargeTitle: true, // ← Changed to false like agenda tab
      hideSearch: true,
      showSearchField: false,
      isLoading: false,
      leading: _buildLeading(context, ref),
      trailing: _buildTrailing(context, ref),
      onRefresh: _onRefresh,
      sliverList: SliverList(
        delegate: SliverChildListDelegate([
          _buildParallaxCarousel(context, ref, homeData),
          // Stats Card
          const SizedBox(height: 20),
          _buildStatsCard(context, ref, homeData),

          // Featured Content
          const SizedBox(height: 20),
          // _buildFeaturedSessions(context, ref, homeData),

          // Bottom Spacing
          const SizedBox(height: 25),
        ]),
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

  Widget _buildParallaxCarousel(
    BuildContext context,
    WidgetRef ref,
    HomePageData? homeData,
  ) {
    // Always show carousel immediately, data updates when ready
    return SizedBox(height: 355, child: _ParallaxCarousel(homeData: homeData));
  }

  Widget _buildFeaturedSessions(
    BuildContext context,
    WidgetRef ref,
    HomePageData? homeData,
  ) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));
    final textColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.9);

    // Use API data only
    final sessions = homeData?.featuredSessions ?? [];
    final displaySessions = sessions
        .asMap()
        .entries
        .map(
          (entry) => {
            'title': entry.value.title,
            'organizer': entry.value.organizer ?? '',
            'time': entry.value.formattedDatetime,
            'icon': _getIconFromString(entry.value.icon),
            'colors': _getColorsForIndex(entry.key),
          },
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Sessions',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.2,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/company'),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: isDarkMode
                            ? const Color(0xFF34D399)
                            : const Color(0xFF21AA62),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SF Pro Display',
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      CupertinoIcons.chevron_right,
                      color: isDarkMode
                          ? const Color(0xFF34D399)
                          : const Color(0xFF21AA62),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.85),
            itemCount: displaySessions.length,
            padEnds: false,
            itemBuilder: (context, index) {
              final session = displaySessions[index];
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 24 : 8,
                  right: index == displaySessions.length - 1 ? 24 : 8,
                ),
                child: _buildSessionCard(
                  context,
                  ref,
                  session['title'] as String,
                  session['organizer'] as String,
                  session['time'] as String,
                  session['icon'] as IconData,
                  session['colors'] as List<int>,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getIconFromString(String icon) {
    switch (icon.toLowerCase()) {
      case 'calendar':
        return CupertinoIcons.calendar;
      case 'scissors':
        return CupertinoIcons.scissors;
      case 'bandage':
        return CupertinoIcons.bandage;
      case 'heart':
        return CupertinoIcons.heart_fill;
      default:
        return CupertinoIcons.calendar;
    }
  }

  List<int> _getColorsForIndex(int index) {
    final colorSets = [
      [0xFF065F46, 0xFF059669],
      [0xFF15803D, 0xFF16A34A],
      [0xFF4D7C0F, 0xFF65A30D],
    ];
    return colorSets[index % colorSets.length];
  }

  Widget _buildSessionCard(
    BuildContext context,
    WidgetRef ref,
    String title,
    String organizer,
    String time,
    IconData icon,
    List<int> gradientColors,
  ) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));

    final baseColor = Color(gradientColors[0]);
    final accentColor = isDarkMode ? Color(gradientColors[1]) : baseColor;
    final cardBg = isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white;
    final textColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.95)
        : const Color(0xFF1F2937);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? accentColor.withValues(alpha: 0.25)
                      : accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? accentColor.withValues(alpha: 0.2)
                      : accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.clock, color: accentColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.2,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                CupertinoIcons.person_circle,
                color: textColor.withValues(alpha: 0.6),
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  organizer,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    WidgetRef ref,
    HomePageData? homeData,
  ) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));

    // Use API data only
    final stats = homeData?.statistics;
    final attendees =
        stats?.display?.attendees ?? '${stats?.totalAttendees ?? 0}';
    final speakers = stats?.display?.speakers ?? '${stats?.totalSpeakers ?? 0}';
    final sessions = stats?.display?.sessions ?? '${stats?.totalSessions ?? 0}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF065F46) : const Color(0xFF21AA62),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(attendees, 'Attendees', CupertinoIcons.person_2),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildStatItem(speakers, 'Speakers', CupertinoIcons.mic),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildStatItem(sessions, 'Sessions', CupertinoIcons.square_list),
            ],
          ),
          // const SizedBox(height: 24),
          // GestureDetector(
          //   onTap: () {
          //     // Add enrollment action
          //   },
          //   child: Container(
          //     width: double.infinity,
          //     padding: const EdgeInsets.symmetric(vertical: 14),
          //     decoration: BoxDecoration(
          //       color: Colors.white,
          //       borderRadius: BorderRadius.circular(12),
          //     ),
          //     child: Center(
          //       child: Text(
          //         'Enroll Now',
          //         style: TextStyle(
          //           color: isDarkMode
          //               ? const Color(0xFF065F46)
          //               : const Color(0xFF21AA62),
          //           fontSize: 16,
          //           fontWeight: FontWeight.bold,
          //           fontFamily: 'SF Pro Display',
          //           letterSpacing: 0.3,
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String number, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          number,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'SF Pro Display',
            letterSpacing: 0.2,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            fontFamily: 'SF Pro Display',
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _ParallaxCarousel extends StatefulWidget {
  final HomePageData? homeData;

  const _ParallaxCarousel({this.homeData});

  @override
  State<_ParallaxCarousel> createState() => _ParallaxCarouselState();
}

class _ParallaxCarouselState extends State<_ParallaxCarousel> {
  late PageController _pageController;
  double _currentPage = 0;
  Timer? _autoScrollTimer;
  static const int _totalCards = 2;
  static const int _initialPage = 0; // Start at 0 for faster initial load

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 1.0,
      initialPage: _initialPage,
    );

    // Defer listener attachment to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        double lastPage = 0;
        _pageController.addListener(() {
          if (mounted) {
            final currentPage = _pageController.page ?? 0;
            // Only update if page changed significantly (reduces rebuilds)
            if ((currentPage - lastPage).abs() > 0.01) {
              setState(() {
                _currentPage = currentPage;
              });
              lastPage = currentPage;
            }
          }
        });

        // Start auto-scroll after initial render is complete
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _startAutoScroll();
          }
        });
      }
    });
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients && mounted) {
        final nextPage = (_pageController.page ?? 0) + 1;
        _pageController.animateToPage(
          nextPage.toInt(),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const PageScrollPhysics(), // Use platform-specific physics
            onPageChanged: (int page) {
              // Reset auto-scroll timer on manual interaction
              _autoScrollTimer?.cancel();
              _startAutoScroll();
            },
            itemBuilder: (context, index) {
              return _buildCarouselCard(context, index);
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildPageIndicator(),
      ],
    );
  }

  Widget _buildPageIndicator() {
    final currentIndex = _currentPage.round() % _totalCards;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalCards, (index) {
        double distance = (currentIndex - index).abs().toDouble();
        if (distance > _totalCards / 2) {
          distance = _totalCards - distance;
        }
        double opacity = (1 - (distance * 0.3)).clamp(0.3, 1.0);
        double size = index == currentIndex ? 8.0 : 6.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF23C061).withValues(alpha: opacity),
          ),
        );
      }),
    );
  }

  Widget _buildCarouselCard(BuildContext context, int index) {
    // Calculate parallax offset for content (moves opposite to scroll)
    double parallaxOffset = (_currentPage - index) * 60;

    return RepaintBoundary(
      child: Consumer(
        builder: (context, ref, child) {
          final systemBrightness = MediaQuery.of(context).platformBrightness;
          final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));

          return _buildCardContent(
            context,
            ref,
            isDarkMode,
            index,
            parallaxOffset,
          );
        },
      ),
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    WidgetRef ref,
    bool isDarkMode,
    int index,
    double parallaxOffset,
  ) {
    final cardIndex = index % _totalCards;
    switch (cardIndex) {
      case 0:
        return _buildLogoCard(context, isDarkMode, parallaxOffset);
      case 1:
        return _buildLogoCard2(context, isDarkMode, parallaxOffset);
      // case 2:
      //   return _buildDateLocationCard(context, isDarkMode, parallaxOffset);
      // case 3:
      //   return _buildVenueCard(context, isDarkMode, parallaxOffset);
      // case 4:
      //   return _buildFloorMapCard(context, isDarkMode, parallaxOffset);
      default:
        return Container();
    }
  }

  // Widget _buildLogoCard(
  //   BuildContext context,
  //   bool isDarkMode,
  //   double parallaxOffset,
  // ) {
  //   return Container(
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: isDarkMode
  //             ? [const Color(0xFF065F46), const Color(0xFF047857)]
  //             : [const Color(0xFF10B981), const Color(0xFF059669)],
  //       ),
  //     ),
  //     child: Stack(
  //       children: [
  //         // Decorative circles
  //         Positioned(
  //           top: -30,
  //           right: -30,
  //           child: Container(
  //             width: 120,
  //             height: 120,
  //             decoration: BoxDecoration(
  //               shape: BoxShape.circle,
  //               color: Colors.white.withValues(alpha: 0.1),
  //             ),
  //           ),
  //         ),
  //         Positioned(
  //           bottom: -20,
  //           left: -20,
  //           child: Container(
  //             width: 80,
  //             height: 80,
  //             decoration: BoxDecoration(
  //               shape: BoxShape.circle,
  //               color: Colors.white.withValues(alpha: 0.05),
  //             ),
  //           ),
  //         ),
  //         // Content with parallax
  //         Transform.translate(
  //           offset: Offset(parallaxOffset, 0),
  //           child: Center(
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Container(
  //                   width: 100,
  //                   height: 100,
  //                   child: Image.asset(
  //                     'assets/images/banner-logo.png',
  //                     fit: BoxFit.cover,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 Text(
  //                   widget.homeData?.event?.title ?? '',
  //                   style: const TextStyle(
  //                     color: Colors.white,
  //                     fontSize: 24,
  //                     fontWeight: FontWeight.bold,
  //                     fontFamily: 'SF Pro Display',
  //                     letterSpacing: 0.5,
  //                   ),
  //                 ),
  //                 if (widget.homeData?.event?.subTitle != null) ...[
  //                   const SizedBox(height: 8),
  //                   Padding(
  //                     padding: const EdgeInsets.symmetric(horizontal: 32),
  //                     child: Text(
  //                       widget.homeData!.event!.subTitle!,
  //                       textAlign: TextAlign.center,
  //                       style: TextStyle(
  //                         color: Colors.white.withValues(alpha: 0.9),
  //                         fontSize: 13,
  //                         fontWeight: FontWeight.w500,
  //                         fontFamily: 'SF Pro Display',
  //                         letterSpacing: 0.2,
  //                         height: 1.4,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildLogoCard(
    BuildContext context,
    bool isDarkMode,
    double parallaxOffset,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [const Color(0xFF065F46), const Color(0xFF047857)]
              : [const Color(0xFF10B981), const Color(0xFF059669)],
        ),
      ),
      child: Container(
        width: 100,
        // height: 100,
        child: Image.asset('assets/images/banner-image.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildLogoCard2(
    BuildContext context,
    bool isDarkMode,
    double parallaxOffset,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [const Color(0xFF065F46), const Color(0xFF047857)]
              : [const Color(0xFF10B981), const Color(0xFF059669)],
        ),
      ),
      child: Container(
        width: 100,
        // height: 100,
        child: Image.asset(
          'assets/images/banner-image-2.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildDateLocationCard(
    BuildContext context,
    bool isDarkMode,
    double parallaxOffset,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [const Color(0xFF15803D), const Color(0xFF16A34A)]
              : [const Color(0xFF22C55E), const Color(0xFF4ADE80)],
        ),
      ),
      child: Stack(
        children: [
          // Decorative elements
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Content with parallax
          Transform.translate(
            offset: Offset(parallaxOffset, 0),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.calendar,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Event Date',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (widget.homeData?.event?.formattedDates?.display !=
                      null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.homeData!.event!.formattedDates!.display,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF Pro Display',
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (widget.homeData?.event?.formattedDates?.year != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${widget.homeData!.event!.formattedDates!.year}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SF Pro Display',
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                  if (widget.homeData?.event?.venue?.address?.city != null) ...[
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.location,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.homeData!.event!.venue!.address!.city}, ${widget.homeData!.event!.venue!.address!.state}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'SF Pro Display',
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueCard(
    BuildContext context,
    bool isDarkMode,
    double parallaxOffset,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [const Color(0xFF4D7C0F), const Color(0xFF65A30D)]
              : [const Color(0xFF84CC16), const Color(0xFFA3E635)],
        ),
      ),
      child: Stack(
        children: [
          // Decorative pattern
          Positioned(
            bottom: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Icon(
              CupertinoIcons.building_2_fill,
              size: 80,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          // Content with parallax
          Transform.translate(
            offset: Offset(parallaxOffset, 0),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.map_pin_ellipse,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Venue',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (widget.homeData?.event?.venue?.name != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.homeData!.event!.venue!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF Pro Display',
                        letterSpacing: 0.3,
                        height: 1.2,
                      ),
                    ),
                  ],
                  if (widget.homeData?.event?.venue?.address?.street !=
                      null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${widget.homeData!.event!.venue!.address!.street}, ${widget.homeData!.event!.venue!.address!.city}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'SF Pro Display',
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorMapCard(
    BuildContext context,
    bool isDarkMode,
    double parallaxOffset,
  ) {
    return GestureDetector(
      onTap: () => context.go('/more'),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [const Color(0xFF047857), const Color(0xFF059669)]
                : [const Color(0xFF10B981), const Color(0xFF34D399)],
          ),
        ),
        child: Stack(
          children: [
            // Decorative grid pattern
            Positioned(
              top: 30,
              left: 30,
              child: Icon(
                CupertinoIcons.square_grid_3x2,
                size: 100,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            // Content with parallax
            Transform.translate(
              offset: Offset(parallaxOffset, 0),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.map_fill,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Floor Map',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF Pro Display',
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'View venue layout and find your way around',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'SF Pro Display',
                        letterSpacing: 0.2,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Go to Floor Map',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'SF Pro Display',
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            CupertinoIcons.arrow_right,
                            color: Colors.white,
                            size: 16,
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
    );
  }
}
