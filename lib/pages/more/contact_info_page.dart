import 'package:flutter/cupertino.dart';
import 'package:aesurg26/components/page_scaffold.dart';

class ContactInfoPage extends StatelessWidget {
  const ContactInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPageScaffold(
      heading: 'Contact Information',
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
                // Conference Secretariat
                Text(
                  'CONFERENCE SECRETARIAT',
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
                  'VAMA Events Private Limited',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Kohinoor Square Phase I, B Wing Office No. 1004, 10th Floor\nN.C. Kelkar Road, Shivaji Park\nDadar West, Mumbai - 400028\nMaharashtra, India',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),

                SizedBox(height: 28),

                // Phone Numbers
                Text(
                  'PHONE NUMBERS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    color: CupertinoColors.systemGrey,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 12),
                _buildBulletPoint(context, '+91-22-35406187'),
                _buildBulletPoint(context, '+91-22-35106391'),
                _buildBulletPoint(context, '+91-22-35406576'),
                _buildBulletPoint(context, '+91-22-35406579'),

                SizedBox(height: 28),

                // Email
                Text(
                  'GENERAL EMAIL',
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
                  'info@aesurg2026.com',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),

                SizedBox(height: 28),

                // Conference Coordinators
                Text(
                  'CONFERENCE COORDINATORS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    color: CupertinoColors.systemGrey,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 12),
                _buildContactItem(
                  context,
                  'Janhavi Bhosle - Vama Events',
                  '+91-99309 26153',
                ),
                _buildContactItem(
                  context,
                  'Vaibhav Murkar - Vama Events',
                  '+91-99309 26116',
                ),

                SizedBox(height: 28),

                // Organizing Committee
                Text(
                  'ORGANIZING COMMITTEE DIRECT CONTACTS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    color: CupertinoColors.systemGrey,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 12),
                _buildContactItem(
                  context,
                  'President / Organizing Chair - Dr. Medha Bhave',
                  'prezaesurg26@gmail.com',
                ),
                _buildContactItem(
                  context,
                  'Organizing Secretary - Dr. Parag Telang',
                  'osaesurg26@gmail.com',
                ),
                _buildContactItem(
                  context,
                  'Organizing Secretary - Dr. Preetish Bhavsar',
                  'ospaesurg26@gmail.com',
                ),
                _buildContactItem(
                  context,
                  'Scientific Chair - Dr. Vinod Vij',
                  'sciaesurg2026@gmail.com',
                ),
                _buildContactItem(
                  context,
                  'Treasurer - Dr. Ajay Hariani',
                  'treasurer.aesurg26@gmail.com',
                ),

                SizedBox(height: 28),

                // For Specific Queries
                Text(
                  'FOR SPECIFIC QUERIES',
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
                  'Registration & Payment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Contact: Janhavi Bhosle / Vaibhav Murkar\nEmail: info@aesurg2026.com\nPhone: +91-99309 26153 / +91-99309 26116',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),

                SizedBox(height: 16),

                Text(
                  'Scientific Program',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Email: sciaesurg2026@gmail.com',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),

                SizedBox(height: 16),

                Text(
                  'Accommodation & Travel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Email: info@aesurg2026.com',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),

                SizedBox(height: 16),

                Text(
                  'Sponsorship & Exhibition',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Email: info@aesurg2026.com',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),

                SizedBox(height: 16),

                Text(
                  'General Inquiries',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Email: info@aesurg2026.com\nPhone: +91-22-35406187',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),

                SizedBox(height: 28),

                // Office Hours
                Text(
                  'OFFICE HOURS',
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
                  'Monday to Saturday: 10:00 AM - 6:00 PM IST\nSunday: Closed',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),

                SizedBox(height: 40),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
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
                color: CupertinoTheme.of(context).textTheme.textStyle.color,
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
                color: CupertinoTheme.of(context).textTheme.textStyle.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(BuildContext context, String name, String contact) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.2,
              color: CupertinoTheme.of(context).textTheme.textStyle.color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            contact,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.2,
              color: CupertinoTheme.of(context).textTheme.textStyle.color,
            ),
          ),
        ],
      ),
    );
  }
}
