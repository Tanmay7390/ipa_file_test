import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rajapsicon/components/page_scaffold.dart';
// import 'package:rajapsicon/pages/chat_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:rajapsicon/pages/company_representative_detail_page.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../apis/providers/exhibitors_provider.dart';

class ExhibitorDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> exhibitor;

  const ExhibitorDetailPage({super.key, required this.exhibitor});

  @override
  ConsumerState<ExhibitorDetailPage> createState() =>
      _ExhibitorDetailPageState();
}

class _ExhibitorDetailPageState extends ConsumerState<ExhibitorDetailPage> {
  bool _isAboutExpanded = false;
  bool _isVideoExpanded = true;
  bool _isCompanyRepExpanded = false;
  bool _isDocumentsExpanded = false;
  FlickManager? _flickManager;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    // Video initialization will be handled when data is loaded
  }

  void _initializeVideoPlayer(String videoUrl) {
    if (_flickManager != null) return;

    try {
      _flickManager = FlickManager(
        videoPlayerController: VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
        ),
        autoPlay: false,
      );

      if (mounted) {
        setState(() {
          _videoError = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _videoError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _flickManager?.dispose();
    super.dispose();
  }

  void _showMeetingSheet(String exhibitorName) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) =>
          _MeetingFormSheet(exhibitorName: exhibitorName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exhibitorId = widget.exhibitor['id']?.toString() ?? '';

    // Use provider to fetch fresh details
    final exhibitorAsync = ref.watch(exhibitorDetailProvider(exhibitorId));

    return exhibitorAsync.when(
      data: (exhibitorData) {
        final exhibitorMap = exhibitorData.toJson();

        // Initialize video if available
        if (exhibitorData.media?.type == 'VIDEO' &&
            exhibitorData.media?.url != null) {
          _initializeVideoPlayer(exhibitorData.media!.url!);
        }

        return _buildContent(context, exhibitorMap);
      },
      loading: () => CustomPageScaffold(
        heading: 'Exhibitor Details',
        hideSearch: true,
        isLoading: true,
        hideLargeTitle: true,
        sliverList: SliverList(delegate: SliverChildListDelegate([])),
      ),
      error: (error, stack) => CustomPageScaffold(
        heading: 'Exhibitor Details',
        hideSearch: true,
        isLoading: false,
        hideLargeTitle: true,
        sliverList: SliverList(
          delegate: SliverChildListDelegate([
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Failed to load details'),
                    SizedBox(height: 16),
                    CupertinoButton(
                      child: Text('Retry'),
                      onPressed: () =>
                          ref.refresh(exhibitorDetailProvider(exhibitorId)),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> exhibitor) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CustomPageScaffold(
      heading: 'Exhibitor Details',
      hideSearch: true,
      isLoading: false,
      hideLargeTitle: true,
      sliverList: SliverList(
        delegate: SliverChildListDelegate([
          // Header with photo and basic info
          Container(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: _buildHeader(isDark, exhibitor),
          ),

          // Action buttons
          // Container(
          //   color: CupertinoColors.systemBackground.resolveFrom(context),
          //   padding: EdgeInsets.only(top: 12, bottom: 12, left: 20, right: 20),
          //   child: _buildActionButtons(context, exhibitor),
          // ),
          _buildSeparator(context),

          // About section
          if (exhibitor['about'] != null &&
              exhibitor['about'].toString().isNotEmpty)
            Container(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              padding: EdgeInsets.only(top: 12, bottom: 12),
              child: _buildAboutSection(isDark, exhibitor),
            ),

          // _buildSeparator(context),

          // Video section
          // Container(
          //   color: CupertinoColors.systemBackground.resolveFrom(context),
          //   padding: EdgeInsets.zero,
          //   child: _buildVideoSection(isDark),
          // ),

          // _buildSeparator(context),

          // Company Representative section
          // Container(
          //   color: CupertinoColors.systemBackground.resolveFrom(context),
          //   padding: EdgeInsets.zero,
          //   child: _buildCompanyRepSection(isDark),
          // ),

          // _buildSeparator(context),

          // Documents section
          // Container(
          //   color: CupertinoColors.systemBackground.resolveFrom(context),
          //   padding: EdgeInsets.zero,
          //   child: _buildDocumentsSection(isDark),
          // ),
          SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildSeparator(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 0.2,
        color: CupertinoColors.separator.resolveFrom(context),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Map<String, dynamic> exhibitor) {
    final activeColor = isDark ? Color(0xFF23C061) : Color(0xFF21AA62);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile photo
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: CupertinoColors.systemGrey.withOpacity(0.5),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: exhibitor['photo'] != null && exhibitor['photo'].isNotEmpty
                  ? Image.network(
                      exhibitor['photo'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset('assets/images/midcoin.png'),
                    )
                  : Image.asset('assets/images/midcoin.png'),
            ),
          ),
          SizedBox(width: 20),

          // Exhibitor details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exhibitor name
                Text(
                  exhibitor['companyName'] ?? exhibitor['name'] ?? '',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                SizedBox(height: 8),

                // Sponsor type and Exhibitor badges
                Row(
                  children: [
                    if (exhibitor['sponsorType'] != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFE8E0F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          exhibitor['sponsorType'] ?? 'Sponsor',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7B5FC7),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SF Pro Display',
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    SizedBox(width: 8),
                    // Exhibitor badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: activeColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Exhibitor',
                        style: TextStyle(
                          fontSize: 13,
                          color: activeColor,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SF Pro Display',
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Social media buttons
                if (exhibitor['socialMedia'] != null)
                  Row(
                    children: [
                      if (exhibitor['socialMedia']['facebook'] != null)
                        _buildSocialButton(
                          FontAwesomeIcons.facebookF,
                          Color(0xFF1877F2),
                          exhibitor['socialMedia']['facebook'],
                        ),
                      if (exhibitor['socialMedia']['twitter'] != null)
                        _buildSocialButton(
                          FontAwesomeIcons.twitter,
                          Color(0xFF1DA1F2),
                          exhibitor['socialMedia']['twitter'],
                        ),
                      if (exhibitor['socialMedia']['instagram'] != null)
                        _buildSocialButton(
                          FontAwesomeIcons.instagram,
                          Color(0xFFE1306C),
                          exhibitor['socialMedia']['instagram'],
                        ),
                      if (exhibitor['socialMedia']['linkedin'] != null)
                        _buildSocialButton(
                          FontAwesomeIcons.linkedinIn,
                          Color(0xFF0077B5),
                          exhibitor['socialMedia']['linkedin'],
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color, String url) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _launchUrl(url),
          child: FaIcon(icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Widget _buildActionButtons(
    BuildContext context,
    Map<String, dynamic> exhibitor,
  ) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Color(0xFF23C061) : Color(0xFF21AA62);

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CupertinoButton(
              padding: EdgeInsets.symmetric(vertical: 12),
              borderRadius: BorderRadius.circular(12),
              onPressed: () =>
                  _showMeetingSheet(exhibitor['companyName'] ?? ''),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.calendar_badge_plus,
                    size: 18,
                    color: CupertinoColors.white,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Book Demo',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                      color: CupertinoColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CupertinoButton(
              padding: EdgeInsets.symmetric(vertical: 12),
              borderRadius: BorderRadius.circular(12),
              onPressed: () {
                // Navigator.of(context).push(
                //   CupertinoPageRoute(
                //     builder: (context) => ChatPage(
                //       userName:
                //           exhibitor['companyName'] ?? exhibitor['name'] ?? '',
                //       userPhoto: exhibitor['photo'],
                //     ),
                //   ),
                // );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.chat_bubble_fill,
                    size: 18,
                    color: CupertinoColors.white,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Message',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                      color: CupertinoColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            color: activeColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: CupertinoButton(
            padding: EdgeInsets.all(12),
            borderRadius: BorderRadius.circular(50),
            onPressed: () {},
            child: Icon(CupertinoIcons.star, size: 22, color: activeColor),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(bool isDark, Map<String, dynamic> exhibitor) {
    final aboutText = exhibitor['about'] ?? '';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ABOUT',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey.resolveFrom(context),
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final textPainter = TextPainter(
                text: TextSpan(
                  text: aboutText,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                  ),
                ),
                maxLines: 3,
                textDirection: TextDirection.ltr,
              )..layout(maxWidth: constraints.maxWidth);

              final isTextOverflow = textPainter.didExceedMaxLines;

              if (!isTextOverflow || _isAboutExpanded) {
                return Text(
                  aboutText,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                  ),
                );
              }

              // Calculate where to place "more"
              final span = TextSpan(
                text: aboutText,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.2,
                ),
              );

              final tp = TextPainter(
                text: span,
                maxLines: 3,
                textDirection: TextDirection.ltr,
              )..layout(maxWidth: constraints.maxWidth);

              // Calculate text that fits in 3 lines minus space for "more"
              final moreWidth = 50.0; // Approximate width for "more"
              final truncatePos = tp.getPositionForOffset(
                Offset(constraints.maxWidth - moreWidth, tp.size.height - 5),
              );

              final displayText = aboutText.substring(0, truncatePos.offset);
              final trimmedText = displayText.trimRight();

              return RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: trimmedText,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: CupertinoTheme.of(
                          context,
                        ).textTheme.textStyle.color,
                        fontFamily: 'SF Pro Display',
                        letterSpacing: 0.2,
                      ),
                    ),
                    TextSpan(text: '... '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isAboutExpanded = true;
                          });
                        },
                        child: Text(
                          'more',
                          style: TextStyle(
                            fontSize: 16,
                            color: CupertinoColors.systemGrey.resolveFrom(
                              context,
                            ),
                            fontFamily: 'SF Pro Display',
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (_isAboutExpanded)
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isAboutExpanded = false;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'see less',
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoSection(bool isDark) {
    final activeColor = isDark ? Color(0xFF23C061) : Color(0xFF21AA62);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                _isVideoExpanded = !_isVideoExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'VIDEO',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                  ),
                ),
                Icon(
                  _isVideoExpanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 18,
                  color: activeColor,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isVideoExpanded
                ? Column(
                    children: [
                      SizedBox(height: 12),
                      // Video player
                      if (_videoError)
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemRed.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: CupertinoColors.systemRed.withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.exclamationmark_triangle,
                                  color: CupertinoColors.systemRed,
                                  size: 40,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Video not available',
                                  style: TextStyle(
                                    color: CupertinoColors.systemRed,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_flickManager != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FlickVideoPlayer(
                            flickManager: _flickManager!,
                            flickVideoWithControls: FlickVideoWithControls(
                              controls: FlickPortraitControls(
                                progressBarSettings: FlickProgressBarSettings(
                                  playedColor: Color(0xFF21AA62),
                                  handleColor: Color(0xFF21AA62),
                                  bufferedColor: Colors.grey.withValues(
                                    alpha: 0.5,
                                  ),
                                  backgroundColor: Colors.grey.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: CupertinoColors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: CupertinoActivityIndicator(
                              color: activeColor,
                            ),
                          ),
                        ),
                    ],
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyRepSection(bool isDark) {
    final activeColor = isDark ? Color(0xFF23C061) : Color(0xFF21AA62);

    // Mock company representatives data
    final List<Map<String, dynamic>> representatives = [
      {
        'name': 'John Anderson',
        'role': 'Sales Manager',
        'photo': 'https://via.placeholder.com/60',
        'about':
            'Experienced sales professional with 10+ years in the industry.',
        'email': 'john.anderson@company.com',
        'phone': '+1 234 567 8900',
      },
      {
        'name': 'Sarah Williams',
        'role': 'Product Specialist',
        'photo': 'https://via.placeholder.com/60',
        'about': 'Product expert with deep knowledge of our solutions.',
        'email': 'sarah.williams@company.com',
        'phone': '+1 234 567 8901',
      },
      {
        'name': 'Michael Chen',
        'role': 'Technical Support',
        'photo': 'https://via.placeholder.com/60',
        'about': 'Technical specialist providing comprehensive support.',
        'email': 'michael.chen@company.com',
        'phone': '+1 234 567 8902',
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                _isCompanyRepExpanded = !_isCompanyRepExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'COMPANY REPRESENTATIVE',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                  ),
                ),
                Icon(
                  _isCompanyRepExpanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 18,
                  color: activeColor,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isCompanyRepExpanded
                ? Column(
                    children: [
                      SizedBox(height: 12),
                      ...representatives.map(
                        (rep) => _buildRepresentativeCard(rep, isDark),
                      ),
                    ],
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildRepresentativeCard(
    Map<String, dynamic> representative,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) =>
                CompanyRepresentativeDetailPage(representative: representative),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Representative icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey3.resolveFrom(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CupertinoIcons.person_fill,
                color: CupertinoColors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            // Representative info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    representative['name'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                      color: CupertinoTheme.of(
                        context,
                      ).textTheme.textStyle.color,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    representative['role'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow icon
            Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey.resolveFrom(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsSection(bool isDark) {
    final activeColor = isDark ? Color(0xFF23C061) : Color(0xFF21AA62);

    // Mock documents data - in a real app, this would come from the exhibitor data
    final List<Map<String, String>> documents = [
      {
        'name': 'Company Brochure',
        'type': 'PDF',
        'size': '2.4 MB',
        'icon': 'doc.fill',
      },
      // {
      //   'name': 'Product Catalog 2026',
      //   'type': 'PDF',
      //   'size': '5.8 MB',
      //   'icon': 'doc.fill',
      // },
      // {
      //   'name': 'Technical Specifications',
      //   'type': 'PDF',
      //   'size': '1.2 MB',
      //   'icon': 'doc.fill',
      // },
      // {
      //   'name': 'Certification Documents',
      //   'type': 'PDF',
      //   'size': '890 KB',
      //   'icon': 'doc.fill',
      // },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                _isDocumentsExpanded = !_isDocumentsExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DOCUMENTS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                  ),
                ),
                Icon(
                  _isDocumentsExpanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 18,
                  color: activeColor,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isDocumentsExpanded
                ? Column(
                    children: [
                      SizedBox(height: 5),
                      ...documents.map(
                        (doc) => _buildDocumentCard(doc, isDark),
                      ),
                    ],
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, String> document, bool isDark) {
    final activeColor = isDark ? Color(0xFF23C061) : Color(0xFF21AA62);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Document icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey3.resolveFrom(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              CupertinoIcons.doc_fill,
              color: CupertinoColors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          // Document info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document['name'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${document['type']} • ${document['size']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          // Download button
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              // TODO: Handle document download
            },
            child: Icon(
              CupertinoIcons.arrow_down_circle_fill,
              color: activeColor,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetingFormSheet extends StatefulWidget {
  final String exhibitorName;

  const _MeetingFormSheet({required this.exhibitorName});

  @override
  State<_MeetingFormSheet> createState() => _MeetingFormSheetState();
}

class _MeetingFormSheetState extends State<_MeetingFormSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isVideoMeeting = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Meeting - ${widget.exhibitorName}';
    _dateController.text = '23/01/2026';
    _startTimeController.text = '10:00 AM';
    _endTimeController.text = '10:30 AM';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Color(0xFF23C061) : Color(0xFF21AA62);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey3.resolveFrom(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Suggest a Meeting',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                fontFamily: 'SF Pro Display',
                letterSpacing: 0.2,
                color: CupertinoTheme.of(context).textTheme.textStyle.color,
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Title (required)',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                      color: CupertinoTheme.of(
                        context,
                      ).textTheme.textStyle.color,
                    ),
                  ),
                  SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _titleController,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                    ),
                  ),

                  SizedBox(height: 20),

                  // Date
                  Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                      color: CupertinoTheme.of(
                        context,
                      ).textTheme.textStyle.color,
                    ),
                  ),
                  SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _dateController,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffix: Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        CupertinoIcons.calendar,
                        color: CupertinoColors.systemGrey.resolveFrom(context),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                    ),
                  ),

                  SizedBox(height: 20),

                  // Time
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start Time',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'SF Pro Display',
                                letterSpacing: 0.2,
                                color: CupertinoTheme.of(
                                  context,
                                ).textTheme.textStyle.color,
                              ),
                            ),
                            SizedBox(height: 8),
                            CupertinoTextField(
                              controller: _startTimeController,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey6.resolveFrom(
                                  context,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffix: Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Icon(
                                  CupertinoIcons.clock,
                                  color: CupertinoColors.systemGrey.resolveFrom(
                                    context,
                                  ),
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'SF Pro Display',
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End Time',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'SF Pro Display',
                                letterSpacing: 0.2,
                                color: CupertinoTheme.of(
                                  context,
                                ).textTheme.textStyle.color,
                              ),
                            ),
                            SizedBox(height: 8),
                            CupertinoTextField(
                              controller: _endTimeController,
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey6.resolveFrom(
                                  context,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffix: Padding(
                                padding: EdgeInsets.only(right: 12),
                                child: Icon(
                                  CupertinoIcons.clock,
                                  color: CupertinoColors.systemGrey.resolveFrom(
                                    context,
                                  ),
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'SF Pro Display',
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Video Meeting Checkbox
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isVideoMeeting = !_isVideoMeeting;
                      });
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _isVideoMeeting
                                  ? activeColor
                                  : CupertinoColors.systemGrey.resolveFrom(
                                      context,
                                    ),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            color: _isVideoMeeting
                                ? activeColor
                                : Colors.transparent,
                          ),
                          child: _isVideoMeeting
                              ? Icon(
                                  CupertinoIcons.check_mark,
                                  size: 16,
                                  color: CupertinoColors.white,
                                )
                              : null,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Video Meeting',
                          style: TextStyle(
                            fontSize: 17,
                            fontFamily: 'SF Pro Display',
                            letterSpacing: 0.2,
                            color: CupertinoTheme.of(
                              context,
                            ).textTheme.textStyle.color,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Location
                  Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                      color: CupertinoTheme.of(
                        context,
                      ).textTheme.textStyle.color,
                    ),
                  ),
                  SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _locationController,
                    placeholder: 'Suggest a location',
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                    ),
                  ),

                  SizedBox(height: 20),

                  // Note
                  Text(
                    'Note',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                      color: CupertinoTheme.of(
                        context,
                      ).textTheme.textStyle.color,
                    ),
                  ),
                  SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _noteController,
                    placeholder: 'Add a message',
                    padding: EdgeInsets.all(16),
                    maxLines: 4,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                    ),
                  ),

                  SizedBox(height: 30),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          borderRadius: BorderRadius.circular(12),
                          color: CupertinoColors.systemGrey6.resolveFrom(
                            context,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'SF Pro Display',
                              letterSpacing: 0.2,
                              color: CupertinoTheme.of(
                                context,
                              ).textTheme.textStyle.color,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: CupertinoButton(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          borderRadius: BorderRadius.circular(12),
                          color: activeColor,
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Handle send invite
                          },
                          child: Text(
                            'Send Invite',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'SF Pro Display',
                              letterSpacing: 0.2,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
