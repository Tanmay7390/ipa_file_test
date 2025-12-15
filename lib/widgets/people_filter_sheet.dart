import 'package:flutter/cupertino.dart';

class PeopleFilterSheet extends StatefulWidget {
  final Map<String, String> currentFilters;

  const PeopleFilterSheet({super.key, required this.currentFilters});

  @override
  State<PeopleFilterSheet> createState() => _PeopleFilterSheetState();
}

class _PeopleFilterSheetState extends State<PeopleFilterSheet> {
  late Map<String, String> _filters;
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  // Title category options
  final List<String> _titleCategories = [
    'All',
    'CEO',
    'CTO',
    'CMO',
    'SAB',
    'BOARD',
    'BD/CD',
    'REGULATORY',
  ];

  String _selectedTitleCategory = 'All';
  bool _isCEOOnly = true;
  bool _excludeDuplicates = false;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.currentFilters);

    // Initialize from current filters
    _companyController.text = _filters['company'] ?? '';
    _locationController.text = _filters['location'] ?? '';
    _countryController.text = _filters['country'] ?? '';
    _selectedTitleCategory = _filters['titleCategory'] ?? 'All';
    _isCEOOnly = _filters['isCEO'] != 'false';
    _excludeDuplicates = _filters['ignoreDates'] == 'true';
  }

  @override
  void dispose() {
    _companyController.dispose();
    _locationController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final filters = <String, String>{};

    if (_companyController.text.isNotEmpty) {
      filters['company'] = _companyController.text;
    }
    if (_locationController.text.isNotEmpty) {
      filters['location'] = _locationController.text;
    }
    if (_countryController.text.isNotEmpty) {
      filters['country'] = _countryController.text;
    }
    if (_selectedTitleCategory != 'All') {
      filters['titleCategory'] = _selectedTitleCategory;
    }
    filters['isCEO'] = _isCEOOnly ? 'true' : 'false';
    if (_excludeDuplicates) {
      filters['ignoreDates'] = 'true';
    }
    filters['isFilter'] = 'true'; // To include filter options in response

    Navigator.of(context).pop(filters);
  }

  void _clearFilters() {
    setState(() {
      _companyController.clear();
      _locationController.clear();
      _countryController.clear();
      _selectedTitleCategory = 'All';
      _isCEOOnly = true;
      _excludeDuplicates = false;
    });
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            border: Border.all(color: CupertinoColors.separator, width: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey3,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: CupertinoColors.systemRed),
                  ),
                ),
                Text(
                  'Filters',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _clearFilters,
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter options
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Category Picker
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 8),
                        child: Text(
                          'Title Category',
                          style: TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.secondaryLabel,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground,
                          border: Border.all(
                            color: CupertinoColors.separator,
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CupertinoPicker(
                          itemExtent: 32,
                          scrollController: FixedExtentScrollController(
                            initialItem: _titleCategories.indexOf(
                              _selectedTitleCategory,
                            ),
                          ),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              _selectedTitleCategory = _titleCategories[index];
                            });
                          },
                          children: _titleCategories.map((category) {
                            return Center(
                              child: Text(
                                category,
                                style: TextStyle(fontSize: 16),
                              ),
                            );
                          }).toList(),
                        ),
                        height: 150,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Company filter
                  _buildTextField(
                    label: 'Company',
                    controller: _companyController,
                    placeholder: 'Enter company name or IDs (comma-separated)',
                  ),

                  const SizedBox(height: 24),

                  // Country filter
                  _buildTextField(
                    label: 'Country',
                    controller: _countryController,
                    placeholder: 'Enter country (e.g., USA)',
                  ),

                  const SizedBox(height: 24),

                  // Location filter
                  _buildTextField(
                    label: 'Location / City',
                    controller: _locationController,
                    placeholder: 'Enter city name',
                  ),

                  const SizedBox(height: 24),

                  // Toggle switches
                  CupertinoListSection.insetGrouped(
                    children: [
                      CupertinoListTile(
                        title: Text('Show All Executives'),
                        subtitle: Text(
                          'Include all executives, not just CEOs',
                          style: TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        trailing: CupertinoSwitch(
                          value: !_isCEOOnly,
                          onChanged: (value) {
                            setState(() {
                              _isCEOOnly = !value;
                            });
                          },
                          activeTrackColor: isDark
                              ? Color(0xFF007AFF)
                              : Color(0xFF0387FE),
                        ),
                      ),
                      CupertinoListTile(
                        title: Text('Exclude Duplicates'),
                        subtitle: Text(
                          'Hide duplicate entries',
                          style: TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        trailing: CupertinoSwitch(
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Apply button
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                  borderRadius: BorderRadius.circular(12),
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
            ),
          ),
        ],
      ),
    );
  }
}
