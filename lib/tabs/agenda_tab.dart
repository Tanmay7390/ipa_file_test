import 'dart:ui' show ImageFilter;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../components/page_scaffold.dart';

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  int _selectedTabIndex = 0; // 0 = All Schedules, 1 = My Schedules
  DateTime _selectedDate = DateTime(2025, 1, 25); // Thursday, Jan 25
  final Set<int> _myScheduleIds = {}; // Track added sessions
  final ScrollController _weekScrollController = ScrollController();

  // Height per hour = 100 pixels
  final double _hourHeight = 100.0;

  // 10-day event schedule (Jan 20-29, 2025)
  final List<Map<String, dynamic>> _allSessions = [
    {
      'id': 1,
      'date': DateTime(2025, 1, 20),
      'topOffset': 0.17,
      'height': 1.33,
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
      'topOffset': 2.0,
      'height': 1.5,
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
      'topOffset': 1.0,
      'height': 2.0,
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
      'topOffset': 3.0,
      'height': 1.0,
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
      'topOffset': 4.0,
      'height': 1.5,
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
      'topOffset': 4.0,
      'height': 0.75,
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
      'topOffset': 5.5,
      'height': 1.0,
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
    {
      'id': 8,
      'date': DateTime(2025, 1, 26),
      'topOffset': 1.5,
      'height': 1.5,
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
      'topOffset': 2.5,
      'height': 1.0,
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
      'topOffset': 2.0,
      'height': 1.5,
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
      'topOffset': 0.5,
      'height': 1.0,
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
    final dates = _allSessions.map((s) => s['date'] as DateTime).toSet().toList();
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

  // Generate full weeks (always 7 days per week)
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

    // Add remaining days as the last week (pad with empty dates if needed)
    if (currentWeek.isNotEmpty) {
      weeks.add(List.from(currentWeek));
    }

    return weeks;
  }

  // Get current week index based on selected date
  int get _currentWeekIndex {
    for (int i = 0; i < _weeks.length; i++) {
      if (_weeks[i].any((d) =>
        d.year == _selectedDate.year &&
        d.month == _selectedDate.month &&
        d.day == _selectedDate.day
      )) {
        return i;
      }
    }
    return 0;
  }

  // Check if a date has sessions
  bool _hasSession(DateTime date) {
    return _datesWithSessions.any((d) =>
      d.year == date.year && d.month == date.month && d.day == date.day
    );
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
      return sessionsForDate.where((s) => _myScheduleIds.contains(s['id'])).toList();
    }
    return sessionsForDate;
  }

  void _previousWeek() {
    final currentIdx = _currentWeekIndex;
    if (currentIdx > 0) {
      final newWeek = _weeks[currentIdx - 1];
      setState(() {
        _selectedDate = newWeek.firstWhere(
          (d) => _hasSession(d),
          orElse: () => newWeek.first,
        );
      });
    }
  }

  void _nextWeek() {
    final currentIdx = _currentWeekIndex;
    if (currentIdx < _weeks.length - 1) {
      final newWeek = _weeks[currentIdx + 1];
      setState(() {
        _selectedDate = newWeek.firstWhere(
          (d) => _hasSession(d),
          orElse: () => newWeek.first,
        );
      });
    }
  }

  @override
  void dispose() {
    _weekScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPageScaffold(
      heading: 'Schedule',
      isLoading: false,
      hideLargeTitle: false,
      hideSearch: true,
      sliverList: SliverMainAxisGroup(
        slivers: [
          // Blurred header section containing tabs, dates, and date label
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyHeaderDelegate(
              minHeight: 210.0,
              maxHeight: 210.0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoTheme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1C1C1E).withValues(alpha: 0.85)
                          : CupertinoColors.systemBackground.withValues(alpha: 0.85),
                      border: const Border(
                        bottom: BorderSide(
                          color: CupertinoColors.systemGrey5,
                          width: 0.5,
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
            ),
          ),
          // Timeline (scrollable)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildTimelineGrid(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTabIndex == 0
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.systemGrey5,
                      width: _selectedTabIndex == 0 ? 3.0 : 1.0,
                    ),
                  ),
                ),
                child: Text(
                  'All Schedules',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 16,
                    letterSpacing: 0.2,
                    fontWeight: _selectedTabIndex == 0
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: _selectedTabIndex == 0
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.systemGrey,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTabIndex == 1
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.systemGrey5,
                      width: _selectedTabIndex == 1 ? 3.0 : 1.0,
                    ),
                  ),
                ),
                child: Text(
                  'My Schedules',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 16,
                    letterSpacing: 0.2,
                    fontWeight: _selectedTabIndex == 1
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: _selectedTabIndex == 1
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.systemGrey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDatePicker() {
    final currentIdx = _currentWeekIndex;
    final currentWeek = _weeks.isNotEmpty && currentIdx < _weeks.length
        ? _weeks[currentIdx]
        : <DateTime>[];

    return Container(
      height: 90,
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
          // Week dates
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(7, (index) {
                  // Show dates if they exist in currentWeek, otherwise show empty space
                  if (index < currentWeek.length) {
                    final date = currentWeek[index];
                    final isSelected = date.year == _selectedDate.year &&
                        date.month == _selectedDate.month &&
                        date.day == _selectedDate.day;
                    final hasSession = _hasSession(date);
                    final isDisabled = !hasSession;

                    return Container(
                      width: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: GestureDetector(
                        onTap: isDisabled
                            ? null
                            : () {
                                setState(() => _selectedDate = date);
                              },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getWeekdayShort(date.weekday),
                              style: TextStyle(
                                fontFamily: '.SF Pro Text',
                                fontSize: 12,
                                letterSpacing: 0.2,
                                color: isDisabled
                                    ? CupertinoColors.systemGrey3
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
                                    ? CupertinoColors.black
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: isDisabled
                                    ? Border.all(
                                        color: CupertinoColors.systemGrey5,
                                        width: 1,
                                      )
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontFamily: '.SF Pro Text',
                                  fontSize: 16,
                                  letterSpacing: 0.2,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? CupertinoColors.white
                                      : isDisabled
                                          ? CupertinoColors.systemGrey3
                                          : CupertinoColors.black,
                                ),
                              ),
                            ),
                            if (hasSession && !isSelected)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: CupertinoColors.activeBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    // Empty space for weeks with less than 7 days
                    return Container(
                      width: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                    );
                  }
                }).toList(),
              ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 18,
            letterSpacing: 0.2,
            color: CupertinoColors.black,
          ),
          children: [
            TextSpan(
              text: '${_getMonthName(_selectedDate.month)} ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: '${_selectedDate.day}, ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: _getWeekdayFull(_selectedDate.weekday),
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      ),
    );
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
                fontFamily: '.SF Pro Text',
                fontSize: 16,
                letterSpacing: 0.2,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: _hourHeight * 10, // 09:00 to 18:00+ extra space
      child: Stack(
        children: [
          // Time markers and lines (NOW ON LEFT)
          ..._buildTimeMarkersAndLines(),
          // Events positioned absolutely (ON RIGHT)
          ..._buildEvents(),
        ],
      ),
    );
  }

  List<Widget> _buildTimeMarkersAndLines() {
    final times = [
      '09:00',
      '10:00',
      '11:00',
      '12:00',
      '13:00',
      '14:00',
      '15:00',
      '16:00',
      '17:00',
    ];
    return List.generate(times.length, (index) {
      return Positioned(
        top: index * _hourHeight,
        left: 0,
        right: 0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // TIME ON LEFT
            SizedBox(
              width: 60,
              child: Text(
                times[index],
                style: const TextStyle(
                  fontFamily: '.SF Pro Text',
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
      );
    });
  }

  List<Widget> _buildEvents() {
    return _filteredSessions.map((event) {
      if (event['isActive'] == true) {
        return _buildActiveEventCard(
          topOffset: (event['topOffset'] as double) * _hourHeight,
          height: (event['height'] as double) * _hourHeight,
          time: event['time'] as String,
          duration: event['duration'] as String,
          title: event['title'] as String,
          location: event['location'] as String,
          organizer: event['organizer'] as String,
          status: event['status'] as String,
          category: event['category'] as String,
          categoryColor: event['categoryColor'] as Color,
          currentTime: event['currentTime'] as String,
          sessionId: event['id'] as int,
        );
      } else {
        return _buildEventCard(
          topOffset: (event['topOffset'] as double) * _hourHeight,
          height: (event['height'] as double) * _hourHeight,
          time: event['time'] as String,
          duration: event['duration'] as String,
          title: event['title'] as String,
          location: event['location'] as String,
          organizer: event['organizer'] as String,
          status: event['status'] as String,
          category: event['category'] as String,
          categoryColor: event['categoryColor'] as Color,
          color: event['bgColor'] as Color,
          showAvatar: event['showAvatar'] as bool? ?? false,
          sessionId: event['id'] as int,
        );
      }
    }).toList();
  }

  Widget _buildEventCard({
    required double topOffset,
    required double height,
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

    return Positioned(
      top: topOffset,
      left: 70, // Space for time on left
      right: 0,
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
                        style: const TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 12,
                          letterSpacing: 0.2,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.black,
                        ),
                      ),
                      Text(
                        '($duration)',
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 11,
                          letterSpacing: 0.2,
                          color: CupertinoColors.black.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 10,
                      letterSpacing: 0.2,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 16,
                letterSpacing: 0.2,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.black,
              ),
            ),
            const SizedBox(height: 8),
            // Location
            Row(
              children: [
                const Icon(
                  CupertinoIcons.location_solid,
                  size: 12,
                  color: CupertinoColors.systemGrey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 12,
                      letterSpacing: 0.2,
                      color: CupertinoColors.black.withValues(alpha: 0.6),
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
                const Icon(
                  CupertinoIcons.person_fill,
                  size: 12,
                  color: CupertinoColors.systemGrey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    organizer,
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 12,
                      letterSpacing: 0.2,
                      color: CupertinoColors.black.withValues(alpha: 0.6),
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
                Expanded(
                  child: Text(
                    status,
                    style: const TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 12,
                      letterSpacing: 0.2,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF16A34A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                      border: Border.all(
                        color: isAdded
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.systemGrey3,
                        width: 2,
                      ),
                      color: isAdded
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.white,
                    ),
                    child: Icon(
                      isAdded ? CupertinoIcons.check_mark : CupertinoIcons.add,
                      color: isAdded
                          ? CupertinoColors.white
                          : CupertinoColors.systemGrey,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveEventCard({
    required double topOffset,
    required double height,
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

    return Positioned(
      top: topOffset,
      left: 70, // Space for time on left
      right: 0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: BoxConstraints(minHeight: height),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                            style: const TextStyle(
                              fontFamily: '.SF Pro Text',
                              fontSize: 12,
                              letterSpacing: 0.2,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.white,
                            ),
                          ),
                          Text(
                            '($duration)',
                            style: TextStyle(
                              fontFamily: '.SF Pro Text',
                              fontSize: 11,
                              letterSpacing: 0.2,
                              color: CupertinoColors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: categoryColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontFamily: '.SF Pro Text',
                              fontSize: 10,
                              letterSpacing: 0.2,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.white,
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
                  style: const TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 16,
                    letterSpacing: 0.2,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Location
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.location_solid,
                      size: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 12,
                          letterSpacing: 0.2,
                          color: CupertinoColors.white.withValues(alpha: 0.6),
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
                    const Icon(
                      CupertinoIcons.person_fill,
                      size: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        organizer,
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 12,
                          letterSpacing: 0.2,
                          color: CupertinoColors.white.withValues(alpha: 0.6),
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
                    Expanded(
                      child: Text(
                        status,
                        style: const TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 12,
                          letterSpacing: 0.2,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4ADE80),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
                          border: Border.all(
                            color: isAdded
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.systemGrey3,
                            width: 2,
                          ),
                          color: isAdded
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.white,
                        ),
                        child: Icon(
                          isAdded ? CupertinoIcons.check_mark : CupertinoIcons.add,
                          color: isAdded
                              ? CupertinoColors.white
                              : CupertinoColors.systemGrey,
                          size: 18,
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
            left: -70,
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
                  Container(width: 58, height: 3, color: Colors.orange),
                ],
              ),
            ),
          ),
        ],
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
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight;
  }
}
