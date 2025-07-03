import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../apis/providers/inventory_provider.dart';

class InventoryFilterBottomSheet extends ConsumerStatefulWidget {
  const InventoryFilterBottomSheet({Key? key}) : super(key: key);

  @override
  ConsumerState<InventoryFilterBottomSheet> createState() =>
      _InventoryFilterBottomSheetState();
}

class _InventoryFilterBottomSheetState
    extends ConsumerState<InventoryFilterBottomSheet> {
  String? selectedItemType;
  String? selectedStatus;
  RangeValues priceRange = const RangeValues(0, 10000);
  String selectedStockFilter = 'all';
  String selectedSortBy = 'name_asc';
  String? selectedDateFilter;
  DateTime? customStartDate;
  DateTime? customEndDate;

  final List<String> itemTypes = ['Product', 'Service'];
  final List<String> statusOptions = ['Active', 'Inactive'];
  final List<Map<String, String>> stockFilters = [
    {'value': 'all', 'label': 'All Items'},
    {'value': 'in_stock', 'label': 'In Stock'},
    {'value': 'low_stock', 'label': 'Low Stock'},
    {'value': 'out_of_stock', 'label': 'Out of Stock'},
  ];
  final List<Map<String, String>> sortOptions = [
    {'value': 'name_asc', 'label': 'Name (A-Z)'},
    {'value': 'name_desc', 'label': 'Name (Z-A)'},
    {'value': 'price_asc', 'label': 'Price (Low to High)'},
    {'value': 'price_desc', 'label': 'Price (High to Low)'},
    {'value': 'stock_asc', 'label': 'Stock (Low to High)'},
    {'value': 'stock_desc', 'label': 'Stock (High to Low)'},
    {'value': 'created_desc', 'label': 'Recently Added'},
    {'value': 'created_asc', 'label': 'Oldest First'},
  ];

  final List<Map<String, String>> dateFilters = [
    {'value': 'today', 'label': 'Today'},
    {'value': 'yesterday', 'label': 'Yesterday'},
    {'value': 'this_week', 'label': 'This Week'},
    {'value': 'last_week', 'label': 'Last Week'},
    {'value': 'this_month', 'label': 'This Month'},
    {'value': 'last_month', 'label': 'Last Month'},
    {'value': 'fy_q1', 'label': 'FY Q1 (Apr - Jun)'},
    {'value': 'fy_q2', 'label': 'FY Q2 (Jul - Sept)'},
    {'value': 'fy_q3', 'label': 'FY Q3 (Oct - Dec)'},
    {'value': 'fy_q4', 'label': 'FY Q4 (Jan - Mar)'},
    {'value': 'this_year', 'label': 'This Year'},
    {'value': 'custom', 'label': 'Custom Date'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with current filter values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      selectedItemType = ref.read(itemTypeFilterProvider);
      selectedStatus = ref.read(statusFilterProvider);
      selectedDateFilter = ref.read(dateFilterProvider);
      customStartDate = ref.read(customStartDateProvider);
      customEndDate = ref.read(customEndDateProvider);

      final priceRangeFilter = ref.read(priceRangeFilterProvider);
      priceRange = RangeValues(
        priceRangeFilter['min'] ?? 0,
        priceRangeFilter['max'] ?? 10000,
      );
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Filter & Sort',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearAllFilters,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange[700],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  child: const Text(
                    'Clear all',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 24),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort By Section
                  _buildSection(title: 'Sort by', child: _buildSortOptions()),

                  const SizedBox(height: 28),

                  // Created Date Filter
                  _buildSection(
                    title: 'Created Date',
                    child: _buildDateFilter(),
                  ),

                  const SizedBox(height: 28),

                  // Item Type Filter
                  _buildSection(
                    title: 'Item Type',
                    child: _buildItemTypeFilter(),
                  ),

                  const SizedBox(height: 28),

                  // Status Filter
                  _buildSection(title: 'Status', child: _buildStatusFilter()),

                  const SizedBox(height: 28),

                  // Stock Filter
                  _buildSection(
                    title: 'Stock Status',
                    child: _buildStockFilter(),
                  ),

                  const SizedBox(height: 28),

                  // Price Range Filter
                  _buildSection(
                    title: 'Price Range',
                    child: _buildPriceRangeFilter(),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Apply Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Apply filters',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildSortOptions() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: sortOptions.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, String> option = entry.value;
          bool isSelected = selectedSortBy == option['value'];
          bool isLast = index == sortOptions.length - 1;

          return Container(
            decoration: BoxDecoration(
              border: !isLast
                  ? Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                    )
                  : null,
            ),
            child: RadioListTile<String>(
              title: Text(
                option['label']!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: isSelected ? Colors.orange[700] : Colors.black87,
                ),
              ),
              value: option['value']!,
              groupValue: selectedSortBy,
              onChanged: (value) {
                setState(() {
                  selectedSortBy = value!;
                });
              },
              activeColor: Colors.orange[600],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              dense: true,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date filter dropdown
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // All dates option
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: RadioListTile<String?>(
                  title: const Text(
                    'All Dates',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                  ),
                  value: null,
                  groupValue: selectedDateFilter,
                  onChanged: (value) {
                    setState(() {
                      selectedDateFilter = null;
                      customStartDate = null;
                      customEndDate = null;
                    });
                  },
                  activeColor: Colors.orange[600],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  dense: true,
                ),
              ),
              // Predefined date options
              ...dateFilters.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, String> filter = entry.value;
                bool isSelected = selectedDateFilter == filter['value'];
                bool isLast = index == dateFilters.length - 1;

                return Container(
                  decoration: BoxDecoration(
                    border: !isLast
                        ? Border(
                            bottom: BorderSide(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          )
                        : null,
                  ),
                  child: RadioListTile<String>(
                    title: Text(
                      filter['label']!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: isSelected ? Colors.orange[700] : Colors.black87,
                      ),
                    ),
                    value: filter['value']!,
                    groupValue: selectedDateFilter,
                    onChanged: (value) {
                      setState(() {
                        selectedDateFilter = value!;
                        if (value != 'custom') {
                          customStartDate = null;
                          customEndDate = null;
                        }
                      });
                    },
                    activeColor: Colors.orange[600],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    dense: true,
                  ),
                );
              }).toList(),
            ],
          ),
        ),

        // Custom date picker (only show when custom is selected)
        if (selectedDateFilter == 'custom') ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Date Range',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePickerField(
                        label: 'Start Date',
                        date: customStartDate,
                        onTap: () => _selectStartDate(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDatePickerField(
                        label: 'End Date',
                        date: customEndDate,
                        onTap: () => _selectEndDate(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: date != null ? Colors.black87 : Colors.grey[500],
                    ),
                  ),
                ),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: customStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange[600]!,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != customStartDate) {
      setState(() {
        customStartDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: customEndDate ?? DateTime.now(),
      firstDate: customStartDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange[600]!,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != customEndDate) {
      setState(() {
        customEndDate = picked;
      });
    }
  }

  Widget _buildItemTypeFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          label: 'All',
          isSelected: selectedItemType == null,
          onTap: () {
            setState(() {
              selectedItemType = null;
            });
          },
        ),
        ...itemTypes.map((type) {
          return _buildFilterChip(
            label: type,
            isSelected: selectedItemType == type,
            onTap: () {
              setState(() {
                selectedItemType = selectedItemType == type ? null : type;
              });
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          label: 'All',
          isSelected: selectedStatus == null,
          onTap: () {
            setState(() {
              selectedStatus = null;
            });
          },
        ),
        ...statusOptions.map((status) {
          return _buildFilterChip(
            label: status,
            isSelected: selectedStatus == status,
            onTap: () {
              setState(() {
                selectedStatus = selectedStatus == status ? null : status;
              });
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[50] : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.orange[400]! : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            color: isSelected ? Colors.orange[700] : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildStockFilter() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: stockFilters.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, String> filter = entry.value;
          bool isSelected = selectedStockFilter == filter['value'];
          bool isLast = index == stockFilters.length - 1;

          return Container(
            decoration: BoxDecoration(
              border: !isLast
                  ? Border(
                      bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                    )
                  : null,
            ),
            child: RadioListTile<String>(
              title: Text(
                filter['label']!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: isSelected ? Colors.orange[700] : Colors.black87,
                ),
              ),
              value: filter['value']!,
              groupValue: selectedStockFilter,
              onChanged: (value) {
                setState(() {
                  selectedStockFilter = value!;
                });
              },
              activeColor: Colors.orange[600],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              dense: true,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.orange[400],
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: Colors.orange[600],
                  overlayColor: Colors.orange[100],
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                ),
                child: RangeSlider(
                  values: priceRange,
                  max: 10000,
                  divisions: 100,
                  labels: RangeLabels(
                    '₹${priceRange.start.round()}',
                    '₹${priceRange.end.round()}',
                  ),
                  onChanged: (RangeValues values) {
                    setState(() {
                      priceRange = values;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Min',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${priceRange.start.round()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Max',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${priceRange.end.round()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _clearAllFilters() {
    setState(() {
      selectedItemType = null;
      selectedStatus = null;
      priceRange = const RangeValues(0, 10000);
      selectedStockFilter = 'all';
      selectedSortBy = 'name_asc';
      selectedDateFilter = null;
      customStartDate = null;
      customEndDate = null;
    });
  }

  void _applyFilters() {
    // Get date range if a date filter is selected
    DateTime? startDate;
    DateTime? endDate;

    if (selectedDateFilter != null) {
      if (selectedDateFilter == 'custom') {
        startDate = customStartDate;
        endDate = customEndDate;
      } else {
        final dateRange = DateFilterHelper.getDateRange(selectedDateFilter!);
        startDate = dateRange['start'];
        endDate = dateRange['end'];
      }
    }

    // Update filter providers
    ref.read(itemTypeFilterProvider.notifier).state = selectedItemType;
    ref.read(statusFilterProvider.notifier).state = selectedStatus;
    ref.read(dateFilterProvider.notifier).state = selectedDateFilter;
    ref.read(customStartDateProvider.notifier).state = customStartDate;
    ref.read(customEndDateProvider.notifier).state = customEndDate;
    ref.read(priceRangeFilterProvider.notifier).state = {
      'min': priceRange.start == 0 ? null : priceRange.start,
      'max': priceRange.end == 10000 ? null : priceRange.end,
    };

    // Apply filters using the updated provider method
    ref
        .read(inventoryProvider.notifier)
        .filterInventories(
          itemType: selectedItemType,
          status: selectedStatus,
          minPrice: priceRange.start == 0 ? null : priceRange.start,
          maxPrice: priceRange.end == 10000 ? null : priceRange.end,
          stockFilter: selectedStockFilter,
          startDate: startDate,
          endDate: endDate,
        );

    // Close the bottom sheet
    Navigator.pop(context);

    // Show applied filters snackbar
    _showAppliedFiltersSnackbar();
  }

  void _showAppliedFiltersSnackbar() {
    final appliedFilters = <String>[];
    if (selectedItemType != null) appliedFilters.add('Type: $selectedItemType');
    if (selectedStatus != null) appliedFilters.add('Status: $selectedStatus');
    if (selectedDateFilter != null) {
      final dateLabel = selectedDateFilter == 'custom'
          ? 'Custom Date'
          : dateFilters.firstWhere(
              (f) => f['value'] == selectedDateFilter,
            )['label']!;
      appliedFilters.add('Date: $dateLabel');
    }
    if (selectedStockFilter != 'all') {
      appliedFilters.add(
        'Stock: ${stockFilters.firstWhere((f) => f['value'] == selectedStockFilter)['label']}',
      );
    }
    if (priceRange.start > 0 || priceRange.end < 10000) {
      appliedFilters.add(
        'Price: ₹${priceRange.start.round()} - ₹${priceRange.end.round()}',
      );
    }

    if (appliedFilters.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Filters applied: ${appliedFilters.join(', ')}'),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        } catch (e) {
          print('Could not show snackbar: $e');
        }
      });
    }
  }
}
