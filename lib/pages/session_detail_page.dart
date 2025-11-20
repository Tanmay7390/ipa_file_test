import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:aesurg26/components/page_scaffold.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:aesurg26/pages/speaker_detail_page.dart';

class SessionDetailPage extends StatefulWidget {
  final Map<String, dynamic> session;

  const SessionDetailPage({super.key, required this.session});

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  int _selectedTabIndex =
      0; // 0 = Details, 1 = Chat/Q&A, 2 = Speakers, 3 = Attachments

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _videoError = false;

  bool _isAboutExpanded = false;
  bool _isAdditionalInfoExpanded = false;
  bool _isAddedToSchedule = false;

  // Chat messages
  final List<Map<String, dynamic>> _chatMessages = [
    {
      'name': 'John Doe',
      'message': 'Great session! Looking forward to the demo.',
      'time': '10:15 AM',
      'isMe': false,
    },
    {
      'name': 'Sarah Smith',
      'message': 'Very informative presentation!',
      'time': '10:16 AM',
      'isMe': false,
    },
    {
      'name': 'Mike Johnson',
      'message': 'Can we get the slides after the session?',
      'time': '10:18 AM',
      'isMe': false,
    },
  ];

  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        ),
      );

      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Color(0xFFFFD700),
          handleColor: Color(0xFFFFD700),
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
    _chatController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (_selectedTabIndex != index) {
      setState(() {
        _selectedTabIndex = index;
      });
    }
  }

  void _sendMessage() {
    if (_chatController.text.trim().isNotEmpty) {
      setState(() {
        _chatMessages.add({
          'name': 'You',
          'message': _chatController.text.trim(),
          'time':
              '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          'isMe': true,
        });
        _chatController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPageScaffold(
      heading: 'Session Details',
      hideSearch: true,
      isLoading: false,
      hideLargeTitle: true,
      sliverList: SliverList(
        delegate: SliverChildListDelegate([
          SizedBox(height: 16),
          // Video Player
          _buildVideoSection(),

          SizedBox(height: 16),

          // Tabs
          _buildTabs(),

          SizedBox(height: 16),

          // Tab Content
          _buildTabContent(),

          SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _buildVideoSection() {
    return Container(
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: Column(
        children: [
          if (_videoError)
            Container(
              height: 220,
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CupertinoColors.systemRed.withValues(alpha: 0.3),
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
              _chewieController!.videoPlayerController.value.isInitialized)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Chewie(controller: _chewieController!),
                ),
              ),
            )
          else
            Container(
              height: 220,
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: CupertinoColors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CupertinoActivityIndicator(color: Color(0xFFFFD700)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final inactiveColor = isDark
        ? CupertinoColors.systemGrey2
        : CupertinoColors.systemGrey;

    return Container(
      color: CupertinoColors.systemBackground.resolveFrom(context),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _switchTab(0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Details',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14,
                        letterSpacing: 0.2,
                        fontWeight: _selectedTabIndex == 0
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _selectedTabIndex == 0
                            ? CupertinoColors.activeBlue
                            : inactiveColor,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _switchTab(1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Chat & Q&A',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14,
                        letterSpacing: 0.2,
                        fontWeight: _selectedTabIndex == 1
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _selectedTabIndex == 1
                            ? CupertinoColors.activeBlue
                            : inactiveColor,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _switchTab(2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Speakers',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14,
                        letterSpacing: 0.2,
                        fontWeight: _selectedTabIndex == 2
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _selectedTabIndex == 2
                            ? CupertinoColors.activeBlue
                            : inactiveColor,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _switchTab(3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Attachments',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14,
                        letterSpacing: 0.2,
                        fontWeight: _selectedTabIndex == 3
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _selectedTabIndex == 3
                            ? CupertinoColors.activeBlue
                            : inactiveColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Animated sliding bottom bar
          Stack(
            children: [
              Container(height: 0.2, color: CupertinoColors.systemGrey5),
              AnimatedAlign(
                alignment: Alignment(
                  -1 +
                      (_selectedTabIndex *
                          2 /
                          3), // Calculate alignment for 4 tabs
                  0,
                ),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: FractionallySizedBox(
                  widthFactor: 0.25, // 1/4 of the width for 4 tabs
                  child: Container(
                    height: 2,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildDetailsTab();
      case 1:
        return _buildChatTab();
      case 2:
        return _buildSpeakersTab();
      case 3:
        return _buildAttachmentsTab();
      default:
        return _buildDetailsTab();
    }
  }

  // Tab 1: Details
  Widget _buildDetailsTab() {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Container(
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: Column(
        children: [
          // Basic Details Section
          _buildBasicDetailsSection(isDark),

          _buildSeparator(context),

          // About Section
          _buildAboutSection(isDark),

          _buildSeparator(context),

          // Additional Info Section
          _buildAdditionalInfoSection(isDark),
        ],
      ),
    );
  }

  Widget _buildBasicDetailsSection(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BASIC DETAILS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey.resolveFrom(context),
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 12),

          // Session Title
          Text(
            widget.session['title'] ?? 'Session Title',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.2,
              color: CupertinoTheme.of(context).textTheme.textStyle.color,
            ),
          ),
          SizedBox(height: 12),

          // Time
          Row(
            children: [
              Icon(CupertinoIcons.clock, size: 16, color: Color(0xFFFFD700)),
              SizedBox(width: 6),
              Text(
                widget.session['time'] ?? '10:00 AM - 11:00 AM',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          // Location
          Row(
            children: [
              Icon(
                CupertinoIcons.location_solid,
                size: 16,
                color: CupertinoColors.systemGrey.resolveFrom(context),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.session['location'] ?? 'Main Conference Hall',
                  style: TextStyle(
                    fontSize: 15,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Category and Status badges
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      (widget.session['categoryColor'] as Color?)?.withValues(
                        alpha: 0.15,
                      ) ??
                      Color(0xFFFFD700).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.session['category'] ?? 'Keynote',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        widget.session['categoryColor'] as Color? ??
                        Color(0xFFFFD700),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF16A34A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.session['status'] ?? 'Open seating',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF16A34A),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Add/Remove Session Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: _isAddedToSchedule
                  ? null
                  : LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: _isAddedToSchedule
                  ? CupertinoColors.systemGrey5.resolveFrom(context)
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: _isAddedToSchedule
                  ? Border.all(color: Color(0xFFFFD700), width: 2)
                  : null,
            ),
            child: CupertinoButton(
              padding: EdgeInsets.symmetric(vertical: 14),
              borderRadius: BorderRadius.circular(12),
              onPressed: () {
                setState(() {
                  _isAddedToSchedule = !_isAddedToSchedule;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isAddedToSchedule
                        ? CupertinoIcons.checkmark_alt
                        : CupertinoIcons.add,
                    size: 20,
                    color: _isAddedToSchedule
                        ? Color(0xFFFFD700)
                        : CupertinoColors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _isAddedToSchedule
                        ? 'Added to My Schedule'
                        : 'Add to My Schedule',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                      color: _isAddedToSchedule
                          ? Color(0xFFFFD700)
                          : CupertinoColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(bool isDark) {
    final aboutText =
        widget.session['about'] ??
        'This session will cover the latest trends and innovations in the field. Join us for an engaging discussion with industry experts and thought leaders. Learn about best practices, case studies, and future directions.';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          Text(
            _isAboutExpanded
                ? aboutText
                : aboutText.substring(
                        0,
                        aboutText.length > 150 ? 150 : aboutText.length,
                      ) +
                      '...',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: CupertinoTheme.of(context).textTheme.textStyle.color,
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.2,
            ),
          ),
          if (aboutText.length > 150)
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isAboutExpanded = !_isAboutExpanded;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    _isAboutExpanded ? 'see less' : 'more',
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

  Widget _buildAdditionalInfoSection(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ADDITIONAL INFORMATION',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey.resolveFrom(context),
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 12),
          _buildInfoRow(
            'Duration',
            widget.session['duration'] ?? '1 hour',
            isDark,
          ),
          SizedBox(height: 8),
          _buildInfoRow(
            'Organizer',
            widget.session['organizer'] ?? 'Event Committee',
            isDark,
          ),
          SizedBox(height: 8),
          _buildInfoRow('Language', 'English', isDark),
          SizedBox(height: 8),
          _buildInfoRow('Track', 'Main Track', isDark),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.systemGrey.resolveFrom(context),
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: CupertinoTheme.of(context).textTheme.textStyle.color,
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  // Tab 2: Chat & Q&A
  Widget _buildChatTab() {
    return Container(
      color: CupertinoColors.systemBackground.resolveFrom(context),
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Live Chat Section
          _buildChatSection(),

          SizedBox(height: 20),

          // Q&A Section
          _buildQASection(),

          SizedBox(height: 20),

          // Polls Section
          _buildPollsSection(),
        ],
      ),
    );
  }

  Widget _buildChatSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.chat_bubble_2_fill,
                color: Color(0xFFFFD700),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'LIVE CHAT',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Messages container
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final message = _chatMessages[index];
                final isMe = message['isMe'] as bool;

                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: isMe
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (!isMe) ...[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: CupertinoColors.activeBlue.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            CupertinoIcons.person_fill,
                            size: 16,
                            color: CupertinoColors.activeBlue,
                          ),
                        ),
                        SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(
                                message['name'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.activeBlue,
                                  fontFamily: 'SF Pro Display',
                                  letterSpacing: 0.2,
                                ),
                              ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? CupertinoColors.activeBlue
                                    : CupertinoColors.systemGrey5.resolveFrom(
                                        context,
                                      ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                message['message'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isMe
                                      ? CupertinoColors.white
                                      : CupertinoTheme.of(
                                          context,
                                        ).textTheme.textStyle.color,
                                  fontFamily: 'SF Pro Display',
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              message['time'] ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: CupertinoColors.systemGrey.resolveFrom(
                                  context,
                                ),
                                fontFamily: 'SF Pro Display',
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isMe) ...[
                        SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: CupertinoColors.activeBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            CupertinoIcons.person_fill,
                            size: 16,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 12),

          // Message input
          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: _chatController,
                  placeholder: 'Type your message...',
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground.resolveFrom(
                      context,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.arrow_up,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQASection() {
    // Dummy Q&A data
    final questions = [
      {
        'question':
            'What are the key differences between AI and Machine Learning?',
        'askedBy': 'Emily Chen',
        'time': '10:20 AM',
        'upvotes': 15,
        'answer':
            'AI is a broader concept that encompasses any technique enabling machines to mimic human intelligence. Machine Learning is a subset of AI that focuses on learning from data.',
        'answeredBy': 'Dr. Sarah Johnson',
      },
      {
        'question':
            'Can you share some real-world applications of this technology?',
        'askedBy': 'David Miller',
        'time': '10:22 AM',
        'upvotes': 8,
        'answer': null,
      },
      {
        'question':
            'What are the best practices for implementing this in production?',
        'askedBy': 'Lisa Anderson',
        'time': '10:25 AM',
        'upvotes': 12,
        'answer': null,
      },
    ];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.question_circle_fill,
                color: Color(0xFFFFD700),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Q&A',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Ask question button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CupertinoButton(
              padding: EdgeInsets.symmetric(vertical: 12),
              borderRadius: BorderRadius.circular(12),
              onPressed: () {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.add,
                    size: 18,
                    color: CupertinoColors.white,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Ask a Question',
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

          SizedBox(height: 16),

          // Questions list
          ...questions.map(
            (q) => Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question header
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey4.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          CupertinoIcons.person_fill,
                          size: 14,
                          color: CupertinoColors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q['askedBy'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'SF Pro Display',
                                letterSpacing: 0.2,
                                color: CupertinoTheme.of(
                                  context,
                                ).textTheme.textStyle.color,
                              ),
                            ),
                            Text(
                              q['time'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: CupertinoColors.systemGrey.resolveFrom(
                                  context,
                                ),
                                fontFamily: 'SF Pro Display',
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Upvote button
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey5.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.arrow_up,
                              size: 14,
                              color: CupertinoColors.systemGrey.resolveFrom(
                                context,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${q['upvotes']}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.systemGrey.resolveFrom(
                                  context,
                                ),
                                fontFamily: 'SF Pro Display',
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  // Question text
                  Text(
                    q['question'] as String,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                      color: CupertinoTheme.of(
                        context,
                      ).textTheme.textStyle.color,
                    ),
                  ),

                  // Answer (if available)
                  if (q['answer'] != null) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(0xFF16A34A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Color(0xFF16A34A).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                size: 16,
                                color: Color(0xFF16A34A),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Answered by ${q['answeredBy']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF16A34A),
                                  fontFamily: 'SF Pro Display',
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            q['answer'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoTheme.of(
                                context,
                              ).textTheme.textStyle.color,
                              fontFamily: 'SF Pro Display',
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollsSection() {
    // Dummy poll data
    final polls = [
      {
        'question': 'Which topic would you like us to cover next?',
        'options': [
          {'text': 'Deep Learning Fundamentals', 'votes': 45, 'voted': true},
          {'text': 'Cloud Architecture', 'votes': 32, 'voted': false},
          {'text': 'Cybersecurity Best Practices', 'votes': 28, 'voted': false},
          {'text': 'Blockchain Technology', 'votes': 15, 'voted': false},
        ],
        'totalVotes': 120,
        'endsIn': '2 hours',
      },
      {
        'question': 'How would you rate this session so far?',
        'options': [
          {'text': 'Excellent', 'votes': 58, 'voted': false},
          {'text': 'Good', 'votes': 35, 'voted': false},
          {'text': 'Average', 'votes': 8, 'voted': false},
          {'text': 'Needs Improvement', 'votes': 2, 'voted': false},
        ],
        'totalVotes': 103,
        'endsIn': '1 hour',
      },
    ];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.chart_bar_fill,
                color: CupertinoColors.activeBlue,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'POLLS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Polls list
          ...polls.map((poll) {
            final totalVotes = poll['totalVotes'] as int;
            return Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poll question
                  Text(
                    poll['question'] as String,
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
                  SizedBox(height: 12),

                  // Poll options
                  ...((poll['options'] as List).map((option) {
                    final votes = option['votes'] as int;
                    final percentage = totalVotes > 0
                        ? (votes / totalVotes * 100).round()
                        : 0;
                    final voted = option['voted'] as bool;

                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      child: Stack(
                        children: [
                          // Progress bar background
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey5.resolveFrom(
                                context,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    option['text'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: voted
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      fontFamily: 'SF Pro Display',
                                      letterSpacing: 0.2,
                                      color: voted
                                          ? CupertinoColors.activeBlue
                                          : CupertinoTheme.of(
                                              context,
                                            ).textTheme.textStyle.color,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Row(
                                  children: [
                                    Text(
                                      '$percentage%',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'SF Pro Display',
                                        letterSpacing: 0.2,
                                        color: voted
                                            ? CupertinoColors.activeBlue
                                            : CupertinoColors.systemGrey
                                                  .resolveFrom(context),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '($votes)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'SF Pro Display',
                                        letterSpacing: 0.2,
                                        color: CupertinoColors.systemGrey
                                            .resolveFrom(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Progress bar fill
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width:
                                  MediaQuery.of(context).size.width *
                                  0.85 *
                                  percentage /
                                  100,
                              decoration: BoxDecoration(
                                color: voted
                                    ? CupertinoColors.activeBlue.withValues(
                                        alpha: 0.2,
                                      )
                                    : CupertinoColors.systemGrey4
                                          .resolveFrom(context)
                                          .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          if (voted)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                size: 18,
                                color: CupertinoColors.activeBlue,
                              ),
                            ),
                        ],
                      ),
                    );
                  })),

                  SizedBox(height: 8),

                  // Poll footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$totalVotes votes',
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey.resolveFrom(
                            context,
                          ),
                          fontFamily: 'SF Pro Display',
                          letterSpacing: 0.2,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.clock,
                            size: 12,
                            color: CupertinoColors.systemGrey.resolveFrom(
                              context,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Ends in ${poll['endsIn']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.systemGrey.resolveFrom(
                                context,
                              ),
                              fontFamily: 'SF Pro Display',
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Tab 3: Speakers
  Widget _buildSpeakersTab() {
    // Mock speakers data
    final List<Map<String, dynamic>> speakers = [
      {
        'name': 'Dr. Sarah Johnson',
        'role': 'Chief Technology Officer',
        'organization': 'Tech Innovations Inc.',
        'photo': 'https://via.placeholder.com/60',
        'about':
            'Leading expert in artificial intelligence and machine learning.',
        'email': 'sarah.johnson@techinnovations.com',
        'phone': '+1 234 567 8900',
      },
      {
        'name': 'Prof. Michael Chen',
        'role': 'Professor of Computer Science',
        'organization': 'MIT',
        'photo': 'https://via.placeholder.com/60',
        'about': 'Renowned researcher in distributed systems.',
        'email': 'michael.chen@mit.edu',
        'phone': '+1 234 567 8901',
      },
    ];

    return Container(
      color: CupertinoColors.systemBackground.resolveFrom(context),
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SESSION SPEAKERS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey.resolveFrom(context),
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 12),
          ...speakers.map((speaker) => _buildSpeakerCard(speaker)),
        ],
      ),
    );
  }

  Widget _buildSpeakerCard(Map<String, dynamic> speaker) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => SpeakerDetailPage(speaker: speaker),
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
            // Speaker icon
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
            // Speaker info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    speaker['name'] ?? '',
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
                    speaker['role'] ?? '',
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

  // Tab 4: Attachments
  Widget _buildAttachmentsTab() {
    // Mock documents data
    final List<Map<String, String>> documents = [
      {'name': 'Session Presentation Slides', 'type': 'PDF', 'size': '3.2 MB'},
      {'name': 'Additional Resources', 'type': 'PDF', 'size': '1.8 MB'},
      {'name': 'Session Handout', 'type': 'PDF', 'size': '950 KB'},
    ];

    return Container(
      color: CupertinoColors.systemBackground.resolveFrom(context),
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SESSION DOCUMENTS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey.resolveFrom(context),
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 12),
          ...documents.map((doc) => _buildDocumentCard(doc)),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, String> document) {
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
              color: Color(0xFFFFD700),
              size: 28,
            ),
          ),
        ],
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
}
