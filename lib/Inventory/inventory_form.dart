import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../apis/core/dio_provider.dart';
import '../../apis/core/api_urls.dart';
import 'package:flutter_test_22/apis/providers/auth_provider.dart';
import '../../apis/providers/inventory_provider.dart';
import '../components/form_fields.dart';

// GST Provider
final gstProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('${ApiUrls.baseUrl}gst');
    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(data['gsts'] ?? []);
    }
    return [];
  } catch (e) {
    return [];
  }
});

// Measuring Units Provider
final measuringUnitsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get(
      '${ApiUrls.baseUrl}${ApiUrls.measuringUnit}',
    );
    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      List<Map<String, dynamic>> units = List<Map<String, dynamic>>.from(
        data['measuringUnits'] ?? [],
      );
      // Sort by priority (lower priority number means higher importance)
      units.sort(
        (a, b) => (a['priority'] as int).compareTo(b['priority'] as int),
      );
      return units;
    }
    return [];
  } catch (e) {
    return [];
  }
});

class CreateInventory extends ConsumerStatefulWidget {
  final String? inventoryId; // Add inventoryId parameter for edit mode

  const CreateInventory({Key? key, this.inventoryId}) : super(key: key);

  @override
  ConsumerState<CreateInventory> createState() => _CreateInventoryState();
}

class _CreateInventoryState extends ConsumerState<CreateInventory> {
  final Map<String, dynamic> _formData = {};
  final Map<String, String> _validationErrors = {};
  bool _isLoading = false;
  bool _isLoadingData = false;
  Map<String, dynamic>? _originalInventoryData;

  // Expansion state for sections
  final Map<String, bool> _sectionExpanded = {
    'Basic Information': true,
    'Pricing Details': true,
    'Tax Information': true,
    'Other Details': true,
    'Product Pricing': true,
    'Wholesale Details': false,
    'Discount Details': false,
    'Stock Details': false,
    'Additional Product Details': false,
    'Unit Details': false,
    'Upload Photos': false,
    'Custom Fields': false,
    'Linked Products': false,
  };

  // Form field options
  final List<String> _itemTypes = ['Product', 'Service'];
  final List<String> _statuses = ['Active', 'Inactive'];

  final List<String> _tags = []; // Dynamic tags list
  List<Map<String, String>> _customFields = [
    {'name': '', 'value': ''},
  ];

