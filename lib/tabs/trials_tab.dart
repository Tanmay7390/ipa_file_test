import 'dart:async';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/page_scaffold.dart';
import '../pages/trial_detail_page.dart';
import '../apis/providers/trials_provider.dart';
import '../models/trial.dart';
import '../widgets/trials_filter_sheet.dart';

class TrialsTab extends ConsumerStatefulWidget {
  const TrialsTab({super.key});

  @override
  ConsumerState<TrialsTab> createState() => _TrialsTabState();
}

class _TrialsTabState extends ConsumerState<TrialsTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSearchField = false;
  List<Trial> _trials = [];
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
      ref.read(trialsListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Debounce search by 500ms
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      ref.read(trialsListProvider.notifier).search(query);
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearchField = !_showSearchField;
      if (!_showSearchField) {
        _debounceTimer?.cancel();
        _searchController.clear();
        ref.read(trialsListProvider.notifier).search('');
      }
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    await ref.read(trialsListProvider.notifier).refresh();

    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _showFilters() async {
    final result = await showCupertinoModalPopup<Map<String, String>>(
      context: context,
      builder: (context) {
        return TrialsFilterSheet(
          currentFilters: ref.read(trialsListProvider.notifier).currentFilters,
        );
      },
    );

    if (result != null) {
      ref.read(trialsListProvider.notifier).applyFilters(result);
    }
  }

  Widget _buildTrialIcon(bool isDark) {
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
          CupertinoIcons.doc_text_fill,
          size: 30,
          color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    Color badgeColor;
    if (status.toUpperCase().contains('RECRUITING')) {
      badgeColor = CupertinoColors.systemGreen;
    } else if (status.toUpperCase().contains('ACTIVE')) {
      badgeColor = CupertinoColors.systemBlue;
    } else if (status.toUpperCase().contains('COMPLETED')) {
      badgeColor = CupertinoColors.systemGrey;
    } else if (status.toUpperCase().contains('TERMINATED') ||
        status.toUpperCase().contains('WITHDRAWN')) {
      badgeColor = CupertinoColors.systemRed;
    } else {
      badgeColor = CupertinoColors.systemOrange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final trialsAsync = ref.watch(trialsListProvider);

    // Listen to provider changes and update local state
    ref.listen<AsyncValue<List<Trial>>>(trialsListProvider, (previous, next) {
      next.when(
        data: (data) {
          setState(() {
            _trials = data;
          });
        },
        loading: () {
          // Keep showing loading
        },
        error: (error, stack) {
          // Show error message if needed
          log('Error loading trials: $error');
        },
      );
    });

    return CustomPageScaffold(
      scrollController: _scrollController,
      isLoading: trialsAsync.isLoading && _trials.isEmpty,
      heading: 'Trials',
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
          final trial = _trials[index];

          return CupertinoListTile(
            backgroundColor: CupertinoColors.systemBackground.resolveFrom(
              context,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            leadingSize: 60,
            leading: _buildTrialIcon(isDark),
            title: Text(
              trial.displayName,
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
                if (trial.nctNumber != null)
                  Text(
                    trial.nctNumber!,
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontSize: 15,
                      letterSpacing: 0.25,
                      color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                    ),
                  ),
                if (trial.displayPhase.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      trial.displayPhase,
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
                if (trial.displayStatus.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _buildStatusBadge(trial.displayStatus, isDark),
                  ),
                if (trial.displayConditions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      trial.displayConditions,
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
            trailing: Icon(
              CupertinoIcons.chevron_right,
              size: 20,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
            onTap: () {
              if (trial.nctNumber != null) {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) =>
                        TrialDetailPage(nctNumber: trial.nctNumber!),
                  ),
                );
              }
            },
          );
        }, childCount: _trials.length),
      ),
    );
  }
}
