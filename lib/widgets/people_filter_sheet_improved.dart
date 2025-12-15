import 'package:flutter/cupertino.dart';
import 'package:pull_down_button/pull_down_button.dart';

class PeopleFilterSheetImproved extends StatefulWidget {
  final Map<String, String> currentFilters;
  final List<String>? availableCompanies;
  final List<String>? availableCountries;
  final List<String>? availableLocations;

  const PeopleFilterSheetImproved({
    super.key,
    required this.currentFilters,
    this.availableCompanies,
    this.availableCountries,
    this.availableLocations,
  });

  @override
  State<PeopleFilterSheetImproved> createState() =>
      _PeopleFilterSheetImprovedState();
}

class _PeopleFilterSheetImprovedState extends State<PeopleFilterSheetImproved> {
  late Map<String, String> _filters;

  String? _selectedCompany;
  String? _selectedCountry;
  String? _selectedLocation;
  bool _excludeDuplicates = false;

  // Sample data - in real app, these would come from API or be passed as props
  late final List<String> _companies;
  late final List<String> _countries;
  late final List<String> _locations;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.currentFilters);

    // Initialize dropdown data
    _companies =
        widget.availableCompanies ??
        [
          'All Companies',
          'Pfizer',
          'Johnson & Johnson',
          'Roche',
          'Novartis',
          'Merck',
          'AstraZeneca',
          'GSK',
          'Sanofi',
          'AbbVie',
          'Bristol Myers Squibb',
        ];

    _countries =
        widget.availableCountries ??
        [
          'All Countries',
          'United States',
          'United Kingdom',
          'Germany',
          'France',
          'Switzerland',
          'Japan',
          'Canada',
          'Australia',
          'Netherlands',
          'Sweden',
        ];

    _locations =
        widget.availableLocations ??
        [
          'All Locations',
          'New York',
          'San Francisco',
          'Boston',
          'London',
          'Basel',
          'Paris',
          'Tokyo',
          'Berlin',
          'Sydney',
          'Toronto',
        ];

    // Initialize from current filters
    _selectedCompany = _filters['company'];
    _selectedCountry = _filters['country'];
    _selectedLocation = _filters['location'];
    _excludeDuplicates = _filters['ignoreDates'] == 'true';
  }

  void _applyFilters() {
    final filters = <String, String>{};

    if (_selectedCompany != null && _selectedCompany != 'All Companies') {
      filters['company'] = _selectedCompany!;
    }
    if (_selectedCountry != null && _selectedCountry != 'All Countries') {
      filters['country'] = _selectedCountry!;
    }
    if (_selectedLocation != null && _selectedLocation != 'All Locations') {
      filters['location'] = _selectedLocation!;
    }
    if (_excludeDuplicates) {
      filters['ignoreDates'] = 'true';
    }
    filters['isFilter'] = 'true';

    Navigator.of(context).pop(filters);
  }

  void _clearFilters() {
    setState(() {
      _selectedCompany = null;
      _selectedCountry = null;
      _selectedLocation = null;
      _excludeDuplicates = false;
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
                      // Company selector
                      _buildSelectField(
                        label: 'Company',
                        value: _selectedCompany,
                        items: _companies,
                        onChanged: (value) {
                          setState(() {
                            _selectedCompany = value;
                          });
                        },
                        icon: CupertinoIcons.building_2_fill,
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

                      const SizedBox(height: 20),

                      // Location/City selector
                      _buildSelectField(
                        label: 'Location / City',
                        value: _selectedLocation,
                        items: _locations,
                        onChanged: (value) {
                          setState(() {
                            _selectedLocation = value;
                          });
                        },
                        icon: CupertinoIcons.location_solid,
                      ),

                      const SizedBox(height: 24),

                      // Additional options
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: CupertinoColors.separator.resolveFrom(
                              context,
                            ),
                            width: 0.5,
                          ),
                          color: CupertinoColors
                              .secondarySystemGroupedBackground
                              .resolveFrom(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Exclude Duplicates',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Hide duplicate entries from results',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: CupertinoColors.secondaryLabel
                                              .resolveFrom(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  CupertinoSwitch(
                                    value: _excludeDuplicates,
                                    onChanged: (value) {
                                      setState(() {
                                        _excludeDuplicates = value;
                                      });
                                    },
                                    activeTrackColor: isDark
                                        ? Color(0xFF007AFF)
                                        : Color(0xFF0387FE),
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
