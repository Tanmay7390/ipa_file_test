import 'dart:async';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/page_scaffold.dart';
import '../pages/people_detail_page.dart';
import '../apis/providers/people_provider.dart';
import '../models/person.dart';
import '../widgets/people_filter_sheet.dart';

class PeopleTab extends ConsumerStatefulWidget {
  const PeopleTab({super.key});

  @override
  ConsumerState<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends ConsumerState<PeopleTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSearchField = false;
  List<Person> _people = [];
  Map<String, List<Person>> _groupedPeople = {};
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
      ref.read(peopleListProvider.notifier).loadMore();
    }
  }

  void _groupPeople() {
    // Sort people by name
    _people.sort((a, b) {
      final nameA = a.displayName.toLowerCase();
      final nameB = b.displayName.toLowerCase();
      return nameA.compareTo(nameB);
    });

    // Group by first letter of name
    _groupedPeople.clear();
    _sectionKeys.clear();

    for (var person in _people) {
      final name = person.displayName;
      if (name.isEmpty) continue;

      final firstLetter = name[0].toUpperCase();

      if (!_groupedPeople.containsKey(firstLetter)) {
        _groupedPeople[firstLetter] = [];
        _sectionKeys[firstLetter] = GlobalKey();
      }
      _groupedPeople[firstLetter]!.add(person);
    }
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Debounce search by 500ms
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      ref.read(peopleListProvider.notifier).search(query);
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearchField = !_showSearchField;
      if (!_showSearchField) {
        _debounceTimer?.cancel();
        _searchController.clear();
        ref.read(peopleListProvider.notifier).search('');
      }
    });
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;

    _isRefreshing = true;

    try {
      await ref.read(peopleListProvider.notifier).refresh();
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      _isRefreshing = false;
    }
  }

  void _showFilters() {
    showCupertinoModalPopup<Map<String, String>>(
      context: context,
      builder: (BuildContext context) => PeopleFilterSheet(
        currentFilters: ref.read(peopleListProvider.notifier).currentFilters,
      ),
    ).then((filters) {
      if (filters != null) {
        ref.read(peopleListProvider.notifier).applyFilters(filters);
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

    return _groupedPeople.containsKey(letter) ? letter : null;
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

  Widget _buildCompanyTypeBadges(Person person) {
    if (person.companyTypes == null || person.companyTypes!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: person.companyTypes!.map((type) {
          Color badgeColor;
          if (type.type.toUpperCase().contains('CEO')) {
            badgeColor = CupertinoColors.systemGreen;
          } else if (type.type.toUpperCase().contains('FOUNDED')) {
            badgeColor = CupertinoColors.systemPurple;
          } else {
            badgeColor = CupertinoColors.systemBlue;
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: badgeColor.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Text(
              '${type.count} ${type.type}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: badgeColor,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final peopleAsync = ref.watch(peopleListProvider);

    // Listen to provider changes and update local state
    ref.listen<AsyncValue<List<Person>>>(peopleListProvider, (previous, next) {
      next.when(
        data: (data) {
          setState(() {
            _people = data;
            _groupPeople();
          });
        },
        loading: () {
          // Keep showing loading
        },
        error: (error, stack) {
          // Show error message if needed
          log('Error loading people: $error');
        },
      );
    });

    return Stack(
      children: [
        CustomPageScaffold(
          scrollController: _scrollController,
          isLoading: peopleAsync.isLoading && _people.isEmpty,
          heading: 'People',
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
              final entries = _groupedPeople.entries.toList();
              final entry = entries[index];
              final letter = entry.key;
              final people = entry.value;

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
                  // People list for this section
                  ClipRect(
                    child: Transform.translate(
                      offset: Offset(0, -0.5),
                      child: CupertinoListSection(
                        margin: EdgeInsets.zero,
                        additionalDividerMargin: 72,
                        backgroundColor: CupertinoColors.systemBackground,
                        topMargin: 0,
                        children: people.map((person) {
                          return CupertinoListTile(
                            backgroundColor: CupertinoColors.systemBackground
                                .resolveFrom(context),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            leadingSize: 60,
                            leading: _buildInitialsAvatar(
                              person.initials,
                              isDark,
                            ),
                            title: Text(
                              person.displayName,
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
                                if (person.displayTitle.isNotEmpty)
                                  Text(
                                    person.displayTitle,
                                    style: TextStyle(
                                      fontFamily: 'SF Pro Display',
                                      fontSize: 15,
                                      letterSpacing: 0.25,
                                    ),
                                  ),
                                if (person.displayCompany.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      person.displayCompany,
                                      style: TextStyle(
                                        fontFamily: 'SF Pro Display',
                                        fontSize: 14,
                                        letterSpacing: 0.25,
                                        color: CupertinoColors.secondaryLabel
                                            .resolveFrom(context),
                                      ),
                                    ),
                                  ),
                                _buildCompanyTypeBadges(person),
                                if (person.displayLocation.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      person.displayLocation,
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
                                      PeopleDetailPage(personId: person.id),
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
            }, childCount: _groupedPeople.length),
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
                    final hasSection = _groupedPeople.containsKey(letter);

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
