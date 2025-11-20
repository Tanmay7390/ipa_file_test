import 'package:flutter/cupertino.dart';
import 'package:aesurg26/components/page_scaffold.dart';

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
                _buildFacultyItem(context, 'Dr. Oswaldo Saldanha', 'Brazil'),
                _buildFacultyItem(context, 'Dr. Moustapha Hamdi', 'Belgium'),
                _buildFacultyItem(context, 'Dr. Chiara Botti', 'Italy'),
                _buildFacultyItem(context, 'Dr. Shailesh Vadodaria', 'UK'),
                _buildFacultyItem(context, 'Dr. Vakis Kontoes', 'Greece'),
                _buildFacultyItem(
                  context,
                  'Dr. Francisco Villegas',
                  'Colombia',
                ),
                _buildFacultyItem(context, 'Dr. Amin Kalaaji', 'Norway'),
                _buildFacultyItem(context, 'Dr. Tracy Pfeiffer', 'USA'),
                _buildFacultyItem(context, 'Dr. Eduardo Yap', 'Philippines'),
                _buildFacultyItem(context, 'Dr. Nora Nugent', 'USA'),
                _buildFacultyItem(context, 'Dr. Melinda Haws', 'USA'),
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

  Widget _buildFacultyItem(BuildContext context, String name, String country) {
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
              color: CupertinoTheme.of(context).textTheme.textStyle.color,
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
