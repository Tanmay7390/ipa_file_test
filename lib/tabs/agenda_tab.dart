import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  int _selectedDateIndex = 3; // Thursday (20th)

  final List<Map<String, dynamic>> _dates = [
    {'day': 'Mon', 'date': 22},
    {'day': 'Tue', 'date': 23},
    {'day': 'Wed', 'date': 24},
    {'day': 'Thu', 'date': 25},
    {'day': 'Fri', 'date': 26},
    {'day': 'Sat', 'date': 27},
    {'day': 'Sun', 'date': 28},
  ];

  // Height per hour = 100 pixels
  final double _hourHeight = 100.0;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildDatePicker(),
            Expanded(child: _buildTimeline()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                CupertinoIcons.back,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Timeline',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_dates.length, (index) {
          final isSelected = index == _selectedDateIndex;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDateIndex = index);
            },
            child: Column(
              children: [
                Text(
                  _dates[index]['day'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${_dates[index]['date']}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimeline() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      children: [
        _buildDateLabel(),
        const SizedBox(height: 20),
        _buildTimelineGrid(),
      ],
    );
  }

  Widget _buildDateLabel() {
    final selectedDate = _dates[_selectedDateIndex];
    String fullDay = '';
    switch (selectedDate['day']) {
      case 'Mon':
        fullDay = 'Monday';
        break;
      case 'Tue':
        fullDay = 'Tuesday';
        break;
      case 'Wed':
        fullDay = 'Wednesday';
        break;
      case 'Thu':
        fullDay = 'Thursday';
        break;
      case 'Fri':
        fullDay = 'Friday';
        break;
      case 'Sat':
        fullDay = 'Saturday';
        break;
      case 'Sun':
        fullDay = 'Sunday';
        break;
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 18, color: Colors.black),
        children: [
          const TextSpan(
            text: 'January ',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(
            text: '${selectedDate['date']}, ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(
            text: fullDay,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineGrid() {
    return SizedBox(
      height: _hourHeight * 10, // 09:00 to 18:00+ extra space
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
            Expanded(
              child: Container(
                height: 1,
                color: Colors.grey.withOpacity(0.2),
                margin: const EdgeInsets.only(right: 8),
              ),
            ),
            Text(
              times[index],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    });
  }

  List<Widget> _buildEvents() {
    return [
      // Event 1: Florence circuit rewind (09:10 - 10:30) = 1h 20m = 1.33 hours
      _buildEventCard(
        topOffset: 0.17 * _hourHeight, // 10 minutes from 09:00
        height: 1.33 * _hourHeight,
        title: 'Rhinoplasty Masterclass',
        time: '09:10 am - 10:30 am',
        color: const Color(0xFFD4F4DD),
      ),

      // Event 2: Roman Slein - Zoom meeting (13:00 - 13:45) = 45m = 0.75 hours
      _buildActiveEventCard(
        topOffset: 4 * _hourHeight, // 4 hours from 09:00 = 13:00
        height: 0.75 * _hourHeight,
        title: 'Advanced Facelift Techniques',
        time: '13:00 pm - 13:45 pm',
        currentTime: '13:02',
      ),

      // Event 3: Octave agenda - Google meet (14:30 - 15:30) = 1 hour
      _buildEventCard(
        topOffset: 5.5 * _hourHeight, // 5.5 hours from 09:00 = 14:30
        height: 1.0 * _hourHeight,
        title: 'Body Contouring Workshop',
        time: '14:30 pm - 15:30 pm',
        color: const Color(0xFFD4F4DD),
      ),

      // Event 4: Gathering Shally's house (17:00 - 19:00) = 2 hours
      _buildEventCard(
        topOffset: 8 * _hourHeight, // 8 hours from 09:00 = 17:00
        height: 2.0 * _hourHeight,
        title: 'Networking Dinner',
        time: '17:00 pm - 19:00 pm',
        color: const Color(0xFFFFF4E6),
        showAvatar: true,
      ),
    ];
  }

  Widget _buildEventCard({
    required double topOffset,
    required double height,
    required String title,
    required String time,
    required Color color,
    bool showAvatar = false,
  }) {
    return Positioned(
      top: topOffset,
      left: 0,
      right: 65,
      height: height,
      child: Container(
        margin: const EdgeInsets.only(right: 5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showAvatar)
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.person_fill,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveEventCard({
    required double topOffset,
    required double height,
    required String title,
    required String time,
    required String currentTime,
  }) {
    return Positioned(
      top: topOffset,
      left: 0,
      right: 65,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 5),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
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
          ),
          // Left orange indicator
          Positioned(
            left: -30,
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
                        color: Colors.orange.withOpacity(0.3),
                        width: 4,
                      ),
                    ),
                  ),
                  Container(width: 8, height: 3, color: Colors.orange),
                ],
              ),
            ),
          ),
          // Right orange time badge
          Positioned(
            right: -75,
            top: 0,
            bottom: 0,
            child: Center(
              child: Row(
                children: [
                  Container(width: 15, height: 3, color: Colors.orange),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFFFA726),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: Text(
                      currentTime,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
