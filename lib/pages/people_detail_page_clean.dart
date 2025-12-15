import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:axlmed/components/page_scaffold.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../apis/providers/people_provider.dart';

class PeopleDetailPageClean extends ConsumerStatefulWidget {
  final int personId;

  const PeopleDetailPageClean({super.key, required this.personId});

  @override
  ConsumerState<PeopleDetailPageClean> createState() =>
      _PeopleDetailPageCleanState();
}

class _PeopleDetailPageCleanState extends ConsumerState<PeopleDetailPageClean> {
  bool _isAboutExpanded = false;
  bool _isBackgroundExpanded = false;

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  // Get initials from name
  String _getInitials(Map<String, dynamic> data) {
    final name = data['name'] ?? data['axl_base_name'] ?? '';
    if (name.isEmpty) return '?';

    // Remove titles
    final cleaned = name.replaceAll(
      RegExp(r'^(Dr\.?|Prof\.?|Mr\.?|Mrs\.?|Ms\.?)\s+', caseSensitive: false),
      '',
    );

    final parts = cleaned.trim().split(' ');
    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }

    return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1))
        .toUpperCase();
  }

  String _getDisplayName(Map<String, dynamic> data) {
    return data['name'] ??
        data['axl_base_name'] ??
        '${data['axl_first_name'] ?? ''} ${data['axl_last_name'] ?? ''}'
            .trim() ??
        'Unknown';
  }

  String _getDisplayTitle(Map<String, dynamic> data) {
    return data['title'] ?? '';
  }

  String _getDisplayCompany(Map<String, dynamic> data) {
    return data['axl_company'] ?? data['company_name'] ?? '';
  }

  String _getDisplayLocation(Map<String, dynamic> data) {
    final city = data['axl_people_location_city'] ?? '';
    final state = data['axl_people_location_state'] ?? '';
    final country = data['axl_people_location_country'] ?? '';

    final parts = [city, state, country].where((s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }

  // Format time from ISO string
  String _formatTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return '';
    try {
      // Handle year-only format
      if (dateTimeString.length == 4 && int.tryParse(dateTimeString) != null) {
        return dateTimeString;
      }
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

  // Format date for display
  String _formatDateRange(String? start, String? end) {
    if (start == null || start.isEmpty) return '';

    // Handle year-only format
    if (start.length == 4 && int.tryParse(start) != null) {
      if (end == null || end.isEmpty) return '$start - Present';
      if (end.length == 4 && int.tryParse(end) != null) return '$start - $end';
    }

    // Full date format
    try {
      final startDate = DateTime.parse(start);
      final startYear = startDate.year.toString();

      if (end == null || end.isEmpty) {
        return '$startYear - Present';
      }

      final endDate = DateTime.parse(end);
      final endYear = endDate.year.toString();
      return '$startYear - $endYear';
    } catch (e) {
      // Fallback to original strings
      if (end == null || end.isEmpty) return '$start - Present';
      return '$start - $end';
    }
  }

  // Build initials avatar widget
  Widget _buildInitialsAvatar(String? name, bool isDark) {
    final initials = _getInitials({'name': name});

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

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final dataAsync = ref.watch(personDetailsProvider(widget.personId));

    return CustomPageScaffold(
      heading: 'Profile Details',
      hideSearch: true,
      isLoading: dataAsync.isLoading,
      hideLargeTitle: true,
      sliverList: SliverList(
        delegate: SliverChildListDelegate([
          dataAsync.when(
            data: (responseData) {
              if (responseData == null) {
                return Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        CupertinoIcons.person_crop_circle_badge_xmark,
                        size: 64,
                        color: CupertinoColors.systemGrey.resolveFrom(context),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Person not found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: CupertinoTheme.of(
                            context,
                          ).textTheme.textStyle.color,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Extract data from response
              final personData = responseData['data'] ?? responseData;
              final notablePositions = responseData['notable_positions'] ?? [];
              final education = responseData['education'] ?? [];

              return Column(
                children: [
                  // Header with photo and basic info
                  Container(
                    color: CupertinoColors.systemBackground.resolveFrom(
                      context,
                    ),
                    child: _buildHeader(personData, isDark),
                  ),

                  // Action buttons
                  Container(
                    color: CupertinoColors.systemBackground.resolveFrom(
                      context,
                    ),
                    padding: EdgeInsets.only(
                      top: 12,
                      bottom: 12,
                      left: 20,
                      right: 20,
                    ),
                    child: _buildActionButtons(context, personData),
                  ),
                  _buildSeparator(context),

                  // About/Bio section
                  if (personData['bio'] != null &&
                      personData['bio'].toString().isNotEmpty)
                    Container(
                      color: CupertinoColors.systemBackground.resolveFrom(
                        context,
                      ),
                      padding: EdgeInsets.only(top: 12, bottom: 12),
                      child: _buildAboutSection(personData, isDark),
                    ),

                  if (personData['bio'] != null &&
                      personData['bio'].toString().isNotEmpty)
                    _buildSeparator(context),

                  // Professional Background section
                  if (personData['professional_background'] != null &&
                      personData['professional_background']
                          .toString()
                          .isNotEmpty) ...[
                    Container(
                      color: CupertinoColors.systemBackground.resolveFrom(
                        context,
                      ),
                      padding: EdgeInsets.only(top: 12, bottom: 12),
                      child: _buildBackgroundSection(personData, isDark),
                    ),
                    _buildSeparator(context),
                  ],

                  // Additional Information section
                  if (_hasAdditionalInfo(personData)) ...[
                    Container(
                      color: CupertinoColors.systemBackground.resolveFrom(
                        context,
                      ),
                      padding: EdgeInsets.zero,
                      child: _buildAdditionalInfoSection(personData, isDark),
                    ),
                    _buildSeparator(context),
                  ],

                  // Career Experience section
                  if (notablePositions.isNotEmpty)
                    Container(
                      color: CupertinoColors.systemBackground.resolveFrom(
                        context,
                      ),
                      padding: EdgeInsets.zero,
                      child: _buildCareerSection(notablePositions, isDark),
                    ),

                  if (notablePositions.isNotEmpty) _buildSeparator(context),

                  // Education section
                  if (education.isNotEmpty)
                    Container(
                      color: CupertinoColors.systemBackground.resolveFrom(
                        context,
                      ),
                      padding: EdgeInsets.zero,
                      child: _buildEducationSection(education, isDark),
                    ),

                  SizedBox(height: 20),
                ],
              );
            },
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
                    'Error loading profile details',
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

  Widget _buildHeader(Map<String, dynamic> personData, bool isDark) {
    final displayName = _getDisplayName(personData);
    final displayTitle = _getDisplayTitle(personData);
    final displayCompany = _getDisplayCompany(personData);
    final displayLocation = _getDisplayLocation(personData);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile photo with initials fallback
          Stack(
            children: [
              _buildInitialsAvatar(displayName, isDark),
              // Photo would go here if available
            ],
          ),
          SizedBox(width: 20),

          // Name and details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                if (displayTitle.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(
                    displayTitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                      fontWeight: FontWeight.w500,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
                if (displayCompany.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    displayCompany,
                    style: TextStyle(
                      fontSize: 15,
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
                if (displayLocation.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.location_solid,
                        size: 14,
                        color: CupertinoColors.systemGrey.resolveFrom(context),
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          displayLocation,
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.systemGrey.resolveFrom(
                              context,
                            ),
                            fontFamily: 'SF Pro Display',
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Map<String, dynamic> personData,
  ) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Color(0xFF007AFF) : Color(0xFF0387FE);

    return Row(
      children: [
        // LinkedIn button
        if (personData['linkedin'] != null &&
            personData['linkedin'].toString().isNotEmpty) ...[
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF0A66C2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CupertinoButton(
                padding: EdgeInsets.symmetric(vertical: 12),
                borderRadius: BorderRadius.circular(12),
                onPressed: () => _launchUrl(personData['linkedin']),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.linkedinIn,
                      size: 18,
                      color: CupertinoColors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'LinkedIn',
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
          if (personData['website'] != null &&
              personData['website'].toString().isNotEmpty)
            SizedBox(width: 10),
        ],

        // Website button
        if (personData['website'] != null &&
            personData['website'].toString().isNotEmpty) ...[
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CupertinoButton(
                padding: EdgeInsets.symmetric(vertical: 12),
                borderRadius: BorderRadius.circular(12),
                onPressed: () => _launchUrl(personData['website']),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.globe,
                      size: 18,
                      color: CupertinoColors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Website',
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
        ],

        // Email button (if no LinkedIn or Website)
        if ((personData['linkedin'] == null ||
                personData['linkedin'].toString().isEmpty) &&
            (personData['website'] == null ||
                personData['website'].toString().isEmpty) &&
            personData['email'] != null &&
            personData['email'].toString().isNotEmpty)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CupertinoButton(
                padding: EdgeInsets.symmetric(vertical: 12),
                borderRadius: BorderRadius.circular(12),
                onPressed: () => _launchUrl('mailto:${personData['email']}'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.mail_solid,
                      size: 18,
                      color: CupertinoColors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Email',
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
      ],
    );
  }

  Widget _buildAboutSection(Map<String, dynamic> personData, bool isDark) {
    final aboutText = personData['bio']?.toString() ?? '';

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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aboutText,
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
                                color: CupertinoColors.systemGrey.resolveFrom(
                                  context,
                                ),
                                fontFamily: 'SF Pro Display',
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }

              return RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: aboutText.substring(0, 150),
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
        ],
      ),
    );
  }

  Widget _buildBackgroundSection(Map<String, dynamic> personData, bool isDark) {
    final backgroundText =
        personData['professional_background']?.toString() ?? '';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROFESSIONAL BACKGROUND',
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
            backgroundText,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: CupertinoTheme.of(context).textTheme.textStyle.color,
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.2,
            ),
            maxLines: _isBackgroundExpanded ? null : 3,
            overflow: _isBackgroundExpanded ? null : TextOverflow.ellipsis,
          ),
          if (backgroundText.length > 150)
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isBackgroundExpanded = !_isBackgroundExpanded;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    _isBackgroundExpanded ? 'see less' : 'see more',
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

  bool _hasAdditionalInfo(Map<String, dynamic> personData) {
    return (personData['department'] != null &&
            personData['department'].toString().isNotEmpty) ||
        (personData['institution'] != null &&
            personData['institution'].toString().isNotEmpty) ||
        (personData['awards'] != null &&
            personData['awards'].toString().isNotEmpty) ||
        (personData['awards_new'] != null &&
            personData['awards_new'].toString().isNotEmpty) ||
        (personData['industry_experiences'] != null &&
            personData['industry_experiences'].toString().isNotEmpty) ||
        (personData['boards'] != null &&
            personData['boards'].toString().isNotEmpty) ||
        (personData['founded'] != null &&
            personData['founded'].toString().isNotEmpty);
  }

  Widget _buildAdditionalInfoSection(
    Map<String, dynamic> personData,
    bool isDark,
  ) {
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

          // Department
          if (personData['department'] != null &&
              personData['department'].toString().isNotEmpty)
            _buildMinimalisticInfoRow(
              icon: CupertinoIcons.folder,
              label: 'Department',
              value: personData['department'].toString(),
            ),

          // Institution
          if (personData['institution'] != null &&
              personData['institution'].toString().isNotEmpty)
            _buildMinimalisticInfoRow(
              icon: CupertinoIcons.building_2_fill,
              label: 'Institution',
              value: personData['institution'].toString(),
            ),

          // Awards
          if ((personData['awards'] ?? personData['awards_new']) != null &&
              (personData['awards'] ?? personData['awards_new'])
                  .toString()
                  .isNotEmpty)
            _buildMinimalisticInfoRow(
              icon: CupertinoIcons.star_fill,
              label: 'Awards',
              value: (personData['awards'] ?? personData['awards_new'])
                  .toString(),
            ),

          // Industry Experience
          if (personData['industry_experiences'] != null &&
              personData['industry_experiences'].toString().isNotEmpty)
            _buildMinimalisticInfoRow(
              icon: CupertinoIcons.briefcase_fill,
              label: 'Industries',
              value: personData['industry_experiences'].toString(),
            ),

          // Boards
          if (personData['boards'] != null &&
              personData['boards'].toString().isNotEmpty)
            _buildMinimalisticInfoRow(
              icon: CupertinoIcons.person_3_fill,
              label: 'Board Memberships',
              value: personData['boards'].toString(),
            ),

          // Founded
          if (personData['founded'] != null &&
              personData['founded'].toString().isNotEmpty)
            _buildMinimalisticInfoRow(
              icon: CupertinoIcons.rocket_fill,
              label: 'Founded',
              value: personData['founded'].toString(),
            ),
        ],
      ),
    );
  }

  Widget _buildMinimalisticInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerSection(List<dynamic> positions, bool isDark) {
    final activeColor = isDark ? Color(0xFF007AFF) : Color(0xFF0387FE);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CAREER EXPERIENCE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey.resolveFrom(context),
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 16),
          ...positions.map(
            (position) =>
                _buildPositionCard(position as Map<String, dynamic>, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionCard(Map<String, dynamic> position, bool isDark) {
    final title = position['title'] ?? 'Position';
    final company =
        position['company_name'] ?? position['company_name_tb'] ?? '';
    final startDate = position['start_date']?.toString() ?? '';
    final endDate = position['end_date']?.toString() ?? '';
    final location = position['location'] ?? '';
    final isPrimary =
        position['is_primary'] == 'TRUE' || position['is_primary'] == true;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
          // Title and Primary badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                    height: 1.3,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
              ),
              if (isPrimary)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: (isDark ? Color(0xFF007AFF) : Color(0xFF0387FE))
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Current',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
            ],
          ),

          if (company.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              company,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Display',
                letterSpacing: 0.2,
              ),
            ),
          ],

          if (startDate.isNotEmpty || endDate.isNotEmpty) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  size: 16,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                ),
                SizedBox(width: 6),
                Text(
                  _formatDateRange(startDate, endDate),
                  style: TextStyle(
                    fontSize: 15,
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],

          if (location.isNotEmpty) ...[
            SizedBox(height: 8),
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
                    location,
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
          ],
        ],
      ),
    );
  }

  Widget _buildEducationSection(List<dynamic> educationList, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EDUCATION',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey.resolveFrom(context),
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 16),
          ...educationList.map(
            (edu) => _buildEducationCard(edu as Map<String, dynamic>, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationCard(Map<String, dynamic> edu, bool isDark) {
    final degree = edu['degree'] ?? '';
    final field = edu['field'] ?? '';
    final university = edu['university'] ?? edu['education_title'] ?? '';
    final startYear = edu['start_year']?.toString() ?? '';
    final endYear = edu['end_year']?.toString() ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
          if (degree.isNotEmpty)
            Text(
              degree,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'SF Pro Display',
                letterSpacing: 0.2,
                height: 1.3,
                color: CupertinoTheme.of(context).textTheme.textStyle.color,
              ),
            ),

          if (field.isNotEmpty) ...[
            SizedBox(height: 6),
            Text(
              field,
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontFamily: 'SF Pro Display',
                letterSpacing: 0.2,
              ),
            ),
          ],

          if (university.isNotEmpty) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  CupertinoIcons.book_solid,
                  size: 16,
                  color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    university,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (startYear.isNotEmpty || endYear.isNotEmpty) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  size: 14,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                ),
                SizedBox(width: 6),
                Text(
                  _formatDateRange(startYear, endYear),
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
