import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axlmed/components/page_scaffold.dart';
// import 'package:axlmed/pages/session_detail_page.dart';
// import 'package:axlmed/pages/direct_chat_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:axlmed/apis/providers/speakers_provider.dart';
// import 'package:axlmed/apis/providers/direct_chat_provider.dart';
import 'package:axlmed/apis/providers/meeting_request_provider.dart';
import 'package:axlmed/providers/home_data_provider.dart';
import 'package:axlmed/providers/user_data_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class SpeakerDetailPage extends ConsumerStatefulWidget {
  final String speakerId;

  const SpeakerDetailPage({super.key, required this.speakerId});

  @override
  ConsumerState<SpeakerDetailPage> createState() => _SpeakerDetailPageState();
}

class _SpeakerDetailPageState extends ConsumerState<SpeakerDetailPage> {
  bool _isAboutExpanded = false;
  bool _isScheduleExpanded = false;
  Map<int, bool> _expandedDays = {}; // Track which days are expanded

  void _showMeetingSheet(String speakerId, String speakerName) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) =>
          _MeetingFormSheet(speakerId: speakerId, speakerName: speakerName),
    );
  }

  Uri _normalizeUrl(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return Uri.parse('about:blank');

    // Preserve known schemes
    if (s.startsWith('mailto:') || s.startsWith('tel:')) {
      return Uri.parse(s);
    }

    // Ensure http/https scheme
    if (s.startsWith('http://') || s.startsWith('https://')) {
      return Uri.parse(s);
    }

    // Social handles or bare domains
    if (s.contains('instagram.com')) {
      return Uri.parse('https://' + s.replaceFirst(RegExp(r'^https?://'), ''));
    }
    if (s.contains('facebook.com')) {
      return Uri.parse('https://' + s.replaceFirst(RegExp(r'^https?://'), ''));
    }
    if (s.contains('linkedin.com')) {
      return Uri.parse('https://' + s.replaceFirst(RegExp(r'^https?://'), ''));
    }

    // Handle @username patterns for Instagram/Twitter if provided
    if (s.startsWith('@')) {
      final handle = s.substring(1);
      return Uri.parse('https://instagram.com/$handle');
    }

    // Default: treat as web domain or path
    return Uri.parse('https://$s');
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final uri = _normalizeUrl(urlString);
      if (uri.scheme == 'about') return;

      if (uri.scheme == 'http' || uri.scheme == 'https') {
        final extOk = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!extOk) {
          final webOk = await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
            webViewConfiguration: const WebViewConfiguration(
              enableJavaScript: true,
            ),
          );
          if (!webOk) {
            await _showLaunchFailure(uri.toString());
          }
        }
      } else {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok) {
          await _showLaunchFailure(uri.toString());
        }
      }
    } catch (_) {
      // As a last resort, show failure dialog
      await _showLaunchFailure(urlString);
    }
  }

  Future<void> _showLaunchFailure(String url) async {
    await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Unable to open link'),
        content: Text(url),
        actions: [
          CupertinoDialogAction(
            child: const Text('Copy'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              Navigator.of(context).pop();
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // Get initials from name
  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';

    // Remove titles with or without period (Dr, Dr., Prof, Prof., Mr, Mr., etc.)
    final cleaned = name.replaceAll(
      RegExp(r'^(Dr\.?|Prof\.?|Mr\.?|Mrs\.?|Ms\.?)\s+', caseSensitive: false),
      '',
    );

    final parts = cleaned.trim().split(' ');
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }

    // First letter of first name + first letter of last name
    return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1))
        .toUpperCase();
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
        ],
      ),
    );
  }

  // Build initials avatar widget
  Widget _buildInitialsAvatar(String? name, bool isDark) {
    final initials = _getInitials(name);

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.systemGrey.resolveFrom(context)
            : CupertinoColors.systemGrey5.resolveFrom(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w600,
            color: isDark
                ? CupertinoColors.white
                : CupertinoColors.darkBackgroundGray,
          ),
        ),
      ),
    );
  }

  // Check if speaker has any additional info to display
  bool _hasAdditionalInfo(Speaker speaker) {
    return (speaker.specialty != null && speaker.specialty!.isNotEmpty) ||
        (speaker.phone != null && speaker.phone!.isNotEmpty) ||
        (speaker.email != null && speaker.email!.isNotEmpty) ||
        (speaker.location != null && speaker.location!.isNotEmpty) ||
        (speaker.organization != null && speaker.organization!.isNotEmpty);
  }

  // Format time from ISO string
  String _formatTime(String? dateTimeString) {
    if (dateTimeString == null) return '';
    try {
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (e) {
      return dateTimeString;
    }
  }

  // Format date from ISO string
  String _formatDate(String? dateTimeString) {
    if (dateTimeString == null) return '';
    try {
      final dateTime = DateTime.parse(dateTimeString).toLocal();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
    } catch (e) {
      return dateTimeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final speakerAsync = ref.watch(speakerDetailProvider(widget.speakerId));

    return CustomPageScaffold(
      heading: 'Speaker Details',
      hideSearch: true,
      isLoading: speakerAsync.isLoading,
      hideLargeTitle: true,
      sliverList: SliverList(
        delegate: SliverChildListDelegate([
          speakerAsync.when(
            data: (speaker) => Column(
              children: [
                // Header with photo and basic info
                Container(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  child: _buildHeader(speaker, isDark),
                ),

                // Action buttons
                Container(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  padding: EdgeInsets.only(
                    top: 12,
                    bottom: 12,
                    left: 20,
                    right: 20,
                  ),
                  child: _buildActionButtons(context, speaker),
                ),
                _buildSeparator(context),

                // About section
                if (speaker.about != null && speaker.about!.isNotEmpty)
                  Container(
                    color: CupertinoColors.systemBackground.resolveFrom(
                      context,
                    ),
                    padding: EdgeInsets.only(top: 12, bottom: 12),
                    child: _buildAboutSection(speaker, isDark),
                  ),

                if (speaker.about != null && speaker.about!.isNotEmpty)
                  _buildSeparator(context),

                // Additional Information section
                if (_hasAdditionalInfo(speaker)) ...[
                  Container(
                    color: CupertinoColors.systemBackground.resolveFrom(
                      context,
                    ),
                    padding: EdgeInsets.zero,
                    child: _buildAdditionalInfoSection(speaker, isDark),
                  ),
                  _buildSeparator(context),
                ],

                // Schedule section
                if (speaker.sessions != null && speaker.sessions!.isNotEmpty)
                  Container(
                    color: CupertinoColors.systemBackground.resolveFrom(
                      context,
                    ),
                    padding: EdgeInsets.zero,
                    child: _buildScheduleSection(speaker, isDark),
                  ),

                SizedBox(height: 20),
              ],
            ),
            loading: () => SizedBox(height: 400),
            error: (error, stack) => Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    size: 64,
                    color: CupertinoColors.systemRed.resolveFrom(context),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error loading speaker details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CupertinoTheme.of(
                        context,
                      ).textTheme.textStyle.color,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
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

  Widget _buildHeader(Speaker speaker, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile photo with initials fallback
          Stack(
            children: [
              // Always show initials first (instant load)
              _buildInitialsAvatar(speaker.name, isDark),
              // Overlay photo on top if available
              if (speaker.photo != null && speaker.photo!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    speaker.photo!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      // While loading, show nothing (initials visible underneath)
                      return const SizedBox.shrink();
                    },
                    errorBuilder: (context, error, stackTrace) {
                      // On error, show nothing (initials remain visible)
                      return const SizedBox.shrink();
                    },
                  ),
                ),
            ],
          ),
          SizedBox(width: 20),

          // Name and title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  speaker.name ?? '',
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
                  speaker.designation ?? speaker.title ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                  ),
                ),
                if (speaker.organization != null) ...[
                  SizedBox(height: 4),
                  Text(
                    speaker.organization!,
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
                _buildSocialMediaButtons(speaker),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaButtons(Speaker speaker) {
    final socialMedia = speaker.socialMedia;
    if (socialMedia == null) return SizedBox.shrink();

    return Row(
      children: [
        // Facebook
        if (socialMedia.facebook != null && socialMedia.facebook!.isNotEmpty)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(0xFF1877F2),
              shape: BoxShape.circle,
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _launchUrl(socialMedia.facebook!),
              child: FaIcon(
                FontAwesomeIcons.facebookF,
                color: CupertinoColors.white,
                size: 14,
              ),
            ),
          ),
        if (socialMedia.facebook != null && socialMedia.facebook!.isNotEmpty)
          SizedBox(width: 8),
        // Instagram
        if (socialMedia.instagram != null && socialMedia.instagram!.isNotEmpty)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(0xFFE4405F),
              shape: BoxShape.circle,
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _launchUrl(socialMedia.instagram!),
              child: FaIcon(
                FontAwesomeIcons.instagram,
                color: CupertinoColors.white,
                size: 14,
              ),
            ),
          ),
        if (socialMedia.instagram != null && socialMedia.instagram!.isNotEmpty)
          SizedBox(width: 8),
        // LinkedIn
        if (socialMedia.linkedin != null && socialMedia.linkedin!.isNotEmpty)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(0xFF0A66C2),
              shape: BoxShape.circle,
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _launchUrl(socialMedia.linkedin!),
              child: FaIcon(
                FontAwesomeIcons.linkedinIn,
                color: CupertinoColors.white,
                size: 14,
              ),
            ),
          ),
        if (socialMedia.linkedin != null && socialMedia.linkedin!.isNotEmpty)
          SizedBox(width: 8),
        // Website
        if (socialMedia.website != null && socialMedia.website!.isNotEmpty)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey,
              shape: BoxShape.circle,
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _launchUrl(socialMedia.website!),
              child: Icon(
                CupertinoIcons.globe,
                color: CupertinoColors.white,
                size: 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Speaker speaker) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Color(0xFF007AFF) : Color(0xFF0387FE);
    final canMessage =
        speaker.canMessage == true && speaker.messengerId != null;

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: canMessage ? activeColor : CupertinoColors.systemGrey4,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CupertinoButton(
              padding: EdgeInsets.symmetric(vertical: 12),
              borderRadius: BorderRadius.circular(12),
              onPressed: () => {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.chat_bubble_fill,
                    size: 18,
                    color: canMessage
                        ? CupertinoColors.white
                        : CupertinoColors.systemGrey,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Message',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                      color: canMessage
                          ? CupertinoColors.white
                          : CupertinoColors.systemGrey,
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
              onPressed: () =>
                  _showMeetingSheet(speaker.id, speaker.name ?? ''),
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
            child: Icon(CupertinoIcons.star, size: 22, color: activeColor),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(Speaker speaker, bool isDark) {
    final aboutText = speaker.about ?? '';

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

  Widget _buildAdditionalInfoSection(Speaker speaker, bool isDark) {
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

          // Specialty
          if (speaker.specialty != null && speaker.specialty!.isNotEmpty)
            _buildMinimalisticInfoRow(
              icon: CupertinoIcons.heart_fill,
              label: 'Specialty',
              value: speaker.specialty!,
              isClickable: false,
            ),

          // Phone
          if (speaker.phone != null && speaker.phone!.isNotEmpty)
            _buildMinimalisticInfoRow(
              icon: CupertinoIcons.phone_fill,
              label: 'Phone',
              value: speaker.phone!,
              isClickable: true,
              onTap: () => _launchUrl('tel:${speaker.phone}'),
            ),

          // Email
          if (speaker.email != null && speaker.email!.isNotEmpty)
            _buildMinimalisticInfoRow(
              icon: CupertinoIcons.mail_solid,
              label: 'Email',
              value: speaker.email!,
              isClickable: true,
              onTap: () => _launchUrl('mailto:${speaker.email}'),
            ),

          // Location
          if (speaker.location != null && speaker.location!.isNotEmpty)
            _buildMinimalisticInfoRow(
              icon: CupertinoIcons.location_solid,
              label: 'Location',
              value: speaker.location!,
              isClickable: false,
            ),

          // Organization
          if (speaker.organization != null && speaker.organization!.isNotEmpty)
            _buildMinimalisticInfoRow(
              icon: CupertinoIcons.building_2_fill,
              label: 'Organization',
              value: speaker.organization!,
              isClickable: false,
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

  Widget _buildScheduleSection(Speaker speaker, bool isDark) {
    final sessions = speaker.sessions ?? [];
    final activeColor = isDark ? Color(0xFF007AFF) : Color(0xFF0387FE);

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
            child: _isScheduleExpanded && sessions.isNotEmpty
                ? Column(
                    children: [
                      SizedBox(height: 16),
                      // Day header with date - shown once for all sessions
                      Row(
                        children: [
                          // Calendar icon with day number
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: activeColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'D1',
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
                          // Session count
                          Expanded(
                            child: Text(
                              '${sessions.length} Session${sessions.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'SF Pro Display',
                                color: CupertinoColors.systemGrey.resolveFrom(
                                  context,
                                ),
                              ),
                            ),
                          ),
                          // Date on the right - extracted from startTime
                          if (sessions.isNotEmpty &&
                              (sessions.first.date != null ||
                                  sessions.first.startTime != null))
                            Text(
                              sessions.first.date ??
                                  _formatDate(sessions.first.startTime),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'SF Pro Display',
                                color: CupertinoColors.systemGrey.resolveFrom(
                                  context,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // All sessions without individual day headers
                      ...sessions.map((session) {
                        return _buildSessionCard(session, isDark);
                      }),
                    ],
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Session session, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          // if (session.id != null && session.id!.isNotEmpty) {
          //   Navigator.of(context, rootNavigator: true).push(
          //     CupertinoPageRoute(
          //       builder: (context) => SessionDetailPage(sessionId: session.id!),
          //     ),
          //   );
          // }
        },
        child: Container(
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
              if (session.title != null && session.title!.isNotEmpty)
                Text(
                  session.title!,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    height: 1.3,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),

              if (session.title != null && session.title!.isNotEmpty)
                SizedBox(height: 16),

              // Time with clock icon
              if (session.time != null ||
                  (session.startTime != null && session.endTime != null))
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.clock,
                      size: 16,
                      color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                    ),
                    SizedBox(width: 6),
                    Text(
                      session.time ??
                          '${_formatTime(session.startTime)} - ${_formatTime(session.endTime)}',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SF Pro Display',
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),

              if (session.time != null ||
                  (session.startTime != null && session.endTime != null))
                SizedBox(height: 12),

              // Venue with location icon
              if (session.location != null || session.venue != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      CupertinoIcons.location_solid,
                      size: 16,
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        session.location ?? session.venue ?? '',
                        style: TextStyle(
                          fontSize: 15,
                          color: CupertinoTheme.of(
                            context,
                          ).textTheme.textStyle.color,
                          fontFamily: 'SF Pro Display',
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),

              if (session.location != null || session.venue != null)
                SizedBox(height: 16),

              // Badges (Role, Session Type, Status)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Role badge (Speaker)
                  if (session.role != null && session.role!.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? Color(0xFF007AFF) : Color(0xFF0387FE))
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        session.role!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SF Pro Display',
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  // Session Type badge
                  if (session.sessionType != null &&
                      session.sessionType!.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? Color(0xFF007AFF) : Color(0xFF0387FE))
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        session.sessionType!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SF Pro Display',
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  // Status badge
                  if (session.status != null && session.status!.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFF16A34A).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        session.status!,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _MeetingFormSheet extends ConsumerStatefulWidget {
  final String speakerId;
  final String speakerName;

  const _MeetingFormSheet({required this.speakerId, required this.speakerName});

  @override
  ConsumerState<_MeetingFormSheet> createState() => _MeetingFormSheetState();
}

class _MeetingFormSheetState extends ConsumerState<_MeetingFormSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isVideoMeeting = false;
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedStartTime = TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _selectedEndTime = TimeOfDay(hour: 10, minute: 30);

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Meeting - ${widget.speakerName}';
    final now = DateTime.now();
    _selectedDate = now.add(Duration(days: 1));
    _dateController.text = _formatDate(_selectedDate);
    _startTimeController.text = '10:00 AM';
    _endTimeController.text = '10:30 AM';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _convertDateFormat(String dateStr) {
    // Convert from DD/MM/YYYY to YYYY-MM-DD
    final parts = dateStr.split('/');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    return dateStr;
  }

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                minimumDate: DateTime.now(),
                maximumDate: DateTime.now().add(Duration(days: 365)),
                onDateTimeChanged: (DateTime picked) {
                  setState(() {
                    _selectedDate = picked;
                    _dateController.text = _formatDate(picked);
                  });
                },
              ),
            ),
            CupertinoButton(
              child: Text('Done'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimePicker(bool isStartTime) {
    TimeOfDay currentTime = isStartTime ? _selectedStartTime : _selectedEndTime;

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: false,
                initialDateTime: DateTime(
                  2024,
                  1,
                  1,
                  currentTime.hour,
                  currentTime.minute,
                ),
                onDateTimeChanged: (DateTime picked) {
                  setState(() {
                    final time = TimeOfDay(
                      hour: picked.hour,
                      minute: picked.minute,
                    );
                    if (isStartTime) {
                      _selectedStartTime = time;
                      _startTimeController.text = time.format(context);
                    } else {
                      _selectedEndTime = time;
                      _endTimeController.text = time.format(context);
                    }
                  });
                },
              ),
            ),
            CupertinoButton(
              child: Text('Done'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    // Show success message at the bottom
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CupertinoColors.systemGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitMeetingRequest() async {
    // Validation
    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a title');
      return;
    }

    if (_dateController.text.trim().isEmpty) {
      _showError('Please select a date');
      return;
    }

    if (_startTimeController.text.trim().isEmpty ||
        _endTimeController.text.trim().isEmpty) {
      _showError('Please select start and end time');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userData = ref.read(userDataProvider).valueOrNull;
      final homeData = ref.read(homePageDataProvider).valueOrNull;

      if (userData == null || homeData?.event == null) {
        throw Exception('User data not available');
      }

      // Convert date format from DD/MM/YYYY to YYYY-MM-DD
      final formattedDate = _convertDateFormat(_dateController.text.trim());

      // Call API
      final meetingRequestActions = ref.read(meetingRequestActionsProvider);
      final result = await meetingRequestActions.createMeetingRequest(
        eventId: homeData!.event!.id,
        requesterId: userData.id,
        requesterName: userData.name,
        recipientId: widget.speakerId,
        recipientName: widget.speakerName,
        title: _titleController.text.trim(),
        meetingDate: formattedDate,
        startTime: _startTimeController.text.trim(),
        endTime: _endTimeController.text.trim(),
        note: _noteController.text.trim(),
        location: _locationController.text.trim(),
        isVideoMeeting: _isVideoMeeting,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (result.success) {
        Navigator.of(context).pop();
        _showSuccessMessage(
          result.message ?? 'Meeting invite sent successfully',
        );
      } else {
        _showError(result.error ?? 'Failed to send invite');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      _showError('An unexpected error occurred');
    }
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
    final activeColor = isDark ? Color(0xFF007AFF) : Color(0xFF0387FE);

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
                  GestureDetector(
                    onTap: _showDatePicker,
                    child: AbsorbPointer(
                      child: CupertinoTextField(
                        controller: _dateController,
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
                            CupertinoIcons.calendar,
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
                            GestureDetector(
                              onTap: () => _showTimePicker(true),
                              child: AbsorbPointer(
                                child: CupertinoTextField(
                                  controller: _startTimeController,
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemGrey6
                                        .resolveFrom(context),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  suffix: Padding(
                                    padding: EdgeInsets.only(right: 12),
                                    child: Icon(
                                      CupertinoIcons.clock,
                                      color: CupertinoColors.systemGrey
                                          .resolveFrom(context),
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'SF Pro Display',
                                    letterSpacing: 0.2,
                                  ),
                                ),
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
                            GestureDetector(
                              onTap: () => _showTimePicker(false),
                              child: AbsorbPointer(
                                child: CupertinoTextField(
                                  controller: _endTimeController,
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemGrey6
                                        .resolveFrom(context),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  suffix: Padding(
                                    padding: EdgeInsets.only(right: 12),
                                    child: Icon(
                                      CupertinoIcons.clock,
                                      color: CupertinoColors.systemGrey
                                          .resolveFrom(context),
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'SF Pro Display',
                                    letterSpacing: 0.2,
                                  ),
                                ),
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
                          onPressed: _isLoading ? null : _submitMeetingRequest,
                          child: _isLoading
                              ? CupertinoActivityIndicator(
                                  color: CupertinoColors.white,
                                )
                              : Text(
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
