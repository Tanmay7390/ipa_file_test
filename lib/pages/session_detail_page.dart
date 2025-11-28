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
      0; // 0 = Details, 1 = Live Chat, 2 = Q&A, 3 = Polls, 4 = Speakers, 5 = Attachments

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _videoError = false;

  bool _isAboutExpanded = false;
  bool _isAdditionalInfoExpanded = false;
  bool _isAddedToSchedule = false;

  // Q&A interactivity
  final Set<int> _upvotedQuestions = {};
  final List<Map<String, dynamic>> _questions = [
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

  // Poll interactivity
  final Map<int, int> _pollVotes = {}; // poll index -> option index
  final List<Map<String, dynamic>> _polls = [
    {
      'question': 'Which topic would you like us to cover next?',
      'options': [
        {'text': 'Deep Learning Fundamentals', 'votes': 45},
        {'text': 'Cloud Architecture', 'votes': 32},
        {'text': 'Cybersecurity Best Practices', 'votes': 28},
        {'text': 'Blockchain Technology', 'votes': 15},
      ],
    },
    {
      'question': 'How would you rate this session so far?',
      'options': [
        {'text': 'Excellent', 'votes': 58},
        {'text': 'Good', 'votes': 35},
        {'text': 'Average', 'votes': 8},
        {'text': 'Needs Improvement', 'votes': 2},
      ],
    },
  ];

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
                child: CupertinoActivityIndicator(color: Color(0xFF21AA62)),
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
    final activeColor = isDark ? Color(0xFF23C061) : Color(0xFF21AA62);

    final tabs = [
      'Details',
      'Live Chat',
      'Q&A',
      'Polls',
      'Speakers',
      'Attachments',
    ];

    return Container(
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: Column(
        children: [
          // Scrollable tab bar
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedTabIndex == index;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _switchTab(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? activeColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14,
                        letterSpacing: 0.2,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? activeColor : inactiveColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Bottom border
          Container(
            height: 0.5,
            color: CupertinoColors.separator.resolveFrom(context),
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
        return _buildLiveChatTab();
      case 2:
        return _buildQATab();
      case 3:
        return _buildPollsTab();
      case 4:
        return _buildSpeakersTab();
      case 5:
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
    final activeColor = isDark ? Color(0xFF23C061) : Color(0xFF21AA62);

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
              Icon(CupertinoIcons.clock, size: 16, color: activeColor),
              SizedBox(width: 6),
              Text(
                widget.session['time'] ?? '10:00 AM - 11:00 AM',
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
                      activeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.session['category'] ?? 'Keynote',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        widget.session['categoryColor'] as Color? ??
                        activeColor,
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
              color: _isAddedToSchedule
                  ? CupertinoColors.systemGrey5.resolveFrom(context)
                  : activeColor,
              borderRadius: BorderRadius.circular(12),
              border: _isAddedToSchedule
                  ? Border.all(color: activeColor, width: 2)
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
                        ? activeColor
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
                          ? activeColor
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

  // Tab 2: Live Chat
  Widget _buildLiveChatTab() {
    return Container(
      color: CupertinoColors.systemBackground.resolveFrom(context),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: _buildChatSection(),
    );
  }

  Widget _buildChatSection() {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final activeColor = isDark ? Color(0xFF23C061) : Color(0xFF21AA62);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Messages container
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            padding: EdgeInsets.all(16),
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
                          color: activeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          CupertinoIcons.person_fill,
                          size: 16,
                          color: activeColor,
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
                                color: activeColor,
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
                                  ? activeColor
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
                                    : CupertinoTheme.of(context)
                                        .textTheme
                                        .textStyle
                                        .color,
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
                              color:
                                  CupertinoColors.systemGrey.resolveFrom(context),
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
                          color: activeColor,
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
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: _chatController,
                  placeholder: 'Type your message...',
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                  ),
                  maxLines: null,
                ),
              ),
              SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.arrow_up,
                    color: CupertinoColors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Tab 3: Q&A
  Widget _buildQATab() {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final activeColor = isDark ? Color(0xFF23C061) : Color(0xFF21AA62);

    return Container(
      color: CupertinoColors.systemBackground.resolveFrom(context),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ask question button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CupertinoButton(
              padding: EdgeInsets.symmetric(vertical: 14),
              borderRadius: BorderRadius.circular(12),
              onPressed: () {
                _showAskQuestionDialog();
              },
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
          ..._questions.map((q) {
            final index = _questions.indexOf(q);
            return _buildQuestionCard(q, index, isDark, activeColor);
          }),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    Map<String, dynamic> q,
    int index,
    bool isDark,
    Color activeColor,
  ) {
    final isUpvoted = _upvotedQuestions.contains(index);
    final upvotes = (q['upvotes'] as int) + (isUpvoted ? 1 : 0);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
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
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isUpvoted) {
                      _upvotedQuestions.remove(index);
                    } else {
                      _upvotedQuestions.add(index);
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isUpvoted
                        ? activeColor.withValues(alpha: 0.15)
                        : CupertinoColors.systemGrey5.resolveFrom(
                            context,
                          ),
                    borderRadius: BorderRadius.circular(12),
                    border: isUpvoted
                        ? Border.all(
                            color: activeColor.withValues(alpha: 0.3),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isUpvoted
                            ? CupertinoIcons.arrow_up_circle_fill
                            : CupertinoIcons.arrow_up,
                        size: 16,
                        color: isUpvoted
                            ? activeColor
                            : CupertinoColors.systemGrey.resolveFrom(
                                context,
                              ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '$upvotes',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isUpvoted
                              ? activeColor
                              : CupertinoColors.systemGrey.resolveFrom(
                                  context,
                                ),
                          fontFamily: 'SF Pro Display',
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
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
    );
  }

  void _showAskQuestionDialog() {
    final questionController = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Ask a Question'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: questionController,
            placeholder: 'Type your question...',
            maxLines: 3,
            style: TextStyle(
              fontFamily: 'SF Pro Display',
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Submit'),
            onPressed: () {
              if (questionController.text.trim().isNotEmpty) {
                setState(() {
                  _questions.insert(0, {
                    'question': questionController.text.trim(),
                    'askedBy': 'You',
                    'time':
                        '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                    'upvotes': 0,
                    'answer': null,
                  });
                });
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // Tab 4: Polls
  Widget _buildPollsTab() {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final activeColor = isDark ? Color(0xFF23C061) : Color(0xFF21AA62);

    return Container(
      color: CupertinoColors.systemBackground.resolveFrom(context),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: _polls.asMap().entries.map((entry) {
          final pollIndex = entry.key;
          final poll = entry.value;
          final options = poll['options'] as List;
          final votedOptionIndex = _pollVotes[pollIndex];

          // Calculate total votes
          int totalVotes = 0;
          for (var option in options) {
            totalVotes += option['votes'] as int;
          }
          if (votedOptionIndex != null) totalVotes++;

          return Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poll question
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.chart_bar_fill,
                      color: activeColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
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
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Poll options
                ...List.generate(options.length, (optionIndex) {
                  final option = options[optionIndex];
                  final votes = (option['votes'] as int) +
                      (votedOptionIndex == optionIndex ? 1 : 0);
                  final percentage =
                      totalVotes > 0 ? (votes / totalVotes * 100).round() : 0;
                  final isVoted = votedOptionIndex == optionIndex;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _pollVotes[pollIndex] = optionIndex;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 10),
                      child: Stack(
                        children: [
                          // Progress bar background
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemBackground
                                  .resolveFrom(context),
                              borderRadius: BorderRadius.circular(10),
                              border: isVoted
                                  ? Border.all(
                                      color: activeColor.withValues(alpha: 0.5),
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    option['text'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isVoted
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      fontFamily: 'SF Pro Display',
                                      letterSpacing: 0.2,
                                      color: isVoted
                                          ? activeColor
                                          : CupertinoTheme.of(
                                              context,
                                            ).textTheme.textStyle.color,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Row(
                                  children: [
                                    Text(
                                      '$percentage%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'SF Pro Display',
                                        letterSpacing: 0.2,
                                        color: isVoted
                                            ? activeColor
                                            : CupertinoColors.systemGrey
                                                .resolveFrom(context),
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    if (isVoted)
                                      Icon(
                                        CupertinoIcons.checkmark_circle_fill,
                                        size: 18,
                                        color: activeColor,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Progress bar fill
                          if (votedOptionIndex != null)
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: (MediaQuery.of(context).size.width -
                                        40) *
                                    percentage /
                                    100,
                                decoration: BoxDecoration(
                                  color: isVoted
                                      ? activeColor.withValues(
                                          alpha: 0.2,
                                        )
                                      : CupertinoColors.systemGrey4
                                          .resolveFrom(context)
                                          .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),

                SizedBox(height: 8),

                // Poll footer
                Text(
                  '$totalVotes ${totalVotes == 1 ? 'vote' : 'votes'}',
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
          );
        }).toList(),
      ),
    );
  }

  // Tab 5: Speakers
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

  // Tab 6: Attachments
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
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
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
