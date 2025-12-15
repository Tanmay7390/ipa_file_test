import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/page_scaffold.dart';
import '../apis/providers/people_provider.dart';

class PeopleDetailPageDynamic extends ConsumerStatefulWidget {
  final int personId;

  const PeopleDetailPageDynamic({super.key, required this.personId});

  @override
  ConsumerState<PeopleDetailPageDynamic> createState() => _PeopleDetailPageDynamicState();
}

class _PeopleDetailPageDynamicState extends ConsumerState<PeopleDetailPageDynamic> {
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

  Widget _buildInitialsAvatar(String initials, bool isDark) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
            isDark ? Color(0xFF005BB5) : Color(0xFF026DCE),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    dynamic content, {
    bool expandable = false,
    bool isExpanded = false,
    VoidCallback? onTap,
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? CupertinoColors.systemGrey6.darkColor
              : CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                if (expandable)
                  Icon(
                    actualExpanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 14,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
              maxLines: expandable && !actualExpanded ? 3 : null,
              overflow: expandable && !actualExpanded
                  ? TextOverflow.ellipsis
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionsSection(List<dynamic> positions) {
    if (positions.isEmpty) return const SizedBox.shrink();

    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Career Experience',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
          ...positions.map((position) {
            final data = position as Map<String, dynamic>;
            final title = data['title'] ?? 'Position';
            final company = data['company_name'] ?? data['company_name_tb'] ?? '';
            final startDate = data['start_date']?.toString() ?? '';
            final endDate = data['end_date']?.toString() ?? '';
            final location = data['location'] ?? '';
            final department = data['department'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? CupertinoColors.systemGrey6.darkColor
                    : CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                  if (company.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      company,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (department.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      department,
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                  if (startDate.isNotEmpty || endDate.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      endDate.isEmpty && startDate.isNotEmpty
                        ? '$startDate - Present'
                        : '$startDate - $endDate'.trim(),
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.location,
                          size: 12,
                          color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEducationSection(List<dynamic> educationList) {
    if (educationList.isEmpty) return const SizedBox.shrink();

    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Education',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
          ...educationList.map((edu) {
            final data = edu as Map<String, dynamic>;
            final degree = data['degree'] ?? '';
            final field = data['field'] ?? '';
            final university = data['university'] ?? data['education_title'] ?? '';
            final startYear = data['start_year']?.toString() ?? '';
            final endYear = data['end_year']?.toString() ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? CupertinoColors.systemGrey6.darkColor
                    : CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (degree.isNotEmpty)
                    Text(
                      degree,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
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
                    const SizedBox(height: 4),
                    Text(
                      university,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (startYear.isNotEmpty || endYear.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      endYear.isNotEmpty
                        ? '$startYear - $endYear'.trim()
                        : startYear,
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(personDetailsProvider(widget.personId));
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CustomPageScaffold(
      scrollController: _scrollController,
      isLoading: dataAsync.isLoading,
      heading: 'Person Details',
      hideLargeTitle: true,
      hideSearch: true,
      onRefresh: () async {
        ref.invalidate(personDetailsProvider(widget.personId));
      },
      sliverList: dataAsync.when(
        data: (responseData) {
          if (responseData == null) {
            return SliverFillRemaining(
              child: Center(child: Text('Person not found')),
            );
          }

          // Extract the person data from response
          final personData = responseData['data'] ?? responseData;
          final notablePositions = responseData['notable_positions'] ?? [];
          final education = responseData['education'] ?? [];

          // Get display values
          final initials = _getInitials(personData);
          final displayName = _getDisplayName(personData);
          final displayTitle = _getDisplayTitle(personData);
          final displayCompany = _getDisplayCompany(personData);
          final displayLocation = _getDisplayLocation(personData);

          return SliverList(
            delegate: SliverChildListDelegate([
              // Profile Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildInitialsAvatar(initials, isDark),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (displayTitle.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        displayTitle,
                        style: TextStyle(
                          fontSize: 18,
                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (displayCompany.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        displayCompany,
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                        ),
                        textAlign: TextAlign.center,
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
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            displayLocation,
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

              // Action Buttons
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (personData['linkedin'] != null && personData['linkedin'].toString().isNotEmpty)
                      Expanded(
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _launchUrl(personData['linkedin']),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Color(0xFF0077B5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.link,
                                  color: CupertinoColors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'LinkedIn',
                                  style: TextStyle(
                                    color: CupertinoColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (personData['linkedin'] != null && personData['website'] != null)
                      const SizedBox(width: 12),
                    if (personData['website'] != null && personData['website'].toString().isNotEmpty)
                      Expanded(
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _launchUrl(personData['website']),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.globe,
                                  color: CupertinoColors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Website',
                                  style: TextStyle(
                                    color: CupertinoColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Biography
              _buildInfoSection(
                'Biography',
                personData['bio'],
                expandable: true,
                isExpanded: _isBioExpanded,
                onTap: () {
                  setState(() {
                    _isBioExpanded = !_isBioExpanded;
                  });
                },
              ),

              // Professional Background
              _buildInfoSection(
                'Professional Background',
                personData['professional_background'],
                expandable: true,
                isExpanded: _isBackgroundExpanded,
                onTap: () {
                  setState(() {
                    _isBackgroundExpanded = !_isBackgroundExpanded;
                  });
                },
              ),

              // Notable Positions
              if (notablePositions.isNotEmpty)
                _buildPositionsSection(notablePositions),

              // Education History
              if (education.isNotEmpty)
                _buildEducationSection(education),

              // Awards
              _buildInfoSection('Awards & Recognition', personData['awards'] ?? personData['awards_new']),

              // Industry Experience
              _buildInfoSection('Industry Experience', personData['industry_experiences']),

              // Boards
              _buildInfoSection('Board Memberships', personData['boards']),

              // Founded Companies
              _buildInfoSection('Founded Companies', personData['founded']),

              // Titles
              _buildInfoSection('Titles', personData['titles']),

              // Department
              _buildInfoSection('Department', personData['department']),

              // Institution
              _buildInfoSection('Institution', personData['institution']),

              // Previous Positions
              _buildInfoSection('Previous Positions', personData['previous_positions']),

              // Context
              _buildInfoSection('Context', personData['context']),

              // Contribution
              _buildInfoSection('Contribution', personData['contribution']),

              const SizedBox(height: 100), // Bottom padding
            ]),
          );
        },
        loading: () => SliverFillRemaining(
          child: Center(child: CupertinoActivityIndicator()),
        ),
        error: (error, stack) => SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_circle,
                  size: 48,
                  color: CupertinoColors.systemRed,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading details',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: () {
                    ref.invalidate(personDetailsProvider(widget.personId));
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}