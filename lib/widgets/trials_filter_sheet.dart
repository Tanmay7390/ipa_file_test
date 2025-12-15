import 'package:flutter/cupertino.dart';
import 'package:pull_down_button/pull_down_button.dart';

class TrialsFilterSheet extends StatefulWidget {
  final Map<String, String> currentFilters;

  const TrialsFilterSheet({super.key, required this.currentFilters});

  @override
  State<TrialsFilterSheet> createState() => _TrialsFilterSheetState();
}

class _TrialsFilterSheetState extends State<TrialsFilterSheet> {
  late Map<String, String> _filters;

  String? _selectedPhase;
  String? _selectedStatus;
  String? _selectedInterventionTreeId;
  String? _selectedTherapeuticArea;
  String? _selectedCountry;

  late final List<String> _phases;
  late final List<String> _statuses;
  late final List<Map<String, dynamic>> _interventionCategories;
  late final List<String> _therapeuticAreas;
  late final List<String> _countries;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.currentFilters);

    // Initialize dropdown data
    _phases = [
      'All Phases',
      'Phase 1',
      'Phase 2',
      'Phase 3',
      'Phase 4',
      'Phase 1|Phase 2',
      'Phase 2|Phase3',
    ];

    _statuses = [
      'All Statuses',
      'RECRUITING',
      'ACTIVE_NOT_RECRUITING',
      'COMPLETED',
      'TERMINATED',
      'WITHDRAWN',
      'SUSPENDED',
      'NOT_YET_RECRUITING',
    ];

    _interventionCategories = [
      {'id': '1', 'name': 'Drug'},
      {'id': '2', 'name': 'Biological'},
      {'id': '3', 'name': 'Device'},
      {'id': '4', 'name': 'Procedure'},
      {'id': '5', 'name': 'Other'},
    ];

    _therapeuticAreas = [
      'All Areas',
      'Oncology',
      'Cardiology',
      'Neurology',
      'Immunology',
      'Dermatology',
      'Cardiovascular',
      'Unclassified',
    ];

    _countries = [
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

    // Initialize from current filters
    _selectedPhase = _filters['trialsPhase'];
    _selectedStatus = _filters['trialsStatus'];
    _selectedInterventionTreeId = _filters['interventionTreeIds'];
    _selectedTherapeuticArea = _filters['therapeuticArea'];
    _selectedCountry = _filters['axlCountry'];
  }

  void _applyFilters() {
    final filters = <String, String>{};

    if (_selectedPhase != null && _selectedPhase != 'All Phases') {
      filters['trialsPhase'] = _selectedPhase!;
    }
    if (_selectedStatus != null && _selectedStatus != 'All Statuses') {
      filters['trialsStatus'] = _selectedStatus!;
    }
    if (_selectedInterventionTreeId != null) {
      filters['interventionTreeIds'] = _selectedInterventionTreeId!;
    }
    if (_selectedTherapeuticArea != null &&
        _selectedTherapeuticArea != 'All Areas') {
      filters['therapeuticArea'] = _selectedTherapeuticArea!;
    }
    if (_selectedCountry != null && _selectedCountry != 'All Countries') {
      filters['axlCountry'] = _selectedCountry!;
    }

    Navigator.of(context).pop(filters);
  }

  void _clearFilters() {
    setState(() {
      _selectedPhase = 'All Phases';
      _selectedStatus = 'All Statuses';
      _selectedInterventionTreeId = null;
      _selectedTherapeuticArea = 'All Areas';
      _selectedCountry = 'All Countries';
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
                      // Trial Phase selector
                      _buildSelectField(
                        label: 'Trial Phase',
                        value: _selectedPhase,
                        items: _phases,
                        onChanged: (value) {
                          setState(() {
                            _selectedPhase = value;
                          });
                        },
                        icon: CupertinoIcons.chart_bar_circle_fill,
                        isMapList: false,
                      ),

                      const SizedBox(height: 20),

                      // Trial Status selector
                      _buildSelectField(
                        label: 'Trial Status',
                        value: _selectedStatus,
                        items: _statuses,
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value;
                          });
                        },
                        icon: CupertinoIcons.checkmark_seal_fill,
                        isMapList: false,
                      ),

                      const SizedBox(height: 20),

                      // Intervention Category selector
                      _buildSelectField(
                        label: 'Intervention Category',
                        value: _selectedInterventionTreeId,
                        items: _interventionCategories,
                        onChanged: (value) {
                          setState(() {
                            _selectedInterventionTreeId = value;
                          });
                        },
                        icon: CupertinoIcons.capsule_fill,
                        isMapList: true,
                      ),

                      const SizedBox(height: 20),

                      // Therapeutic Area selector
                      _buildSelectField(
                        label: 'Therapeutic Area',
                        value: _selectedTherapeuticArea,
                        items: _therapeuticAreas,
                        onChanged: (value) {
                          setState(() {
                            _selectedTherapeuticArea = value;
                          });
                        },
                        icon: CupertinoIcons.heart_fill,
                        isMapList: false,
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
