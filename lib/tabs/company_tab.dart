import 'dart:async';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/page_scaffold.dart';
import '../pages/company_detail_page.dart';
import '../apis/providers/company_provider.dart';
import '../models/company.dart';
import '../widgets/company_filter_sheet.dart';

class CompanyTab extends ConsumerStatefulWidget {
  const CompanyTab({super.key});

  @override
  ConsumerState<CompanyTab> createState() => _CompanyTabState();
}

class _CompanyTabState extends ConsumerState<CompanyTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSearchField = false;
  List<Company> _companies = [];
  Map<String, List<Company>> _groupedCompanies = {};
  Map<String, GlobalKey> _sectionKeys = {};
  String? _scrollingLetter;
  final GlobalKey _indexBarKey = GlobalKey();
  Timer? _debounceTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(companyListProvider.notifier).loadMore();
    }
  }

  void _groupCompanies() {
    // Sort companies by name
    _companies.sort((a, b) {
      final nameA = a.displayName.toLowerCase();
      final nameB = b.displayName.toLowerCase();
      return nameA.compareTo(nameB);
    });

    // Group by first letter of name
    _groupedCompanies.clear();
    _sectionKeys.clear();

    for (var company in _companies) {
      final name = company.displayName;
      if (name.isEmpty) continue;

      final firstLetter = name[0].toUpperCase();

      if (!_groupedCompanies.containsKey(firstLetter)) {
        _groupedCompanies[firstLetter] = [];
        _sectionKeys[firstLetter] = GlobalKey();
      }
      _groupedCompanies[firstLetter]!.add(company);
    }
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Debounce search by 500ms
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      ref.read(companyListProvider.notifier).search(query);
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearchField = !_showSearchField;
      if (!_showSearchField) {
        _debounceTimer?.cancel();
        _searchController.clear();
        ref.read(companyListProvider.notifier).search('');
      }
    });
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;

    _isRefreshing = true;

    try {
      await ref.read(companyListProvider.notifier).refresh();
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      _isRefreshing = false;
    }
  }

  void _showFilters() {
    showCupertinoModalPopup<Map<String, String>>(
      context: context,
      builder: (BuildContext context) => CompanyFilterSheet(
        currentFilters: ref.read(companyListProvider.notifier).currentFilters,
      ),
    ).then((filters) {
      if (filters != null) {
        ref.read(companyListProvider.notifier).applyFilters(filters);
      }
    });
  }

  String? _getLetterAtPosition(double localY) {
    final RenderBox? renderBox =
        _indexBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final barHeight = renderBox.size.height;
    final itemHeight = barHeight / 26;
    final index = (localY / itemHeight).floor().clamp(0, 25);
    final letter = String.fromCharCode(65 + index);

    return _groupedCompanies.containsKey(letter) ? letter : null;
  }

  void _handleIndexDragStart(DragStartDetails details) {
    final letter = _getLetterAtPosition(details.localPosition.dy);
    if (letter != null) {
      HapticFeedback.selectionClick();
      setState(() {
        _scrollingLetter = letter;
      });
      _scrollToSection(letter);
    }
  }

  void _handleIndexDragUpdate(DragUpdateDetails details) {
    final letter = _getLetterAtPosition(details.localPosition.dy);
    if (letter != null && letter != _scrollingLetter) {
      HapticFeedback.selectionClick();
      setState(() {
        _scrollingLetter = letter;
      });
      _scrollToSection(letter);
    }
  }

  void _handleIndexDragEnd(DragEndDetails details) {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _scrollingLetter = null;
        });
      }
    });
  }

  void _scrollToSection(String letter) {
    final key = _sectionKeys[letter];
    if (key?.currentContext != null) {
      try {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.0,
        );
      } catch (e) {
        // Ignore scroll errors
      }
    }
  }

  Widget _buildInitialsAvatar(String initials, bool isDark) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.systemGrey.resolveFrom(context)
            : CupertinoColors.systemGrey5.resolveFrom(context),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: isDark
                ? CupertinoColors.white
                : CupertinoColors.darkBackgroundGray,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    if (status == null || status.isEmpty || status == 'null') {
      return const SizedBox.shrink();
    }

    Color badgeColor;
    if (status.toUpperCase().contains('ACTIVE')) {
      badgeColor = CupertinoColors.systemGreen;
    } else if (status.toUpperCase().contains('PUBLIC')) {
      badgeColor = CupertinoColors.systemBlue;
    } else if (status.toUpperCase().contains('ACQUIRED')) {
      badgeColor = CupertinoColors.systemPurple;
    } else if (status.toUpperCase().contains('INACTIVE') ||
        status.toUpperCase().contains('SHUTDOWN')) {
      badgeColor = CupertinoColors.systemRed;
    } else {
      badgeColor = CupertinoColors.systemGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final companiesAsync = ref.watch(companyListProvider);

    // Listen to provider changes and update local state
    ref.listen<AsyncValue<List<Company>>>(companyListProvider, (
      previous,
      next,
    ) {
      next.when(
        data: (data) {
          setState(() {
            _companies = data;
            _groupCompanies();
          });
        },
        loading: () {
          // Keep showing loading
        },
        error: (error, stack) {
          // Show error message if needed
          log('Error loading companies: $error');
        },
      );
    });

    return Stack(
      children: [
        CustomPageScaffold(
          scrollController: _scrollController,
          isLoading: companiesAsync.isLoading && _companies.isEmpty,
          heading: 'Companies',
          searchController: _searchController,
          showSearchField: _showSearchField,
          onSearchToggle: (_) => _toggleSearch(),
          onRefresh: _onRefresh,
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showFilters,
            child: Icon(
              CupertinoIcons.slider_horizontal_3,
              size: 22,
              color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
            ),
          ),
          sliverList: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final entries = _groupedCompanies.entries.toList();
              final entry = entries[index];
              final letter = entry.key;
              final companies = entry.value;

              return Column(
                key: _sectionKeys[letter],
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    color: CupertinoColors.systemBackground.resolveFrom(
                      context,
                    ),
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  ),
                  // Companies list for this section
                  ClipRect(
                    child: Transform.translate(
                      offset: Offset(0, -0.5),
                      child: CupertinoListSection(
                        margin: EdgeInsets.zero,
                        additionalDividerMargin: 72,
                        backgroundColor: CupertinoColors.systemBackground,
                        topMargin: 0,
                        children: companies.map((company) {
                          return CupertinoListTile(
                            backgroundColor: CupertinoColors.systemBackground
                                .resolveFrom(context),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            leadingSize: 60,
                            leading:
                                (company.axlCompanyLogo != null &&
                                    company.axlCompanyLogo!.isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Image.network(
                                      company.axlCompanyLogo!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return _buildInitialsAvatar(
                                              company.initials,
                                              isDark,
                                            );
                                          },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return _buildInitialsAvatar(
                                              company.initials,
                                              isDark,
                                            );
                                          },
                                    ),
                                  )
                                : _buildInitialsAvatar(
                                    company.initials,
                                    isDark,
                                  ),
                            title: Text(
                              company.displayName,
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.25,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (company.displayType.isNotEmpty)
                                  Text(
                                    company.displayType,
                                    style: TextStyle(
                                      fontFamily: 'SF Pro Display',
                                      fontSize: 15,
                                      letterSpacing: 0.25,
                                    ),
                                  ),
                                if (company.displayStatus.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: _buildStatusBadge(
                                      company.displayStatus,
                                    ),
                                  ),
                                if (company.displayLocation.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      company.displayLocation,
                                      style: TextStyle(
                                        fontFamily: 'SF Pro Display',
                                        fontSize: 13,
                                        letterSpacing: 0.25,
                                        color: CupertinoColors.tertiaryLabel
                                            .resolveFrom(context),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: const CupertinoListTileChevron(),
                            ),
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).push(
                                CupertinoPageRoute(
                                  builder: (context) =>
                                      CompanyDetailPage(companyId: company.id),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              );
            }, childCount: _groupedCompanies.length),
          ),
        ),
        // A-Z Index on the right
        Positioned(
          right: 2,
          top: 0,
          bottom: 0,
          child: Center(
            child: GestureDetector(
              key: _indexBarKey,
              onVerticalDragStart: _handleIndexDragStart,
              onVerticalDragUpdate: _handleIndexDragUpdate,
              onVerticalDragEnd: _handleIndexDragEnd,
              child: Container(
                width: 20,
                color: CupertinoColors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(26, (index) {
                    final letter = String.fromCharCode(65 + index);
                    final hasSection = _groupedCompanies.containsKey(letter);

                    return GestureDetector(
                      onTap: hasSection
                          ? () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _scrollingLetter = letter;
                              });
                              _scrollToSection(letter);
                              Future.delayed(
                                const Duration(milliseconds: 200),
                                () {
                                  if (mounted) {
                                    setState(() {
                                      _scrollingLetter = null;
                                    });
                                  }
                                },
                              );
                            }
                          : null,
                      child: Container(
                        height: 14,
                        alignment: Alignment.center,
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: hasSection
                                ? isDark
                                      ? Color(0xFF007AFF)
                                      : Color(0xFF0387FE)
                                : CupertinoColors.systemGrey3,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
        // Floating letter indicator
        if (_scrollingLetter != null)
          Positioned(
            right: 40,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                _scrollingLetter!,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemGrey.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
