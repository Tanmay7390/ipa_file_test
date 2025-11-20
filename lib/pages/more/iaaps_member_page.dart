import 'package:flutter/cupertino.dart';
import 'package:aesurg26/components/page_scaffold.dart';

class IaapsMemberPage extends StatelessWidget {
  const IaapsMemberPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPageScaffold(
      heading: 'IAAPS Membership',
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
                Text(
                  'Join the Indian Association of Aesthetic Plastic Surgeons (IAAPS) to avail exclusive benefits:',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),

                SizedBox(height: 32),

                // Membership Benefits
                Text(
                  'MEMBERSHIP BENEFITS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    color: CupertinoColors.systemGrey,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 16),
                _buildBulletPoint(
                  context,
                  'Discounted conference registration rates',
                ),
                _buildBulletPoint(
                  context,
                  'Access to members-only scientific content',
                ),
                _buildBulletPoint(
                  context,
                  'Networking opportunities with leading aesthetic surgeons',
                ),
                _buildBulletPoint(
                  context,
                  'Regular updates on advances in aesthetic surgery',
                ),
                _buildBulletPoint(
                  context,
                  'Participation in IAAPS educational programs',
                ),
                _buildBulletPoint(
                  context,
                  'Subscription to IAAPS publications',
                ),
                _buildBulletPoint(
                  context,
                  'Voting rights in association matters',
                ),

                SizedBox(height: 32),

                // How to Join
                Text(
                  'HOW TO JOIN',
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
                  'To become a member or for membership queries:',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Website: www.iaaps.org',
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
                  'Email: info@iaaps.org',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
}
