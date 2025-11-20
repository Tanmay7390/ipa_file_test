import 'package:flutter/cupertino.dart';
import 'package:flutter_test_22/components/page_scaffold.dart';
import 'package:go_router/go_router.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPageScaffold(
      heading: 'More',
      hideSearch: true,
      isLoading: false,
      sliverList: SliverList(
        delegate: SliverChildListDelegate([
          SizedBox(height: 20),
          CupertinoListSection(
            topMargin: 0,
            margin: EdgeInsets.symmetric(horizontal: 0),
            children: [
              _buildMenuItem(
                context,
                title: 'About AESURG 2026',
                icon: CupertinoIcons.info_circle,
                onTap: () => context.push('/more/about-aesurg'),
              ),
              _buildMenuItem(
                context,
                title: 'Confirmed International Faculty',
                icon: CupertinoIcons.person_3,
                onTap: () => context.push('/more/international-faculty'),
              ),
              _buildMenuItem(
                context,
                title: 'Messages from Organizing Committee',
                icon: CupertinoIcons.chat_bubble_text,
                onTap: () => context.push('/more/committee-messages'),
              ),
              _buildMenuItem(
                context,
                title: 'Venue Information',
                icon: CupertinoIcons.map,
                onTap: () => context.push('/more/venue-info'),
              ),
              _buildMenuItem(
                context,
                title: 'About Mumbai - The City of Dreams',
                icon: CupertinoIcons.location,
                onTap: () => context.push('/more/about-mumbai'),
              ),
              _buildMenuItem(
                context,
                title: 'Contact Information',
                icon: CupertinoIcons.phone,
                onTap: () => context.push('/more/contact-info'),
              ),
              _buildMenuItem(
                context,
                title: 'Become an IAAPS Member',
                icon: CupertinoIcons.person_add,
                onTap: () => context.push('/more/iaaps-member'),
              ),
            ],
          ),
          SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return CupertinoListTile(
      leading: Icon(icon, color: CupertinoColors.systemGrey, size: 28),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'SF Pro Display',
          letterSpacing: 0.2,
        ),
      ),
      trailing: Icon(
        CupertinoIcons.chevron_right,
        color: CupertinoColors.systemGrey2,
        size: 20,
      ),
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
