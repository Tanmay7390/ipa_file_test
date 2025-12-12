import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../components/page_scaffold.dart';
// import '../pages/session_detail_page.dart';
import '../apis/providers/sessions_provider.dart';
import '../providers/home_data_provider.dart';
import 'package:rajapsicon/providers/user_data_provider.dart';
import 'package:flash/flash.dart';

class ScheduleTab extends ConsumerStatefulWidget {
  const ScheduleTab({super.key});

  @override
  ConsumerState<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends ConsumerState<ScheduleTab>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0; // 0 = All Schedules, 1 = My Schedules
  DateTime _selectedDate = DateTime(2025, 12, 7); // Start with first event date
  final Set<String> _myScheduleIds = {}; // Track added sessions
  String? _eventId;
  late ScrollController _scrollController;
  late ScrollController _dateScrollController;
  late AnimationController _tabAnimationController;
  late Animation<double> _tabAnimation;
  bool _showScrollToTopButton = false;
  DateTime? _currentVisibleDate;
  List<Map<String, dynamic>> _allSessions = []; // Sessions converted from API
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _dateScrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _tabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tabAnimationController, curve: Curves.easeInOut),
    );

    // Load sessions after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSessions();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _dateScrollController.dispose();
    _tabAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 300 && !_showScrollToTopButton) {
      setState(() => _showScrollToTopButton = true);
    } else if (_scrollController.offset <= 300 && _showScrollToTopButton) {
      setState(() => _showScrollToTopButton = false);
    }
  }

  void _loadSessions() {
    // Get eventId from home data provider
    final homeData = ref.read(homePageDataProvider).valueOrNull;
    _eventId = homeData?.event?.id;

    if (_eventId != null) {
      // Load sessions for this event
      ref.read(sessionsProvider.notifier).loadSessions(_eventId!);

      // Load user schedule
      final userData = ref.read(userDataProvider).valueOrNull;
      final userId = userData?.id;

      if (userId != null) {
        ref
            .read(userScheduleProvider.notifier)
            .loadUserSchedule(userId: userId, eventId: _eventId!);
      }
    }
  }

  // Convert API Session to UI format
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
        // Refresh sessions
        await ref.read(sessionsProvider.notifier).refresh();

        // Refresh user schedule if user is logged in
        final userData = ref.read(userDataProvider).valueOrNull;
        if (userData != null) {
          await ref.read(userScheduleProvider.notifier).refresh();
        }

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

  Map<String, dynamic> _convertSessionToMap(Session session) {
    // Parse ISO date string to DateTime
    DateTime? sessionDate;
    String timeRange = '';
    String durationStr = '';

    if (session.startTime != null) {
      try {
        // Parse UTC time and convert to local time
        final startTimeUtc = DateTime.parse(session.startTime!);
        sessionDate = startTimeUtc.toLocal();

        final endTimeUtc = session.endTime != null
            ? DateTime.parse(session.endTime!)
            : null;
        final endTimeLocal = endTimeUtc?.toLocal();

        // Format time range (e.g., "9:00 AM - 9:20 AM")
        final startFormatted = DateFormat('h:mm a').format(sessionDate);
        if (endTimeLocal != null) {
          final endFormatted = DateFormat('h:mm a').format(endTimeLocal);
          timeRange = '$startFormatted - $endFormatted';
        } else {
          timeRange = startFormatted;
        }
      } catch (e) {
        sessionDate = DateTime.now();
      }
    }

    // Format duration (e.g., "1h 5m", "2h", "45m")
    if (session.duration != null) {
      final hours = session.duration! ~/ 60; // Integer division
      final minutes = session.duration! % 60; // Remainder

      if (hours > 0 && minutes > 0) {
        durationStr = '${hours}h ${minutes}m';
      } else if (hours > 0) {
        durationStr = '${hours}h';
      } else {
        durationStr = '${minutes}m';
      }
    }

    // Determine category and color based on sessionType
    String category = session.sessionType ?? 'Other';
    Color categoryColor;

    switch (session.sessionType?.toUpperCase()) {
      case 'PRESENTATION':
        category = 'Presentation';
        categoryColor = const Color(0xFF2563EB);
        break;
      case 'NETWORKING':
        category = 'Networking';
        categoryColor = const Color(0xFF16A34A);
        break;
      case 'KEYNOTE':
        category = 'Keynote';
        categoryColor = const Color(0xFFDC2626);
        break;
      case 'DEMO':
        category = 'Demo';
        categoryColor = const Color(0xFF7C3AED);
        break;
      case 'OTHER':
        category = 'Break';
        categoryColor = const Color(0xFF16A34A);
        break;
      default:
        category = session.sessionType ?? 'Other';
        categoryColor = const Color(0xFF21AA62);
    }

    // Build speakers list from API
    final speakers = <Map<String, dynamic>>[];
    if (session.speakers != null && session.speakers!.isNotEmpty) {
      for (var speaker in session.speakers!) {
        if (speaker.name != null) {
          speakers.add({
            'name': speaker.name!,
            'initials': _getInitials(speaker.name),
            'photo': speaker.photo,
            'id': speaker.id,
          });
        }
      }
    }

    return {
      'id': session.id,
      'date': sessionDate ?? DateTime.now(),
      'time': timeRange,
      'duration': durationStr,
      'title': session.title ?? 'Untitled Session',
      'location': session.venue ?? '',
      'organizer': session.organizer,
      'category': category,
      'categoryColor': categoryColor,
      'isActive': session.status == 'ONGOING', // status == 'ONGOING'
      'isAllDay': false,
      'speakers': speakers,
      'hasContent': session.organizer != null || speakers.isNotEmpty,
    };
  }

  // Helper to get initials from name
  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';

    final cleaned = name.replaceAll(
      RegExp(r'^(Dr\.?|Prof\.?|Mr\.?|Mrs\.?|Ms\.?)\s+', caseSensitive: false),
      '',
    );

    final parts = cleaned.trim().split(' ');
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }

    return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1))
        .toUpperCase();
  }

  // Get list of dates that have sessions
  List<DateTime> get _datesWithSessions {
    final dates = _allSessions
        .map((s) {
          final d = s['date'] as DateTime;
          return DateTime(d.year, d.month, d.day);
        })
        .toSet()
        .toList();
    dates.sort();
    return dates;
  }

  // Get only dates that have events (not full weeks)
  List<DateTime> get _eventDates {
    if (_selectedTabIndex == 1) {
      // For "My Schedule" tab, only show dates with sessions in user's schedule
      final dates = _datesWithSessions.where((date) {
        final sessionsForDate = _getSessionsForDate(date);
        return sessionsForDate.any((s) => _myScheduleIds.contains(s['id']));
      }).toList();
      dates.sort();
      return dates;
    }
    // For "All" tab, show all dates with sessions
    return _datesWithSessions;
  }

  // Get sessions for a specific date
  List<Map<String, dynamic>> _getSessionsForDate(DateTime date) {
    return _allSessions.where((s) {
      final sessionDate = s['date'] as DateTime;
      return sessionDate.year == date.year &&
          sessionDate.month == date.month &&
          sessionDate.day == date.day;
    }).toList();
  }

  // Helper function to parse time string to minutes since midnight
  int _parseTimeToMinutes(String timeString) {
    if (timeString.isEmpty) return 0;

    // Extract start time from "9:20 AM - 10:10 AM" format
    final startTime = timeString.split(' - ')[0].trim();

    // Parse hour and minute
    final parts = startTime.split(' ');
    if (parts.length < 2) return 0;

    final timeParts = parts[0].split(':');
    if (timeParts.length < 2) return 0;

    var hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = int.tryParse(timeParts[1]) ?? 0;
    final isPM = parts[1].toUpperCase() == 'PM';

    // Convert to 24-hour format
    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }

    return hour * 60 + minute;
  }

  // Group sessions by date
  Map<DateTime, List<Map<String, dynamic>>> get _sessionsByDate {
    final map = <DateTime, List<Map<String, dynamic>>>{};

    for (var session in _allSessions) {
      final date = session['date'] as DateTime;
      final dateKey = DateTime(date.year, date.month, date.day);

      if (!map.containsKey(dateKey)) {
        map[dateKey] = [];
      }
      map[dateKey]!.add(session);
    }

    // Sort sessions within each date by time
    for (var key in map.keys) {
      map[key]!.sort((a, b) {
        final aAllDay = a['isAllDay'] as bool;
        final bAllDay = b['isAllDay'] as bool;

        if (aAllDay && !bAllDay) return -1;
        if (!aAllDay && bAllDay) return 1;

        // Sort by parsed time (minutes since midnight)
        final aTime = _parseTimeToMinutes(a['time'] as String);
        final bTime = _parseTimeToMinutes(b['time'] as String);

        return aTime.compareTo(bTime);
      });
    }

    return map;
  }

  // Group sessions by time slot within a date
  List<List<Map<String, dynamic>>> _groupSessionsByTimeSlot(
    List<Map<String, dynamic>> sessions,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (var session in sessions) {
      final time = session['time'] as String;
      if (!grouped.containsKey(time)) {
        grouped[time] = [];
      }
      grouped[time]!.add(session);
    }

    // Convert to list of lists, maintaining time order
    final result = <List<Map<String, dynamic>>>[];
    String? lastTime;

    for (var session in sessions) {
      final time = session['time'] as String;
      if (time != lastTime) {
        result.add(grouped[time]!);
        lastTime = time;
      }
    }

    return result;
  }

  // Get filtered sessions based on tab
  Map<DateTime, List<Map<String, dynamic>>> get _filteredSessionsByDate {
    if (_selectedTabIndex == 1) {
      final map = <DateTime, List<Map<String, dynamic>>>{};

      for (var entry in _sessionsByDate.entries) {
        final filtered = entry.value
            .where((s) => _myScheduleIds.contains(s['id']))
            .toList();

        if (filtered.isNotEmpty) {
          map[entry.key] = filtered;
        }
      }

      return map;
    }
    return _sessionsByDate;
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _switchTab(int index) {
    if (_selectedTabIndex != index) {
      setState(() {
        _selectedTabIndex = index;
      });
      if (index == 1) {
        _tabAnimationController.forward();
      } else {
        _tabAnimationController.reverse();
      }
    }
  }

  String _formatDateHeader(DateTime date) {
    return '${_getWeekdayFull(date.weekday)}, ${_getMonthName(date.month)} ${date.day}';
  }

  String _formatDuration(String duration) {
    if (duration.isEmpty) return '';

    // Convert "2 hours" to "2h", "1.5 hours" to "1.5h", "45 minutes" to "45m", "1 hour" to "1h"
    if (duration.contains('hour')) {
      final hours = duration.replaceAll(' hours', '').replaceAll(' hour', '');
      return '${hours}h';
    } else if (duration.contains('minute')) {
      final minutes = duration
          .replaceAll(' minutes', '')
          .replaceAll(' minute', '');
      return '${minutes}m';
    }
    return duration;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final sessionsAsync = ref.watch(sessionsProvider);
    final userScheduleAsync = ref.watch(userScheduleProvider);

    // Listen to provider changes and update local state
    ref.listen<AsyncValue<SessionsData>>(sessionsProvider, (previous, next) {
      next.whenData((data) {
        setState(() {
          _allSessions = data.sessions
              .map((s) => _convertSessionToMap(s))
              .toList();
          // Set first event date as selected if no date is selected
          if (_eventDates.isNotEmpty && !_eventDates.contains(_selectedDate)) {
            _selectedDate = _eventDates.first;
          }
        });
      });
    });

    // Listen to user schedule changes
    ref.listen<AsyncValue<List<Session>>>(userScheduleProvider, (
      previous,
      next,
    ) {
      next.whenData((sessions) {
        setState(() {
          _myScheduleIds.clear();
          _myScheduleIds.addAll(sessions.map((s) => s.id));
        });
      });
    });

    // Listen to home data to load sessions when event ID is available
    ref.listen(homePageDataProvider, (previous, next) {
      if (next.value?.event?.id != null && _eventId == null) {
        _loadSessions();
      }
    });

    // Listen to user data to load schedule when user ID is available
    ref.listen(userDataProvider, (previous, next) {
      if (next.value?.id != null) {
        // Only load if we haven't loaded user schedule yet or if we need to refresh
        _loadSessions();
      }
    });

    final filteredSessions = _filteredSessionsByDate;
    // Only show events for the selected date
    final selectedDateKey = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final dates = filteredSessions.containsKey(selectedDateKey)
        ? [selectedDateKey]
        : <DateTime>[];

    return Stack(
      children: [
        CustomPageScaffold(
          heading: 'Schedule',
          isLoading:
              (sessionsAsync.isLoading && _allSessions.isEmpty) ||
              (userScheduleAsync.isLoading && _myScheduleIds.isEmpty),
          hideLargeTitle: false,
          hideSearch: true,
          scrollController: _scrollController,
          onRefresh: _onRefresh,
          sliverList: SliverMainAxisGroup(
            slivers: [
              // Tabs header
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  minHeight: 50.0,
                  maxHeight: 50.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground.resolveFrom(
                        context,
                      ),
                    ),
                    child: _buildTabs(),
                  ),
                ),
              ),

              // Event date picker
              if (_eventDates.length > 1)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyHeaderDelegate(
                    minHeight: 80.0,
                    maxHeight: 80.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground.resolveFrom(
                          context,
                        ),
                        border: const Border(
                          bottom: BorderSide(
                            color: CupertinoColors.systemGrey,
                            width: 0.2,
                          ),
                        ),
                      ),
                      child: _buildWeekDatePicker(),
                    ),
                  ),
                ),

              // Scrollable list of days and events
              if (dates.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    height: 400,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.calendar,
                          size: 64,
                          color: CupertinoColors.systemGrey3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedTabIndex == 1
                              ? 'No sessions in your schedule'
                              : 'No sessions scheduled',
                          style: const TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 16,
                            letterSpacing: 0.2,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...dates.asMap().entries.map((entry) {
                  final date = entry.value;
                  final sessions = filteredSessions[date]!;
                  final timeSlotGroups = _groupSessionsByTimeSlot(sessions);

                  return SliverMainAxisGroup(
                    slivers: [
                      // Sticky day header with visibility tracking
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _DateHeaderDelegate(
                          minHeight: 35.0,
                          maxHeight: 35.0,
                          date: date,
                          selectedDate: _selectedDate,
                          onDateVisible: (visibleDate) {
                            // Only update if coming from scroll, not from date bar tap
                            if (_currentVisibleDate != visibleDate &&
                                _selectedDate != visibleDate) {
                              setState(() {
                                _currentVisibleDate = visibleDate;
                                _selectedDate = visibleDate;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemBackground
                                  .resolveFrom(context),
                              border: const Border(
                                bottom: BorderSide(
                                  color: CupertinoColors.systemGrey,
                                  width: 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _formatDateHeader(date).toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.systemGrey
                                        .resolveFrom(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Events for this day (grouped by time slot)
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final timeSlotGroup = timeSlotGroups[index];
                          if (timeSlotGroup.length == 1) {
                            // Single event in this time slot
                            return _buildEventItem(timeSlotGroup[0]);
                          } else {
                            // Multiple events in same time slot - show stacked
                            return _buildTimeSlotGroup(timeSlotGroup);
                          }
                        }, childCount: timeSlotGroups.length),
                      ),
                    ],
                  );
                }),
            ],
          ),
        ),
        // Floating scroll to top button
        if (_showScrollToTopButton)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            right: 16,
            child: CupertinoButton(
              onPressed: _scrollToTop,
              padding: EdgeInsets.zero,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: isDark
                      ? CupertinoColors.darkBackgroundGray
                      : CupertinoColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  CupertinoIcons.chevron_up,
                  color: isDark
                      ? CupertinoColors.white
                      : CupertinoColors.darkBackgroundGray,
                  size: 24,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showFlashMessage(String message, {Color? backgroundColor}) {
    showFlash(
      context: context,
      duration: const Duration(seconds: 2),
      builder: (context, controller) {
        return FlashBar(
          controller: controller,
          backgroundColor: backgroundColor ?? CupertinoColors.black,
          position: FlashPosition.bottom,
          content: Text(
            message,
            style: const TextStyle(color: CupertinoColors.white),
          ),
        );
      },
    );
  }

  Future<void> _handleToggleSession(String sessionId) async {
    final userData = ref.read(userDataProvider).valueOrNull;
    final userId = userData?.id;

    if (userId == null || _eventId == null) {
      _showFlashMessage(
        'User or Event ID not found',
        backgroundColor: CupertinoColors.systemRed,
      );
      return;
    }

    // Call API
    final result = await ref
        .read(userScheduleProvider.notifier)
        .toggleSession(
          userId: userId,
          eventId: _eventId!,
          sessionId: sessionId,
        );

    if (mounted) {
      if (result.success) {
        // Show success message
        _showFlashMessage(
          result.message ?? 'Session updated successfully',
          backgroundColor: const Color(0xFF21AA62),
        );
      } else {
        // Show error message
        _showFlashMessage(
          result.error ?? 'Failed to update session',
          backgroundColor: CupertinoColors.systemRed,
        );
      }
    }
  }

  Widget _buildTabs() {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final inactiveColor = isDark
        ? CupertinoColors.systemGrey2
        : CupertinoColors.systemGrey;
    final activeColor = isDark
        ? const Color(0xFF23C061)
        : const Color(0xFF21AA62);

    return Container(
      padding: const EdgeInsets.only(top: 5),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _switchTab(0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'All',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 16,
                        letterSpacing: 0.2,
                        fontWeight: _selectedTabIndex == 0
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _selectedTabIndex == 0
                            ? activeColor
                            : inactiveColor,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _switchTab(1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'My Schedule',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 16,
                        letterSpacing: 0.2,
                        fontWeight: _selectedTabIndex == 1
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _selectedTabIndex == 1
                            ? activeColor
                            : inactiveColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Animated sliding bottom bar
          Stack(
            children: [
              AnimatedBuilder(
                animation: _tabAnimation,
                builder: (context, child) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final halfWidth = constraints.maxWidth / 2;
                      final offset = halfWidth * _tabAnimation.value;

                      return Transform.translate(
                        offset: Offset(offset, 0),
                        child: Container(
                          width: halfWidth,
                          height: 2,
                          color: activeColor,
                        ),
                      );
                    },
                  );
                },
              ),
              Container(height: 0.5, color: CupertinoColors.systemGrey5),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDatePicker() {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final activeColor = isDark
        ? const Color(0xFF23C061)
        : const Color(0xFF21AA62);
    final eventDates = _eventDates;

    return Container(
      padding: const EdgeInsets.only(top: 0, bottom: 10),
      height: 80,
      child: eventDates.length < 8
          ? Center(
              // Center dates when less than 8
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: eventDates
                    .map((date) => _buildDateItem(date, activeColor, isDark))
                    .toList(),
              ),
            )
          : SingleChildScrollView(
              // Horizontal scroll when 8 or more dates
              controller: _dateScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: eventDates
                    .map((date) => _buildDateItem(date, activeColor, isDark))
                    .toList(),
              ),
            ),
    );
  }

  Widget _buildDateItem(DateTime date, Color activeColor, bool isDark) {
    final isSelected =
        date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedDate = date);
      },
      child: Container(
        width: 50,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getWeekdayShort(date.weekday),
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14,
                letterSpacing: 0.2,
                color: isDark
                    ? CupertinoColors.systemGrey2
                    : CupertinoColors.systemGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 18,
                  letterSpacing: 0.2,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? CupertinoColors.white
                      : (isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotGroup(List<Map<String, dynamic>> sessions) {
    final firstSession = sessions[0];
    final isAllDay = firstSession['isAllDay'] as bool;

    return Column(
      children: sessions.asMap().entries.map((entry) {
        final index = entry.key;
        final session = entry.value;
        final isFirst = index == 0;
        final isLast = index == sessions.length - 1;

        return _buildStackedEventContent(
          session,
          showTime: isFirst,
          isAllDay: isAllDay,
          isLastInGroup: isLast,
        );
      }).toList(),
    );
  }

  Widget _buildStackedEventContent(
    Map<String, dynamic> session, {
    bool showTime = true,
    bool isAllDay = false,
    bool isLastInGroup = true,
  }) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final activeColor = isDark
        ? const Color(0xFF23C061)
        : const Color(0xFF21AA62);
    final isAdded = _myScheduleIds.contains(session['id']);
    final isActive = session['isActive'] as bool;
    final speakers = session['speakers'] as List<dynamic>;
    final organizer = session['organizer'] as SessionOrganizer?;
    final hasContent = session['hasContent'] as bool? ?? false;
    final canAddToSchedule =
        hasContent; // Show plus button if organizer/speakers available

    return GestureDetector(
      onTap: () {
        // if (hasContent) {
        //   Navigator.of(context, rootNavigator: true).push(
        //     CupertinoPageRoute(
        //       builder: (context) => SessionDetailPage(
        //         sessionId: session["_id"] ?? session["id"] ?? "",
        //       ),
        //     ),
        //   );
        // }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                    ? activeColor.withValues(alpha: 0.15)
                    : activeColor.withValues(alpha: 0.08))
              : CupertinoColors.systemBackground.resolveFrom(context),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left side - Time or All Day indicator (border only on last item in group)
              Container(
                width: 85,
                padding: const EdgeInsets.only(left: 20, top: 14, bottom: 12),
                decoration: BoxDecoration(
                  border: isLastInGroup
                      ? const Border(
                          bottom: BorderSide(
                            color: CupertinoColors.systemGrey,
                            width: 0.2,
                          ),
                        )
                      : null,
                ),
                child: showTime
                    ? (isAllDay
                          ? Text(
                              'ALL DAY',
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 14,
                                letterSpacing: 0.3,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.systemGrey.resolveFrom(
                                  context,
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _extractStartTime(session['time'] as String),
                                  style: TextStyle(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 14,
                                    letterSpacing: 0.2,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? CupertinoColors.white
                                        : CupertinoColors.black,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  _formatDuration(
                                    session['duration'] as String,
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'SF Pro Display',
                                    fontSize: 13,
                                    letterSpacing: 0.2,
                                    color: CupertinoColors.systemGrey
                                        .resolveFrom(context),
                                  ),
                                ),
                              ],
                            ))
                    : const SizedBox.shrink(),
              ),

              // Rounded vertical bar indicator (full height) with conditional border
              Container(
                padding: const EdgeInsets.only(top: 16, bottom: 16, right: 10),
                decoration: BoxDecoration(
                  border: isLastInGroup
                      ? const Border(
                          bottom: BorderSide(
                            color: CupertinoColors.systemGrey,
                            width: 0.2,
                          ),
                        )
                      : null,
                ),
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: isActive
                        ? activeColor
                        : (isDark
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.systemGrey4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Event details
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(
                    top: 12,
                    bottom: 12,
                    right: 20,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: CupertinoColors.systemGrey,
                        width: 0.2,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session['title'] as String,
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: 15,
                          letterSpacing: 0.2,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (speakers.isNotEmpty || organizer != null) ...[
                        const SizedBox(height: 6),
                        _buildSpeakerAvatars(speakers, organizer),
                      ],
                      if (session['location'] != null &&
                          (session['location'] as String).isNotEmpty) ...[
                        // const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.location,
                              size: 16,
                              color: CupertinoColors.systemGrey.resolveFrom(
                                context,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                session['location'] as String,
                                style: TextStyle(
                                  fontFamily: 'SF Pro Display',
                                  fontSize: 14,
                                  letterSpacing: 0.2,
                                  color: CupertinoColors.systemGrey.resolveFrom(
                                    context,
                                  ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Add button next to location (only for actual sessions)
                            if (canAddToSchedule) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () =>
                                    _handleToggleSession(session['id']),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isAdded
                                        ? activeColor.withValues(alpha: 0.2)
                                        : activeColor,
                                    border: isAdded
                                        ? Border.all(
                                            color: activeColor.withValues(
                                              alpha: 0.4,
                                            ),
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
                                  child: Icon(
                                    isAdded
                                        ? CupertinoIcons.checkmark
                                        : CupertinoIcons.plus,
                                    color: isAdded
                                        ? activeColor
                                        : CupertinoColors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
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

  Widget _buildEventItem(Map<String, dynamic> session) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final activeColor = isDark
        ? const Color(0xFF23C061)
        : const Color(0xFF21AA62);
    final isAdded = _myScheduleIds.contains(session['id']);
    final isActive = session['isActive'] as bool;
    final isAllDay = session['isAllDay'] as bool;
    final speakers = session['speakers'] as List<dynamic>;
    final organizer = session['organizer'] as SessionOrganizer?;
    final hasContent = session['hasContent'] as bool? ?? false;

    // Show plus button if organizer/speakers available
    final canAddToSchedule = hasContent;

    return GestureDetector(
      onTap: () {
        // if (hasContent) {
        //   Navigator.of(context, rootNavigator: true).push(
        //     CupertinoPageRoute(
        //       builder: (context) => SessionDetailPage(
        //         sessionId: session["_id"] ?? session["id"] ?? "",
        //       ),
        //     ),
        //   );
        // }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                    ? activeColor.withValues(alpha: 0.15)
                    : activeColor.withValues(alpha: 0.08))
              : CupertinoColors.systemBackground.resolveFrom(context),
          border: const Border(
            bottom: BorderSide(color: CupertinoColors.systemGrey, width: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side - Time or All Day indicator
            Container(
              width: 80,
              padding: const EdgeInsets.only(left: 20, top: 14, bottom: 12),
              child: isAllDay
                  ? Text(
                      'ALL DAY',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14,
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.systemGrey.resolveFrom(context),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _extractStartTime(session['time'] as String),
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 14,
                            letterSpacing: 0.2,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          _formatDuration(session['duration'] as String),
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 13,
                            letterSpacing: 0.2,
                            color: CupertinoColors.systemGrey.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            // Rounded vertical bar indicator (full height)
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 16, right: 10),
              child: Container(
                width: 10,
                decoration: BoxDecoration(
                  color: isActive
                      ? activeColor
                      : (isDark
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Event details
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(top: 12, bottom: 12, right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session['title'] as String,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 15,
                        letterSpacing: 0.2,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (speakers.isNotEmpty || organizer != null) ...[
                      const SizedBox(height: 6),
                      _buildSpeakerAvatars(speakers, organizer),
                    ],
                    if (session['location'] != null &&
                        (session['location'] as String).isNotEmpty) ...[
                      // const SizedBox(height: 0),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.location,
                            size: 14,
                            color: CupertinoColors.systemGrey.resolveFrom(
                              context,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              session['location'] as String,
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 14,
                                letterSpacing: 0.2,
                                color: CupertinoColors.systemGrey.resolveFrom(
                                  context,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Add button next to location (only for actual sessions)
                          if (canAddToSchedule) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _handleToggleSession(session['id']),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isAdded
                                      ? activeColor.withValues(alpha: 0.2)
                                      : activeColor,
                                  border: isAdded
                                      ? Border.all(
                                          color: activeColor.withValues(
                                            alpha: 0.4,
                                          ),
                                          width: 1.5,
                                        )
                                      : null,
                                ),
                                child: Icon(
                                  isAdded
                                      ? CupertinoIcons.checkmark
                                      : CupertinoIcons.plus,
                                  color: isAdded
                                      ? activeColor
                                      : CupertinoColors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakerAvatars(
    List<dynamic> speakers,
    SessionOrganizer? organizer,
  ) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    final List<Color> avatarColors = [
      CupertinoColors.systemBlue,
      CupertinoColors.systemOrange,
      CupertinoColors.systemPurple,
      CupertinoColors.systemPink,
      CupertinoColors.systemTeal,
    ];

    // Build list of people to display (speakers or organizer as fallback)
    List<Map<String, dynamic>> peopleToDisplay = [];

    if (speakers.isNotEmpty) {
      // Use speakers if available
      peopleToDisplay = speakers.cast<Map<String, dynamic>>();
    } else if (organizer != null && organizer.name != null) {
      // Fallback to organizer if no speakers
      peopleToDisplay = [
        {
          'name': organizer.name!,
          'initials': _getInitials(organizer.name),
          'photo': organizer.photo,
          'id': organizer.id,
        },
      ];
    }

    if (peopleToDisplay.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show max 5 avatars, rest in +X format
    final displayCount = peopleToDisplay.length > 5
        ? 5
        : peopleToDisplay.length;
    final extraCount = peopleToDisplay.length > 5
        ? peopleToDisplay.length - 5
        : 0;
    final showName = peopleToDisplay.length == 1;

    return Row(
      children: [
        ...List.generate(displayCount, (index) {
          final person = peopleToDisplay[index];
          final initials = person['initials'] as String;
          final name = person['name'] as String;
          final photo = person['photo'] as String?;
          final hasPhoto = photo != null && photo.isNotEmpty;
          final isSpecialInitial = initials == '?';

          return Padding(
            padding: EdgeInsets.only(left: index > 0 ? 4 : 0),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: hasPhoto
                        ? Colors.transparent
                        : (isSpecialInitial
                              ? CupertinoColors.systemGrey
                              : avatarColors[index % avatarColors.length]
                                    .withValues(alpha: 0.5)),
                    shape: BoxShape.circle,
                  ),
                  child: hasPhoto
                      ? ClipOval(
                          child: Image.network(
                            photo,
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback to initials if image fails to load
                              return Container(
                                decoration: BoxDecoration(
                                  color:
                                      avatarColors[index % avatarColors.length]
                                          .withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      fontFamily: 'SF Pro Display',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoColors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ),
                ),
                if (showName && index == 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 14,
                      letterSpacing: 0.2,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
        if (extraCount > 0) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5.resolveFrom(context),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '+$extraCount',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _extractStartTime(String timeRange) {
    if (timeRange.isEmpty) return '';
    final parts = timeRange.split(' - ');
    if (parts.isEmpty) return timeRange;
    return parts[0];
  }

  String _getWeekdayShort(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  String _getWeekdayFull(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }
}

// Delegate for pinned headers
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return true;
  }
}

// Delegate for date headers with visibility tracking
class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;
  final DateTime date;
  final DateTime selectedDate;
  final Function(DateTime) onDateVisible;

  _DateHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
    required this.date,
    required this.selectedDate,
    required this.onDateVisible,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Notify when this header overlaps content (is pinned) or when selected date matches
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (overlapsContent ||
          (date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day)) {
        onDateVisible(date);
      }
    });
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_DateHeaderDelegate oldDelegate) {
    return oldDelegate.date != date || oldDelegate.selectedDate != selectedDate;
  }
}
