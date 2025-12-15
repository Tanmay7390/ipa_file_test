import 'package:flutter/cupertino.dart';
import 'package:pull_down_button/pull_down_button.dart';

class FundsFilterSheet extends StatefulWidget {
  final Map<String, String> currentFilters;

  const FundsFilterSheet({super.key, required this.currentFilters});

  @override
  State<FundsFilterSheet> createState() => _FundsFilterSheetState();
}

class _FundsFilterSheetState extends State<FundsFilterSheet> {
  late Map<String, String> _filters;

  String? _selectedType;
  String? _selectedLocation;
  String? _selectedFirm;
  String? _selectedTitle;
  String? _selectedInvestment;

  late final List<String> _types;
  late final List<String> _locations;
  late final List<String> _firms;
  late final List<String> _titles;
  late final List<String> _investmentOptions;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.currentFilters);

    // Initialize dropdown data
    _types = [
      'All Types',
      'Venture Capital',
      'Private Equity',
      'Angel Investor',
      'Corporate VC',
      'Accelerator',
      'Incubator',
    ];

    _locations = [
      'All Locations',
      'San Francisco',
      'New York',
      'Boston',
      'London',
      'Singapore',
      'Hong Kong',
      'Shanghai',
      'Bangalore',
      'Tel Aviv',
    ];

    _firms = [
      'All Firms',
      'Sequoia Capital',
      'Andreessen Horowitz',
      'Accel',
      'Kleiner Perkins',
      'Benchmark',
      'Greylock Partners',
    ];

    _titles = [
      'All Titles',
      'Partner',
      'Managing Director',
      'Principal',
      'Associate',
      'Venture Partner',
      'General Partner',
    ];

    _investmentOptions = ['All', 'Has Investments', 'No Investments'];

    // Initialize from current filters
    _selectedType = _filters['type'];
    _selectedLocation = _filters['location'];
    _selectedFirm = _filters['firm'];
    _selectedTitle = _filters['title'];
    _selectedInvestment = _filters['isInvestment'];
  }

  void _applyFilters() {
    final filters = <String, String>{};

    if (_selectedType != null && _selectedType != 'All Types') {
      filters['type'] = _selectedType!;
    }
    if (_selectedLocation != null && _selectedLocation != 'All Locations') {
      filters['location'] = _selectedLocation!;
    }
    if (_selectedFirm != null && _selectedFirm != 'All Firms') {
      filters['firm'] = _selectedFirm!;
    }
    if (_selectedTitle != null && _selectedTitle != 'All Titles') {
      filters['title'] = _selectedTitle!;
    }
    if (_selectedInvestment != null && _selectedInvestment != 'All') {
      filters['isInvestment'] = _selectedInvestment == 'Has Investments'
          ? 'true'
          : 'false';
    }

    Navigator.of(context).pop(filters);
  }

  void _clearFilters() {
    setState(() {
      _selectedType = 'All Types';
      _selectedLocation = 'All Locations';
      _selectedFirm = 'All Firms';
      _selectedTitle = 'All Titles';
      _selectedInvestment = 'All';
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
                color: CupertinoColors.secondarySystemGroupedBackground
                    .resolveFrom(context),
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
                            : CupertinoColors.placeholderText.resolveFrom(
                                context,
                              ),
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
                  color: CupertinoColors.tertiarySystemFill.resolveFrom(
                    context,
                  ),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
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
                      'Filter Options',
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
                      // Type selector
                      _buildSelectField(
                        label: 'Type',
                        value: _selectedType,
                        items: _types,
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value;
                          });
                        },
                        icon: CupertinoIcons.building_2_fill,
                      ),

                      const SizedBox(height: 20),

                      // Location selector
                      _buildSelectField(
                        label: 'Location',
                        value: _selectedLocation,
                        items: _locations,
                        onChanged: (value) {
                          setState(() {
                            _selectedLocation = value;
                          });
                        },
                        icon: CupertinoIcons.location_fill,
                      ),

                      const SizedBox(height: 20),

                      // Firm selector
                      _buildSelectField(
                        label: 'Firm',
                        value: _selectedFirm,
                        items: _firms,
                        onChanged: (value) {
                          setState(() {
                            _selectedFirm = value;
                          });
                        },
                        icon: CupertinoIcons.briefcase_fill,
                      ),

                      const SizedBox(height: 20),

                      // Title selector
                      _buildSelectField(
                        label: 'Title',
                        value: _selectedTitle,
                        items: _titles,
                        onChanged: (value) {
                          setState(() {
                            _selectedTitle = value;
                          });
                        },
                        icon: CupertinoIcons.person_fill,
                      ),

                      const SizedBox(height: 20),

                      // Investment filter
                      _buildSelectField(
                        label: 'Investments',
                        value: _selectedInvestment,
                        items: _investmentOptions,
                        onChanged: (value) {
                          setState(() {
                            _selectedInvestment = value;
                          });
                        },
                        icon: CupertinoIcons.money_dollar_circle_fill,
                      ),

                      const SizedBox(height: 80), // Space for button
                    ],
                  ),
                ),
              ),

              // Apply button (fixed at bottom)
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGroupedBackground.resolveFrom(
                    context,
                  ),
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
