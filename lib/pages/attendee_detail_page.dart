import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AttendeeDetailPage extends StatelessWidget {
  final Map<String, dynamic> attendee;

  const AttendeeDetailPage({super.key, required this.attendee});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text('Attendee Details'),
        previousPageTitle: 'Attendees',
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
              if (attendee['about'] != null && attendee['about'].toString().isNotEmpty)
                Container(
                  color: CupertinoColors.systemBackground,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: _buildAboutSection(),
                ),

              SizedBox(height: 16),

              // Additional Information section
              if (attendee['location'] != null || attendee['venue'] != null || attendee['organization'] != null)
                Container(
                  color: CupertinoColors.systemBackground,
                  child: _buildAdditionalInfoSection(),
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
              attendee['photo'] ?? '',
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
                  attendee['name'] ?? '',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  attendee['title'] ?? attendee['role'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.secondaryLabel,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (attendee['organization'] != null) ...[
                  SizedBox(height: 4),
                  Text(
                    attendee['organization'],
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
            attendee['about'] ?? '',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: CupertinoColors.label,
            ),
          ),
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

          // Organization
          if (attendee['organization'] != null)
            _buildInfoRow(
              icon: CupertinoIcons.building_2_fill,
              label: 'Organization',
              value: attendee['organization'],
            ),

          // Role/Position
          if (attendee['role'] != null)
            _buildInfoRow(
              icon: CupertinoIcons.briefcase_fill,
              label: 'Role',
              value: attendee['role'],
            ),

          // Location
          if (attendee['location'] != null)
            _buildInfoRow(
              icon: CupertinoIcons.location_solid,
              label: 'Location',
              value: attendee['location'],
            ),

          // Venue and Room
          if (attendee['venue'] != null)
            _buildInfoRow(
              icon: CupertinoIcons.placemark_fill,
              label: attendee['venue'],
              value: attendee['room'] ?? '',
            ),

          // Email
          if (attendee['email'] != null)
            _buildInfoRow(
              icon: CupertinoIcons.mail_solid,
              label: 'Email',
              value: attendee['email'],
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
}
