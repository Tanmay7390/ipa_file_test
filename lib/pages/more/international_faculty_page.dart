import 'package:flutter/cupertino.dart';
import 'package:flutter_test_22/components/page_scaffold.dart';

class InternationalFacultyPage extends StatelessWidget {
  const InternationalFacultyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPageScaffold(
      heading: 'International Faculty',
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
                  'CONFIRMED INTERNATIONAL FACULTY',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    color: CupertinoColors.systemGrey,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 16),
                _buildFacultyItem('Dr. Oswaldo Saldanha', 'Brazil'),
                _buildFacultyItem('Dr. Moustapha Hamdi', 'Belgium'),
                _buildFacultyItem('Dr. Chiara Botti', 'Italy'),
                _buildFacultyItem('Dr. Shailesh Vadodaria', 'UK'),
                _buildFacultyItem('Dr. Vakis Kontoes', 'Greece'),
                _buildFacultyItem('Dr. Francisco Villegas', 'Colombia'),
                _buildFacultyItem('Dr. Amin Kalaaji', 'Norway'),
                _buildFacultyItem('Dr. Tracy Pfeiffer', 'USA'),
                _buildFacultyItem('Dr. Eduardo Yap', 'Philippines'),
                _buildFacultyItem('Dr. Nora Nugent', 'USA'),
                _buildFacultyItem('Dr. Melinda Haws', 'USA'),
                SizedBox(height: 16),
                Text(
                  'And many more...',
                  style: TextStyle(
                    fontSize: 16,
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

  Widget _buildFacultyItem(String name, String country) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
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
              color: CupertinoColors.label,
            ),
          ),
          SizedBox(height: 4),
          Text(
            country,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.2,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }
}
