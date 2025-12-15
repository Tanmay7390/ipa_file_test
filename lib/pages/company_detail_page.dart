import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/page_scaffold.dart';
import '../apis/providers/company_provider.dart';

class CompanyDetailPage extends ConsumerStatefulWidget {
  final int companyId;

  const CompanyDetailPage({super.key, required this.companyId});

  @override
  ConsumerState<CompanyDetailPage> createState() => _CompanyDetailPageState();
}

class _CompanyDetailPageState extends ConsumerState<CompanyDetailPage> {
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

  Widget _buildNotablePositionsSection(List<dynamic> positions) {
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
              'Key Personnel',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
          ...positions.map((position) {
            final peopleName = position['people_name'] ?? '';
            final titleCategory = position['title_category'] ?? '';
            final companyPeopleCategory =
                position['company_people_category'] ?? '';

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
                    titleCategory.isNotEmpty ? titleCategory : peopleName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  if (peopleName.isNotEmpty && titleCategory.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      peopleName,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (companyPeopleCategory.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      companyPeopleCategory,
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
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

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty
        ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase()
        : '?';
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

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(companyDetailsProvider(widget.companyId));
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CustomPageScaffold(
      scrollController: _scrollController,
      isLoading: companyAsync.isLoading,
      heading: 'Company Details',
      hideLargeTitle: true,
      hideSearch: true,
      onRefresh: () async {
        ref.invalidate(companyDetailsProvider(widget.companyId));
      },
      sliverList: companyAsync.when(
        data: (dynamic company) {
          if (company == null) {
            return SliverFillRemaining(
              child: Center(child: Text('Company not found')),
            );
          }

          final data = company['data'] ?? {};
          final String companyName =
              data['axl_company_name'] ?? 'Unknown Company';
          final companyWebsite = data['axl_company_website'];
          final companyLinkedin = data['axl_company_linkedin'];
          final companyType = data['axl_company_type'];
          final companyCountry = data['axl_company_country'];
          final companyCity = data['axl_company_city'];
          final companyState = data['axl_company_state'];
          final overview = data['axl_markdown_overview'];
          final history = data['axl_markdown_history'];
          final founders = data['axl_markdown_founders'];
          final management = data['axl_markdown_management'];
          final financials = data['axl_markdown_financials'];
          final products = data['axl_markdown_products'];
          final trials = data['axl_markdown_trials'];
          final notablePositions = company['notable_positions'] ?? [];

          final initials = _getInitials(companyName);

          final locationParts = <String>[];
          if (companyCity != null &&
              companyCity != 'null' &&
              companyCity.toString().isNotEmpty) {
            locationParts.add(companyCity);
          }
          if (companyState != null &&
              companyState != 'null' &&
              companyState.toString().isNotEmpty) {
            locationParts.add(companyState);
          }
          if (companyCountry != null &&
              companyCountry != 'null' &&
              companyCountry.toString().isNotEmpty) {
            locationParts.add(companyCountry);
          }
          final location = locationParts.join(', ');

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
                      companyName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (companyType != null &&
                        companyType != 'null' &&
                        companyType.toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        companyType,
                        style: TextStyle(
                          fontSize: 18,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (location.isNotEmpty) ...[
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
                            location,
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
                    if (companyLinkedin != null &&
                        companyLinkedin != 'null' &&
                        companyLinkedin.toString().isNotEmpty)
                      Expanded(
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _launchUrl(companyLinkedin),
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
                    if (companyLinkedin != null && companyWebsite != null)
                      const SizedBox(width: 12),
                    if (companyWebsite != null &&
                        companyWebsite != 'null' &&
                        companyWebsite.toString().isNotEmpty)
                      Expanded(
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _launchUrl(companyWebsite),
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
                      _buildTabButton('Overview', 0, isDark),
                      const SizedBox(width: 24),
                      _buildTabButton('Company', 1, isDark),
                      const SizedBox(width: 24),
                      _buildTabButton('Financials', 2, isDark),
                      const SizedBox(width: 24),
                      _buildTabButton('Products', 3, isDark),
                      const SizedBox(width: 24),
                      _buildTabButton('People', 4, isDark),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),

              // Tab Content
              if (_currentTabIndex == 0)
              // Overview Tab
              ...[
                // Overview content - plain text without background
                if (overview != null && overview != 'null')
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      overview,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
              ],

              // Tab 1: Company Info (History, Founders, Management)
              if (_currentTabIndex == 1) ...[
                // Content without titles (tab already says "Company")
                if (history != null && history != 'null')
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      history,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
                if (founders != null && founders != 'null')
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      founders,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
                if (management != null && management != 'null')
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      management,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
              ],

              // Tab 2: Financials
              if (_currentTabIndex == 2) ...[
                // Financials content
                if (financials != null && financials != 'null')
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      financials,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
              ],

              // Tab 3: Products & Trials
              if (_currentTabIndex == 3) ...[
                // Products and trials content
                if (products != null && products != 'null')
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      products,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
                if (trials != null && trials != 'null')
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      trials,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
              ],

              // Tab 4: People
              if (_currentTabIndex == 4) ...[
                // Notable Positions (Key Personnel)
                if (notablePositions.isNotEmpty)
                  _buildNotablePositionsSection(notablePositions),
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
                  'Failed to load company details',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: () {
                    ref.invalidate(companyDetailsProvider(widget.companyId));
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
