import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/page_scaffold.dart';
import '../apis/providers/people_provider.dart';

class PeopleDetailPageRedesigned extends ConsumerStatefulWidget {
  final int personId;

  const PeopleDetailPageRedesigned({super.key, required this.personId});

  @override
  ConsumerState<PeopleDetailPageRedesigned> createState() => _PeopleDetailPageRedesignedState();
}

class _PeopleDetailPageRedesignedState extends ConsumerState<PeopleDetailPageRedesigned> {
  final ScrollController _scrollController = ScrollController();
  bool _isBioExpanded = false;
  bool _isBackgroundExpanded = false;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _getInitials(Map<String, dynamic> data) {
    final name = data['name'] ?? data['axl_base_name'] ?? '';
    if (name.isEmpty) return '?';

    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _getDisplayName(Map<String, dynamic> data) {
    return data['name'] ??
           data['axl_base_name'] ??
           '${data['axl_first_name'] ?? ''} ${data['axl_last_name'] ?? ''}'.trim() ??
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

  Widget _buildProfileHeader(Map<String, dynamic> personData, bool isDark) {
    final initials = _getInitials(personData);
    final displayName = _getDisplayName(personData);
    final displayTitle = _getDisplayTitle(personData);
    final displayCompany = _getDisplayCompany(personData);
    final displayLocation = _getDisplayLocation(personData);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Color(0xFF1C3A52) : Color(0xFF4A90E2),
            isDark ? Color(0xFF0F1F2E) : Color(0xFF357ABD),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CupertinoColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Color(0xFF1C3A52) : Color(0xFF4A90E2),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Name
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.white,
                ),
                textAlign: TextAlign.center,
              ),

              if (displayTitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    displayTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ],

              if (displayCompany.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.building_2_fill,
                      size: 16,
                      color: CupertinoColors.white.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      displayCompany,
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ],

              if (displayLocation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.location_solid,
                      size: 14,
                      color: CupertinoColors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      displayLocation,
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],

              // Action Buttons
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (personData['linkedin'] != null && personData['linkedin'].toString().isNotEmpty) ...[
                    _buildActionButton(
                      icon: CupertinoIcons.link,
                      label: 'LinkedIn',
                      color: Color(0xFF0077B5),
                      onTap: () => _launchUrl(personData['linkedin']),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (personData['website'] != null && personData['website'].toString().isNotEmpty)
                    _buildActionButton(
                      icon: CupertinoIcons.globe,
                      label: 'Website',
                      color: CupertinoColors.white,
                      textColor: isDark ? Color(0xFF1C3A52) : Color(0xFF4A90E2),
                      onTap: () => _launchUrl(personData['website']),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    Color textColor = CupertinoColors.white,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: CupertinoColors.systemBlue,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    dynamic content, {
    bool expandable = false,
    bool isExpanded = false,
    VoidCallback? onTap,
    IconData? icon,
  }) {
    String? text;
    if (content is String && content.isNotEmpty) {
      text = content;
    } else if (content != null && content.toString().isNotEmpty && content.toString() != 'null') {
      text = content.toString();
    }

    if (text == null || text.isEmpty) return const SizedBox.shrink();

    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final actualExpanded = expandable ? isExpanded : false;

    return GestureDetector(
      onTap: expandable ? onTap : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? CupertinoColors.systemGrey6.darkColor
              : CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 18,
                      color: CupertinoColors.systemBlue,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ),
                  if (expandable)
                    Icon(
                      actualExpanded
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.chevron_down,
                      size: 16,
                      color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
                maxLines: expandable && !actualExpanded ? 3 : null,
                overflow: expandable && !actualExpanded
                    ? TextOverflow.ellipsis
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPositionCard(Map<String, dynamic> position) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final title = position['title'] ?? 'Position';
    final company = position['company_name'] ?? position['company_name_tb'] ?? '';
    final startDate = position['start_date']?.toString() ?? '';
    final endDate = position['end_date']?.toString() ?? '';
    final location = position['location'] ?? '';
    final department = position['department'] ?? '';
    final isPrimary = position['is_primary'] == 'TRUE' || position['is_primary'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? CupertinoColors.systemGrey6.darkColor : CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPrimary ? Border.all(
          color: CupertinoColors.systemBlue.withValues(alpha: 0.3),
          width: 2,
        ) : null,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (company.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          company,
                          style: TextStyle(
                            fontSize: 15,
                            color: CupertinoColors.systemBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isPrimary)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Current',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.systemBlue,
                      ),
                    ),
                  ),
              ],
            ),
            if (department.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5.resolveFrom(context),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  department,
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  size: 14,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                ),
                const SizedBox(width: 6),
                Text(
                  endDate.isEmpty && startDate.isNotEmpty
                    ? '$startDate - Present'
                    : startDate.isNotEmpty || endDate.isNotEmpty
                      ? '$startDate - $endDate'.trim()
                      : 'Duration not specified',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
            if (location.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.location,
                    size: 14,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEducationCard(Map<String, dynamic> edu) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final degree = edu['degree'] ?? '';
    final field = edu['field'] ?? '';
    final university = edu['university'] ?? edu['education_title'] ?? '';
    final startYear = edu['start_year']?.toString() ?? '';
    final endYear = edu['end_year']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? CupertinoColors.systemGrey6.darkColor : CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (degree.isNotEmpty)
              Text(
                degree,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (field.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                field,
                style: TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
            if (university.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.book,
                    size: 16,
                    color: CupertinoColors.systemBlue,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      university,
                      style: TextStyle(
                        fontSize: 15,
                        color: CupertinoColors.systemBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (startYear.isNotEmpty || endYear.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.calendar,
                    size: 14,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    endYear.isNotEmpty
                      ? '$startYear - $endYear'.trim()
                      : startYear,
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(personDetailsProvider(widget.personId));
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF1C3A52) : Color(0xFF4A90E2),
        border: null,
        middle: Text(
          'Profile',
          style: TextStyle(color: CupertinoColors.white),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              Icon(CupertinoIcons.back, color: CupertinoColors.white),
              const SizedBox(width: 4),
              Text(
                'Back',
                style: TextStyle(color: CupertinoColors.white),
              ),
            ],
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: dataAsync.when(
        data: (responseData) {
          if (responseData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.person_crop_circle_badge_xmark,
                    size: 64,
                    color: CupertinoColors.systemGrey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Person not found',
                    style: TextStyle(
                      fontSize: 18,
                      color: CupertinoColors.secondaryLabel,
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

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Profile Header
              SliverToBoxAdapter(
                child: _buildProfileHeader(personData, isDark),
              ),

              // Biography Section
              if (personData['bio'] != null && personData['bio'].toString().isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader('About', icon: CupertinoIcons.person_fill),
                ),
                SliverToBoxAdapter(
                  child: _buildInfoCard(
                    'Biography',
                    personData['bio'],
                    expandable: true,
                    isExpanded: _isBioExpanded,
                    icon: CupertinoIcons.doc_text,
                    onTap: () {
                      setState(() {
                        _isBioExpanded = !_isBioExpanded;
                      });
                    },
                  ),
                ),
              ],

              // Professional Background
              if (personData['professional_background'] != null &&
                  personData['professional_background'].toString().isNotEmpty) ...[
                if (personData['bio'] == null || personData['bio'].toString().isEmpty)
                  SliverToBoxAdapter(
                    child: _buildSectionHeader('About', icon: CupertinoIcons.person_fill),
                  ),
                SliverToBoxAdapter(
                  child: _buildInfoCard(
                    'Professional Background',
                    personData['professional_background'],
                    expandable: true,
                    isExpanded: _isBackgroundExpanded,
                    icon: CupertinoIcons.briefcase,
                    onTap: () {
                      setState(() {
                        _isBackgroundExpanded = !_isBackgroundExpanded;
                      });
                    },
                  ),
                ),
              ],

              // Career Experience Section
              if (notablePositions.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader('Career Experience', icon: CupertinoIcons.briefcase_fill),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildPositionCard(notablePositions[index]),
                    childCount: notablePositions.length,
                  ),
                ),
              ],

              // Education Section
              if (education.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader('Education', icon: CupertinoIcons.book_fill),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildEducationCard(education[index]),
                    childCount: education.length,
                  ),
                ),
              ],

              // Additional Information Section
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Awards
                    if ((personData['awards'] ?? personData['awards_new']) != null &&
                        (personData['awards'] ?? personData['awards_new']).toString().isNotEmpty) ...[
                      _buildSectionHeader('Recognition', icon: CupertinoIcons.star_fill),
                      _buildInfoCard(
                        'Awards & Achievements',
                        personData['awards'] ?? personData['awards_new'],
                        icon: CupertinoIcons.rosette,
                      ),
                    ],

                    // Industry Experience
                    if (personData['industry_experiences'] != null &&
                        personData['industry_experiences'].toString().isNotEmpty) ...[
                      if ((personData['awards'] ?? personData['awards_new']) == null)
                        _buildSectionHeader('Experience', icon: CupertinoIcons.chart_bar_fill),
                      _buildInfoCard(
                        'Industry Experience',
                        personData['industry_experiences'],
                        icon: CupertinoIcons.building_2_fill,
                      ),
                    ],

                    // Boards
                    if (personData['boards'] != null &&
                        personData['boards'].toString().isNotEmpty) ...[
                      _buildSectionHeader('Leadership', icon: CupertinoIcons.person_3_fill),
                      _buildInfoCard(
                        'Board Memberships',
                        personData['boards'],
                        icon: CupertinoIcons.person_badge_plus,
                      ),
                    ],

                    // Founded Companies
                    if (personData['founded'] != null &&
                        personData['founded'].toString().isNotEmpty)
                      _buildInfoCard(
                        'Founded Companies',
                        personData['founded'],
                        icon: CupertinoIcons.rocket_fill,
                      ),

                    // Department
                    if (personData['department'] != null &&
                        personData['department'].toString().isNotEmpty) ...[
                      _buildSectionHeader('Organization', icon: CupertinoIcons.building_2_fill),
                      _buildInfoCard(
                        'Department',
                        personData['department'],
                        icon: CupertinoIcons.folder,
                      ),
                    ],

                    // Institution
                    if (personData['institution'] != null &&
                        personData['institution'].toString().isNotEmpty)
                      _buildInfoCard(
                        'Institution',
                        personData['institution'],
                        icon: CupertinoIcons.building_2_fill,
                      ),

                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoActivityIndicator(radius: 20),
              const SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.exclamationmark_circle,
                size: 64,
                color: CupertinoColors.systemRed,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please try again',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: 24),
              CupertinoButton.filled(
                onPressed: () {
                  ref.invalidate(personDetailsProvider(widget.personId));
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}