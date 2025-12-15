import 'package:flutter/cupertino.dart';
import 'package:pull_down_button/pull_down_button.dart';

class CompanyFilterSheet extends StatefulWidget {
  final Map<String, String> currentFilters;
  final List<Map<String, dynamic>>? availableTypes;
  final List<Map<String, dynamic>>? availableSubtypes;
  final List<Map<String, dynamic>>? availableInvestorTypes;
  final List<String>? availableCountries;

  const CompanyFilterSheet({
    super.key,
    required this.currentFilters,
    this.availableTypes,
    this.availableSubtypes,
    this.availableInvestorTypes,
    this.availableCountries,
  });

  @override
  State<CompanyFilterSheet> createState() => _CompanyFilterSheetState();
}

class _CompanyFilterSheetState extends State<CompanyFilterSheet> {
  late Map<String, String> _filters;

  String? _selectedTypeId;
  String? _selectedSubtypeId;
  String? _selectedInvestorTypeId;
  String? _selectedCountry;
  String? _selectedConditionId;
  String? _selectedHasParent;

  // Sample data - in real app, these would come from API
  late final List<Map<String, dynamic>> _companyTypes;
  late final List<Map<String, dynamic>> _companySubtypes;
  late final List<Map<String, dynamic>> _investorTypes;
  late final List<String> _countries;
  late final List<String> _conditionIds;
  late final List<String> _hasParentOptions;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.currentFilters);

    // Initialize dropdown data
    _companyTypes =
        widget.availableTypes ??
        [
          {'id': '1', 'name': 'Biotech'},
          {'id': '2', 'name': 'Pharmaceutical'},
          {'id': '3', 'name': 'Medical Device'},
          {'id': '4', 'name': 'Diagnostics'},
          {'id': '5', 'name': 'CRO'},
          {'id': '6', 'name': 'CDMO'},
        ];

    _companySubtypes =
        widget.availableSubtypes ??
        [
          {'id': '1', 'name': 'Oncology'},
          {'id': '2', 'name': 'Neurology'},
          {'id': '3', 'name': 'Cardiology'},
          {'id': '4', 'name': 'Immunology'},
          {'id': '5', 'name': 'Rare Disease'},
        ];

    _investorTypes =
        widget.availableInvestorTypes ??
        [
          {'id': '1', 'name': 'VC Firm'},
          {'id': '2', 'name': 'Private Equity'},
          {'id': '3', 'name': 'Corporate Investor'},
          {'id': '4', 'name': 'Angel Investor'},
        ];

    _countries =
        widget.availableCountries ??
        [
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

    _conditionIds = [
      '1 - COVID-19',
      '2 - Cancer',
      '3 - Diabetes',
      '4 - Alzheimer\'s',
      '5 - Parkinson\'s',
      '6 - Heart Disease',
    ];

    _hasParentOptions = ['All', 'Has Parent', 'No Parent'];

    // Initialize from current filters
    _selectedTypeId = _filters['typeIds'];
    _selectedSubtypeId = _filters['subtypeIds'];
    _selectedInvestorTypeId = _filters['investorTypeIds'];
    _selectedCountry = _filters['country'];
    _selectedConditionId = _filters['conditionId'];

    final hasParent = _filters['hasParent'];
    if (hasParent == 'true') {
      _selectedHasParent = 'Has Parent';
    } else if (hasParent == 'false') {
      _selectedHasParent = 'No Parent';
    } else {
      _selectedHasParent = 'All';
    }
  }

  void _applyFilters() {
    final filters = <String, String>{};

    if (_selectedTypeId != null) {
      filters['typeIds'] = _selectedTypeId!;
    }
    if (_selectedSubtypeId != null) {
      filters['subtypeIds'] = _selectedSubtypeId!;
    }
    if (_selectedInvestorTypeId != null) {
      filters['investorTypeIds'] = _selectedInvestorTypeId!;
    }
    if (_selectedCountry != null) {
      filters['country'] = _selectedCountry!;
    }
    if (_selectedConditionId != null) {
      filters['conditionId'] = _selectedConditionId!.split(' - ')[0];
    }
    if (_selectedHasParent == 'Has Parent') {
      filters['hasParent'] = 'true';
    } else if (_selectedHasParent == 'No Parent') {
      filters['hasParent'] = 'false';
    }

    Navigator.of(context).pop(filters);
  }

  void _clearFilters() {
    setState(() {
      _selectedTypeId = null;
      _selectedSubtypeId = null;
      _selectedInvestorTypeId = null;
      _selectedCountry = null;
      _selectedConditionId = null;
      _selectedHasParent = 'All';
    });
  }

  Widget _buildSelectField({
    required String label,
    required String? value,
    required List<dynamic> items,
    required ValueChanged<String?> onChanged,
    IconData icon = CupertinoIcons.chevron_down,
    bool isMapList = false,
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
            final String itemValue;
            final String itemLabel;

            if (isMapList && item is Map) {
              itemValue = item['id'].toString();
              itemLabel = item['name'] as String;
            } else {
              itemValue = item as String;
              itemLabel = item;
            }

            final isSelected = itemValue == value || itemLabel == value;

            return PullDownMenuItem(
              title: itemLabel,
              icon: isSelected ? CupertinoIcons.checkmark : null,
              iconColor: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
              onTap: () => onChanged(itemValue),
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
                      value != null
                          ? (isMapList
                                ? (items.firstWhere(
                                        (item) =>
                                            item is Map &&
                                            item['id'].toString() == value,
                                        orElse: () => {'name': value},
                                      )['name']
                                      as String)
                                : value)
                          : 'Select $label',
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
                      // Company Type selector
                      _buildSelectField(
                        label: 'Company Type',
                        value: _selectedTypeId,
                        items: _companyTypes,
                        onChanged: (value) {
                          setState(() {
                            _selectedTypeId = value;
                          });
                        },
                        icon: CupertinoIcons.building_2_fill,
                        isMapList: true,
                      ),

                      const SizedBox(height: 20),

                      // Company Subtype selector
                      _buildSelectField(
                        label: 'Company Subtype',
                        value: _selectedSubtypeId,
                        items: _companySubtypes,
                        onChanged: (value) {
                          setState(() {
                            _selectedSubtypeId = value;
                          });
                        },
                        icon: CupertinoIcons.square_stack_3d_up_fill,
                        isMapList: true,
                      ),

                      const SizedBox(height: 20),

                      // Investor Type selector
                      _buildSelectField(
                        label: 'Investor Type',
                        value: _selectedInvestorTypeId,
                        items: _investorTypes,
                        onChanged: (value) {
                          setState(() {
                            _selectedInvestorTypeId = value;
                          });
                        },
                        icon: CupertinoIcons.money_dollar_circle_fill,
                        isMapList: true,
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
                        isMapList: false,
                      ),

                      const SizedBox(height: 20),

                      // Condition/Disease selector
                      _buildSelectField(
                        label: 'Condition / Disease',
                        value: _selectedConditionId,
                        items: _conditionIds,
                        onChanged: (value) {
                          setState(() {
                            _selectedConditionId = value;
                          });
                        },
                        icon: CupertinoIcons.shield_lefthalf_fill,
                        isMapList: false,
                      ),

                      const SizedBox(height: 20),

                      // Has Parent selector
                      _buildSelectField(
                        label: 'Parent Company',
                        value: _selectedHasParent,
                        items: _hasParentOptions,
                        onChanged: (value) {
                          setState(() {
                            _selectedHasParent = value;
                          });
                        },
                        icon: CupertinoIcons.arrow_branch,
                        isMapList: false,
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
