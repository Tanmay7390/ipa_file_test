import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:aesurg26/components/page_scaffold.dart';
import 'package:aesurg26/pages/chat_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CompanyRepresentativeDetailPage extends StatefulWidget {
  final Map<String, dynamic> representative;

  const CompanyRepresentativeDetailPage({
    super.key,
    required this.representative,
  });

  @override
  State<CompanyRepresentativeDetailPage> createState() =>
      _CompanyRepresentativeDetailPageState();
}

class _CompanyRepresentativeDetailPageState
    extends State<CompanyRepresentativeDetailPage> {
  bool _isAboutExpanded = false;
  bool _isAdditionalInfoExpanded = false;
  bool _isScheduleExpanded = false;
  Map<int, bool> _expandedDays = {}; // Track which days are expanded

  void _showMeetingSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => _MeetingFormSheet(
        representativeName: widget.representative['name'] ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CustomPageScaffold(
      heading: 'Representative Details',
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
          if (widget.representative['about'] != null &&
              widget.representative['about'].toString().isNotEmpty)
            Container(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              padding: EdgeInsets.only(top: 12, bottom: 12),
              child: _buildAboutSection(isDark),
            ),

          _buildSeparator(context),

          // Additional Information section
          Container(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            padding: EdgeInsets.zero,
            child: _buildAdditionalInfoSection(isDark),
          ),

          _buildSeparator(context),

          // Schedule section
          if (widget.representative['sessions'] != null &&
              widget.representative['sessions'].isNotEmpty)
            Container(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              padding: EdgeInsets.zero,
              child: _buildScheduleSection(isDark),
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile photo
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              widget.representative['photo'] ?? '',
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

          // Name and title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.representative['name'] ?? '',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  widget.representative['title'] ??
                      widget.representative['specialty'] ??
                      '',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                  ),
                ),
                if (widget.representative['company'] != null) ...[
                  SizedBox(height: 4),
                  Text(
                    widget.representative['company'],
                    style: TextStyle(
                      fontSize: 15,
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
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
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => ChatPage(
                      userName: widget.representative['name'] ?? '',
                      userPhoto: widget.representative['photo'],
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
                    CupertinoIcons.videocam_fill,
                    size: 22,
                    color: CupertinoColors.white,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Meeting',
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
    final aboutText = widget.representative['about'] ?? '';

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


  Widget _buildAdditionalInfoSection(bool isDark) {
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
                _isAdditionalInfoExpanded = !_isAdditionalInfoExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Icon(
                  _isAdditionalInfoExpanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 18,
                  color: activeColor,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: Duration(milliseconds: 350),
            curve: Curves.fastOutSlowIn,
            child: _isAdditionalInfoExpanded
                ? Column(
                    children: [
                      SizedBox(height: 12),

                      // Speciality
                      if (widget.representative['specialty'] != null)
                        _buildMinimalisticInfoRow(
                          icon: CupertinoIcons.heart_fill,
                          label: 'Specialty',
                          value: widget.representative['specialty'],
                          isClickable: false,
                        ),

                      // Phone
                      _buildMinimalisticInfoRow(
                        icon: CupertinoIcons.phone_fill,
                        label: 'Phone',
                        value: '+91 9876543210',
                        isClickable: true,
                        onTap: () {
                          // TODO: Open phone dialer
                        },
                      ),

                      // Email
                      _buildMinimalisticInfoRow(
                        icon: CupertinoIcons.mail_solid,
                        label: 'Email',
                        value: 'aditya7390@gmail.com',
                        isClickable: true,
                        onTap: () {
                          // TODO: Open email client
                        },
                      ),

                      // Location
                      if (widget.representative['location'] != null)
                        _buildMinimalisticInfoRow(
                          icon: CupertinoIcons.location_solid,
                          label: 'Location',
                          value: widget.representative['location'],
                          isClickable: false,
                        ),
                    ],
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalisticInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isClickable = false,
    VoidCallback? onTap,
  }) {
    Widget content = Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: CupertinoColors.systemGrey.resolveFrom(context),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 15,
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isClickable && onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }

  Widget _buildScheduleSection(bool isDark) {
    final sessions = widget.representative['sessions'] as List<dynamic>;
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
                _isScheduleExpanded = !_isScheduleExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SCHEDULE',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                  ),
                ),
                Icon(
                  _isScheduleExpanded
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
            child: _isScheduleExpanded
                ? Column(
                    children: [
                      SizedBox(height: 16),
                      ...sessions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final session = entry.value;
                        if (session is Map<String, dynamic>) {
                          return _buildSessionCard(session, index + 1, isDark);
                        } else if (session is String) {
                          return _buildLegacySessionCard(
                            session,
                            index + 1,
                            isDark,
                          );
                        }
                        return SizedBox.shrink();
                      }),
                    ],
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(
    Map<String, dynamic> session,
    int dayNumber,
    bool isDark,
  ) {
    // Initialize day expansion state if not set
    _expandedDays.putIfAbsent(dayNumber, () => true);
    final isExpanded = _expandedDays[dayNumber] ?? true;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header with expand/collapse
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                _expandedDays[dayNumber] = !isExpanded;
              });
            },
            child: Row(
              children: [
                // Calendar icon with day number
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF23C061) : Color(0xFF21AA62),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'SF Pro Display',
                          color: CupertinoColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                // Date and session count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session['date'] ?? '',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SF Pro Display',
                          letterSpacing: 0.2,
                          color: CupertinoTheme.of(
                            context,
                          ).textTheme.textStyle.color,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '1 Session',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'SF Pro Display',
                          color: CupertinoColors.systemGrey.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 20,
                  color: isDark ? Color(0xFF23C061) : Color(0xFF21AA62),
                ),
              ],
            ),
          ),

          // Animated session card
          AnimatedSize(
            duration: Duration(milliseconds: 350),
            curve: Curves.fastOutSlowIn,
            child: isExpanded
                ? Column(
                    children: [
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? CupertinoColors.systemGrey6.darkColor
                              : CupertinoColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? CupertinoColors.systemGrey5.darkColor
                                : CupertinoColors.systemGrey5.color,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Session title
                            Text(
                              session['title'] ?? '',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'SF Pro Display',
                                letterSpacing: 0.2,
                                height: 1.3,
                                color: CupertinoTheme.of(
                                  context,
                                ).textTheme.textStyle.color,
                              ),
                            ),

                            SizedBox(height: 12),

                            // Role badge (Attendee)
                            if (session['role'] != null)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: (isDark
                                          ? Color(0xFF23C061)
                                          : Color(0xFF21AA62))
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: (isDark
                                            ? Color(0xFF23C061)
                                            : Color(0xFF21AA62))
                                        .withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  session['role'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'SF Pro Display',
                                    letterSpacing: 0.2,
                                    color: isDark
                                        ? Color(0xFF23C061)
                                        : Color(0xFF21AA62),
                                  ),
                                ),
                              ),

                            SizedBox(height: 16),

                            // Time
                            Text(
                              session['time'] ?? '',
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: 'SF Pro Display',
                                letterSpacing: 0.2,
                                color: CupertinoColors.systemGrey.resolveFrom(
                                  context,
                                ),
                              ),
                            ),

                            if (session['location'] != null) ...[
                              SizedBox(height: 12),
                              // Location badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Color(0xFF4A2B3A)
                                      : Color(0xFFFFE4E8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  session['location'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'SF Pro Display',
                                    letterSpacing: 0.2,
                                    color: isDark
                                        ? Color(0xFFFF8CB4)
                                        : Color(0xFFD53F8C),
                                  ),
                                ),
                              ),
                            ],
                          ],
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

  Widget _buildLegacySessionCard(
    String sessionTitle,
    int dayNumber,
    bool isDark,
  ) {
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
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Day $dayNumber',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'SF Pro Display',
                letterSpacing: 0.2,
                color: CupertinoColors.white,
              ),
            ),
          ),
          SizedBox(width: 12),
          Icon(
            CupertinoIcons.calendar,
            size: 20,
            color: CupertinoColors.systemGrey.resolveFrom(context),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              sessionTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                fontFamily: 'SF Pro Display',
                letterSpacing: 0.2,
                color: CupertinoTheme.of(context).textTheme.textStyle.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetingFormSheet extends StatefulWidget {
  final String representativeName;

  const _MeetingFormSheet({required this.representativeName});

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
    _titleController.text = 'Meeting - ${widget.representativeName}';
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
