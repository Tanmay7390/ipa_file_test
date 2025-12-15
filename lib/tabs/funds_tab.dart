import 'dart:async';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/page_scaffold.dart';
import '../pages/fund_detail_page.dart';
import '../apis/providers/funds_provider.dart';
import '../models/fund.dart';
import '../widgets/funds_filter_sheet.dart';

class FundsTab extends ConsumerStatefulWidget {
  const FundsTab({super.key});

  @override
  ConsumerState<FundsTab> createState() => _FundsTabState();
}

class _FundsTabState extends ConsumerState<FundsTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSearchField = false;
  List<Fund> _funds = [];
  Timer? _debounceTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(fundsListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Debounce search by 500ms
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      ref.read(fundsListProvider.notifier).search(query);
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearchField = !_showSearchField;
      if (!_showSearchField) {
        _debounceTimer?.cancel();
        _searchController.clear();
        ref.read(fundsListProvider.notifier).search('');
      }
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    await ref.read(fundsListProvider.notifier).refresh();

    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _showFilters() async {
    final result = await showCupertinoModalPopup<Map<String, String>>(
      context: context,
      builder: (context) {
        return FundsFilterSheet(
          currentFilters: ref.read(fundsListProvider.notifier).currentFilters,
        );
      },
    );

    if (result != null) {
      ref.read(fundsListProvider.notifier).applyFilters(result);
    }
  }

  Widget _buildFundIcon(bool isDark) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.systemBlue.darkColor.withValues(alpha: 0.2)
            : CupertinoColors.systemBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.creditcard_fill,
          size: 30,
          color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final fundsAsync = ref.watch(fundsListProvider);

    // Listen to provider changes and update local state
    ref.listen<AsyncValue<List<Fund>>>(fundsListProvider, (previous, next) {
      next.when(
        data: (data) {
          setState(() {
            _funds = data;
          });
        },
        loading: () {
          // Keep showing loading
        },
        error: (error, stack) {
          // Show error message if needed
          log('Error loading funds: $error');
        },
      );
    });

    return CustomPageScaffold(
      scrollController: _scrollController,
      isLoading: fundsAsync.isLoading && _funds.isEmpty,
      heading: 'Funds',
      searchController: _searchController,
      showSearchField: _showSearchField,
      onSearchToggle: (_) => _toggleSearch(),
      onRefresh: _onRefresh,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _showFilters,
        child: Icon(
          CupertinoIcons.slider_horizontal_3,
          size: 22,
          color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
        ),
      ),
      sliverList: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final fund = _funds[index];

          return CupertinoListTile(
            backgroundColor: CupertinoColors.systemBackground.resolveFrom(
              context,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            leadingSize: 60,
            leading: _buildFundIcon(isDark),
            title: Text(
              fund.displayName,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fund.displayFirm.isNotEmpty)
                  Text(
                    fund.displayFirm,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 15,
                      letterSpacing: 0.25,
                      color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                    ),
                  ),
                if (fund.displayTitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      fund.displayTitle,
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontSize: 14,
                        letterSpacing: 0.25,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  ),
                if (fund.displayLocation.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.location_solid,
                          size: 12,
                          color: CupertinoColors.tertiaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            fund.displayLocation,
                            style: TextStyle(
                              fontFamily: 'SF Pro Display',
                              fontSize: 13,
                              letterSpacing: 0.25,
                              color: CupertinoColors.tertiaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            trailing: Icon(
              CupertinoIcons.chevron_right,
              size: 20,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) =>
                      FundDetailPage(fundId: fund.id.toString()),
                ),
              );
            },
          );
        }, childCount: _funds.length),
      ),
    );
  }
}
