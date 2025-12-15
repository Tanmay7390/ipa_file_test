import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/page_scaffold.dart';
import '../pages/company_detail_page.dart';
import '../apis/providers/companies_provider.dart';
import '../widgets/companies_filter_sheet.dart';

class CompaniesTab extends ConsumerStatefulWidget {
  const CompaniesTab({super.key});

  @override
  ConsumerState<CompaniesTab> createState() => _CompaniesTabState();
}

class _CompaniesTabState extends ConsumerState<CompaniesTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);

    // Load initial data
    Future.microtask(() {
      ref.read(companiesListProvider.notifier).loadCompanies(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref
          .read(companiesListProvider.notifier)
          .searchCompanies(_searchController.text);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(companiesListProvider.notifier).loadCompanies();
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    await ref.read(companiesListProvider.notifier).loadCompanies(refresh: true);

    _isRefreshing = false;
  }

  void _showFilters() {
    showCupertinoModalPopup<Map<String, String>>(
      context: context,
      builder: (BuildContext context) => CompaniesFilterSheet(
        currentFilters: ref.read(companiesListProvider.notifier).currentFilters,
      ),
    ).then((filters) {
      if (filters != null) {
        ref.read(companiesListProvider.notifier).applyFilters(filters);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companiesListProvider);
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CustomPageScaffold(
      scrollController: _scrollController,
      searchController: _searchController,
      heading: 'Companies',
      onSearchChange: (_) {},
      onRefresh: _handleRefresh,
      isLoading: state.isLoading && state.companies.isEmpty,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _showFilters,
        child: Icon(
          CupertinoIcons.slider_horizontal_3,
          size: 24,
          color: isDark ? CupertinoColors.white : CupertinoColors.black,
        ),
      ),
      sliverList: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          // Show loading indicator at the end
          if (index == state.companies.length) {
            if (state.isLoading && state.companies.isNotEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                child: CupertinoActivityIndicator(),
              );
            }
            return const SizedBox.shrink();
          }

          final company = state.companies[index];
          return _buildCompanyTile(company);
        }, childCount: state.companies.length + 1),
      ),
    );
  }

  Widget _buildCompanyTile(Map<String, dynamic> company) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    final companyName = company['axl_company_name'] ?? 'Unknown Company';
    final companyType = company['axl_company_type'] ?? '';
    final status = company['axl_company_status'] ?? '';
    final website = company['axl_company_website'] ?? '';
    final country = company['axl_company_country'] ?? '';
    final state = company['axl_company_state'] ?? '';
    final id = company['id'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          // Navigator.of(context, rootNavigator: true).push(
          //   CupertinoPageRoute(
          //     builder: (context) => CompanyDetailPage(companyId: id),
          //   ),
          // );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company logo placeholder
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? CupertinoColors.systemGrey5.darkColor
                          : CupertinoColors.systemGrey5.resolveFrom(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        companyName.isNotEmpty
                            ? companyName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.darkBackgroundGray,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Company info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          companyName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),

                        if (companyType.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            companyType,
                            style: TextStyle(
                              fontSize: 15,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),

                        // Location
                        if (state.isNotEmpty || country.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.location,
                                size: 14,
                                color: CupertinoColors.tertiaryLabel
                                    .resolveFrom(context),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  [
                                    state,
                                    country,
                                  ].where((s) => s.isNotEmpty).join(', '),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: CupertinoColors.tertiaryLabel
                                        .resolveFrom(context),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                        // Website
                        if (website.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.globe,
                                size: 14,
                                color: CupertinoColors.tertiaryLabel
                                    .resolveFrom(context),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  Uri.tryParse(website)?.host ?? website,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: CupertinoColors.systemBlue,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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

              // Status badges
              if (status.isNotEmpty && status != 'null') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      status,
                      isDark,
                    ).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(status, isDark),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status, bool isDark) {
    switch (status.toLowerCase()) {
      case 'active':
        return CupertinoColors.systemGreen;
      case 'inactive':
        return CupertinoColors.systemOrange;
      case 'acquired':
        return CupertinoColors.systemBlue;
      case 'shutdown':
      case 'delisted':
        return CupertinoColors.systemRed;
      case 'public':
        return CupertinoColors.systemPurple;
      default:
        return CupertinoColors.systemGrey;
    }
  }
}
