import 'dart:async';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/page_scaffold.dart';
import '../pages/attendee_detail_page.dart';
import '../apis/providers/attendees_provider.dart';
import '../providers/home_data_provider.dart';

class AttendeesTab extends ConsumerStatefulWidget {
  const AttendeesTab({super.key});

  @override
  ConsumerState<AttendeesTab> createState() => _AttendeesTabState();
}

class _AttendeesTabState extends ConsumerState<AttendeesTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSearchField = false;
  List<Attendee> _filteredAttendees = [];
  Map<String, List<Attendee>> _groupedAttendees = {};
  Map<String, GlobalKey> _sectionKeys = {};
  String? _scrollingLetter;
  final GlobalKey _indexBarKey = GlobalKey();
  String? _eventId;
  Timer? _debounceTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Load attendees after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendees();
    });
  }

  void _loadAttendees() {
    // Get eventId from home data provider
    final homeData = ref.read(homePageDataProvider).valueOrNull;
    _eventId = homeData?.event?.id;

    if (_eventId != null) {
      // Load attendees for this event
      ref.read(attendeesProvider.notifier).loadAttendees(_eventId!);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _groupAttendees() {
    // Sort attendees by sortFirstName from API
    _filteredAttendees.sort((a, b) {
      final firstNameA = a.sortFirstName ?? '';
      final firstNameB = b.sortFirstName ?? '';
      return firstNameA.compareTo(firstNameB);
    });

    // Group by first letter of sortFirstName
    _groupedAttendees.clear();
    _sectionKeys.clear();

    for (var attendee in _filteredAttendees) {
      final sortName = attendee.sortFirstName ?? '';
      if (sortName.isEmpty) continue;

      final firstLetter = sortName[0].toUpperCase();

      if (!_groupedAttendees.containsKey(firstLetter)) {
        _groupedAttendees[firstLetter] = [];
        _sectionKeys[firstLetter] = GlobalKey();
      }
      _groupedAttendees[firstLetter]!.add(attendee);
    }
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Debounce search by 500ms
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (_eventId != null) {
        ref.read(attendeesProvider.notifier).search(query);
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearchField = !_showSearchField;
      if (!_showSearchField) {
        _debounceTimer?.cancel();
        _searchController.clear();
        // Reset search on server
        if (_eventId != null) {
          ref.read(attendeesProvider.notifier).search('');
        }
      }
    });
  }

  Future<void> _onRefresh() async {
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
      if (_eventId != null) {
        // Just trigger refresh - ref.listen will handle state update
        await ref.read(attendeesProvider.notifier).refresh();
        log('🔄 [$timestamp] _onRefresh() COMPLETED successfully');

        // Keep the flag true for 500ms to prevent rapid successive calls
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      log('❌ [$timestamp] _onRefresh() ERROR: $e');
    } finally {
      _isRefreshing = false;
      log('🔄 [$timestamp] _isRefreshing set to FALSE');
    }
  }

  Future<void> _loadMore() async {
    log('🔄 _loadMore called in UI');
    if (_eventId != null) {
      final notifier = ref.read(attendeesProvider.notifier);
      log('🔄 hasMore: ${notifier.hasMore}');
      if (notifier.hasMore) {
        log('🔄 Calling notifier.loadMore()');
        await notifier.loadMore();
      } else {
        log('🔄 No more data to load');
      }
    } else {
      log('🔄 eventId is null');
    }
  }

  String? _getLetterAtPosition(double localY) {
    final RenderBox? renderBox =
        _indexBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final barHeight = renderBox.size.height;
    final itemHeight = barHeight / 26;
    final index = (localY / itemHeight).floor().clamp(0, 25);
    final letter = String.fromCharCode(65 + index);

    return _groupedAttendees.containsKey(letter) ? letter : null;
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
        // Use ensureVisible which automatically handles all the scrolling logic
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.0, // Align to top of viewport
        );
      } catch (e) {
        // Ignore scroll errors - section might not be in viewport yet
      }
    }
  }

  // Helper function to convert country code to emoji flag
  String _countryCodeToEmoji(String countryCode) {
    final codePoints = countryCode.toUpperCase().codeUnits;
    return String.fromCharCodes(
      codePoints.map((code) => 0x1F1E6 + (code - 0x41)),
    );
  }

  // Helper function to get initials from name
  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';

    // Remove titles with or without period (Dr, Dr., Prof, Prof., Mr, Mr., etc.)
    final cleaned = name.replaceAll(
      RegExp(r'^(Dr\.?|Prof\.?|Mr\.?|Mrs\.?|Ms\.?)\s+', caseSensitive: false),
      '',
    );

    final parts = cleaned.trim().split(' ');
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }

    // First letter of first name + first letter of last name
    return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1))
        .toUpperCase();
  }

  // Build initials avatar widget
  Widget _buildInitialsAvatar(String? name, bool isDark) {
    final initials = _getInitials(name);

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

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final attendeesAsync = ref.watch(attendeesProvider);

    // Listen to provider changes and update local state
    ref.listen<AsyncValue<AttendeesData>>(attendeesProvider, (previous, next) {
      next.whenData((data) {
        setState(() {
          _filteredAttendees = data.attendees;
          _groupAttendees();
        });
      });
    });

    return Stack(
      children: [
        CustomPageScaffold(
          scrollController: _scrollController,
          isLoading: attendeesAsync.isLoading,
          heading: 'Attendees',
          searchController: _searchController,
          showSearchField: _showSearchField,
          onSearchToggle: (_) => _toggleSearch(),
          onBottomRefresh: _loadMore,
          onRefresh: _onRefresh,
          sliverList: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final entries = _groupedAttendees.entries.toList();
              final entry = entries[index];
              final letter = entry.key;
              final attendees = entry.value;

              return Column(
                key: _sectionKeys[letter],
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header - Full width with sticky effect using Container
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
                  // Attendees list for this section
                  ClipRect(
                    child: Transform.translate(
                      offset: Offset(0, -0.5),
                      child: CupertinoListSection(
                        margin: EdgeInsets.zero,
                        additionalDividerMargin: 72,
                        backgroundColor: CupertinoColors.systemBackground,
                        topMargin: 0,
                        children: attendees.map((attendee) {
                          return CupertinoListTile(
                            backgroundColor: CupertinoColors.systemBackground
                                .resolveFrom(context),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            leadingSize: 60,
                            leading: Stack(
                              children: [
                                // Always show initials first (instant load)
                                _buildInitialsAvatar(attendee.name, isDark),
                                // Overlay photo on top if available
                                if (attendee.photo != null &&
                                    attendee.photo!.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Image.network(
                                      attendee.photo!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            // While loading, show nothing (initials visible underneath)
                                            return const SizedBox.shrink();
                                          },
                                      errorBuilder: (context, error, stackTrace) {
                                        // On error, show nothing (initials remain visible)
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              '${attendee.title?.isNotEmpty == true ? attendee.title! + ' ' : ''}${attendee.name ?? ''}',
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
                                if (attendee.designation != null &&
                                    attendee.designation!.isNotEmpty)
                                  Text(
                                    attendee.designation!,
                                    style: TextStyle(
                                      fontFamily: 'SF Pro Display',
                                      fontSize: 15,
                                      letterSpacing: 0.25,
                                    ),
                                  ),
                                if (attendee.designation != null &&
                                    attendee.designation!.isNotEmpty)
                                  SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (attendee.countryCode != null)
                                      Text(
                                        _countryCodeToEmoji(
                                          attendee.countryCode!,
                                        ),
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    if (attendee.countryCode != null)
                                      SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${attendee.organization ?? ''}${attendee.organization != null && attendee.organization!.isNotEmpty && attendee.location != null && attendee.location!.isNotEmpty ? ', ' : ''}${attendee.location ?? ''}',
                                        style: TextStyle(
                                          fontFamily: 'SF Pro Display',
                                          fontSize: 14,
                                          letterSpacing: 0.25,
                                          color: CupertinoColors.secondaryLabel
                                              .resolveFrom(context),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
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
                                  builder: (context) => AttendeeDetailPage(
                                    attendeeId: attendee.id,
                                  ),
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
            }, childCount: _groupedAttendees.length),
          ),
        ),
        // A-Z Index on the right - iOS style
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
                    final hasSection = _groupedAttendees.containsKey(letter);

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
                                      ? Color(0xFF23C061)
                                      : Color(0xFF21AA62)
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
