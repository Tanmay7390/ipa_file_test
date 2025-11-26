import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:aesurg26/components/page_scaffold.dart';
import 'package:go_router/go_router.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;

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
            backgroundColor: CupertinoColors.systemBackground.resolveFrom(
              context,
            ),
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
                      cacheHeight: 800,
                      cacheWidth: 1200,
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
    // Use root navigator to ensure bottom tabs are hidden
    Navigator.of(context, rootNavigator: true).push(
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
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
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

  double _currentScale = 1.0;
  static const double _minScale = 0.5;
  static const double _maxScale = 5.0;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _currentScale = 1.0;
    });
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    // Toggle between 100% and 200% zoom on double tap
    final newScale = _currentScale < 2.0 ? 2.0 : 1.0;

    if (newScale == 1.0) {
      // Reset to original
      _transformationController.value = Matrix4.identity();
    } else {
      // Zoom in centered on tap position
      final position = details.localPosition;
      _transformationController.value = Matrix4.identity()
        ..translate(
          -position.dx * (newScale - 1),
          -position.dy * (newScale - 1),
        )
        ..scale(newScale);
    }

    setState(() {
      _currentScale = newScale;
    });
  }

  void _setZoomFromSlider(double value) {
    final matrix = Matrix4.identity()..scale(value);
    _transformationController.value = matrix;
    setState(() {
      _currentScale = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Detect system brightness for adaptive colors
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;

    // Adaptive colors
    final buttonBg = isDark
        ? CupertinoColors.white.withValues(alpha: 0.15)
        : CupertinoColors.black.withValues(alpha: 0.15);
    final buttonFg = isDark
        ? CupertinoColors.systemGrey
        : CupertinoColors.black;
    final sliderBg = isDark
        ? CupertinoColors.systemBackground.withValues(alpha: 0.15)
        : CupertinoColors.white.withValues(alpha: 0.15);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: Stack(
          children: [
            // Interactive floor map viewer with double-tap
            GestureDetector(
              onDoubleTapDown: _handleDoubleTapDown,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: _minScale,
                maxScale: _maxScale,
                panEnabled: true,
                scaleEnabled: true,
                boundaryMargin: EdgeInsets.all(double.infinity),
                onInteractionUpdate: (details) {
                  setState(() {
                    _currentScale = _transformationController.value
                        .getMaxScaleOnAxis();
                  });
                },
                child: Center(
                  child: Image.asset(
                    'assets/images/floormap.jpg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Top controls
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Reset zoom button
                  GestureDetector(
                    onTap: _resetZoom,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: buttonBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.arrow_counterclockwise,
                                size: 18,
                                color: buttonFg,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Reset',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: buttonFg,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: buttonBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.xmark,
                            size: 24,
                            color: buttonFg,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // iOS-style zoom slider at bottom
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: sliderBg,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Zoom out button
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            final newScale = (_currentScale - 0.5).clamp(
                              _minScale,
                              _maxScale,
                            );
                            _setZoomFromSlider(newScale);
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? CupertinoColors.systemGrey5.darkColor
                                  : CupertinoColors.systemGrey5,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.minus,
                              size: 20,
                              color: buttonFg,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        // iOS-style slider
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: CupertinoSlider(
                              value: _currentScale,
                              min: _minScale,
                              max: _maxScale,
                              divisions: 18,
                              activeColor: CupertinoColors.systemBlue,
                              thumbColor: CupertinoColors.white,
                              onChanged: _setZoomFromSlider,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        // Zoom in button
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            final newScale = (_currentScale + 0.5).clamp(
                              _minScale,
                              _maxScale,
                            );
                            _setZoomFromSlider(newScale);
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? CupertinoColors.systemGrey5.darkColor
                                  : CupertinoColors.systemGrey5,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              CupertinoIcons.plus,
                              size: 20,
                              color: buttonFg,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        // Zoom percentage with iOS styling
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            '${(_currentScale * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: buttonFg,
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                        ),
                      ],
                    ),
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
