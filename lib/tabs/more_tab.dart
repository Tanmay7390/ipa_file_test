import 'package:flutter/cupertino.dart';
import 'package:aesurg26/components/page_scaffold.dart';
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
          _buildFloorMapSection(context),
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

  Widget _buildFloorMapSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Floor Map',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'SF Pro Display',
            ),
          ),
          SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showFullScreenFloorMap(context),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/images/floormap.jpg',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          CupertinoIcons.fullscreen,
                          size: 20,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenFloorMap(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => _FloorMapViewer(),
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

class _FloorMapViewer extends StatefulWidget {
  const _FloorMapViewer();

  @override
  State<_FloorMapViewer> createState() => _FloorMapViewerState();
}

class _FloorMapViewerState extends State<_FloorMapViewer> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: Stack(
          children: [
            InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 5.0,
              panEnabled: true,
              scaleEnabled: true,
              child: Center(
                child: Image.asset(
                  'assets/images/floormap.jpg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 24,
                    color: CupertinoColors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
