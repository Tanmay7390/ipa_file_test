import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SpeakerDetailPage extends StatelessWidget {
  final Map<String, dynamic> speaker;

  const SpeakerDetailPage({super.key, required this.speaker});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text('Speaker Details'),
        previousPageTitle: 'Speakers',
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with photo and basic info
              Container(
                color: CupertinoColors.systemBackground,
                child: _buildHeader(),
              ),

              SizedBox(height: 16),

              // Action buttons
              Container(
                color: CupertinoColors.systemBackground,
                padding: EdgeInsets.symmetric(vertical: 16),
                child: _buildActionButtons(context),
              ),

              SizedBox(height: 16),

              // About section
              if (speaker['about'] != null && speaker['about'].toString().isNotEmpty)
                Container(
                  color: CupertinoColors.systemBackground,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: _buildAboutSection(),
                ),

              SizedBox(height: 16),

              // Additional Information section
              if (speaker['location'] != null || speaker['venue'] != null)
                Container(
                  color: CupertinoColors.systemBackground,
                  child: _buildAdditionalInfoSection(),
                ),

              SizedBox(height: 16),

              // Schedule section
              if (speaker['sessions'] != null && speaker['sessions'].isNotEmpty)
                Container(
                  color: CupertinoColors.systemBackground,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: _buildScheduleSection(),
                ),

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile photo
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              speaker['photo'] ?? '',
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      CupertinoIcons.person_fill,
                      size: 60,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
            ),
          ),
          SizedBox(width: 20),

          // Name and title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  speaker['name'] ?? '',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  speaker['title'] ?? speaker['specialty'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.secondaryLabel,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (speaker['company'] != null) ...[
                  SizedBox(height: 4),
                  Text(
                    speaker['company'],
                    style: TextStyle(
                      fontSize: 15,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFFF9500),
          borderRadius: BorderRadius.circular(12),
        ),
        child: CupertinoButton(
          padding: EdgeInsets.symmetric(vertical: 14),
          borderRadius: BorderRadius.circular(12),
          onPressed: () {
            // Handle message or meet action
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.chat_bubble_fill,
                size: 20,
                color: CupertinoColors.white,
              ),
              SizedBox(width: 8),
              Text(
                'Login to Message or Meet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ABOUT',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12),
          Text(
            speaker['about'] ?? '',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: CupertinoColors.label,
            ),
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ADDITIONAL INFORMATION',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemGrey,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(
                CupertinoIcons.chevron_up,
                size: 18,
                color: CupertinoColors.systemOrange,
              ),
            ],
          ),
          SizedBox(height: 16),

          // Location
          if (speaker['location'] != null)
            _buildInfoRow(
              icon: CupertinoIcons.location_solid,
              label: 'Location',
              value: speaker['location'],
            ),

          // Venue and Room
          if (speaker['venue'] != null)
            _buildInfoRow(
              icon: CupertinoIcons.building_2_fill,
              label: speaker['venue'],
              value: speaker['room'] ?? '',
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: CupertinoColors.systemGrey),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (value.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    final sessions = speaker['sessions'] as List<dynamic>;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SCHEDULE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 16),

          ...sessions.map((session) {
            if (session is Map<String, dynamic>) {
              return _buildSessionCard(session);
            } else if (session is String) {
              // Handle legacy string format
              return _buildLegacySessionCard(session);
            }
            return SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGrey5,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Row(
            children: [
              Icon(
                CupertinoIcons.calendar,
                size: 18,
                color: CupertinoColors.systemOrange,
              ),
              SizedBox(width: 8),
              Text(
                session['date'] ?? '',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemOrange,
                ),
              ),
              Spacer(),
              Text(
                '${session['sessionCount'] ?? 1} Session${(session['sessionCount'] ?? 1) > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Session title
          Text(
            session['title'] ?? '',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),

          SizedBox(height: 12),

          // Role badge
          if (session['role'] != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                session['role'],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.label,
                ),
              ),
            ),

          SizedBox(height: 12),

          // Time and location
          Row(
            children: [
              Icon(
                CupertinoIcons.clock,
                size: 16,
                color: CupertinoColors.systemGrey,
              ),
              SizedBox(width: 6),
              Text(
                session['time'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey2,
                ),
              ),
              if (session['addToCalendar'] == true) ...[
                Spacer(),
                Icon(
                  CupertinoIcons.calendar_badge_plus,
                  size: 18,
                  color: CupertinoColors.systemGrey,
                ),
              ],
            ],
          ),

          if (session['location'] != null) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  CupertinoIcons.location_solid,
                  size: 16,
                  color: CupertinoColors.systemGrey,
                ),
                SizedBox(width: 6),
                Text(
                  session['location'],
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey2,
                  ),
                ),
              ],
            ),
          ],

          // Tags/Categories
          if (session['tags'] != null && session['tags'].isNotEmpty) ...[
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (session['tags'] as List).map((tag) {
                Color tagColor;
                switch (tag.toString().toLowerCase()) {
                  case 'conference hall':
                    tagColor = Color(0xFFE9D5FF);
                    break;
                  case 'vip access':
                    tagColor = Color(0xFFD1FAE5);
                    break;
                  case 'interactive breakout room':
                    tagColor = Color(0xFFFCE7F3);
                    break;
                  case 'virtual':
                    tagColor = Color(0xFFDBEAFE);
                    break;
                  default:
                    tagColor = CupertinoColors.systemGrey6;
                }

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: tagColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag.toString(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegacySessionCard(String sessionTitle) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.calendar,
            size: 20,
            color: CupertinoColors.systemGrey,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              sessionTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
