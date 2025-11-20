import 'dart:ui' show ImageFilter;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../components/page_scaffold.dart';
import '../pages/session_detail_page.dart';

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0; // 0 = All Schedules, 1 = My Schedules
  DateTime _selectedDate = DateTime(2025, 1, 25); // Thursday, Jan 25
  final Set<int> _myScheduleIds = {}; // Track added sessions
  late PageController _pageController;
  late ScrollController _scrollController;
  late AnimationController _tabAnimationController;
  late Animation<double> _tabAnimation;

  // Height per 30 minutes
  final double _halfHourHeightEmpty = 40.0; // Height for empty slots
  final double _eventCardTopPadding = 10.0; // Top padding for event cards
  final double _eventCardBottomPadding = 10.0; // Bottom padding for event cards
  final double _eventCardSpacing = 10.0; // Spacing between stacked cards

  // 10-day event schedule (Jan 20-29, 2025)
  final List<Map<String, dynamic>> _allSessions = [
    {
      'id': 1,
      'date': DateTime(2025, 1, 20),
      'topOffset': 0.34, // 00:10 (0.17 hours from 00:00)
      'height': 2.66,
      'time': '2:00 PM - 3:00 PM IST',
      'duration': '1 hour',
      'title': 'Welcome & Registration',
      'location': 'Grand Ballroom, The Westin',
      'organizer': 'Organizing Committee',
      'status': 'Open seating',
      'category': 'Opening',
      'categoryColor': Color(0xFFDC2626),
      'bgColor': Color(0xFFD4F4DD),
    },
    {
      'id': 2,
      'date': DateTime(2025, 1, 21),
      'topOffset': 4.0,
      'height': 3.0,
      'time': '11:00 AM - 12:30 PM IST',
      'duration': '1.5 hours',
      'title': 'Workshop: Advanced Techniques',
      'location': 'Conference Room A',
      'organizer': 'Dr. Sarah Johnson',
      'status': 'Limited seats',
      'category': 'Workshop',
      'categoryColor': Color(0xFF2563EB),
      'bgColor': Color(0xFFDCEFFF),
    },
    {
      'id': 3,
      'date': DateTime(2025, 1, 22),
      'topOffset': 2.0,
      'height': 4.0,
      'time': '10:00 AM - 12:00 PM IST',
      'duration': '2 hours',
      'title': 'Panel Discussion: Future Trends',
      'location': 'Main Hall',
      'organizer': 'Industry Experts Panel',
      'status': 'Open seating',
      'category': 'Panel',
      'categoryColor': Color(0xFFCA8A04),
      'bgColor': Color(0xFFFFF4E6),
    },
    {
      'id': 4,
      'date': DateTime(2025, 1, 23),
      'topOffset': 6.0,
      'height': 2.0,
      'time': '12:00 PM - 1:00 PM IST',
      'duration': '1 hour',
      'title': 'Networking Lunch',
      'location': 'Garden Terrace',
      'organizer': 'All Attendees',
      'status': 'Open to all',
      'category': 'Social',
      'categoryColor': Color(0xFF16A34A),
      'bgColor': Color(0xFFD4F4DD),
    },
    {
      'id': 5,
      'date': DateTime(2025, 1, 24),
      'topOffset': 8.0,
      'height': 3.0,
      'time': '1:00 PM - 2:30 PM IST',
      'duration': '1.5 hours',
      'title': 'Technical Session: AI & ML',
      'location': 'Tech Lab',
      'organizer': 'Prof. Michael Chen',
      'status': 'Open seating',
      'category': 'Technical',
      'categoryColor': Color(0xFF7C3AED),
      'bgColor': Color(0xFFE9D5FF),
    },
    {
      'id': 6,
      'date': DateTime(2025, 1, 25),
      'topOffset': 8.0,
      'height': 1.5,
      'time': '4:00 PM - 5:30 PM IST',
      'duration': '1.5 hours',
      'title': 'Inaugural Ceremony & Presidential Address',
      'location': 'Grand Ballroom, The Westin',
      'organizer': 'Dr. Medha Bhave, President IAAPS',
      'status': 'Open seating',
      'category': 'Keynote',
      'categoryColor': Color(0xFFDC2626),
      'isActive': true,
      'currentTime': '13:02',
    },
    {
      'id': 7,
      'date': DateTime(2025, 1, 25),
      'topOffset': 11.0,
      'height': 2.0,
      'time': '6:00 PM - 8:00 PM IST',
      'duration': '2 hours',
      'title': 'Welcome Reception & Networking Dinner',
      'location': 'Poolside Terrace, The Westin',
      'organizer': 'All Attendees',
      'status': 'Open to all',
      'category': 'Social',
      'categoryColor': Color(0xFFCA8A04),
      'bgColor': Color(0xFFFFF4E6),
      'showAvatar': true,
    },
    // Multiple sessions at same time slot (8.0)
    {
      'id': 12,
      'date': DateTime(2025, 1, 25),
      'topOffset': 8.0,
      'height': 1.5,
      'time': '4:00 PM - 4:45 PM IST',
      'duration': '45 minutes',
      'title': 'Workshop A: Data Analytics',
      'location': 'Room 101',
      'organizer': 'Prof. Kumar',
      'status': 'Limited seats',
      'category': 'Workshop',
      'categoryColor': Color(0xFF2563EB),
      'bgColor': Color(0xFFDCEFFF),
    },
    {
      'id': 13,
      'date': DateTime(2025, 1, 25),
      'topOffset': 8.0,
      'height': 1.5,
      'time': '4:00 PM - 4:45 PM IST',
      'duration': '45 minutes',
      'title': 'Workshop B: Cloud Computing',
      'location': 'Room 102',
      'organizer': 'Dr. Sharma',
      'status': 'Limited seats',
      'category': 'Technical',
      'categoryColor': Color(0xFF7C3AED),
      'bgColor': Color(0xFFE9D5FF),
    },
    {
      'id': 8,
      'date': DateTime(2025, 1, 26),
      'topOffset': 3.0,
      'height': 3.0,
      'time': '10:30 AM - 12:00 PM IST',
      'duration': '1.5 hours',
      'title': 'Hands-on Training: New Technologies',
      'location': 'Lab 1 & 2',
      'organizer': 'Tech Team',
      'status': 'Registration required',
      'category': 'Training',
      'categoryColor': Color(0xFF2563EB),
      'bgColor': Color(0xFFDCEFFF),
    },
    {
      'id': 9,
      'date': DateTime(2025, 1, 27),
      'topOffset': 5.0,
      'height': 2.0,
      'time': '11:30 AM - 12:30 PM IST',
      'duration': '1 hour',
      'title': 'Case Study Presentation',
      'location': 'Auditorium B',
      'organizer': 'Research Team',
      'status': 'Open seating',
      'category': 'Research',
      'categoryColor': Color(0xFF7C3AED),
      'bgColor': Color(0xFFE9D5FF),
    },
    {
      'id': 10,
      'date': DateTime(2025, 1, 28),
      'topOffset': 4.0,
      'height': 3.0,
      'time': '11:00 AM - 12:30 PM IST',
      'duration': '1.5 hours',
      'title': 'Closing Ceremony',
      'location': 'Main Hall, The Westin',
      'organizer': 'Event Committee',
      'status': 'All invited',
      'category': 'Closing',
      'categoryColor': Color(0xFF7C3AED),
      'bgColor': Color(0xFFE9D5FF),
    },
    {
      'id': 11,
      'date': DateTime(2025, 1, 29),
      'topOffset': 1.0,
      'height': 2.0,
      'time': '9:30 AM - 10:30 AM IST',
      'duration': '1 hour',
      'title': 'Farewell Breakfast',
      'location': 'Restaurant, The Westin',
      'organizer': 'Organizing Committee',
      'status': 'Open to all',
      'category': 'Social',
      'categoryColor': Color(0xFF16A34A),
      'bgColor': Color(0xFFD4F4DD),
    },
  ];

  // Get list of dates that have sessions
  List<DateTime> get _datesWithSessions {
    final dates = _allSessions
        .map((s) => s['date'] as DateTime)
        .toSet()
        .toList();
    dates.sort();
    return dates;
  }

  // Get date range for the entire event
  DateTime? get _eventStartDate {
    if (_datesWithSessions.isEmpty) return null;
    return _datesWithSessions.first;
  }

  DateTime? get _eventEndDate {
    if (_datesWithSessions.isEmpty) return null;
    return _datesWithSessions.last;
  }

  // Generate list of all dates in the event range
  List<DateTime> get _allEventDates {
    if (_eventStartDate == null || _eventEndDate == null) return [];

    final dates = <DateTime>[];
    var current = _eventStartDate!;

    while (current.isBefore(_eventEndDate!) ||
        current.isAtSameMomentAs(_eventEndDate!)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  // Generate full weeks (always 7 days per week, pad with future dates if needed)
  List<List<DateTime>> get _weeks {
    if (_allEventDates.isEmpty) return [];

    final weeks = <List<DateTime>>[];
    final List<DateTime> currentWeek = [];

    for (var date in _allEventDates) {
      currentWeek.add(date);

      // When we have 7 days, complete the week
      if (currentWeek.length == 7) {
        weeks.add(List.from(currentWeek));
        currentWeek.clear();
      }
    }

    // Pad remaining days to make a full week of 7 days
    if (currentWeek.isNotEmpty) {
      final lastDate = currentWeek.last;
      int daysToAdd = 1;
      while (currentWeek.length < 7) {
        currentWeek.add(lastDate.add(Duration(days: daysToAdd)));
        daysToAdd++;
      }
      weeks.add(List.from(currentWeek));
    }

    return weeks;
  }

  // Get current week index based on selected date
  int get _currentWeekIndex {
    for (int i = 0; i < _weeks.length; i++) {
      if (_weeks[i].any(
        (d) =>
            d.year == _selectedDate.year &&
            d.month == _selectedDate.month &&
            d.day == _selectedDate.day,
      )) {
        return i;
      }
    }
    return 0;
  }

  // Check if a date has sessions
  bool _hasSession(DateTime date) {
    if (_selectedTabIndex == 1) {
      // For "My Schedules" tab, check if there are sessions added to my schedule for this date
      final sessionsForDate = _getSessionsForDate(date);
      return sessionsForDate.any((s) => _myScheduleIds.contains(s['id']));
    } else {
      // For "All Schedules" tab, check if there are any sessions for this date
      return _datesWithSessions.any(
        (d) =>
            d.year == date.year && d.month == date.month && d.day == date.day,
      );
    }
  }

  // Get sessions for selected date
  List<Map<String, dynamic>> _getSessionsForDate(DateTime date) {
    return _allSessions.where((s) {
      final sessionDate = s['date'] as DateTime;
      return sessionDate.year == date.year &&
          sessionDate.month == date.month &&
          sessionDate.day == date.day;
    }).toList();
  }

  // Get filtered sessions based on tab
  List<Map<String, dynamic>> get _filteredSessions {
    final sessionsForDate = _getSessionsForDate(_selectedDate);

    if (_selectedTabIndex == 1) {
      return sessionsForDate
          .where((s) => _myScheduleIds.contains(s['id']))
          .toList();
    }
    return sessionsForDate;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentWeekIndex);
    _scrollController = ScrollController();
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _tabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tabAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _tabAnimationController.dispose();
    super.dispose();
  }

  void _scrollToFirstSession() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_filteredSessions.isNotEmpty && _scrollController.hasClients) {
        final firstSession = _filteredSessions.first;
        final topOffset = firstSession['topOffset'] as double;

        // Calculate the absolute position of the first session
        double position = 0;
        for (int i = 0; i < topOffset.floor(); i++) {
          position += _getSlotHeight(i);
        }

        // Account for the fixed header height (190px)
        // Scroll to position with some padding
        final scrollPosition = position > 50 ? position - 50 : 0.0;

        _scrollController.animateTo(
          scrollPosition.toDouble(),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onPageChanged(int index) {
    if (index < _weeks.length) {
      final newWeek = _weeks[index];
      setState(() {
        // Select first date with session in the new week, or first date if none
        _selectedDate = newWeek.firstWhere(
          (d) => _hasSession(d),
          orElse: () => newWeek.first,
        );
      });
      _scrollToFirstSession();
    }
  }

  void _previousWeek() {
    if (_pageController.page! > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextWeek() {
    if (_pageController.page! < _weeks.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return CustomPageScaffold(
      heading: 'Schedule',
      isLoading: false,
      hideLargeTitle: false,
      hideSearch: true,
      scrollController: _scrollController,
      sliverList: SliverMainAxisGroup(
        slivers: [
          // Blurred header section containing tabs, dates, and date label
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              minHeight: 190.0,
              maxHeight: 190.0,
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: const Border(
                    bottom: BorderSide(
                      color: CupertinoColors.systemGrey,
                      width: 0.2,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    _buildTabs(),
                    _buildWeekDatePicker(),
                    _buildDateLabel(),
                  ],
                ),
              ),
            ),
          ),
          // Timeline (scrollable)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _buildTimelineGrid(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final inactiveColor = isDark
        ? CupertinoColors.systemGrey2
        : CupertinoColors.systemGrey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _switchTab(0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'All Schedules',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 16,
                        letterSpacing: 0.2,
                        fontWeight: _selectedTabIndex == 0
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _selectedTabIndex == 0
                            ? CupertinoColors.activeBlue
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'My Schedules',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 16,
                        letterSpacing: 0.2,
                        fontWeight: _selectedTabIndex == 1
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _selectedTabIndex == 1
                            ? CupertinoColors.activeBlue
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
              // Background bar
              // Animated blue bar
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
                          color: CupertinoColors.activeBlue,
                        ),
                      );
                    },
                  );
                },
              ),

              Container(height: 0.2, color: CupertinoColors.systemGrey5),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDatePicker() {
    final currentIdx = _currentWeekIndex;
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Left arrow
          GestureDetector(
            onTap: currentIdx > 0 ? _previousWeek : null,
            child: Container(
              width: 40,
              height: 80,
              alignment: Alignment.center,
              child: Icon(
                CupertinoIcons.chevron_left,
                color: currentIdx > 0
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey4,
                size: 24,
              ),
            ),
          ),
          // Week dates with PageView
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _weeks.length,
              itemBuilder: (context, weekIndex) {
                final week = _weeks[weekIndex];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: week.map((date) {
                    final isSelected =
                        date.year == _selectedDate.year &&
                        date.month == _selectedDate.month &&
                        date.day == _selectedDate.day;
                    final hasSession = _hasSession(date);
                    final isDisabled = !hasSession;

                    return Expanded(
                      child: GestureDetector(
                        onTap: isDisabled
                            ? null
                            : () {
                                setState(() => _selectedDate = date);
                                _scrollToFirstSession();
                              },
                        child: Opacity(
                          opacity: isDisabled ? 0.5 : 1.0,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
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
                                const SizedBox(height: 8),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDark
                                              ? CupertinoColors.white
                                              : CupertinoColors.black)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      fontFamily: 'SF Pro Display',
                                      fontSize: 18,
                                      letterSpacing: 0.2,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? (isDark
                                                ? CupertinoColors.black
                                                : CupertinoColors.white)
                                          : isDisabled
                                          ? CupertinoColors.systemGrey
                                          : (isDark
                                                ? CupertinoColors.white
                                                : CupertinoColors.black),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          // Right arrow
          GestureDetector(
            onTap: currentIdx < _weeks.length - 1 ? _nextWeek : null,
            child: Container(
              width: 40,
              height: 80,
              alignment: Alignment.center,
              child: Icon(
                CupertinoIcons.chevron_right,
                color: currentIdx < _weeks.length - 1
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey4,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildDateLabel() {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    // Calculate day number (Day 1, Day 2, etc.)
    int dayNumber = 1;
    if (_eventStartDate != null) {
      final difference = _selectedDate.difference(_eventStartDate!).inDays;
      dayNumber = difference + 1;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 18,
            letterSpacing: 0.2,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
          children: [
            TextSpan(
              text: '${_getMonthName(_selectedDate.month)} ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: '${_selectedDate.day},  ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: _getWeekdayFull(_selectedDate.weekday),
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                color: CupertinoColors.systemGrey,
              ),
            ),
            TextSpan(
              text: '  •  Day $dayNumber',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFD700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Check if there's a session at a specific half-hour slot
  bool _hasSessionAtSlot(int slotIndex) {
    for (var session in _filteredSessions) {
      final topOffset = session['topOffset'] as double;
      final height = session['height'] as double;

      // Calculate session start and end in half-hour slots
      final sessionStartSlot = topOffset;
      final sessionEndSlot = topOffset + height;

      // Check if this slot falls within the session
      if (slotIndex >= sessionStartSlot && slotIndex < sessionEndSlot) {
        return true;
      }
    }
    return false;
  }

  // Calculate height for event card based on title length
  double _calculateCardHeight(String title) {
    // Base height for card content:
    // Padding: 32px (16 all sides)
    // Time/Duration: 25px
    // SizedBox: 8px
    // Location: 18px
    // SizedBox: 4px
    // Organizer: 18px
    // SizedBox: 12px
    // Footer: 36px
    // Base total: 153px

    double baseHeight = 153.0;

    // Add title height based on content length
    // Short titles (<30 chars): ~20px (1 line)
    // Medium titles (30-45 chars): ~36px (2 lines)
    // Long titles (>45 chars): ~52px (3 lines)
    double titleHeight;
    if (title.length > 45) {
      titleHeight = 52.0;
    } else if (title.length > 30) {
      titleHeight = 36.0;
    } else {
      titleHeight = 20.0;
    }

    // Add SizedBox after title
    double titleSpacing = 8.0;

    return baseHeight + titleHeight + titleSpacing; // 181-213px
  }

  // Calculate height for event card based on content
  double _estimateCardHeight(Map<String, dynamic> event) {
    final title = event['title'] as String;
    return _calculateCardHeight(title);
  }

  // Get the height for a specific time slot
  double _getSlotHeight(int slotIndex) {
    // Find all sessions that start at this slot
    final sessionsAtSlot = <Map<String, dynamic>>[];

    for (var session in _filteredSessions) {
      final topOffset = session['topOffset'] as double;
      if (slotIndex == topOffset.floor()) {
        sessionsAtSlot.add(session);
      }
    }

    if (sessionsAtSlot.isNotEmpty) {
      // Calculate total height for stacked cards
      double totalHeight = _eventCardTopPadding;

      for (int i = 0; i < sessionsAtSlot.length; i++) {
        totalHeight += _estimateCardHeight(sessionsAtSlot[i]);
        if (i < sessionsAtSlot.length - 1) {
          totalHeight += _eventCardSpacing;
        }
      }

      totalHeight += _eventCardBottomPadding;
      return totalHeight;
    } else if (_hasSessionAtSlot(slotIndex)) {
      // This slot is within a session but not the start, so it's already accounted for
      return 0;
    } else {
      // Empty slot
      return _halfHourHeightEmpty;
    }
  }

  // Get sessions that overlap at a specific time slot
  List<Map<String, dynamic>> _getSessionsAtSlot(int slotIndex) {
    return _filteredSessions.where((session) {
      final topOffset = session['topOffset'] as double;
      final height = session['height'] as double;
      final sessionStartSlot = topOffset;
      final sessionEndSlot = topOffset + height;
      return slotIndex >= sessionStartSlot && slotIndex < sessionEndSlot;
    }).toList();
  }

  Widget _buildTimelineGrid() {
    if (_filteredSessions.isEmpty) {
      return Container(
        height: 300,
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
                  : 'No sessions scheduled for this day',
              style: const TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 16,
                letterSpacing: 0.2,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      );
    }

    // Calculate total height based on dynamic slot heights
    double totalHeight = 0;
    for (int i = 0; i < 48; i++) {
      // 48 half-hour slots in 24 hours
      totalHeight += _getSlotHeight(i);
    }

    return SizedBox(
      height: totalHeight,
      child: Stack(
        children: [
          // Time markers and lines
          ..._buildTimeMarkersAndLines(),
          // Events positioned absolutely
          ..._buildEvents(),
        ],
      ),
    );
  }

  List<Widget> _buildTimeMarkersAndLines() {
    final times = <Widget>[];
    double currentTop = 0;

    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final slotIndex = hour * 2 + (minute ~/ 30);
        final height = _getSlotHeight(slotIndex);

        // Only show timestamp if it has height (not in middle of session)
        if (height > 0) {
          final period = hour >= 12 ? 'PM' : 'AM';
          final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
          final timeString =
              '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';

          times.add(
            Positioned(
              top: currentTop,
              left: 0,
              right: 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TIME ON LEFT
                  SizedBox(
                    width: 80,
                    child: Text(
                      timeString,
                      style: const TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14,
                        letterSpacing: 0.2,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ),
                  // LINE
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey.withValues(alpha: 0.2),
                      margin: const EdgeInsets.only(left: 8),
                    ),
                  ),
                ],
              ),
            ),
          );

          currentTop += height;
        }
      }
    }

    return times;
  }

  List<Widget> _buildEvents() {
    final widgets = <Widget>[];
    final processedSlots = <int>{};

    for (var event in _filteredSessions) {
      final topOffset = (event['topOffset'] as double);
      final startSlot = topOffset.floor();

      // Calculate absolute position based on actual slot heights
      double topPosition = 0;
      for (int i = 0; i < startSlot; i++) {
        topPosition += _getSlotHeight(i);
      }

      // Find all events at this slot
      final eventsAtSlot = _filteredSessions
          .where((s) => (s['topOffset'] as double).floor() == startSlot)
          .toList();

      // Skip if we've already processed this slot
      if (processedSlots.contains(startSlot)) {
        continue;
      }
      processedSlots.add(startSlot);

      // Stack multiple events vertically
      double cardTopOffset = topPosition + _eventCardTopPadding;
      for (int i = 0; i < eventsAtSlot.length; i++) {
        final evt = eventsAtSlot[i];
        final cardHeight = _estimateCardHeight(evt);

        if (evt['isActive'] == true) {
          widgets.add(
            _buildActiveEventCard(
              topOffset: cardTopOffset,
              time: evt['time'] as String,
              duration: evt['duration'] as String,
              title: evt['title'] as String,
              location: evt['location'] as String,
              organizer: evt['organizer'] as String,
              status: evt['status'] as String,
              category: evt['category'] as String,
              categoryColor: evt['categoryColor'] as Color,
              currentTime: evt['currentTime'] as String,
              sessionId: evt['id'] as int,
            ),
          );
        } else {
          widgets.add(
            _buildEventCard(
              topOffset: cardTopOffset,
              time: evt['time'] as String,
              duration: evt['duration'] as String,
              title: evt['title'] as String,
              location: evt['location'] as String,
              organizer: evt['organizer'] as String,
              status: evt['status'] as String,
              category: evt['category'] as String,
              categoryColor: evt['categoryColor'] as Color,
              color: evt['bgColor'] as Color,
              showAvatar: evt['showAvatar'] as bool? ?? false,
              sessionId: evt['id'] as int,
            ),
          );
        }

        // Move to next card position
        cardTopOffset += cardHeight + _eventCardSpacing;
      }
    }

    return widgets;
  }

  Widget _buildEventCard({
    required double topOffset,
    required String time,
    required String duration,
    required String title,
    required String location,
    required String organizer,
    required String status,
    required String category,
    required Color categoryColor,
    required Color color,
    required int sessionId,
    bool showAvatar = false,
  }) {
    final isAdded = _myScheduleIds.contains(sessionId);
    final cardHeight = _calculateCardHeight(title);
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    // Get the full session data
    final sessionData = _allSessions.firstWhere(
      (s) => s['id'] == sessionId,
      orElse: () => {},
    );

    return Positioned(
      top: topOffset,
      left: 90, // Space for time on left
      right: 0,
      height: cardHeight,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => SessionDetailPage(session: sessionData),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? CupertinoColors.white.withValues(alpha: 0.2)
                  : CupertinoColors.black.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Header: Time/Duration + Category Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 12,
                            letterSpacing: 0.2,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                          ),
                        ),
                        Text(
                          '($duration)',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 11,
                            letterSpacing: 0.2,
                            color: isDark
                                ? CupertinoColors.white.withValues(alpha: 0.6)
                                : CupertinoColors.black.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 12,
                        letterSpacing: 0.2,
                        fontWeight: FontWeight.w600,
                        color: categoryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Title
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 16,
                  letterSpacing: 0.2,
                  fontWeight: FontWeight.w600,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Location
              Row(
                children: [
                  Icon(
                    CupertinoIcons.location,
                    size: 14,
                    color: isDark
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 12,
                        letterSpacing: 0.2,
                        color: isDark
                            ? CupertinoColors.white.withValues(alpha: 0.6)
                            : CupertinoColors.black.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Organizer
              Row(
                children: [
                  Icon(
                    CupertinoIcons.person,
                    size: 14,
                    color: isDark
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      organizer,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 12,
                        letterSpacing: 0.2,
                        color: isDark
                            ? CupertinoColors.white.withValues(alpha: 0.6)
                            : CupertinoColors.black.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Footer: Status + Add Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 12,
                        letterSpacing: 0.2,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? CupertinoColors.black
                            : CupertinoColors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isAdded) {
                          _myScheduleIds.remove(sessionId);
                        } else {
                          _myScheduleIds.add(sessionId);
                        }
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isAdded
                            ? LinearGradient(
                                colors: [
                                  const Color(
                                    0xFFFFD700,
                                  ).withValues(alpha: 0.3),
                                  const Color(
                                    0xFFFFA500,
                                  ).withValues(alpha: 0.3),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [
                                  const Color(0xFFFFD700),
                                  const Color(0xFFFFA500),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        boxShadow: isAdded
                            ? null
                            : [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFD700,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                      ),
                      child: Icon(
                        isAdded
                            ? CupertinoIcons.checkmark
                            : CupertinoIcons.plus,
                        color: isAdded
                            ? const Color(0xFFFFD700)
                            : CupertinoColors.white,
                        size: 18,
                        weight: 600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveEventCard({
    required double topOffset,
    required String time,
    required String duration,
    required String title,
    required String location,
    required String organizer,
    required String status,
    required String category,
    required Color categoryColor,
    required String currentTime,
    required int sessionId,
  }) {
    final isAdded = _myScheduleIds.contains(sessionId);
    final cardHeight = _calculateCardHeight(title);
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    // Get the full session data
    final sessionData = _allSessions.firstWhere(
      (s) => s['id'] == sessionId,
      orElse: () => {},
    );

    return Positioned(
      top: topOffset,
      left: 90, // Space for time on left
      right: 0,
      height: cardHeight,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => SessionDetailPage(session: sessionData),
            ),
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6
                    .resolveFrom(context)
                    .withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFFF9500), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Header: Time/Duration + Category Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              time,
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 12,
                                letterSpacing: 0.2,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? CupertinoColors.white
                                    : CupertinoColors.black,
                              ),
                            ),
                            Text(
                              '($duration)',
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 11,
                                letterSpacing: 0.2,
                                color: isDark
                                    ? CupertinoColors.white.withValues(
                                        alpha: 0.6,
                                      )
                                    : CupertinoColors.black.withValues(
                                        alpha: 0.6,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 12,
                                letterSpacing: 0.2,
                                fontWeight: FontWeight.w600,
                                color: categoryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 16,
                      letterSpacing: 0.2,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Location
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.location,
                        size: 14,
                        color: isDark
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 12,
                            letterSpacing: 0.2,
                            color: isDark
                                ? CupertinoColors.white.withValues(alpha: 0.6)
                                : CupertinoColors.black.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Organizer
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.person,
                        size: 14,
                        color: isDark
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          organizer,
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 12,
                            letterSpacing: 0.2,
                            color: isDark
                                ? CupertinoColors.white.withValues(alpha: 0.6)
                                : CupertinoColors.black.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Footer: Status + Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontSize: 12,
                            letterSpacing: 0.2,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? CupertinoColors.black
                                : CupertinoColors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isAdded) {
                              _myScheduleIds.remove(sessionId);
                            } else {
                              _myScheduleIds.add(sessionId);
                            }
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isAdded
                                ? LinearGradient(
                                    colors: [
                                      const Color(
                                        0xFFFFD700,
                                      ).withValues(alpha: 0.3),
                                      const Color(
                                        0xFFFFA500,
                                      ).withValues(alpha: 0.3),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      const Color(0xFFFFD700),
                                      const Color(0xFFFFA500),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            boxShadow: isAdded
                                ? null
                                : [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFFD700,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ],
                          ),
                          child: Icon(
                            isAdded
                                ? CupertinoIcons.checkmark
                                : CupertinoIcons.plus,
                            color: isAdded
                                ? const Color(0xFFFFD700)
                                : CupertinoColors.white,
                            size: 18,
                            weight: 700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Left orange indicator
            Positioned(
              left: -90,
              top: 0,
              bottom: 0,
              child: Center(
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                          width: 4,
                        ),
                      ),
                    ),
                    Container(width: 78, height: 3, color: Colors.orange),
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
    // Always rebuild when state changes
    return true;
  }
}
