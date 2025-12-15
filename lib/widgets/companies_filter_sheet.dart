import 'package:flutter/cupertino.dart';
import 'package:pull_down_button/pull_down_button.dart';

class CompaniesFilterSheet extends StatefulWidget {
  final Map<String, String> currentFilters;

  const CompaniesFilterSheet({
    super.key,
    required this.currentFilters,
  });

  @override
  State<CompaniesFilterSheet> createState() => _CompaniesFilterSheetState();
}

class _CompaniesFilterSheetState extends State<CompaniesFilterSheet> {
  late Map<String, String> _filters;

  String? _selectedType;
  String? _selectedStatus;
  String? _selectedCountry;
  bool _hasParent = false;

  // Sample data - in real app, these would come from API
  final List<String> _companyTypes = [
    'All Types',
    'Company',
    'Investor',
    'Partner',
    'Vendor',
    'Non-Profit',
  ];

  final List<String> _companyStatuses = [
    'All Status',
    'Active',
    'Inactive',
    'Public',
    'Acquired',
    'Shutdown',
    'Delisted',
  ];

  final List<String> _countries = [
    'All Countries',
    'United States',
    'United Kingdom',
    'Germany',
    'France',
    'Switzerland',
    'Japan',
    'Canada',
    'Australia',
    'China',
    'India',
  ];

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.currentFilters);

    // Initialize from current filters
    _selectedType = _filters['type'];
    _selectedStatus = _filters['status'];
    _selectedCountry = _filters['axl_country'];
    _hasParent = _filters['has_parent'] == 'true';
  }

  void _applyFilters() {
    final filters = <String, String>{};

    if (_selectedType != null && _selectedType != 'All Types') {
      filters['type'] = _selectedType!;
    }
    if (_selectedStatus != null && _selectedStatus != 'All Status') {
      filters['status'] = _selectedStatus!;
    }
    if (_selectedCountry != null && _selectedCountry != 'All Countries') {
      filters['axl_country'] = _selectedCountry!;
    }
    if (_hasParent) {
      filters['has_parent'] = 'true';
    }

    Navigator.of(context).pop(filters);
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedStatus = null;
      _selectedCountry = null;
      _hasParent = false;
    });
  }

  Widget _buildSelectField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    IconData icon = CupertinoIcons.chevron_down,
  }) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        PullDownButton(
          itemBuilder: (context) => items.map((item) {
            final isSelected = item == value;
            return PullDownMenuItem(
              title: item,
              icon: isSelected ? CupertinoIcons.checkmark : null,
              iconColor: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
              onTap: () => onChanged(item),
            );
          }).toList(),
          buttonBuilder: (context, showMenu) => CupertinoButton(
            onPressed: showMenu,
            padding: EdgeInsets.zero,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                border: Border.all(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      value ?? 'Select $label',
                      style: TextStyle(
                        fontSize: 16,
                        color: value != null
                          ? CupertinoColors.label.resolveFrom(context)
                          : CupertinoColors.placeholderText.resolveFrom(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    icon,
                    size: 20,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 17,
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                    ),
                    Text(
                      'Filter Companies',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _clearFilters,
                      child: Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 17,
                          color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filter description
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                            ? CupertinoColors.systemFill.darkColor
                            : CupertinoColors.systemGrey6.resolveFrom(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.info_circle_fill,
                              size: 20,
                              color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Filter companies by type, status, and location',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Company Type selector
                      _buildSelectField(
                        label: 'Company Type',
                        value: _selectedType,
                        items: _companyTypes,
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value;
                          });
                        },
                        icon: CupertinoIcons.building_2_fill,
                      ),

                      const SizedBox(height: 20),

                      // Status selector
                      _buildSelectField(
                        label: 'Status',
                        value: _selectedStatus,
                        items: _companyStatuses,
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value;
                          });
                        },
                        icon: CupertinoIcons.flag,
                      ),

                      const SizedBox(height: 20),

                      // Country selector
                      _buildSelectField(
                        label: 'Country',
                        value: _selectedCountry,
                        items: _countries,
                        onChanged: (value) {
                          setState(() {
                            _selectedCountry = value;
                          });
                        },
                        icon: CupertinoIcons.globe,
                      ),

                      const SizedBox(height: 24),

                      // Additional options
                      Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: CupertinoColors.separator.resolveFrom(context),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Has Parent Company',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Show only subsidiaries',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  CupertinoSwitch(
                                    value: _hasParent,
                                    onChanged: (value) {
                                      setState(() {
                                        _hasParent = value;
                                      });
                                    },
                                    activeTrackColor: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 80), // Space for button
                    ],
                  ),
                ),
              ),

              // Apply button (fixed at bottom)
              Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
                  border: Border(
                    top: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: CupertinoButton(
                  color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                  borderRadius: BorderRadius.circular(14),
                  onPressed: _applyFilters,
                  child: Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}