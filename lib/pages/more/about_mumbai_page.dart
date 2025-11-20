import 'package:flutter/cupertino.dart';
import 'package:aesurg26/components/page_scaffold.dart';

class AboutMumbaiPage extends StatelessWidget {
  const AboutMumbaiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPageScaffold(
      heading: 'About Mumbai',
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
                  'THE CITY OF DREAMS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Mumbai, the Financial Capital of India and Maharashtra\'s capital, is a vibrant metropolis that never sleeps. Known for its unique blend of tradition and modernity, Mumbai offers an unforgettable experience with its rich history, diverse culture, bustling markets, and world-class dining.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),

                SizedBox(height: 28),

                // Iconic Landmarks
                Text(
                  'ICONIC LANDMARKS & ATTRACTIONS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    color: CupertinoColors.systemGrey,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 12),
                _buildBulletPoint(
                  context,
                  'Gateway of India - iconic monument overlooking the Arabian Sea',
                ),
                _buildBulletPoint(
                  context,
                  'Marine Drive (Queen\'s Necklace) - scenic promenade perfect for evening walks',
                ),
                _buildBulletPoint(
                  context,
                  'Elephanta Caves - UNESCO World Heritage Site with ancient rock-cut temples',
                ),
                _buildBulletPoint(
                  context,
                  'Taj Mahal Palace Hotel - historic luxury landmark',
                ),
                _buildBulletPoint(
                  context,
                  'Chhatrapati Shivaji Maharaj Terminus - UNESCO World Heritage Victorian Gothic architecture',
                ),
                _buildBulletPoint(
                  context,
                  'Siddhivinayak Temple - revered Hindu temple',
                ),
                _buildBulletPoint(
                  context,
                  'Haji Ali Dargah - mosque and tomb on an islet',
                ),
                _buildBulletPoint(
                  context,
                  'Bandra-Worli Sea Link - engineering marvel connecting western suburbs',
                ),

                SizedBox(height: 28),

                // Shopping Destinations
                Text(
                  'SHOPPING DESTINATIONS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    color: CupertinoColors.systemGrey,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 12),
                _buildBulletPoint(
                  context,
                  'Colaba Causeway - street shopping and souvenirs',
                ),
                _buildBulletPoint(
                  context,
                  'Crawford Market - fresh produce and spices',
                ),
                _buildBulletPoint(
                  context,
                  'Linking Road, Bandra - fashion street',
                ),
                _buildBulletPoint(
                  context,
                  'Phoenix Palladium & Palladium Mall - luxury shopping',
                ),
                _buildBulletPoint(
                  context,
                  'Chor Bazaar - antiques and vintage finds',
                ),

                SizedBox(height: 28),

                // Culinary Experiences
                Text(
                  'CULINARY EXPERIENCES',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    color: CupertinoColors.systemGrey,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 12),
                _buildBulletPoint(
                  context,
                  'Vada Pav - Mumbai\'s iconic street food',
                ),
                _buildBulletPoint(
                  context,
                  'Pav Bhaji - spicy vegetable mash with bread',
                ),
                _buildBulletPoint(
                  context,
                  'Street Chaat - tangy and spicy snacks',
                ),
                _buildBulletPoint(
                  context,
                  'Bombay Sandwich - grilled street sandwich',
                ),
                _buildBulletPoint(context, 'Seafood at Mahim or Juhu Beach'),
                _buildBulletPoint(
                  context,
                  'Fine dining at heritage restaurants',
                ),
                _buildBulletPoint(
                  context,
                  'Irani cafés for authentic Mumbai experience',
                ),

                SizedBox(height: 28),

                // Cultural & Entertainment
                Text(
                  'CULTURAL & ENTERTAINMENT',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    color: CupertinoColors.systemGrey,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 12),
                _buildBulletPoint(context, 'Bollywood Film City Tours'),
                _buildBulletPoint(
                  context,
                  'Prithvi Theatre - live performances',
                ),
                _buildBulletPoint(
                  context,
                  'National Centre for the Performing Arts (NCPA)',
                ),
                _buildBulletPoint(
                  context,
                  'Art galleries in Kala Ghoda district',
                ),
                _buildBulletPoint(
                  context,
                  'Nightlife at Bandra and Lower Parel',
                ),

                SizedBox(height: 28),

                // For Accompanying Persons
                Text(
                  'FOR ACCOMPANYING PERSONS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    color: CupertinoColors.systemGrey,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Special curated programs include:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                SizedBox(height: 12),
                _buildBulletPoint(
                  context,
                  'Guided city tours covering major attractions',
                ),
                _buildBulletPoint(
                  context,
                  'Shopping expeditions to local markets and malls',
                ),
                _buildBulletPoint(
                  context,
                  'Cultural performances and entertainment',
                ),
                _buildBulletPoint(
                  context,
                  'Culinary tours and cooking classes',
                ),
                _buildBulletPoint(context, 'Spa and wellness experiences'),
                _buildBulletPoint(context, 'Heritage walks in South Mumbai'),
                _buildBulletPoint(
                  context,
                  'Day trips to nearby destinations (Lonavala, Alibaug)',
                ),

                SizedBox(height: 20),
                Text(
                  'Mumbai\'s warm hospitality, diverse experiences, and cosmopolitan charm ensure an unforgettable stay for all conference attendees and their families.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoColors.systemGrey,
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
