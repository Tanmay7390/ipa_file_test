import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axlmed/theme_provider.dart';
import '../components/page_scaffold.dart';
import '../pages/exhibitor_detail_page.dart';
import '../apis/providers/exhibitors_provider.dart';
import '../providers/home_data_provider.dart';
import '../services/auth_service.dart';

class ExhibitorsTab extends ConsumerStatefulWidget {
  const ExhibitorsTab({super.key});

  @override
  ConsumerState<ExhibitorsTab> createState() => _ExhibitorsTabState();
}

class _ExhibitorsTabState extends ConsumerState<ExhibitorsTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSearchField = false;
  bool _isGridView = false;
  List<Exhibitor> _filteredExhibitors = [];
  String? _selectedCategory;
  String? _eventId;
  String? _userId;
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Load exhibitors after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExhibitors();
    });
  }

  Future<void> _loadExhibitors() async {
    log('🔄 _loadExhibitors() called');

    // 1. Try getting IDs from Home Data Provider
    final homeData = ref.read(homePageDataProvider).valueOrNull;

    if (homeData != null) {
      _eventId = homeData.event?.id;

      final userData = homeData.user;
      if (userData is Map) {
        _userId = userData['_id'] ?? userData['id'];
      } else if (userData is String) {
        _userId = userData;
      }
    }

    // 2. Fallback: Try getting User ID from AuthService if missing
    if (_userId == null) {
      log('⚠️ User ID missing from HomeData, checking AuthService...');
      try {
        final userData = await AuthService.getUserData();
        if (userData != null) {
          _userId = userData['_id'] ?? userData['id'];
          log('👤 User ID found in AuthService: $_userId');
        }
      } catch (e) {
        log('❌ Error fetching user data from AuthService: $e');
      }
    }

    // 3. Fallback: Try getting Event ID from AuthService if missing
    if (_eventId == null) {
      log('⚠️ Event ID missing from HomeData, checking AuthService...');
      try {
        final homeMap = await AuthService.getHomePage();
        if (homeMap != null && homeMap['event'] != null) {
          _eventId = homeMap['event']['id'];
          log('📍 Event ID found in AuthService: $_eventId');
        }
      } catch (e) {
        log('❌ Error fetching home data from AuthService: $e');
      }
    }

    log('📝 Final IDs - Event: $_eventId, User: $_userId');

    if (_eventId != null && _userId != null) {
      log(
        '🚀 Triggering API call: loadExhibitors(userId: $_userId, eventId: $_eventId)',
      );
      // Load exhibitors for this event
      await ref
          .read(exhibitorsProvider.notifier)
          .loadExhibitors(userId: _userId!, eventId: _eventId!);
    } else {
      log('❌ Cannot load exhibitors: Missing eventId or userId');
      if (mounted) setState(() {}); // Trigger rebuild to show error UI
    }
  }

  List<String> _getAllCategories(List<Exhibitor> exhibitors) {
    final categories = exhibitors
        .map((e) => e.category ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  void _filterByCategory(String? category, List<Exhibitor> allExhibitors) {
    setState(() {
      _selectedCategory = category;
      _applyFilters(allExhibitors);
    });
  }

  void _applyFilters(List<Exhibitor> allExhibitors) {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredExhibitors = allExhibitors.where((exhibitor) {
        // Category filter
        if (_selectedCategory != null &&
            exhibitor.category != _selectedCategory) {
          return false;
        }

        // Search filter
        if (query.isNotEmpty) {
          return (exhibitor.companyName?.toLowerCase().contains(query) ??
                  false) ||
              (exhibitor.category?.toLowerCase().contains(query) ?? false) ||
              (exhibitor.booth?.toLowerCase().contains(query) ?? false) ||
              (exhibitor.about?.toLowerCase().contains(query) ?? false);
        }

        return true;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final exhibitorsAsync = ref.read(exhibitorsProvider);
    exhibitorsAsync.whenData((data) {
      _applyFilters(data);
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearchField = !_showSearchField;
      if (!_showSearchField) {
        _searchController.clear();
        final exhibitorsAsync = ref.read(exhibitorsProvider);
        exhibitorsAsync.whenData((data) {
          _applyFilters(data);
        });
      }
    });
  }

  Future<void> _onRefresh() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    log('🔄 [$timestamp] _onRefresh() ENTRY - _isRefreshing=$_isRefreshing');

    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      // Retry loading IDs if missing
      if (_eventId == null || _userId == null) {
        await _loadExhibitors();
      }

      if (_eventId != null && _userId != null) {
        await ref.read(exhibitorsProvider.notifier).refresh();

        if (mounted) {
          setState(() {
            _selectedCategory = null;
            _searchController.clear();
          });
        }
      }
    } catch (e) {
      log('❌ _onRefresh error: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  Color _getBadgeColor(String? badge) {
    if (badge == null) return const Color(0xFF34C759);

    switch (badge) {
      case 'Platinum Sponsor':
        return const Color(0xFF5856D6);
      case 'Gold Sponsor':
        return const Color(0xFFFFCC00);
      case 'Silver Sponsor':
        return const Color(0xFF8E8E93);
      default:
        return const Color(0xFF34C759);
    }
  }

  Widget _buildViewToggleButton(bool isDarkMode) {
    final activeColor = isDarkMode ? Color(0xFF007AFF) : Color(0xFF0387FE);

    return SizedBox(
      height: 32,
      child: CupertinoSlidingSegmentedControl<bool>(
        groupValue: _isGridView,
        backgroundColor: isDarkMode
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemGrey6,
        thumbColor: activeColor,
        padding: const EdgeInsets.all(2),
        onValueChanged: (value) {
          if (value != null) {
            setState(() {
              _isGridView = value;
            });
          }
        },
        children: {
          false: Container(
            width: 32,
            alignment: Alignment.center,
            child: Icon(
              CupertinoIcons.list_bullet,
              size: 18,
              color: !_isGridView
                  ? Colors.white
                  : (isDarkMode
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey2),
            ),
          ),
          true: Container(
            width: 32,
            alignment: Alignment.center,
            child: Icon(
              CupertinoIcons.square_grid_2x2,
              size: 18,
              color: _isGridView
                  ? Colors.white
                  : (isDarkMode
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey2),
            ),
          ),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));
    final cardBg = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    final exhibitorsAsync = ref.watch(exhibitorsProvider);

    // Listen to home data provider to load exhibitors when ready
    ref.listen<AsyncValue<HomePageData?>>(homePageDataProvider, (
      previous,
      next,
    ) {
      next.whenData((data) {
        if (data != null && (_eventId == null || _userId == null)) {
          log('🏠 Home data loaded, triggering exhibitors fetch...');
          _loadExhibitors();
        }
      });
    });

    // Listen to provider changes to update local filtered list
    ref.listen<AsyncValue<List<Exhibitor>>>(exhibitorsProvider, (
      previous,
      next,
    ) {
      next.whenData((data) {
        // Only update if the list changed or we are initializing
        if (previous?.valueOrNull != data) {
          log('📊 Exhibitors data updated: ${data.length} items');
          _applyFilters(data);
        }
      });
    });

    return CustomPageScaffold(
      scrollController: _scrollController,
      isLoading: exhibitorsAsync.isLoading,
      heading: 'Exhibitors',
      trailing: _buildViewToggleButton(isDarkMode),
      searchController: _searchController,
      showSearchField: _showSearchField,
      onSearchToggle: (_) => _toggleSearch(),
      onBottomRefresh: () => _onRefresh(),
      onRefresh: _onRefresh,
      sliverList: SliverList(
        delegate: SliverChildListDelegate([
          // Category Filter
          exhibitorsAsync.when(
            data: (data) => _buildCategoryFilter(isDarkMode, data),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Grid/List View Container
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child:
                (_eventId == null || _userId == null) &&
                    !exhibitorsAsync.isLoading
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.exclamationmark_circle,
                            size: 48,
                            color: CupertinoColors.systemGrey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Unable to load data',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Event or User ID missing',
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          SizedBox(height: 24),
                          CupertinoButton.filled(
                            child: Text('Retry'),
                            onPressed: _loadExhibitors,
                          ),
                        ],
                      ),
                    ),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    transitionBuilder: (child, animation) {
                      final offsetAnimation =
                          Tween<Offset>(
                            begin: const Offset(0.15, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOutCubic,
                            ),
                          );

                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: _isGridView
                        ? _buildGridContent(isDarkMode, cardBg, textColor)
                        : _buildListContent(isDarkMode, cardBg, textColor),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDarkMode, List<Exhibitor> allExhibitors) {
    final categories = _getAllCategories(allExhibitors);
    if (categories.isEmpty) return const SizedBox.shrink();

    final activeColor = isDarkMode ? Color(0xFF007AFF) : Color(0xFF0387FE);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // All Categories chip
            _buildCategoryChip(
              'All',
              _selectedCategory == null,
              () => _filterByCategory(null, allExhibitors),
              isDarkMode,
              activeColor,
            ),
            const SizedBox(width: 8),
            // Individual category chips
            ...categories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildCategoryChip(
                  category,
                  _selectedCategory == category,
                  () => _filterByCategory(category, allExhibitors),
                  isDarkMode,
                  activeColor,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    bool isDarkMode,
    Color activeColor,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDarkMode
                    ? CupertinoColors.systemGrey6.darkColor
                    : CupertinoColors.systemGrey6),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDarkMode ? CupertinoColors.white : CupertinoColors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildGridContent(bool isDarkMode, Color cardBg, Color textColor) {
    if (_filteredExhibitors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No exhibitors found',
            style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 16),
          ),
        ),
      );
    }

    final cols = MediaQuery.of(context).size.width > 600 ? 3 : 2;
    return GridView.builder(
      key: const ValueKey('grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredExhibitors.length,
      itemBuilder: (context, index) {
        final exhibitor = _filteredExhibitors[index];
        return _buildExhibitorGridCard(
          exhibitor,
          isDarkMode,
          cardBg,
          textColor,
        );
      },
    );
  }

  Widget _buildListContent(bool isDarkMode, Color cardBg, Color textColor) {
    if (_filteredExhibitors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No exhibitors found',
            style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      key: const ValueKey('list'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredExhibitors.length,
      itemBuilder: (context, index) {
        final exhibitor = _filteredExhibitors[index];
        final isLast = index == _filteredExhibitors.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
          child: _buildExhibitorListCard(
            exhibitor,
            isDarkMode,
            cardBg,
            textColor,
          ),
        );
      },
    );
  }

  Widget _buildExhibitorGridCard(
    Exhibitor exhibitor,
    bool isDarkMode,
    Color cardBg,
    Color textColor,
  ) {
    final activeColor = isDarkMode ? Color(0xFF007AFF) : Color(0xFF0387FE);

    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          CupertinoPageRoute(
            builder: (context) =>
                ExhibitorDetailPage(exhibitor: exhibitor.toJson()),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [const Color(0xFF1C1C1E), const Color(0xFF1A1A1C)]
                : [Colors.white, const Color(0xFFFAFAFA)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withValues(alpha: 0.4)
                  : _getBadgeColor(exhibitor.badge).withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company Logo with overlay gradient
                Stack(
                  children: [
                    Container(
                      // height: 120,
                      width: double.infinity,
                      child:
                          exhibitor.photo != null && exhibitor.photo!.isNotEmpty
                          ? Image.network(
                              exhibitor.photo!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholderImage(isDarkMode),
                            )
                          : _buildPlaceholderImage(isDarkMode),
                    ),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.15),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Company Name
                        Text(
                          exhibitor.companyName ?? 'Unknown',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Category with icon
                        if (exhibitor.category != null)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: activeColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  CupertinoIcons.cube_box_fill,
                                  size: 11,
                                  color: activeColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  exhibitor.category!,
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        const Spacer(),
                        // Booth Number with enhanced design
                        if (exhibitor.booth != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: activeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.location_solid,
                                  size: 13,
                                  color: activeColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  exhibitor.booth!,
                                  style: TextStyle(
                                    color: activeColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
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
            // Badge positioned at top right
            if (exhibitor.badge != null)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getBadgeColor(exhibitor.badge),
                        _getBadgeColor(exhibitor.badge).withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _getBadgeColor(
                          exhibitor.badge,
                        ).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    exhibitor.badge!.replaceAll(' Sponsor', ''),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExhibitorListCard(
    Exhibitor exhibitor,
    bool isDarkMode,
    Color cardBg,
    Color textColor,
  ) {
    final activeColor = isDarkMode ? Color(0xFF007AFF) : Color(0xFF0387FE);

    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          CupertinoPageRoute(
            builder: (context) =>
                ExhibitorDetailPage(exhibitor: exhibitor.toJson()),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isDarkMode
                ? [const Color(0xFF1C1C1E), const Color(0xFF1A1A1C)]
                : [Colors.white, const Color(0xFFFAFAFA)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withValues(alpha: 0.4)
                  : _getBadgeColor(exhibitor.badge).withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Row(
                children: [
                  // Company Logo with gradient overlay
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        child:
                            exhibitor.photo != null &&
                                exhibitor.photo!.isNotEmpty
                            ? Image.network(
                                exhibitor.photo!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholderImage(isDarkMode),
                              )
                            : _buildPlaceholderImage(isDarkMode),
                      ),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              isDarkMode
                                  ? const Color(
                                      0xFF1C1C1E,
                                    ).withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Company Name
                          Text(
                            exhibitor.companyName ?? 'Unknown',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Category with icon
                          if (exhibitor.category != null)
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: activeColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    CupertinoIcons.cube_box_fill,
                                    size: 12,
                                    color: activeColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    exhibitor.category!,
                                    style: TextStyle(
                                      color: textColor.withValues(alpha: 0.6),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 10),
                          // Booth Number
                          if (exhibitor.booth != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: activeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.location_solid,
                                    size: 13,
                                    color: activeColor,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    exhibitor.booth!,
                                    style: TextStyle(
                                      color: activeColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Chevron
                  Padding(
                    padding: const EdgeInsets.only(right: 18),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.chevron_right,
                        color: activeColor,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              // Badge positioned at top left
              if (exhibitor.badge != null)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getBadgeColor(exhibitor.badge),
                          _getBadgeColor(
                            exhibitor.badge,
                          ).withValues(alpha: 0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _getBadgeColor(
                            exhibitor.badge,
                          ).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      exhibitor.badge!.replaceAll(' Sponsor', ''),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(bool isDarkMode) {
    return Container(
      color: isDarkMode
          ? CupertinoColors.systemGrey6.darkColor
          : CupertinoColors.systemGrey6,
      child: Center(
        child: Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey),
      ),
    );
  }
}
