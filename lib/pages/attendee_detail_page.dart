import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rajapsicon/components/page_scaffold.dart';
// import 'package:rajapsicon/pages/direct_chat_page.dart';
import 'package:rajapsicon/apis/providers/attendees_provider.dart';
import 'package:rajapsicon/apis/providers/meeting_request_provider.dart';
// import 'package:rajapsicon/apis/providers/direct_chat_provider.dart';
import 'package:rajapsicon/providers/user_data_provider.dart';
import 'package:rajapsicon/providers/home_data_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AttendeeDetailPage extends ConsumerStatefulWidget {
  final String attendeeId;

  const AttendeeDetailPage({super.key, required this.attendeeId});

  @override
  ConsumerState<AttendeeDetailPage> createState() => _AttendeeDetailPageState();
}

class _AttendeeDetailPageState extends ConsumerState<AttendeeDetailPage> {
  bool _isAboutExpanded = false;

  void _showMeetingSheet(String attendeeId, String attendeeName) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) =>
          _MeetingFormSheet(attendeeId: attendeeId, attendeeName: attendeeName),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

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

  // Check if attendee has any additional info to display
  bool _hasAdditionalInfo(Attendee attendee) {
    return (attendee.phone != null && attendee.phone!.isNotEmpty) ||
        (attendee.email != null && attendee.email!.isNotEmpty) ||
        (attendee.location != null && attendee.location!.isNotEmpty) ||
        (attendee.organization != null && attendee.organization!.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final attendeeAsync = ref.watch(attendeeDetailProvider(widget.attendeeId));

    return CustomPageScaffold(
      heading: 'Attendee Details',
      hideSearch: true,
      isLoading: attendeeAsync.isLoading,
      hideLargeTitle: true,
      sliverList: SliverList(
        delegate: SliverChildListDelegate([
          attendeeAsync.when(
            data: (attendee) => Column(
              children: [
                // Header with photo and basic info
                Container(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  child: _buildHeader(attendee, isDark),
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
                  child: _buildActionButtons(context, attendee),
                ),
                _buildSeparator(context),

                // About section
                if (attendee.about != null && attendee.about!.isNotEmpty)
                  Container(
                    color: CupertinoColors.systemBackground.resolveFrom(
                      context,
                    ),
                    padding: EdgeInsets.only(top: 12, bottom: 12),
                    child: _buildAboutSection(attendee, isDark),
                  ),

                if (attendee.about != null && attendee.about!.isNotEmpty)
                  _buildSeparator(context),

                // Additional Information section
                if (_hasAdditionalInfo(attendee))
                  Container(
                    color: CupertinoColors.systemBackground.resolveFrom(
                      context,
                    ),
                    padding: EdgeInsets.zero,
                    child: _buildAdditionalInfoSection(attendee, isDark),
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
                    'Error loading attendee details',
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

  Widget _buildHeader(Attendee attendee, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile photo with initials fallback
          Stack(
            children: [
              // Always show initials first (instant load)
              _buildInitialsAvatar(attendee.name, isDark),
              // Overlay photo on top if available
              if (attendee.photo != null && attendee.photo!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    attendee.photo!,
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
                  attendee.name ?? '',
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
                  attendee.designation ?? attendee.title ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                  ),
                ),
                if (attendee.organization != null) ...[
                  SizedBox(height: 4),
                  Text(
                    attendee.organization!,
                    style: TextStyle(
                      fontSize: 15,
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Attendee attendee) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Color(0xFF23C061) : Color(0xFF21AA62);
    final canMessage =
        attendee.canMessage == true && attendee.messengerId != null;

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
                  _showMeetingSheet(attendee.id, attendee.name ?? ''),
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

  Widget _buildAboutSection(Attendee attendee, bool isDark) {
    final aboutText = attendee.about ?? '';

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

  Widget _buildAdditionalInfoSection(Attendee attendee, bool isDark) {
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

          // Phone
          if (attendee.phone != null && attendee.phone!.isNotEmpty)
            _buildMinimalisticInfoRow(
              icon: CupertinoIcons.phone_fill,
              label: 'Phone',
              value: attendee.phone!,
              isClickable: true,
              onTap: () => _launchUrl('tel:${attendee.phone}'),
            ),

          // Email
          if (attendee.email != null && attendee.email!.isNotEmpty)
            _buildMinimalisticInfoRow(
              icon: CupertinoIcons.mail_solid,
              label: 'Email',
              value: attendee.email!,
              isClickable: true,
              onTap: () => _launchUrl('mailto:${attendee.email}'),
            ),

          // Location
          if (attendee.location != null && attendee.location!.isNotEmpty)
            _buildMinimalisticInfoRow(
              icon: CupertinoIcons.location_solid,
              label: 'Location',
              value: attendee.location!,
              isClickable: false,
            ),

          // Organization
          if (attendee.organization != null &&
              attendee.organization!.isNotEmpty)
            _buildMinimalisticInfoRow(
              icon: CupertinoIcons.building_2_fill,
              label: 'Organization',
              value: attendee.organization!,
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
}

class _MeetingFormSheet extends ConsumerStatefulWidget {
  final String attendeeId;
  final String attendeeName;

  const _MeetingFormSheet({
    required this.attendeeId,
    required this.attendeeName,
  });

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
  DateTime _selectedStartTime = DateTime.now();
  DateTime _selectedEndTime = DateTime.now().add(Duration(minutes: 30));

  @override
  void initState() {
    super.initState();
    _titleController.text = 'Meeting - ${widget.attendeeName}';
    _updateDateTimeDisplay();
  }

  void _updateDateTimeDisplay() {
    // Format date as DD/MM/YYYY
    _dateController.text =
        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';

    // Format time as HH:MM AM/PM
    _startTimeController.text = _formatTime(_selectedStartTime);
    _endTimeController.text = _formatTime(_selectedEndTime);
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoButton(
                  child: Text('Done'),
                  onPressed: () {
                    setState(() {
                      _updateDateTimeDisplay();
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                minimumDate: DateTime.now().subtract(Duration(days: 1)),
                onDateTimeChanged: (DateTime newDate) {
                  _selectedDate = newDate;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimePicker(bool isStartTime) {
    final initialTime = isStartTime ? _selectedStartTime : _selectedEndTime;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoButton(
                  child: Text('Done'),
                  onPressed: () {
                    setState(() {
                      _updateDateTimeDisplay();
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: initialTime,
                use24hFormat: false,
                onDateTimeChanged: (DateTime newTime) {
                  if (isStartTime) {
                    _selectedStartTime = newTime;
                  } else {
                    _selectedEndTime = newTime;
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
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

  String _convertDateFormat(String date) {
    // Convert from DD/MM/YYYY to YYYY-MM-DD
    try {
      final parts = date.split('/');
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$year-$month-$day';
      }
    } catch (e) {
      // Return original if conversion fails
    }
    return date;
  }

  Future<void> _handleSendInvite() async {
    // Validate required fields
    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a title');
      return;
    }

    if (_dateController.text.trim().isEmpty) {
      _showError('Please select a date');
      return;
    }

    if (_startTimeController.text.trim().isEmpty) {
      _showError('Please select a start time');
      return;
    }

    if (_endTimeController.text.trim().isEmpty) {
      _showError('Please select an end time');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user data
      final userData = ref.read(userDataProvider).valueOrNull;
      if (userData == null) {
        _showError('User not found. Please login again.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get event ID
      final homeData = ref.read(homePageDataProvider).valueOrNull;
      if (homeData?.event?.id == null) {
        _showError('Event not found. Please try again.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Convert date format from DD/MM/YYYY to YYYY-MM-DD
      final formattedDate = _convertDateFormat(_dateController.text.trim());

      // Call API
      final meetingRequestActions = ref.read(meetingRequestActionsProvider);
      final result = await meetingRequestActions.createMeetingRequest(
        eventId: homeData!.event!.id,
        requesterId: userData.id,
        requesterName: userData.name,
        recipientId: widget.attendeeId,
        recipientName: widget.attendeeName,
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

  void _showSuccessMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Success'),
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
            padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Suggest a Meeting',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1),
          SizedBox(height: 16),

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
                          onPressed: _isLoading ? null : _handleSendInvite,
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
