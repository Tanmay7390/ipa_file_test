import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/page_scaffold.dart';
import '../apis/providers/people_provider.dart';
import '../models/person.dart';

class PeopleDetailPage extends ConsumerStatefulWidget {
  final int personId;

  const PeopleDetailPage({super.key, required this.personId});

  @override
  ConsumerState<PeopleDetailPage> createState() => _PeopleDetailPageState();
}

class _PeopleDetailPageState extends ConsumerState<PeopleDetailPage> {
  final ScrollController _scrollController = ScrollController();
  int _currentTabIndex = 0;

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildInitialsAvatar(String initials, bool isDark) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.systemGrey.resolveFrom(context)
            : CupertinoColors.systemGrey5.resolveFrom(context),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w600,
            color: isDark
                ? CupertinoColors.white
                : CupertinoColors.darkBackgroundGray,
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index, bool isDark) {
    final isSelected = _currentTabIndex == index;
    return IntrinsicWidth(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentTabIndex = index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? (isDark ? Color(0xFF007AFF) : Color(0xFF0387FE))
                      : CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const Spacer(),
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Color(0xFF007AFF) : Color(0xFF0387FE))
                      : CupertinoColors.transparent,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(1.5),
                    topRight: Radius.circular(1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    String? content, {
    bool expandable = false,
    bool isExpanded = false,
    VoidCallback? onTap,
  }) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();

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
              content,
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

  Widget _buildPositionsSection(List<NotablePosition> positions) {
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
          ...positions.map(
            (position) => Container(
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
                    position.title ?? 'Position',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  if (position.companyName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      position.companyName!,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (position.startDate != null ||
                      position.endDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${position.startDate ?? ''} ${position.endDate != null
                              ? '- ${position.endDate}'
                              : position.startDate != null
                              ? '- Present'
                              : ''}'
                          .trim(),
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  ],
                  if (position.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.location,
                          size: 12,
                          color: CupertinoColors.tertiaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            position.location!,
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.tertiaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ),
                      ],
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
          ...educationList.map(
            (edu) => Container(
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
                    edu.degree,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  if (edu.field != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      edu.field!,
                      style: TextStyle(
                        fontSize: 15,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  ],
                  if (edu.university != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      edu.university!,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (edu.startYear != null || edu.endYear != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${edu.startYear ?? ''} ${edu.endYear != null
                              ? '- ${edu.endYear}'
                              : edu.startYear != null
                              ? '- Present'
                              : ''}'
                          .trim(),
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.tertiaryLabel.resolveFrom(
                          context,
                        ),
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

  Widget _buildCompanyTypesSection(List<CompanyType> companyTypes) {
    if (companyTypes.isEmpty) return const SizedBox.shrink();

    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Container(
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
          Text(
            'Company Affiliations',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: companyTypes
                .map(
                  (type) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Color(0xFF007AFF).withValues(alpha: 0.2)
                          : Color(0xFF0387FE).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          type.type,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Color(0xFF007AFF)
                                : Color(0xFF0387FE),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Color(0xFF007AFF)
                                : Color(0xFF0387FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${type.count}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<dynamic> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
          CupertinoListSection.insetGrouped(
            children: items.map((item) {
              String displayText = '';
              String? subtitle;

              if (item is NotablePosition) {
                displayText = item.position;
                subtitle = item.company;
              } else if (item is Education) {
                displayText = item.degree;
                subtitle = item.institution;
              } else if (item is CompanyType) {
                displayText = item.type;
                subtitle = '${item.count} companies';
              } else {
                displayText = item.toString();
              }

              return CupertinoListTile(
                title: Text(
                  displayText,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                subtitle: subtitle != null
                    ? Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      )
                    : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final personAsync = ref.watch(personDetailsProvider(widget.personId));
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CustomPageScaffold(
      scrollController: _scrollController,
      isLoading: personAsync.isLoading,
      heading: 'Person Details',
      hideLargeTitle: true,
      hideSearch: true,
      onRefresh: () async {
        ref.invalidate(personDetailsProvider(widget.personId));
      },
      sliverList: personAsync.when(
        data: (dynamic person) {
          if (person == null) {
            return SliverFillRemaining(
              child: Center(child: Text('Person not found')),
            );
          }

          return SliverList(
            delegate: SliverChildListDelegate([
              // Profile Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildInitialsAvatar(person.initials, isDark),
                    const SizedBox(height: 16),
                    Text(
                      person.displayName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (person.displayTitle.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        person.displayTitle,
                        style: TextStyle(
                          fontSize: 18,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (person.displayCompany.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        person.displayCompany,
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.tertiaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (person.displayLocation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.location_solid,
                            size: 14,
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            person.displayLocation,
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    if (person.linkedin != null && person.linkedin!.isNotEmpty)
                      Expanded(
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _launchUrl(person.linkedin!),
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
                    if (person.linkedin != null && person.website != null)
                      const SizedBox(width: 12),
                    if (person.website != null && person.website!.isNotEmpty)
                      Expanded(
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _launchUrl(person.website!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Color(0xFF007AFF)
                                  : Color(0xFF0387FE),
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

              // Tab Bar - Scrollable tabs with full-width underline
              Container(
                height: 50,
                margin: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: 0,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.systemGrey3.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTabButton('About', 0, isDark),
                      const SizedBox(width: 24),
                      _buildTabButton('Career', 1, isDark),
                      const SizedBox(width: 24),
                      _buildTabButton('Work', 2, isDark),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),

              // Tab Content - About
              if (_currentTabIndex == 0) ...[
                if (person.bio != null && person.bio!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      person.bio!,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
                if (person.background != null && person.background!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Professional Experience:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          person.background!,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],

              // Tab Content - Career
              if (_currentTabIndex == 1) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (person.awards != null &&
                          person.awards!.isNotEmpty) ...[
                        Text(
                          'Awards & Recognition:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          person.awards!,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (person.education != null &&
                          person.education!.isNotEmpty) ...[
                        Text(
                          'Education:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          person.education!,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (person.boards != null &&
                          person.boards!.isNotEmpty) ...[
                        Text(
                          'Board Memberships:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          person.boards!,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (person.founded != null &&
                          person.founded!.isNotEmpty) ...[
                        Text(
                          'Founded Companies:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          person.founded!,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Tab Content - Work
              if (_currentTabIndex == 2) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (person.institution != null &&
                          person.institution!.isNotEmpty) ...[
                        Text(
                          'Institution:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          person.institution!,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (person.department != null &&
                          person.department!.isNotEmpty) ...[
                        Text(
                          'Department:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          person.department!,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (person.workInfo != null &&
                          person.workInfo!.isNotEmpty) ...[
                        Text(
                          'Work Information:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          person.workInfo!,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

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
                  'Failed to load person details',
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
