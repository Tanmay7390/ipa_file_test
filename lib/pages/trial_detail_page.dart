import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/page_scaffold.dart';
import '../apis/providers/trials_provider.dart';

class TrialDetailPage extends ConsumerStatefulWidget {
  final String nctNumber;

  const TrialDetailPage({super.key, required this.nctNumber});

  @override
  ConsumerState<TrialDetailPage> createState() => _TrialDetailPageState();
}

class _TrialDetailPageState extends ConsumerState<TrialDetailPage> {
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
    if (content == null || content.isEmpty || content == 'null') {
      return const SizedBox.shrink();
    }

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

  String _getInitials(String nctNumber) {
    return nctNumber.substring(0, nctNumber.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final trialAsync = ref.watch(trialDetailsProvider(widget.nctNumber));
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CustomPageScaffold(
      scrollController: _scrollController,
      isLoading: trialAsync.isLoading,
      heading: 'Trial Details',
      hideLargeTitle: true,
      hideSearch: true,
      onRefresh: () async {
        ref.invalidate(trialDetailsProvider(widget.nctNumber));
      },
      sliverList: trialAsync.when(
        data: (dynamic trial) {
          if (trial == null) {
            return SliverFillRemaining(
              child: Center(child: Text('Trial not found')),
            );
          }

          final data = trial['data'] ?? {};
          final String nctNumber = data['nct_number'] ?? widget.nctNumber;
          final String? briefTitle = data['axl_brief_title']?.toString();
          final String? officialTitle = data['axl_official_title']?.toString();
          final String? briefSummary = data['axl_brief_summary']?.toString();
          final String? description = data['axl_description']?.toString();
          final String? phase = data['axl_phase']?.toString();
          final String? status = data['axl_status']?.toString();
          final String? companyName = data['axl_company_name']?.toString();
          final String? conditions = data['conditions']?.toString();
          final String? interventions = data['interventions']?.toString();
          final String? locations = data['locations']?.toString();
          final String? outcomeMeasures = data['outcome_measures']?.toString();
          final String? studyDesigns = data['study_designs']?.toString();
          final enrollment = data['enrollment'];
          final String? startDate = data['axl_start_date']?.toString();
          final String? completionDate = data['axl_primary_completion_date']
              ?.toString();

          final initials = _getInitials(nctNumber);
          final title = briefTitle ?? officialTitle ?? 'Unknown Trial';

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
                      nctNumber,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (phase != null &&
                        phase != 'null' &&
                        phase.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        phase,
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (status != null &&
                        status != 'null' &&
                        status.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            status!,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getStatusColor(
                              status!,
                            ).withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          status!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(status!),
                          ),
                        ),
                      ),
                    ],
                    if (companyName != null &&
                        companyName != 'null' &&
                        companyName.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.building_2_fill,
                            size: 14,
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            companyName!,
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

              // Action Button - ClinicalTrials.gov Link
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () =>
                      _launchUrl('https://clinicaltrials.gov/study/$nctNumber'),
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
                          CupertinoIcons.link,
                          color: CupertinoColors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'View on ClinicalTrials.gov',
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
                      _buildTabButton('Overview', 0, isDark),
                      const SizedBox(width: 24),
                      _buildTabButton('Details', 1, isDark),
                      const SizedBox(width: 24),
                      _buildTabButton('Design', 2, isDark),
                      const SizedBox(width: 24),
                      _buildTabButton('Info', 3, isDark),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),

              // Tab Content - Overview
              if (_currentTabIndex == 0) ...[
                if (briefSummary != null && briefSummary != 'null')
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Brief Summary:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          briefSummary,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (description != null && description != 'null')
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detailed Description:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
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

              // Tab Content - Details
              if (_currentTabIndex == 1) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (conditions != null && conditions != 'null') ...[
                        Text(
                          'Conditions:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          conditions,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (interventions != null && interventions != 'null') ...[
                        Text(
                          'Interventions:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          interventions,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (enrollment != null ||
                          startDate != null ||
                          completionDate != null) ...[
                        Text(
                          'Trial Information:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (phase != null && phase != 'null')
                          Text(
                            '• Phase: $phase',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: CupertinoColors.label.resolveFrom(context),
                            ),
                          ),
                        if (status != null && status != 'null')
                          Text(
                            '• Status: $status',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: CupertinoColors.label.resolveFrom(context),
                            ),
                          ),
                        if (enrollment != null)
                          Text(
                            '• Enrollment: $enrollment',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: CupertinoColors.label.resolveFrom(context),
                            ),
                          ),
                        if (startDate != null && startDate != 'null')
                          Text(
                            '• Start Date: $startDate',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: CupertinoColors.label.resolveFrom(context),
                            ),
                          ),
                        if (completionDate != null && completionDate != 'null')
                          Text(
                            '• Completion Date: $completionDate',
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

              // Tab Content - Design
              if (_currentTabIndex == 2) ...[
                if (studyDesigns != null && studyDesigns != 'null')
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      studyDesigns,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
              ],

              // Tab Content - Info
              if (_currentTabIndex == 3) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Assuming sponsor, responsibleParty, primaryOutcome are available in `data`
                      // For now, using companyName for sponsor as a placeholder if not available
                      if (companyName != null && companyName != 'null') ...[
                        Text(
                          'Sponsor:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          companyName, // Placeholder, replace with actual sponsor if available
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (locations != null && locations != 'null') ...[
                        Text(
                          'Locations:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          locations,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (outcomeMeasures != null &&
                          outcomeMeasures != 'null') ...[
                        Text(
                          'Outcome Measures:', // Renamed from 'Responsible Party' for existing data
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          outcomeMeasures, // Placeholder, replace with actual responsibleParty if available
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Assuming primaryOutcome is part of outcomeMeasures or a separate field
                      // For now, not adding a separate primaryOutcome if it's not in the original data structure
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
                  'Failed to load trial details',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: () {
                    ref.invalidate(trialDetailsProvider(widget.nctNumber));
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

  Color _getStatusColor(String status) {
    if (status.toUpperCase().contains('RECRUITING')) {
      return CupertinoColors.systemGreen;
    } else if (status.toUpperCase().contains('ACTIVE')) {
      return CupertinoColors.systemBlue;
    } else if (status.toUpperCase().contains('COMPLETED')) {
      return CupertinoColors.systemGrey;
    } else if (status.toUpperCase().contains('TERMINATED') ||
        status.toUpperCase().contains('WITHDRAWN')) {
      return CupertinoColors.systemRed;
    } else {
      return CupertinoColors.systemOrange;
    }
  }
}
