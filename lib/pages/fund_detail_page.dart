import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/page_scaffold.dart';
import '../apis/providers/funds_provider.dart';

class FundDetailPage extends ConsumerStatefulWidget {
  final String fundId;

  const FundDetailPage({super.key, required this.fundId});

  @override
  ConsumerState<FundDetailPage> createState() => _FundDetailPageState();
}

class _FundDetailPageState extends ConsumerState<FundDetailPage> {
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
            ? CupertinoColors.systemBlue.darkColor.withValues(alpha: 0.3)
            : CupertinoColors.systemBlue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.money_dollar_circle_fill,
          size: 50,
          color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
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

  @override
  Widget build(BuildContext context) {
    final fundAsync = ref.watch(fundDetailsProvider(widget.fundId));
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CustomPageScaffold(
      scrollController: _scrollController,
      isLoading: fundAsync.isLoading,
      heading: 'Fund Details',
      hideLargeTitle: true,
      hideSearch: true,
      onRefresh: () async {
        ref.invalidate(fundDetailsProvider(widget.fundId));
      },
      sliverList: fundAsync.when(
        data: (dynamic fund) {
          if (fund == null) {
            return SliverFillRemaining(
              child: Center(child: Text('Fund not found')),
            );
          }

          // Handle both cases: fund could be the data directly or wrapped in {'data': ...}
          final Map<String, dynamic> data;
          if (fund is Map<String, dynamic>) {
            if (fund.containsKey('data') &&
                fund['data'] is Map<String, dynamic>) {
              // API returned {'data': {...}}
              data = fund['data'] as Map<String, dynamic>;
            } else {
              // API returned data directly
              data = fund;
            }
          } else {
            return SliverFillRemaining(
              child: Center(child: Text('Invalid data format')),
            );
          }

          final String? name = data['axl_vc_name']?.toString();
          final String? firm = data['axl_vc_firm']?.toString();
          final String? title = data['axl_vc_title']?.toString();
          final String? location = data['axl_vc_location']?.toString();
          final String? bio = data['axl_vc_bio']?.toString();
          final String? since = data['axl_vc_since']?.toString();
          final String? boards = data['axl_vc_boards']?.toString();
          final String? linkedin = data['axl_linkedin']?.toString();
          final List? investments = data['investments'] as List?;
          final List? education = data['all_education'] as List?;
          final List? companyTypes = data['company_type'] as List?;

          final displayName = name ?? 'Unknown Fund';
          final initials = displayName.length >= 2
              ? displayName.substring(0, 2).toUpperCase()
              : displayName.substring(0, 1).toUpperCase();

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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (firm != null && firm != 'null' && firm.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        firm,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (title != null &&
                        title != 'null' &&
                        title.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (location != null &&
                        location != 'null' &&
                        location.isNotEmpty) ...[
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

              // Action Button - LinkedIn Link
              if (linkedin != null && linkedin != 'null' && linkedin.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _launchUrl(linkedin),
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
                            'View on LinkedIn',
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
                      _buildTabButton('Details', 0, isDark),
                      const SizedBox(width: 24),
                      _buildTabButton('Background', 1, isDark),
                      const SizedBox(width: 24),
                      _buildTabButton('Investments', 2, isDark),
                      const SizedBox(width: 24),
                      _buildTabButton('Focus', 3, isDark),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),

              // Tab Content - Details
              if (_currentTabIndex == 0) ...[
                if (bio != null && bio != 'null')
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      bio,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
              ],

              // Tab Content - Background
              if (_currentTabIndex == 1) ...[
                if (since != null && since != 'null')
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Active Since: $since',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
                if (boards != null && boards != 'null')
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'Board Positions:\n$boards',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
                if (education != null && education.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Education:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...education.map(
                          (edu) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• ${edu.toString()}',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: CupertinoColors.label.resolveFrom(
                                  context,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],

              // Tab Content - Investments
              if (_currentTabIndex == 2) ...[
                if (investments != null && investments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Investments (${investments.length}):',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...investments.map((inv) {
                          final companyName =
                              inv['axl_company_name']?.toString() ?? 'Unknown';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '• $companyName',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: CupertinoColors.label.resolveFrom(
                                  context,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
              ],

              // Tab Content - Focus
              if (_currentTabIndex == 3) ...[
                if (companyTypes != null && companyTypes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: companyTypes.map((type) {
                        final typeName =
                            type['axl_company_type']?.toString() ?? '';
                        final count = type['count']?.toString() ?? '0';
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isDark ? Color(0xFF007AFF) : Color(0xFF0387FE))
                                    .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  (isDark
                                          ? Color(0xFF007AFF)
                                          : Color(0xFF0387FE))
                                      .withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '$typeName ($count)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Color(0xFF007AFF)
                                  : Color(0xFF0387FE),
                            ),
                          ),
                        );
                      }).toList(),
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
                  'Failed to load fund details',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: () {
                    ref.invalidate(fundDetailsProvider(widget.fundId));
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
