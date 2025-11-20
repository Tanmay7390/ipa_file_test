import 'package:flutter/cupertino.dart';
import 'package:flutter_test_22/components/page_scaffold.dart';

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
                  color: CupertinoColors.label,
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
                  color: CupertinoColors.label,
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
              _buildBulletPoint('Gateway of India - iconic monument overlooking the Arabian Sea'),
              _buildBulletPoint('Marine Drive (Queen\'s Necklace) - scenic promenade perfect for evening walks'),
              _buildBulletPoint('Elephanta Caves - UNESCO World Heritage Site with ancient rock-cut temples'),
              _buildBulletPoint('Taj Mahal Palace Hotel - historic luxury landmark'),
              _buildBulletPoint('Chhatrapati Shivaji Maharaj Terminus - UNESCO World Heritage Victorian Gothic architecture'),
              _buildBulletPoint('Siddhivinayak Temple - revered Hindu temple'),
              _buildBulletPoint('Haji Ali Dargah - mosque and tomb on an islet'),
              _buildBulletPoint('Bandra-Worli Sea Link - engineering marvel connecting western suburbs'),

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
              _buildBulletPoint('Colaba Causeway - street shopping and souvenirs'),
              _buildBulletPoint('Crawford Market - fresh produce and spices'),
              _buildBulletPoint('Linking Road, Bandra - fashion street'),
              _buildBulletPoint('Phoenix Palladium & Palladium Mall - luxury shopping'),
              _buildBulletPoint('Chor Bazaar - antiques and vintage finds'),

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
              _buildBulletPoint('Vada Pav - Mumbai\'s iconic street food'),
              _buildBulletPoint('Pav Bhaji - spicy vegetable mash with bread'),
              _buildBulletPoint('Street Chaat - tangy and spicy snacks'),
              _buildBulletPoint('Bombay Sandwich - grilled street sandwich'),
              _buildBulletPoint('Seafood at Mahim or Juhu Beach'),
              _buildBulletPoint('Fine dining at heritage restaurants'),
              _buildBulletPoint('Irani cafés for authentic Mumbai experience'),

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
              _buildBulletPoint('Bollywood Film City Tours'),
              _buildBulletPoint('Prithvi Theatre - live performances'),
              _buildBulletPoint('National Centre for the Performing Arts (NCPA)'),
              _buildBulletPoint('Art galleries in Kala Ghoda district'),
              _buildBulletPoint('Nightlife at Bandra and Lower Parel'),

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
                  color: CupertinoColors.label,
                ),
              ),
              SizedBox(height: 12),
              _buildBulletPoint('Guided city tours covering major attractions'),
              _buildBulletPoint('Shopping expeditions to local markets and malls'),
              _buildBulletPoint('Cultural performances and entertainment'),
              _buildBulletPoint('Culinary tours and cooking classes'),
              _buildBulletPoint('Spa and wellness experiences'),
              _buildBulletPoint('Heritage walks in South Mumbai'),
              _buildBulletPoint('Day trips to nearby destinations (Lonavala, Alibaug)'),

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