  // Check if we're in edit mode
  bool get _isEditMode => widget.inventoryId != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (_isEditMode) {
      _loadInventoryData();
    } else {
      _setDefaultValues();
    }
  }

  void _setDefaultValues() {
    // Set default values for create mode
    _formData['itemType'] = 'Product';
    _formData['status'] = 'Active';
    _formData['lowStockWarning'] = false;
    _formData['isRefrigerated'] = false;
    _formData['wholeSalePriceWithTax'] = false;
    _formData['stockAsOfDate'] = DateTime.now();
    _formData['customFields'] = _customFields;
    _formData['tags'] = [];
  }

  Future<void> _loadInventoryData() async {
    if (widget.inventoryId == null) return;

    setState(() {
      _isLoadingData = true;
    });

    try {
      final inventoryNotifier = ref.read(inventoryProvider.notifier);
      final inventoryData = await inventoryNotifier.getInventoryById(
        widget.inventoryId!,
      );

      if (inventoryData != null) {
        _originalInventoryData = inventoryData;
        _populateFormFromInventoryData(inventoryData);
      }
    } catch (e) {
      _showErrorDialog('Failed to load inventory data: $e');
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  void _populateFormFromInventoryData(Map<String, dynamic> data) {
    setState(() {
      // Basic Information
      _formData['name'] = data['name'] ?? '';
      _formData['description'] = data['description'] ?? '';
      _formData['itemType'] = data['itemType'] ?? 'Product';
      _formData['status'] = data['status'] ?? 'Active';
      _formData['category'] = data['category'] ?? '';
      _formData['subCategory'] = data['subCategory'] ?? '';

      // Codes
      _formData['itemCode'] = data['itemCode'] ?? '';
      _formData['hsnCode'] = data['hsnCode'] ?? '';

      // Pricing
      _formData['mrp'] = data['mrp']?.toString() ?? '';

      // Sale price
      if (data['sale'] != null) {
        _formData['salePrice'] = data['sale']['price']?.toString() ?? '';
        if (data['sale']['unit'] != null) {
          _formData['saleUnitId'] = data['sale']['unit']['_id'] ?? '';
          _formData['saleUnit'] = data['sale']['unit']['code'] ?? '';
        }
      }

      // Purchase price
      if (data['purchase'] != null) {
        _formData['purchasePrice'] =
            data['purchase']['price']?.toString() ?? '';
        if (data['purchase']['unit'] != null) {
          _formData['purchaseUnitId'] = data['purchase']['unit']['_id'] ?? '';
          _formData['purchaseUnit'] = data['purchase']['unit']['code'] ?? '';
        }
      }

      // Discount
      if (data['discount'] != null) {
        _formData['discountPercent'] =
            data['discount']['discountPercent']?.toString() ?? '';
        _formData['discountAmount'] =
            data['discount']['discountAmount']?.toString() ?? '';
        _formData['discountAboveQty'] =
            data['discount']['discountAboveQty']?.toString() ?? '';
      }

      // Stock
      if (data['stock'] != null) {
        _formData['openingStock'] =
            data['stock']['openingStock']?.toString() ?? '';
        _formData['currentStock'] =
            data['stock']['currentStock']?.toString() ?? '';
        _formData['isRefrigerated'] = data['stock']['isRefrigerated'] ?? false;

        if (data['stock']['stockAsOfDate'] != null) {
          _formData['stockAsOfDate'] = DateTime.parse(
            data['stock']['stockAsOfDate'],
          );
        }
      }

      // Store location
      if (data['storeLocation'] != null) {
        _formData['storeName'] = data['storeLocation']['storeName'] ?? '';
      }

      // Additional fields
      _formData['brand'] = data['brand'] ?? '';
      _formData['color'] = data['color'] ?? '';

      // Photos
      _formData['photos'] = data['photos'] ?? [];

      // Tags
      _formData['tags'] = data['tags'] ?? [];

      // Custom fields
      if (data['additionalFields'] != null &&
          data['additionalFields'] is List) {
        _customFields = (data['additionalFields'] as List)
            .map(
              (field) => {
                'name': field['name']?.toString() ?? '',
                'value': field['value']?.toString() ?? '',
              },
            )
            .toList();

        if (_customFields.isEmpty) {
          _customFields = [
            {'name': '', 'value': ''},
          ];
        }
      }
      _formData['customFields'] = _customFields;

      // Set default values for fields that might not be in the data
      _formData['lowStockWarning'] = _formData['lowStockWarning'] ?? false;
      _formData['wholeSalePriceWithTax'] =
          _formData['wholeSalePriceWithTax'] ?? false;
    });
  }

  void _updateFormData(String key, dynamic value) {
    setState(() {
      _formData[key] = value;
      _validationErrors.remove(key);
    });
  }

  // Helper method to handle unit selection
  void _handleUnitSelection(
    String unitKey,
    String unitIdKey,
    String value,
    List<Map<String, dynamic>> units,
  ) {
    // Extract code from "NAME(CODE)" format
    String code = value;
    if (value.contains('(') && value.contains(')')) {
      code = value.substring(
        value.lastIndexOf('(') + 1,
        value.lastIndexOf(')'),
      );
    }

    final selectedUnit = units.firstWhere(
      (unit) => unit['code'] == code,
      orElse: () => {},
    );

    if (selectedUnit.isNotEmpty) {
      _updateFormData(unitKey, code);
      _updateFormData(unitIdKey, selectedUnit['_id']);
    }
  }

  // Helper method to format unit display text
  String _formatUnitDisplay(Map<String, dynamic> unit) {
    return "${unit['name']}(${unit['code']})";
  }

  // Helper method to get current unit display value
  String? _getCurrentUnitDisplay(
    String unitKey,
    List<Map<String, dynamic>> units,
  ) {
    final currentCode = _formData[unitKey];
    if (currentCode == null) return null;

    final unit = units.firstWhere(
      (unit) => unit['code'] == currentCode,
      orElse: () => {},
    );

    return unit.isNotEmpty ? _formatUnitDisplay(unit) : null;
  }

  void _toggleSection(String sectionName) {
    setState(() {
      _sectionExpanded[sectionName] = !(_sectionExpanded[sectionName] ?? false);
    });
  }

  bool _validateForm() {
    _validationErrors.clear();

    if (_formData['name'] == null || _formData['name'].toString().isEmpty) {
      _validationErrors['name'] = _formData['itemType'] == 'Service'
          ? 'Service name is required'
          : 'Item name is required';
    }

    if (_formData['itemType'] == null ||
        _formData['itemType'].toString().isEmpty) {
      _validationErrors['itemType'] = 'Item type is required';
    }

    return _validationErrors.isEmpty;
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) {
      setState(() {});
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final inventoryNotifier = ref.read(inventoryProvider.notifier);
      InventoryResult result;

      if (_isEditMode) {
        result = await inventoryNotifier.updateInventoryFromForm(
          widget.inventoryId!,
          _formData,
        );
      } else {
        result = await inventoryNotifier.createInventoryFromForm(_formData);
      }

      if (result.isSuccess) {
        Navigator.of(context).pop();
        _showSuccessDialog(
          result.successMessage ?? 'Operation completed successfully',
        );
      } else {
        _showErrorDialog(result.errorMessage ?? 'Operation failed');
      }
    } catch (e) {
      _showErrorDialog('An unexpected error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Success'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  bool get _isService => _formData['itemType'] == 'Service';

  @override
  Widget build(BuildContext context) {
    final gstAsyncValue = ref.watch(gstProvider);
    final measuringUnitsAsyncValue = ref.watch(measuringUnitsProvider);

    if (_isLoadingData) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(_isEditMode ? 'Edit Inventory' : 'Add Inventory'),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoActivityIndicator(),
              SizedBox(height: 16),
              Text('Loading inventory data...'),
            ],
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          _isEditMode
              ? (_isService ? 'Edit Service' : 'Edit Inventory')
              : (_isService ? 'Add Service' : 'Add Inventory'),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text('Cancel'),
          onPressed: () => context.pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: _isLoading
              ? CupertinoActivityIndicator()
              : Text(_isEditMode ? 'Update' : 'Save'),
          onPressed: _isLoading ? null : _submitForm,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Basic Information Section
              _buildSectionHeader('Basic Information'),
              if (_sectionExpanded['Basic Information'] == true) ...[
                FormFieldWidgets.buildSelectField(
                  'itemType',
                  'Item Type',
                  _itemTypes,
                  onChanged: (key, value) {
                    _updateFormData(key, value);
                    // Clear form data when switching types to avoid confusion
                    if (key == 'itemType' && !_isEditMode) {
                      // Don't clear in edit mode
                      _formData.clear();
                      _formData['itemType'] = value;
                      _formData['status'] = 'Active';
                      _formData['lowStockWarning'] = false;
                      _formData['isRefrigerated'] = false;
                      _formData['wholeSalePriceWithTax'] = false;
                      _formData['stockAsOfDate'] = DateTime.now();
                    }
                  },
                  formData: _formData,
                  validationErrors: _validationErrors,
                  isRequired: true,
                ),

                FormFieldWidgets.buildTextField(
                  'name',
                  _isService ? 'Service Name' : 'Item Name',
                  'text',
                  context,
                  onChanged: _updateFormData,
                  formData: _formData,
                  validationErrors: _validationErrors,
                  isRequired: true,
                ),

                FormFieldWidgets.buildTextAreaField(
                  'description',
                  'Description',
                  onChanged: _updateFormData,
                  formData: _formData,
                  validationErrors: _validationErrors,
                ),

                FormFieldWidgets.buildTextField(
                  'category',
                  _isService ? 'Service Category' : 'Category',
                  'text',
                  context,
                  onChanged: _updateFormData,
                  formData: _formData,
                  validationErrors: _validationErrors,
                ),

                FormFieldWidgets.buildTextField(
                  'subCategory',
                  _isService ? 'Service Sub Category' : 'Sub Category',
                  'text',
                  context,
                  onChanged: _updateFormData,
                  formData: _formData,
                  validationErrors: _validationErrors,
                ),
              ],

              // Pricing Section (Common for both)
              _buildSectionHeader('Pricing Details'),
              if (_sectionExpanded['Pricing Details'] == true) ...[
                FormFieldWidgets.buildTextField(
                  'salePrice',
                  'Sale Price',
                  'text',
                  context,
                  onChanged: _updateFormData,
                  formData: _formData,
                  validationErrors: _validationErrors,
                ),

                // Sale Unit Dropdown
                measuringUnitsAsyncValue.when(
                  data: (units) => FormFieldWidgets.buildSelectField(
                    'saleUnit',
                    'Sale Unit',
                    units.map((unit) => _formatUnitDisplay(unit)).toList(),
                    onChanged: (key, value) {
                      _handleUnitSelection(
                        'saleUnit',
                        'saleUnitId',
                        value,
                        units,
                      );
                    },
                    formData: {
                      ..._formData,
                      'saleUnit': _getCurrentUnitDisplay('saleUnit', units),
                    },
                    validationErrors: _validationErrors,
                  ),
                  loading: () => Container(
                    padding: EdgeInsets.all(16),
                    child: CupertinoActivityIndicator(),
                  ),
                  error: (error, stack) => Container(
                    padding: EdgeInsets.all(16),
                    child: Text('Error loading units: $error'),
                  ),
                ),
              ],

              // Tax Information (Common for both)
              _buildSectionHeader('Tax Information'),
              if (_sectionExpanded['Tax Information'] == true) ...[
                gstAsyncValue.when(
                  data: (gstList) => FormFieldWidgets.buildSelectField(
                    'gst',
                    'Tax Rate',
                    gstList.map((gst) => gst['lable'].toString()).toList(),
                    onChanged: (key, value) {
                      _updateFormData(key, value);
                      final selectedGst = gstList.firstWhere(
                        (gst) => gst['lable'] == value,
                        orElse: () => {},
                      );
                      if (selectedGst.isNotEmpty) {
                        _updateFormData('gstId', selectedGst['_id']);
                        _updateFormData(
                          'taxRate',
                          double.tryParse(selectedGst['value'].toString()) ?? 0,
                        );
                      }
                    },
                    formData: _formData,
                    validationErrors: _validationErrors,
                  ),
                  loading: () => Container(
                    padding: EdgeInsets.all(16),
                    child: CupertinoActivityIndicator(),
                  ),
                  error: (error, stack) => FormFieldWidgets.buildTextField(
                    'gst',
                    'Tax Rate (Manual)',
                    'text',
                    context,
                    onChanged: _updateFormData,
                    formData: _formData,
                    validationErrors: _validationErrors,
                  ),
                ),

                FormFieldWidgets.buildTextField(
                  'hsnCode',
                  _isService ? 'SAC Code' : 'HSN Code',
                  'text',
                  context,
                  onChanged: _updateFormData,
                  formData: _formData,
                  validationErrors: _validationErrors,
                ),
              ],

              // Other Details Section (Common for both)
              _buildSectionHeader('Other Details'),
              if (_sectionExpanded['Other Details'] == true) ...[
                FormFieldWidgets.buildTextField(
                  'itemCode',
                  _isService ? 'Service Code' : 'Item Code',
                  'text',
                  context,
                  onChanged: _updateFormData,
                  formData: _formData,
                  validationErrors: _validationErrors,
                ),
              ],

              // Product-specific fields (only show when itemType is 'Product')
              if (!_isService) ...[
                // Additional Product Pricing
                _buildSectionHeader('Product Pricing'),
                if (_sectionExpanded['Product Pricing'] == true) ...[
                  FormFieldWidgets.buildTextField(
                    'mrp',
                    'MRP',
                    'text',
                    context,
                    onChanged: _updateFormData,
                    formData: _formData,
                    validationErrors: _validationErrors,
                  ),

                  FormFieldWidgets.buildTextField(
                    'purchasePrice',
                    'Purchase Price',
                    'text',
                    context,
                    onChanged: _updateFormData,
                    formData: _formData,
                    validationErrors: _validationErrors,
                  ),

                  // Purchase Unit Dropdown
                  measuringUnitsAsyncValue.when(
                    data: (units) => FormFieldWidgets.buildSelectField(
                      'purchaseUnit',
                      'Purchase Unit',
                      units.map((unit) => _formatUnitDisplay(unit)).toList(),
                      onChanged: (key, value) {
                        _handleUnitSelection(
                          'purchaseUnit',
                          'purchaseUnitId',
                          value,
                          units,
                        );
                      },
                      formData: {
                        ..._formData,
                        'purchaseUnit': _getCurrentUnitDisplay(
                          'purchaseUnit',
                          units,
                        ),
                      },
                      validationErrors: _validationErrors,
                    ),
                    loading: () => Container(
                      padding: EdgeInsets.all(16),
                      child: CupertinoActivityIndicator(),
                    ),
                    error: (error, stack) => Container(
                      padding: EdgeInsets.all(16),
                      child: Text('Error loading units: $error'),
                    ),
                  ),
                ],

                // Wholesale Section
                _buildSectionHeader('Wholesale Details'),
                if (_sectionExpanded['Wholesale Details'] == true) ...[
                  FormFieldWidgets.buildTextField(
                    'wholeSalePrice',
                    'Wholesale Price',
                    'text',
                    context,
                    onChanged: _updateFormData,
                    formData: _formData,
                    validationErrors: _validationErrors,
                  ),

                  FormFieldWidgets.buildSwitchField(
                    'wholeSalePriceWithTax',
                    'Wholesale Price With Tax',
                    onChanged: _updateFormData,
                    formData: _formData,
                    validationErrors: _validationErrors,
                  ),

                  FormFieldWidgets.buildTextField(
                    'wholeSaleMinQty',
                    'Wholesale Min Quantity',
                    'text',
                    context,
                    onChanged: _updateFormData,
                    formData: _formData,
                    validationErrors: _validationErrors,
                  ),
                ],

                // Discount Section
                _buildSectionHeader('Discount Details'),
                if (_sectionExpanded['Discount Details'] == true) ...[
                  FormFieldWidgets.buildTextField(
                    'discountPercent',
                    'Discount (%)',
                    'text',
                    context,
                    onChanged: _updateFormData,
                    formData: _formData,
                    validationErrors: _validationErrors,
                  ),

                  FormFieldWidgets.buildTextField(
                    'discountAmount',
                    'Discount Amount',
                    'text',
                    context,
                    onChanged: _updateFormData,
                    formData: _formData,
                    validationErrors: _validationErrors,
                  ),

                  FormFieldWidgets.buildTextField(
                    'discountAboveQty',
                    'Discount Above Qty',
                    'text',
                    context,
                    onChanged: _updateFormData,
                    formData: _formData,
                    validationErrors: _validationErrors,
                  ),
                ],

                // Stock Details Section
                _buildSectionHeader('Stock Details'),
                if (_sectionExpanded['Stock Details'] == true) ...[
                  FormFieldWidgets.buildTextField(
                    'openingStock',
                    'Opening Stock',
                    'text',
                    context,
                    onChanged: _updateFormData,
                    formData: _formData,
                    validationErrors: _validationErrors,
                  ),

                  FormFieldWidgets.buildDateField(
                    'stockAsOfDate',
                    'As Of Date',
                    context: context,
                    onChanged: _updateFormData,
                    formData: _formData,
                    validationErrors: _validationErrors,
                  ),

                  FormFieldWidgets.buildSwitchField(
                    'lowStockWarning',
                    'Low Stock Warning',
                    onChanged: _updateFormData,
                    formData: _formData,
                    validationErrors: _validationErrors,
                  ),

                  if (_formData['lowStockWarning'] == true)
                    FormFieldWidgets.buildTextField(
                      'lowStockQuantity',
                      'Low Stock Quantity',
                      'text',
                      context,
                      onChanged: _updateFormData,
                      formData: _formData,
                      validationErrors: _validationErrors,
                    ),

                  FormFieldWidgets.buildTextField(
                    'reorderQty',
                    'Reorder Quantity',
                    'text',
                    context,
                    onChanged: _updateFormData,
                    formData: _formData,
                    validationErrors: _validationErrors,
                  ),

                  FormFieldWidgets.buildSwitchField(
                    'isRefrigerated',
                    'Refrigerated Item',
                    onChanged: _updateFormData,
                    formData: _formData,
                    validationErrors: _validationErrors,
                  ),
                ],

                // Additional Product Details
                _buildSectionHeader('Additional Product Details'),
                if (_sectionExpanded['Additional Product Details'] == true) ...[
                  FormFieldWidgets.buildTextField(
                    'brand',
                    'Brand',
                    'text',
                    context,
                    onChanged: _updateFormData,
                    formData: _formData,
                    validationErrors: _validationErrors,
                  ),

                  FormFieldWidgets.buildTextField(
                    'color',
                    'Color',
                    'text',
                    context,
                    onChanged: _updateFormData,
                    formData: _formData,
                    validationErrors: _validationErrors,
                  ),

                  FormFieldWidgets.buildTextField(
                    'storeName',
                    'Store Name',
                    'text',
                    context,
                    onChanged: _updateFormData,
                    formData: _formData,
                    validationErrors: _validationErrors,
                  ),

                  FormFieldWidgets.buildTextField(
                    'storeLocation',
                    'Store Location',
                    'text',
                    context,
                    onChanged: _updateFormData,
                    formData: _formData,
                    validationErrors: _validationErrors,
                  ),
                ],

                // Units Section
                _buildSectionHeader('Unit Details'),
                if (_sectionExpanded['Unit Details'] == true) ...[
                  // Base Unit Dropdown
                  measuringUnitsAsyncValue.when(
                    data: (units) => FormFieldWidgets.buildSelectField(
                      'baseUnit',
                      'Base Unit',
                      units.map((unit) => _formatUnitDisplay(unit)).toList(),
                      onChanged: (key, value) {
                        _handleUnitSelection(
                          'baseUnit',
                          'baseUnitId',
                          value,
                          units,
                        );
                      },
                      formData: {
                        ..._formData,
                        'baseUnit': _getCurrentUnitDisplay('baseUnit', units),
                      },
                      validationErrors: _validationErrors,
                    ),
                    loading: () => Container(
                      padding: EdgeInsets.all(16),
                      child: CupertinoActivityIndicator(),
                    ),
                    error: (error, stack) => Container(
                      padding: EdgeInsets.all(16),
                      child: Text('Error loading units: $error'),
                    ),
                  ),

                  // Secondary Unit Dropdown
                  measuringUnitsAsyncValue.when(
                    data: (units) => FormFieldWidgets.buildSelectField(
                      'secondaryUnit',
                      'Secondary Unit',
                      units.map((unit) => _formatUnitDisplay(unit)).toList(),
                      onChanged: (key, value) {
                        _handleUnitSelection(
                          'secondaryUnit',
                          'secondaryUnitId',
                          value,
                          units,
                        );
                      },
                      formData: {
                        ..._formData,
                        'secondaryUnit': _getCurrentUnitDisplay(
                          'secondaryUnit',
                          units,
                        ),
                      },
                      validationErrors: _validationErrors,
                    ),
                    loading: () => Container(
                      padding: EdgeInsets.all(16),
                      child: CupertinoActivityIndicator(),
                    ),
                    error: (error, stack) => Container(
                      padding: EdgeInsets.all(16),
                      child: Text('Error loading units: $error'),
                    ),
                  ),

                  FormFieldWidgets.buildTextField(
                    'conversationRate',
                    'Conversion Rate',
                    'text',
                    context,
                    onChanged: _updateFormData,
                    formData: _formData,
                    validationErrors: _validationErrors,
                  ),
                ],
              ],

              // Photos field - shown for both Product and Service
              _buildSectionHeader('Upload Photos'),
              if (_sectionExpanded['Upload Photos'] == true) ...[
                FormFieldWidgets.buildMultiplePhotosField(
                  'photos',
                  'Photos',
                  onChanged: _updateFormData,
                  formData: _formData,
                  validationErrors: _validationErrors,
                  context: context,
                ),
              ],

              _buildSectionHeader('Custom Fields'),
              if (_sectionExpanded['Custom Fields'] == true) ...[
                ..._buildCustomFields(),
              ],

              // Add Tags section
              _buildSectionHeader('Linked Products'),
              if (_sectionExpanded['Linked Products'] == true) ...[
                FormFieldWidgets.buildMultiSelectField(
                  'tags',
                  'Tag Inventory Items',
                  _tags, // You'll need to populate this with available tags
                  onChanged: _updateFormData,
                  formData: _formData,
                  validationErrors: _validationErrors,
                ),
              ],

              SizedBox(height: 100), // Extra space at bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isExpanded = _sectionExpanded[title] ?? false;

    return GestureDetector(
      onTap: () => _toggleSection(title),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: CupertinoColors.systemGrey6,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.black,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.25,
                ),
              ),
            ),
            AnimatedRotation(
              turns: isExpanded ? 0.25 : 0,
              duration: Duration(milliseconds: 200),
              child: Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoColors.systemGrey,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCustomFields() {
    List<Widget> customFieldWidgets = [];

    for (int i = 0; i < _customFields.length; i++) {
      customFieldWidgets.add(
        Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  placeholder: 'Field Name',
                  controller: TextEditingController(
                    text: _customFields[i]['name'],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _customFields[i]['name'] = value;
                      _formData['customFields'] = _customFields;
                    });
                  },
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.25,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: CupertinoTextField(
                  placeholder: 'Field Value',
                  controller: TextEditingController(
                    text: _customFields[i]['value'],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _customFields[i]['value'] = value;
                      _formData['customFields'] = _customFields;
                    });
                  },
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.25,
                  ),
                ),
              ),
              SizedBox(width: 8),
              if (_customFields.length > 1)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    CupertinoIcons.minus_circle_fill,
                    color: CupertinoColors.systemRed,
                  ),
                  onPressed: () {
                    setState(() {
                      _customFields.removeAt(i);
                      _formData['customFields'] = _customFields;
                    });
                  },
                ),
            ],
          ),
        ),
      );
    }

    // Add button to add more custom fields
    customFieldWidgets.add(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.plus_circle_fill,
                color: CupertinoColors.activeBlue,
              ),
              SizedBox(width: 8),
              Text(
                'Add Another Field',
                style: TextStyle(
                  color: CupertinoColors.activeBlue,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.25,
                ),
              ),
            ],
          ),
          onPressed: () {
            setState(() {
              _customFields.add({'name': '', 'value': ''});
              _formData['customFields'] = _customFields;
            });
          },
        ),
      ),
    );

    return customFieldWidgets;
  }
}
