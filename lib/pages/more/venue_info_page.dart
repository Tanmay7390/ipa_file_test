import 'package:flutter/cupertino.dart';
import 'package:flutter_test_22/components/page_scaffold.dart';

class VenueInfoPage extends StatelessWidget {
  const VenueInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPageScaffold(
      heading: 'Venue Information',
      hideSearch: true,
      isLoading: false,
      sliverList: SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
              // Venue Name
              Text(
                'The Westin Mumbai Powai Lake',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.2,
                  color: CupertinoColors.label,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'A luxurious 5-star resort nestled in the heart of Mumbai, overlooking the serene Powai Lake. The hotel offers world-class amenities, spacious conference facilities, and elegant accommodations perfect for an international conference.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.2,
                  color: CupertinoColors.label,
                ),
              ),

              SizedBox(height: 28),

              // Address
              Text(
                'ADDRESS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Display',
                  color: CupertinoColors.systemGrey,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'The Westin Mumbai Powai Lake\nIAC Road, Near Indian Institute of Technology (IIT)\nPowai, Mumbai, Maharashtra 400087\nIndia',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.2,
                  color: CupertinoColors.label,
                ),
              ),

              SizedBox(height: 28),

              // Contact
              Text(
                'HOTEL CONTACT',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Display',
                  color: CupertinoColors.systemGrey,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Phone: +91-22-6693-4444\nWebsite: www.marriott.com',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.2,
                  color: CupertinoColors.label,
                ),
              ),

              SizedBox(height: 28),

              // Check-in/Check-out
              Text(
                'CHECK-IN / CHECK-OUT TIMINGS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Display',
                  color: CupertinoColors.systemGrey,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Check-in: 2:00 PM (14:00 hrs) - January 22, 2026\nCheck-out: 12:00 Noon - January 26, 2026\n\nEarly check-in and late check-out subject to availability and additional charges.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.2,
                  color: CupertinoColors.label,
                ),
              ),

              SizedBox(height: 28),

              // From Airports
              Text(
                'FROM CHHATRAPATI SHIVAJI MAHARAJ INTERNATIONAL AIRPORT (TERMINAL 2)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Display',
                  color: CupertinoColors.systemGrey,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Distance: Approximately 7 km\nTravel Time: 15-20 minutes',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.2,
                  color: CupertinoColors.label,
                ),
              ),
              SizedBox(height: 8),
              _buildBulletPoint('Pre-paid taxi counters available at airport'),
              _buildBulletPoint('App-based cabs (Uber/Ola)'),
              _buildBulletPoint('Hotel transfer (can be arranged on request, charges apply)'),
              _buildBulletPoint('Approximate fare: ₹300-500'),

              SizedBox(height: 24),

              Text(
                'FROM MUMBAI DOMESTIC AIRPORT (TERMINAL 1)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Display',
                  color: CupertinoColors.systemGrey,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Distance: Approximately 4 km\nTravel Time: 10-15 minutes',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.2,
                  color: CupertinoColors.label,
                ),
              ),
              SizedBox(height: 8),
              _buildBulletPoint('Easy access via taxi or app-based cabs'),
              _buildBulletPoint('Approximate fare: ₹200-350'),

              SizedBox(height: 28),

              // From Railway Stations
              Text(
                'FROM MAJOR RAILWAY STATIONS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Display',
                  color: CupertinoColors.systemGrey,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 12),
              _buildBulletPoint('Mumbai Central: 18 km (35-40 minutes)'),
              _buildBulletPoint('Chhatrapati Shivaji Terminus (CST): 24 km (45-50 minutes)'),
              _buildBulletPoint('Bandra Terminus: 12 km (25-30 minutes)'),

              SizedBox(height: 20),

              Text(
                'Important Note: Airport transfers, railway station pickups, and local transportation are NOT included in the conference package and must be arranged separately by delegates.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.2,
                  color: CupertinoColors.systemGrey,
                ),
              ),

              SizedBox(height: 28),

              // Hotel Amenities
              Text(
                'HOTEL AMENITIES',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Display',
                  color: CupertinoColors.systemGrey,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 12),
              _buildBulletPoint('Multiple dining restaurants with diverse cuisines'),
              _buildBulletPoint('State-of-the-art conference and banquet facilities'),
              _buildBulletPoint('Heavenly Spa by Westin - wellness center'),
              _buildBulletPoint('Outdoor swimming pool overlooking Powai Lake'),
              _buildBulletPoint('WestinWORKOUT® Fitness Studio'),
              _buildBulletPoint('Business center with high-speed WiFi'),
              _buildBulletPoint('24-hour room service'),
              _buildBulletPoint('Concierge services for city tours and activities'),
              _buildBulletPoint('Ample parking facilities'),

                SizedBox(height: 40),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              '• ',
              style: TextStyle(
                fontSize: 18,
                height: 1.3,
                fontFamily: 'SF Pro Display',
                letterSpacing: 0.2,
                color: CupertinoColors.label,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                fontFamily: 'SF Pro Display',
                letterSpacing: 0.2,
                color: CupertinoColors.label,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
