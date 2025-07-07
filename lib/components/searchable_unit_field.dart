// lib/components/searchable_unit_field.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Wareozo/apis/providers/measuring_units_provider.dart';

class SearchableUnitField extends ConsumerStatefulWidget {
  final String fieldKey;
  final String label;
  final Function(String, String) onChanged;
  final Map<String, dynamic> formData;
  final Map<String, String> validationErrors;
  final bool isRequired;

  const SearchableUnitField({
    Key? key,
    required this.fieldKey,
    required this.label,
    required this.onChanged,
    required this.formData,
    required this.validationErrors,
    this.isRequired = false,
  }) : super(key: key);

  @override
  ConsumerState<SearchableUnitField> createState() =>
      _SearchableUnitFieldState();
}

class _SearchableUnitFieldState extends ConsumerState<SearchableUnitField> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isDropdownOpen = false;
  String? _selectedValue;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();

    // Initialize with current form value
    _selectedValue = widget.formData[widget.fieldKey];
    if (_selectedValue != null) {
      _searchController.text = _selectedValue!;
    }

    // Fetch units when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(measuringUnitsProvider.notifier).fetchMeasuringUnits();
    });

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isDropdownOpen) {
        setState(() {
          _isDropdownOpen = false;
        });
        // Reset field if user was typing but didn't select anything
        if (_isTyping && _selectedValue != null) {
          _searchController.text = _selectedValue!;
          setState(() {
            _isTyping = false;
          });
        }
        // Clear search when dropdown closes to reset for next time
        ref.read(measuringUnitsProvider.notifier).clearSearch();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleUnitSelection(
    String displayValue,
    List<Map<String, dynamic>> units,
  ) {
    final selectedUnit = MeasuringUnitsHelper.findUnitByDisplay(
      units,
      displayValue,
    );

    if (selectedUnit != null) {
      final code = selectedUnit['code'];
      setState(() {
        _selectedValue = displayValue;
        _searchController.text = displayValue;
        _isDropdownOpen = false;
        _isTyping = false;
      });

      // Call the onChanged callback with unit code and unit ID
      widget.onChanged(widget.fieldKey, code);

      // Also set the unit ID if the field key pattern matches
      if (widget.fieldKey.endsWith('Unit')) {
        final idKey = widget.fieldKey.replaceAll('Unit', 'UnitId');
        widget.onChanged(idKey, selectedUnit['_id']);
      }

      // Clear search and close dropdown
      ref.read(measuringUnitsProvider.notifier).clearSearch();
      _focusNode.unfocus();
    }
  }

  void _handleSearchChanged(String query) {
    setState(() {
      _isTyping = query.isNotEmpty && query != _selectedValue;
    });

    ref.read(measuringUnitsProvider.notifier).searchUnits(query);

    if (!_isDropdownOpen) {
      setState(() {
        _isDropdownOpen = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitsState = ref.watch(measuringUnitsProvider);
    final hasError = widget.validationErrors.containsKey(widget.fieldKey);

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Row(
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.black,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.25,
                ),
              ),
              if (widget.isRequired) ...[
                SizedBox(width: 4),
                Text(
                  '*',
                  style: TextStyle(
                    color: CupertinoColors.systemRed,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8),

          // Search Field
          Stack(
            children: [
              CupertinoTextField(
                controller: _searchController,
                focusNode: _focusNode,
                placeholder: 'Search ${widget.label.toLowerCase()}...',
                onChanged: _handleSearchChanged,
                onTap: () {
                  if (!_isDropdownOpen) {
                    setState(() {
                      _isDropdownOpen = true;
                      _isTyping = false;
                    });
                    // Always show all units when dropdown opens
                    ref.read(measuringUnitsProvider.notifier).clearSearch();
                    _focusNode.requestFocus();
                  }
                },
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  border: Border.all(
                    color: hasError
                        ? CupertinoColors.systemRed
                        : CupertinoColors.systemGrey4,
                    width: hasError ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                suffix: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (unitsState.isLoading)
                      Container(
                        padding: EdgeInsets.all(8),
                        child: CupertinoActivityIndicator(radius: 8),
                      )
                    else
                      CupertinoButton(
                        padding: EdgeInsets.all(8),
                        minSize: 0,
                        child: Icon(
                          _isDropdownOpen
                              ? CupertinoIcons.chevron_up
                              : CupertinoIcons.chevron_down,
                          size: 16,
                          color: CupertinoColors.systemGrey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isDropdownOpen = !_isDropdownOpen;
                            if (_isDropdownOpen) {
                              _isTyping = false;
                            }
                          });
                          if (_isDropdownOpen) {
                            _focusNode.requestFocus();
                            // Always show all units when dropdown opens
                            ref
                                .read(measuringUnitsProvider.notifier)
                                .clearSearch();
                          } else {
                            _focusNode.unfocus();
                          }
                        },
                      ),
                  ],
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.25,
                ),
              ),

              // Dropdown List
              if (_isDropdownOpen && !unitsState.isLoading)
                Positioned(
                  top: 45,
                  left: 0,
                  right: 0,
                  child: Container(
                    constraints: BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      border: Border.all(color: CupertinoColors.systemGrey4),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: unitsState.filteredUnits.isEmpty
                        ? Container(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              unitsState.searchQuery.isNotEmpty
                                  ? 'No units found for "${unitsState.searchQuery}"'
                                  : 'No units available',
                              style: TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header showing count and search status
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemGrey6,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: CupertinoColors.systemGrey4,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  unitsState.searchQuery.isNotEmpty
                                      ? '${unitsState.filteredUnits.length} units found'
                                      : '${unitsState.filteredUnits.length} units (A-Z)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: CupertinoColors.systemGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              // Units list
                              Flexible(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: unitsState.filteredUnits.length,
                                  itemBuilder: (context, index) {
                                    final unit =
                                        unitsState.filteredUnits[index];
                                    final displayText =
                                        MeasuringUnitsHelper.formatUnitDisplay(
                                          unit,
                                        );
                                    final isSelected =
                                        _selectedValue == displayText;

                                    return CupertinoButton(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      minSize: 0,
                                      color: isSelected
                                          ? CupertinoColors.systemBlue
                                                .withOpacity(0.1)
                                          : null,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          displayText,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: isSelected
                                                ? CupertinoColors.systemBlue
                                                : CupertinoColors.black,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      onPressed: () => _handleUnitSelection(
                                        displayText,
                                        unitsState.allUnits,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
            ],
          ),

          // Error Message
          if (hasError) ...[
            SizedBox(height: 8),
            Text(
              widget.validationErrors[widget.fieldKey]!,
              style: TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: 14,
                fontFamily: 'SF Pro Display',
              ),
            ),
          ],

          // API Error Message
          if (unitsState.error != null) ...[
            SizedBox(height: 8),
            Text(
              unitsState.error!,
              style: TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: 14,
                fontFamily: 'SF Pro Display',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
