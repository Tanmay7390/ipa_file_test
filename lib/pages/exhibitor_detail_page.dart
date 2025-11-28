import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:aesurg26/components/page_scaffold.dart';
import 'package:aesurg26/pages/chat_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:aesurg26/pages/company_representative_detail_page.dart';

class ExhibitorDetailPage extends StatefulWidget {
  final Map<String, dynamic> exhibitor;

  const ExhibitorDetailPage({super.key, required this.exhibitor});

  @override
  State<ExhibitorDetailPage> createState() => _ExhibitorDetailPageState();
}

class _ExhibitorDetailPageState extends State<ExhibitorDetailPage> {
  bool _isAboutExpanded = false;
  bool _isVideoExpanded = true;
  bool _isCompanyRepExpanded = false;
  bool _isDocumentsExpanded = false;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      // Try to load network video (more reliable than asset for testing)
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        ),
      );

      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Color(0xFF21AA62),
          handleColor: Color(0xFF21AA62),
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey.withValues(alpha: 0.5),
        ),
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
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _showMeetingSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) =>
          _MeetingFormSheet(exhibitorName: widget.exhibitor['name'] ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            child: _buildHeader(isDark),
          ),

          // Action buttons
          Container(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            padding: EdgeInsets.only(top: 12, bottom: 12, left: 20, right: 20),
            child: _buildActionButtons(context),
          ),

          _buildSeparator(context),

          // About section
          if (widget.exhibitor['about'] != null &&
              widget.exhibitor['about'].toString().isNotEmpty)
            Container(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              padding: EdgeInsets.only(top: 12, bottom: 12),
              child: _buildAboutSection(isDark),
            ),

          _buildSeparator(context),

          // Video section
          Container(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            padding: EdgeInsets.zero,
            child: _buildVideoSection(isDark),
          ),

          _buildSeparator(context),

          // Company Representative section
          Container(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            padding: EdgeInsets.zero,
            child: _buildCompanyRepSection(isDark),
          ),

          _buildSeparator(context),

          // Documents section
          Container(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            padding: EdgeInsets.zero,
            child: _buildDocumentsSection(isDark),
          ),

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

  Widget _buildHeader(bool isDark) {
    final activeColor = isDark ? Color(0xFF23C061) : Color(0xFF21AA62);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile photo
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              widget.exhibitor['photo'] ?? '',
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5.resolveFrom(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  CupertinoIcons.person_fill,
                  size: 60,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                ),
              ),
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
                  widget.exhibitor['companyName'] ??
                      widget.exhibitor['name'] ??
                      '',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                SizedBox(height: 8),

                // Location/Conference Room
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.location_solid,
                      size: 16,
                      color: activeColor,
                    ),
                    SizedBox(width: 4),
                    Text(
                      widget.exhibitor['location'] ?? 'Conference Room 1',
                      style: TextStyle(
                        fontSize: 15,
                        color: activeColor,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SF Pro Display',
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Sponsor type and Exhibitor badges
                Row(
                  children: [
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
                        widget.exhibitor['sponsorType'] ?? 'Platinum Sponsor',
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
                Row(
                  children: [
                    // Facebook
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(0xFF1877F2),
                        shape: BoxShape.circle,
                      ),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {},
                        child: FaIcon(
                          FontAwesomeIcons.facebookF,
                          color: CupertinoColors.white,
                          size: 14,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // Instagram
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(0xFFE4405F),
                        shape: BoxShape.circle,
                      ),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {},
                        child: FaIcon(
                          FontAwesomeIcons.instagram,
                          color: CupertinoColors.white,
                          size: 14,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // LinkedIn
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(0xFF0A66C2),
                        shape: BoxShape.circle,
                      ),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {},
                        child: FaIcon(
                          FontAwesomeIcons.linkedinIn,
                          color: CupertinoColors.white,
                          size: 14,
                        ),
                      ),
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

  Widget _buildActionButtons(BuildContext context) {
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
              onPressed: _showMeetingSheet,
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
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => ChatPage(
                      userName: widget.exhibitor['companyName'] ?? widget.exhibitor['name'] ?? '',
                      userPhoto: widget.exhibitor['photo'],
                    ),
                  ),
                );
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
            child: Icon(
              CupertinoIcons.star,
              size: 22,
              color: activeColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(bool isDark) {
    final aboutText = widget.exhibitor['about'] ?? '';

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
                      else if (_chewieController != null &&
                          _chewieController!
                              .videoPlayerController
                              .value
                              .isInitialized)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Chewie(controller: _chewieController!),
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
      {
        'name': 'Product Catalog 2026',
        'type': 'PDF',
        'size': '5.8 MB',
        'icon': 'doc.fill',
      },
      {
        'name': 'Technical Specifications',
        'type': 'PDF',
        'size': '1.2 MB',
        'icon': 'doc.fill',
      },
      {
        'name': 'Certification Documents',
        'type': 'PDF',
        'size': '890 KB',
        'icon': 'doc.fill',
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
