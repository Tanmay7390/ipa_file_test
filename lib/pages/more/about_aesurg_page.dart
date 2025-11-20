import 'package:flutter/cupertino.dart';
import 'package:aesurg26/components/page_scaffold.dart';

class AboutAesurgPage extends StatelessWidget {
  const AboutAesurgPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPageScaffold(
      heading: 'About AESURG 2026',
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

                // Overview Section
                Text(
                  'OVERVIEW',
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
                  'AESURG 2026 is the 21st Annual Conference of the Indian Association of Aesthetic Plastic Surgeons (IAAPS), taking place January 22-26, 2026 at The Westin Mumbai Powai Lake.',
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
                  'Theme: "Initiate, Innovate, Inspire"',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Reflects our commitment to advancing aesthetic surgery through innovation, patient safety practices, and inspiring the next generation of plastic surgeons.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),

                SizedBox(height: 32),

                // Conference Highlights
                Text(
                  'CONFERENCE HIGHLIGHTS',
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
                  'Four days of resort life in the heart of Mumbai',
                ),
                _buildBulletPoint(context, 'Resident\'s flexi package options'),
                _buildBulletPoint(
                  context,
                  'Stalwart international faculty from around the globe',
                ),
                _buildBulletPoint(
                  context,
                  'Video workshops and unique dermatoplastic workshops',
                ),
                _buildBulletPoint(
                  context,
                  'Learn from national and international masters',
                ),
                _buildBulletPoint(
                  context,
                  'Fun-filled evenings with sumptuous dinners and cultural events',
                ),
                _buildBulletPoint(
                  context,
                  'Vendor exhibitions and networking opportunities',
                ),
                _buildBulletPoint(
                  context,
                  'Special competitions to encourage innovation',
                ),
                _buildBulletPoint(
                  context,
                  'Year-long social media campaign featuring past presidents',
                ),
                _buildBulletPoint(
                  context,
                  'Republic Day celebration with flag salutation',
                ),

                SizedBox(height: 32),

                // Organizing Committee
                Text(
                  'ORGANIZING COMMITTEE',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    color: CupertinoColors.systemGrey,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 16),
                _buildCommitteeItem(
                  context,
                  'President',
                  'Dr. Medha Bhave - Organizing Chair',
                ),
                _buildCommitteeItem(
                  context,
                  'Organizing Secretaries',
                  'Dr. Parag Telang, Dr. Preetish Bhavsar',
                ),
                _buildCommitteeItem(
                  context,
                  'Scientific Chairs',
                  'Dr. Vinod Vij, Dr. Viraj Tambwekar',
                ),
                _buildCommitteeItem(context, 'Treasurer', 'Dr. Ajay Hariani'),
                _buildCommitteeItem(
                  context,
                  'Joint Organizing Secretaries',
                  'Dr. Devayani Barve Venkat, Dr. Nikunj Mody',
                ),

                SizedBox(height: 24),

                Text(
                  'Committee Members:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                SizedBox(height: 12),
                _buildBulletPoint(
                  context,
                  'Dr. Umang Kothari - Souvenir Committee',
                ),
                _buildBulletPoint(
                  context,
                  'Dr. Eulalia Desouza - Souvenir and Gifts Committee',
                ),
                _buildBulletPoint(
                  context,
                  'Dr. Ashish Magdum - Scientific Committee and Workshops',
                ),
                _buildBulletPoint(
                  context,
                  'Dr. Shivprasad Date - Audiovisual Department',
                ),
                _buildBulletPoint(
                  context,
                  'Dr. Sudhanva Hemantkumar - Social Media Cell',
                ),

                SizedBox(height: 32),

                // Our Inspiration and Patrons
                Text(
                  'OUR INSPIRATION AND PATRONS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    color: CupertinoColors.systemGrey,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 16),
                _buildBulletPoint(context, 'Dr. Rakesh Kalra'),
                _buildBulletPoint(context, 'Dr. L. D. Dhami'),
                _buildBulletPoint(context, 'Dr. Anil Tibrewala'),
                _buildBulletPoint(context, 'Dr. Satish Arolkar'),

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

  Widget _buildCommitteeItem(BuildContext context, String role, String names) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.2,
              color: CupertinoTheme.of(context).textTheme.textStyle.color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            names,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
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
