// lib/inventory_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../theme_provider.dart';
import '../apis/providers/inventory_provider.dart';
import './widgets/inventory_card.dart';
import './widgets/inventory_filter_bottom_sheet.dart';
import 'inventory_form.dart';

class InventoryList extends ConsumerStatefulWidget {
  const InventoryList({Key? key}) : super(key: key);

  @override
  ConsumerState<InventoryList> createState() => _InventoryListState();
}

class _InventoryListState extends ConsumerState<InventoryList> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isGridView = true;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Load inventories when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryProvider.notifier).fetchInventories(isRefresh: true);
    });

    // Add scroll listener for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) {
        // Check if we have filters or search query applied
        final searchQuery = ref.read(searchQueryProvider);
        final itemTypeFilter = ref.read(itemTypeFilterProvider);
        final statusFilter = ref.read(statusFilterProvider);
        final priceRangeFilter = ref.read(priceRangeFilterProvider);
        final dateFilter = ref.read(dateFilterProvider);
        final customStartDate = ref.read(customStartDateProvider);
        final customEndDate = ref.read(customEndDateProvider);

        DateTime? startDate;
        DateTime? endDate;

        if (dateFilter != null) {
          if (dateFilter == 'custom') {
            startDate = customStartDate;
            endDate = customEndDate;
          } else {
            final dateRange = DateFilterHelper.getDateRange(dateFilter);
            startDate = dateRange['start'];
            endDate = dateRange['end'];
          }
        }

        // If any filters are applied, use the filtered fetch
        if (searchQuery.isNotEmpty ||
            itemTypeFilter != null ||
            statusFilter != null ||
            priceRangeFilter['min'] != null ||
            priceRangeFilter['max'] != null ||
            dateFilter != null) {
          ref
              .read(inventoryProvider.notifier)
              .fetchInventories(
                searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
                itemType: itemTypeFilter,
                status: statusFilter,
                minPrice: priceRangeFilter['min'],
                maxPrice: priceRangeFilter['max'],
                startDate: startDate,
                endDate: endDate,
              );
        } else {
          ref.read(inventoryProvider.notifier).fetchInventories();
        }
      }
    });

    // Initialize search controller with current search query
    final currentQuery = ref.read(searchQueryProvider);
    if (currentQuery.isNotEmpty) {
      _searchController.text = currentQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Update search query state immediately for UI responsiveness
    ref.read(searchQueryProvider.notifier).state = value;

    // Debounce the actual search API call
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (value.isEmpty) {
        // If search is empty, refresh to show all items
        ref.read(inventoryProvider.notifier).refresh();
      } else {
        // Perform search with debounced value using the filter endpoint
        ref.read(inventoryProvider.notifier).searchInventories(value);
      }
    });
  }

  void _onSearchSubmitted(String value) {
    // Cancel any pending debounced search
    _debounceTimer?.cancel();

    // Perform immediate search on submit
    if (value.isEmpty) {
      ref.read(inventoryProvider.notifier).refresh();
    } else {
      ref.read(inventoryProvider.notifier).searchInventories(value);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(inventoryProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorProvider);
    final inventoryState = ref.watch(inventoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(searchQuery, colors),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () => ref.read(inventoryProvider.notifier).refresh(),
          ),
          _buildFilterBar(inventoryState, colors),
          ..._buildSlivers(inventoryState, colors),
        ],
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Color(0xFF4C9656),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () async {
            final result = await Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => const CreateInventory()),
            );

            // Refresh the list when returning from create inventory
            if (result == true) {
              ref.read(inventoryProvider.notifier).refresh();
            }
          },
          child: Icon(
            CupertinoIcons.add,
            color: CupertinoColors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    String searchQuery,
    WareozeColorScheme colors,
  ) {
    return AppBar(
      backgroundColor: colors.surface,
      foregroundColor: colors.textPrimary,
      elevation: 0,
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
        child: Icon(CupertinoIcons.back, color: colors.textPrimary, size: 24),
      ),
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search by name, description, item code...',
            hintStyle: TextStyle(color: colors.textSecondary, fontSize: 16),
            prefixIcon: Icon(
              Icons.search,
              color: colors.textSecondary,
              size: 22,
            ),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                    onPressed: _clearSearch,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: _onSearchChanged,
          onSubmitted: _onSearchSubmitted,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isGridView ? Icons.view_list : Icons.grid_view,
            color: colors.textPrimary,
          ),
          onPressed: () {
            setState(() {
              _isGridView = !_isGridView;
            });
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFilterBar(InventoryState state, WareozeColorScheme colors) {
    final searchQuery = ref.watch(searchQueryProvider);
    final isSearching = searchQuery.isNotEmpty;

    // Check if any filters are applied
    final itemTypeFilter = ref.watch(itemTypeFilterProvider);
    final statusFilter = ref.watch(statusFilterProvider);
    final dateFilter = ref.watch(dateFilterProvider);
    final priceRangeFilter = ref.watch(priceRangeFilterProvider);

    final hasFiltersApplied =
        itemTypeFilter != null ||
        statusFilter != null ||
        dateFilter != null ||
        priceRangeFilter['min'] != null ||
        priceRangeFilter['max'] != null;

    return SliverToBoxAdapter(
      child: Container(
        color: colors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                isSearching
                    ? 'Found ${state.inventories.length} of ${state.total} results for "$searchQuery"'
                    : hasFiltersApplied
                    ? '${state.inventories.length} of ${state.total} filtered results'
                    : '${state.inventories.length} of ${state.total} results',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: hasFiltersApplied
                      ? Colors.orange[400]!
                      : colors.border,
                ),
                borderRadius: BorderRadius.circular(6),
                color: hasFiltersApplied ? Colors.orange[50] : null,
              ),
              child: InkWell(
                onTap: () => _showFilterBottomSheet(context),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 18,
                        color: hasFiltersApplied
                            ? Colors.orange[700]
                            : colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasFiltersApplied
                            ? 'Filter (${_getFilterCount()})'
                            : 'Filter',
                        style: TextStyle(
                          fontSize: 14,
                          color: hasFiltersApplied
                              ? Colors.orange[700]
                              : colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (state.isLoading) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _getFilterCount() {
    int count = 0;
    final itemTypeFilter = ref.watch(itemTypeFilterProvider);
    final statusFilter = ref.watch(statusFilterProvider);
    final dateFilter = ref.watch(dateFilterProvider);
    final priceRangeFilter = ref.watch(priceRangeFilterProvider);

    if (itemTypeFilter != null) count++;
    if (statusFilter != null) count++;
    if (dateFilter != null) count++;
    if (priceRangeFilter['min'] != null || priceRangeFilter['max'] != null)
      count++;

    return count;
  }

  List<Widget> _buildSlivers(InventoryState state, WareozeColorScheme colors) {
    final searchQuery = ref.watch(searchQueryProvider);
    final isSearching = searchQuery.isNotEmpty;

    if (state.isLoading && state.inventories.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  isSearching ? 'Searching products...' : 'Loading products...',
                  style: TextStyle(fontSize: 16, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (state.error != null && state.inventories.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: colors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    fontSize: 18,
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.error!,
                  style: TextStyle(fontSize: 14, color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    if (isSearching) {
                      ref
                          .read(inventoryProvider.notifier)
                          .searchInventories(searchQuery);
                    } else {
                      ref.read(inventoryProvider.notifier).refresh();
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (state.inventories.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSearching ? Icons.search_off : Icons.inventory_2_outlined,
                  size: 80,
                  color: colors.textSecondary,
                ),
                const SizedBox(height: 24),
                Text(
                  isSearching ? 'No products found' : 'No products found',
                  style: TextStyle(
                    fontSize: 20,
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isSearching
                      ? 'Try a different search term or clear your search'
                      : 'Try adjusting your search or filters',
                  style: TextStyle(fontSize: 16, color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (isSearching)
                  ElevatedButton.icon(
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.textSecondary,
                      foregroundColor: colors.surface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const CreateInventory(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Product'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.surface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      // Product Grid
      SliverPadding(
        padding: const EdgeInsets.all(8),
        sliver: _isGridView
            ? SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == state.inventories.length) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.primary,
                            ),
                          ),
                        ),
                      );
                    }

                    final inventory = state.inventories[index];
                    return InventoryGridCard(inventory: inventory);
                  },
                  childCount:
                      state.inventories.length + (state.hasMore ? 1 : 0),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == state.inventories.length) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.primary,
                            ),
                          ),
                        ),
                      );
                    }

                    final inventory = state.inventories[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: InventoryGridCard(
                        inventory: inventory,
                        isListView: true,
                      ),
                    );
                  },
                  childCount:
                      state.inventories.length + (state.hasMore ? 1 : 0),
                ),
              ),
      ),
    ];
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const InventoryFilterBottomSheet(),
    );
  }
}
