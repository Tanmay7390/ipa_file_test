import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../apis/core/dio_provider.dart';
import '../../apis/core/api_urls.dart';
import 'package:Wareozo/apis/providers/auth_provider.dart';
import 'package:Wareozo/apis/providers/category_provider.dart';
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
      // Sort alphabetically by name instead of priority
      units.sort(
        (a, b) => (a['name']?.toString() ?? '').toLowerCase().compareTo(
          (b['name']?.toString() ?? '').toLowerCase(),
        ),
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
    print('Populating form with data: $data'); // Debug print

    setState(() {
      // Basic Information
      _formData['name'] = data['name'] ?? '';
      _formData['description'] = data['description'] ?? '';
      _formData['itemType'] = data['itemType'] ?? 'Product';
      _formData['status'] = data['status'] ?? 'Active';

      // Codes
      _formData['itemCode'] = data['itemCode'] ?? '';
      _formData['hsnCode'] = data['hsnCode'] ?? '';

      // FIXED: Handle Category and SubCategory properly
      if (data['category'] != null) {
        if (data['category'] is String) {
          _formData['category'] = data['category'];
          // Load category name if we have the ID
          _loadCategoryName(data['category']);
        } else if (data['category'] is Map) {
          _formData['category'] = data['category']['_id'] ?? '';
          _formData['categoryName'] = data['category']['name'] ?? '';
        }
      }

      if (data['subCategory'] != null) {
        if (data['subCategory'] is String) {
          _formData['subCategory'] = data['subCategory'];
          // Load subcategory name if we have the ID
          _loadSubCategoryName(data['subCategory']);
        } else if (data['subCategory'] is Map) {
          _formData['subCategory'] = data['subCategory']['_id'] ?? '';
          _formData['subCategoryName'] = data['subCategory']['name'] ?? '';
        }
      }

      // Pricing - MRP
      _formData['mrp'] = data['mrp']?.toString() ?? '';

      // FIXED: Handle different possible sale price structures
      if (data['salePrice'] != null) {
        _formData['salePrice'] = data['salePrice'].toString();
      } else if (data['sale'] != null && data['sale']['price'] != null) {
        _formData['salePrice'] = data['sale']['price']?.toString() ?? '';
      }

      // FIXED: Handle sale unit - check multiple possible locations
      if (data['saleUnit'] != null) {
        if (data['saleUnit'] is String) {
          _formData['saleUnit'] = data['saleUnit'];
        } else if (data['saleUnit'] is Map && data['saleUnit']['_id'] != null) {
          _formData['saleUnit'] = data['saleUnit']['_id'];
          _formData['saleUnitCode'] = data['saleUnit']['code'];
        }
      } else if (data['sale'] != null && data['sale']['unit'] != null) {
        if (data['sale']['unit'] is String) {
          _formData['saleUnit'] = data['sale']['unit'];
        } else if (data['sale']['unit'] is Map) {
          _formData['saleUnit'] = data['sale']['unit']['_id'] ?? '';
          _formData['saleUnitCode'] = data['sale']['unit']['code'] ?? '';
        }
      }

      // FIXED: Handle different possible purchase price structures
      if (data['purchasePrice'] != null) {
        if (data['purchasePrice'] is Map &&
            data['purchasePrice']['price'] != null) {
          _formData['purchasePrice'] =
              data['purchasePrice']['price']?.toString() ?? '';
        } else {
          _formData['purchasePrice'] = data['purchasePrice']?.toString() ?? '';
        }
      } else if (data['purchase'] != null &&
          data['purchase']['price'] != null) {
        _formData['purchasePrice'] =
            data['purchase']['price']?.toString() ?? '';
      }

      // FIXED: Handle purchase unit - check multiple possible locations
      if (data['purchaseUnit'] != null) {
        if (data['purchaseUnit'] is String) {
          _formData['purchaseUnit'] = data['purchaseUnit'];
        } else if (data['purchaseUnit'] is Map &&
            data['purchaseUnit']['_id'] != null) {
          _formData['purchaseUnit'] = data['purchaseUnit']['_id'];
          _formData['purchaseUnitCode'] = data['purchaseUnit']['code'];
        }
      } else if (data['purchase'] != null && data['purchase']['unit'] != null) {
        if (data['purchase']['unit'] is String) {
          _formData['purchaseUnit'] = data['purchase']['unit'];
        } else if (data['purchase']['unit'] is Map) {
          _formData['purchaseUnit'] = data['purchase']['unit']['_id'] ?? '';
          _formData['purchaseUnitCode'] =
              data['purchase']['unit']['code'] ?? '';
        }
      }

      // FIXED: Handle Base and Secondary Units properly
      if (data['baseUnit'] != null) {
        if (data['baseUnit'] is String) {
          _formData['baseUnit'] = data['baseUnit'];
        } else if (data['baseUnit'] is Map) {
          _formData['baseUnit'] = data['baseUnit']['_id'] ?? '';
          _formData['baseUnitCode'] = data['baseUnit']['code'] ?? '';
        }
      }

      if (data['secondaryUnit'] != null) {
        if (data['secondaryUnit'] is String) {
          _formData['secondaryUnit'] = data['secondaryUnit'];
        } else if (data['secondaryUnit'] is Map) {
          _formData['secondaryUnit'] = data['secondaryUnit']['_id'] ?? '';
          _formData['secondaryUnitCode'] = data['secondaryUnit']['code'] ?? '';
        }
      }

      // Conversion Rate
      _formData['conversationRate'] =
          data['conversationRate']?.toString() ?? '';

      // FIXED: GST Information - handle both string ID and object
      if (data['gst'] != null) {
        if (data['gst'] is String) {
          // If gst is stored as ID string, use it directly
          _formData['gst'] = data['gst'];
        } else if (data['gst'] is Map) {
          // If gst is stored as object, get the label for display and store ID for API
          _formData['gst'] =
              data['gst']['lable'] ?? ''; // For display in dropdown
          _formData['gstId'] =
              data['gst']['_id'] ?? ''; // Store ID for API submission
          _formData['taxRate'] =
              double.tryParse(data['gst']['value']?.toString() ?? '0') ?? 0;

          print(
            'Loaded GST: label=${data['gst']['lable']}, id=${data['gst']['_id']}, rate=${data['gst']['value']}',
          );
        }
      }

      // FIXED: Handle wholesale pricing from nested structure
      if (data['wholeSale'] != null) {
        _formData['wholeSalePrice'] =
            data['wholeSale']['price']?.toString() ?? '';
        _formData['wholeSaleMinQty'] =
            data['wholeSale']['minQty']?.toString() ?? '';
      } else {
        // Fallback to flat structure
        _formData['wholeSalePrice'] = data['wholeSalePrice']?.toString() ?? '';
        _formData['wholeSaleMinQty'] =
            data['wholeSaleMinQty']?.toString() ?? '';
      }

      // Handle wholesale price with tax (this is usually a flat field)
      if (data['wholeSalePriceWithTax'] != null) {
        _formData['wholeSalePriceWithTax'] =
            data['wholeSalePriceWithTax'] ?? false;
      }

      // Discount - handle both flat and nested structures
      if (data['discount'] != null) {
        _formData['discountPercent'] =
            data['discount']['discountPercent']?.toString() ?? '';
        _formData['discountAmount'] =
            data['discount']['discountAmount']?.toString() ?? '';
        _formData['discountAboveQty'] =
            data['discount']['discountAboveQty']?.toString() ?? '';
      } else {
        // Handle flat discount fields
        _formData['discountPercent'] =
            data['discountPercent']?.toString() ?? '';
        _formData['discountAmount'] = data['discountAmount']?.toString() ?? '';
        _formData['discountAboveQty'] =
            data['discountAboveQty']?.toString() ?? '';
      }

      // FIXED: Handle stock and reorder quantity from nested structure
      if (data['stock'] != null) {
        _formData['openingStock'] =
            data['stock']['openingStock']?.toString() ?? '';
        _formData['currentStock'] =
            data['stock']['currentStock']?.toString() ?? '';
        _formData['isRefrigerated'] = data['stock']['isRefrigerated'] ?? false;

        // FIXED: Handle reorder quantity from nested stock
        _formData['reorderQty'] = data['stock']['reorderQty']?.toString() ?? '';

        // Handle low stock fields from nested structure
        _formData['lowStockQuantity'] =
            data['stock']['lowStockQuantity']?.toString() ?? '';

        if (data['stock']['stockAsOfDate'] != null) {
          _formData['stockAsOfDate'] = DateTime.parse(
            data['stock']['stockAsOfDate'],
          );
        }
      } else {
        // Handle flat stock fields
        _formData['openingStock'] = data['openingStock']?.toString() ?? '';
        _formData['currentStock'] = data['currentStock']?.toString() ?? '';
        _formData['isRefrigerated'] = data['isRefrigerated'] ?? false;
        _formData['reorderQty'] = data['reorderQty']?.toString() ?? '';
        _formData['lowStockQuantity'] =
            data['lowStockQuantity']?.toString() ?? '';

        if (data['stockAsOfDate'] != null) {
          _formData['stockAsOfDate'] = DateTime.parse(data['stockAsOfDate']);
        }
      }

      // FIXED: Store location - handle nested structure properly
      if (data['storeLocation'] != null) {
        if (data['storeLocation'] is Map) {
          _formData['storeName'] = data['storeLocation']['storeName'] ?? '';
          _formData['storeLocation'] = data['storeLocation']['location'] ?? '';
        } else if (data['storeLocation'] is String) {
          _formData['storeLocation'] = data['storeLocation'];
        }
      }

      // Handle flat store fields as fallback
      if (_formData['storeName'] == null ||
          _formData['storeName'].toString().isEmpty) {
        _formData['storeName'] = data['storeName'] ?? '';
      }

      // Additional product fields
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

      // Set default stock date if not present
      if (_formData['stockAsOfDate'] == null) {
        _formData['stockAsOfDate'] = DateTime.now();
      }
    });

    // Debug prints to verify form data
    print('Form data after population:');
    print('salePrice: ${_formData['salePrice']}');
    print('saleUnit: ${_formData['saleUnit']}');
    print('purchasePrice: ${_formData['purchasePrice']}');
    print('purchaseUnit: ${_formData['purchaseUnit']}');
    print('baseUnit: ${_formData['baseUnit']}');
    print('secondaryUnit: ${_formData['secondaryUnit']}');
    print('gst: ${_formData['gst']}');
    print('gstId: ${_formData['gstId']}');
    print('wholeSalePrice: ${_formData['wholeSalePrice']}');
    print('wholeSaleMinQty: ${_formData['wholeSaleMinQty']}');
    print('reorderQty: ${_formData['reorderQty']}');
    print('storeName: ${_formData['storeName']}');
    print('storeLocation: ${_formData['storeLocation']}');
    print('category: ${_formData['category']}');
    print('categoryName: ${_formData['categoryName']}');
    print('subCategory: ${_formData['subCategory']}');
    print('subCategoryName: ${_formData['subCategoryName']}');
  }

  void _updateFormData(String key, dynamic value) {
    setState(() {
      _formData[key] = value;
      _validationErrors.remove(key);
    });
  }
  // Add these helper methods to load category/subcategory names from IDs:

  Future<void> _loadCategoryName(String categoryId) async {
    final categoryState = ref.read(categoryProvider);
    final category = categoryState.categories.firstWhere(
      (cat) => cat['_id'] == categoryId,
      orElse: () => {},
    );

    if (category.isNotEmpty) {
      setState(() {
        _formData['categoryName'] = category['name'];
      });
    } else {
      // If category not found in current list, load categories
      await ref.read(categoryProvider.notifier).getCategories();
      final updatedState = ref.read(categoryProvider);
      final foundCategory = updatedState.categories.firstWhere(
        (cat) => cat['_id'] == categoryId,
        orElse: () => {},
      );
      if (foundCategory.isNotEmpty) {
        setState(() {
          _formData['categoryName'] = foundCategory['name'];
        });
      }
    }
  }

  Future<void> _loadSubCategoryName(String subCategoryId) async {
    final categoryState = ref.read(categoryProvider);
    final categoryId = _formData['category'];

    if (categoryId != null) {
      final subCategories = categoryState.subCategories[categoryId] ?? [];
      final subCategory = subCategories.firstWhere(
        (subCat) => subCat['_id'] == subCategoryId,
        orElse: () => {},
      );

      if (subCategory.isNotEmpty) {
        setState(() {
          _formData['subCategoryName'] = subCategory['name'];
        });
      } else {
        // Load subcategories if not found
        await ref.read(categoryProvider.notifier).getSubCategories(categoryId);
        final updatedState = ref.read(categoryProvider);
        final updatedSubCategories =
            updatedState.subCategories[categoryId] ?? [];
        final foundSubCategory = updatedSubCategories.firstWhere(
          (subCat) => subCat['_id'] == subCategoryId,
          orElse: () => {},
        );
        if (foundSubCategory.isNotEmpty) {
          setState(() {
            _formData['subCategoryName'] = foundSubCategory['name'];
          });
        }
      }
    }
  }

  // FIXED: Helper method to handle unit selection
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
      // Store the unit ID (ObjectId) for the API
      _updateFormData(unitKey, selectedUnit['_id']);
      // Store the code for display purposes
      _updateFormData('${unitKey}Code', code);

      print(
        'Unit selected: ${selectedUnit['name']} (${code}) - ID: ${selectedUnit['_id']}',
      );
    }
  }

  // Helper method to format unit display text
  String _formatUnitDisplay(Map<String, dynamic> unit) {
    return "${unit['name']}(${unit['code']})";
  }

  // FIXED: Helper method to get current unit display value
  String? _getCurrentUnitDisplay(
    String unitKey,
    List<Map<String, dynamic>> units,
  ) {
    // First check if we have the unit ID stored
    final currentUnitId = _formData[unitKey];
    if (currentUnitId != null) {
      final unit = units.firstWhere(
        (unit) => unit['_id'] == currentUnitId,
        orElse: () => {},
      );
      if (unit.isNotEmpty) {
        return _formatUnitDisplay(unit);
      }
    }

    // Fallback to checking by code
    final currentCode = _formData['${unitKey}Code'];
    if (currentCode != null) {
      final unit = units.firstWhere(
        (unit) => unit['code'] == currentCode,
        orElse: () => {},
      );
      if (unit.isNotEmpty) {
        return _formatUnitDisplay(unit);
      }
    }

    return null;
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

  // Fixed _prepareFormDataForSubmission method in inventory_form.dart
  Map<String, dynamic> _prepareFormDataForSubmission() {
    Map<String, dynamic> submissionData = Map.from(_formData);

    // Remove display-only fields that shouldn't be sent to API
    submissionData.remove('saleUnitCode');
    submissionData.remove('purchaseUnitCode');
    submissionData.remove('baseUnitCode');
    submissionData.remove('secondaryUnitCode');

    // FIXED: For GST, if we have gstId, use that instead of the label
    if (submissionData['gstId'] != null &&
        submissionData['gstId'].toString().isNotEmpty) {
      submissionData['gst'] = submissionData['gstId'];
      submissionData.remove('gstId'); // Remove the temporary field
    }

    // Debug prints to verify submission data
    print('=== SUBMISSION DATA DEBUG ===');
    print('wholeSalePrice: ${submissionData['wholeSalePrice']}');
    print('wholeSaleMinQty: ${submissionData['wholeSaleMinQty']}');
    print('reorderQty: ${submissionData['reorderQty']}');
    print('storeName: ${submissionData['storeName']}');
    print('storeLocation: ${submissionData['storeLocation']}');
    print('===============================');

    return submissionData;
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

      // FIXED: Use prepared form data
      final submissionData = _prepareFormDataForSubmission();

      if (_isEditMode) {
        result = await inventoryNotifier.updateInventoryFromForm(
          widget.inventoryId!,
          submissionData,
        );
      } else {
        result = await inventoryNotifier.createInventoryFromForm(
          submissionData,
        );
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
                  'itemCode',
                  _isService ? 'Service Code' : 'Item Code',
                  'text',
                  context,
                  onChanged: _updateFormData,
                  formData: _formData,
                  validationErrors: _validationErrors,
                ),

                // Category Dropdown
                Consumer(
                  builder: (context, ref, child) {
                    final categoryState = ref.watch(categoryProvider);

                    if (categoryState.isLoading) {
                      return Container(
                        padding: EdgeInsets.all(16),
                        child: CupertinoActivityIndicator(),
                      );
                    }

                    if (categoryState.categories.isEmpty) {
                      // Load categories when form loads
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ref.read(categoryProvider.notifier).getCategories();
                      });
                    }

                    return FormFieldWidgets.buildSelectField(
                      'category',
                      _isService ? 'Service Category' : 'Category',
                      categoryState.categories
                          .map((cat) => cat['name'].toString())
                          .toList(),
                      onChanged: (key, value) {
                        // Find the selected category
                        final selectedCategory = categoryState.categories
                            .firstWhere(
                              (cat) => cat['name'] == value,
                              orElse: () => {},
                            );

                        if (selectedCategory.isNotEmpty) {
                          // Store category ID for API
                          _updateFormData('category', selectedCategory['_id']);
                          _updateFormData('categoryName', value); // For display

                          // Clear subcategory when category changes
                          _updateFormData('subCategory', null);
                          _updateFormData('subCategoryName', null);

                          // Load subcategories for this category
                          ref
                              .read(categoryProvider.notifier)
                              .getSubCategories(selectedCategory['_id']);
                        }
                      },
                      formData: {
                        ..._formData,
                        'category': _formData['categoryName'],
                      }, // Use name for display
                      validationErrors: _validationErrors,
                    );
                  },
                ),

                // Sub Category Dropdown
                Consumer(
                  builder: (context, ref, child) {
                    final categoryState = ref.watch(categoryProvider);
                    final selectedCategoryId = _formData['category'];

                    if (selectedCategoryId == null) {
                      return FormFieldWidgets.buildSelectField(
                        'subCategory',
                        _isService ? 'Service Sub Category' : 'Sub Category',
                        [],
                        onChanged: (key, value) {},
                        formData: _formData,
                        validationErrors: _validationErrors,
                        isEnabled: false,
                      );
                    }

                    final subCategories =
                        categoryState.subCategories[selectedCategoryId] ?? [];

                    return FormFieldWidgets.buildSelectField(
                      'subCategory',
                      _isService ? 'Service Sub Category' : 'Sub Category',
                      subCategories
                          .map((subCat) => subCat['name'].toString())
                          .toList(),
                      onChanged: (key, value) {
                        // Find the selected subcategory
                        final selectedSubCategory = subCategories.firstWhere(
                          (subCat) => subCat['name'] == value,
                          orElse: () => {},
                        );

                        if (selectedSubCategory.isNotEmpty) {
                          // Store subcategory ID for API
                          _updateFormData(
                            'subCategory',
                            selectedSubCategory['_id'],
                          );
                          _updateFormData(
                            'subCategoryName',
                            value,
                          ); // For display
                        }
                      },
                      formData: {
                        ..._formData,
                        'subCategory': _formData['subCategoryName'],
                      }, // Use name for display
                      validationErrors: _validationErrors,
                    );
                  },
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

                // FIXED: Sale Unit Dropdown
                measuringUnitsAsyncValue.when(
                  data: (units) => FormFieldWidgets.buildSearchableUnitField(
                    'saleUnit',
                    'Sale Unit',
                    units,
                    context,
                    onUnitSelection: _handleUnitSelection,
                    formData: _formData,
                    validationErrors: _validationErrors,
                    unitKey: 'saleUnit',
                    unitIdKey:
                        'saleUnit', // Same as unitKey since we store ID directly
                    getCurrentValue: () =>
                        _getCurrentUnitDisplay('saleUnit', units),
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
                  data: (gstList) {
                    // Helper function to get the currently selected GST label for display
                    String? getCurrentGstLabel() {
                      // If we have gstId from editing, find the corresponding label
                      if (_formData['gstId'] != null &&
                          _formData['gstId'].toString().isNotEmpty) {
                        final gst = gstList.firstWhere(
                          (g) => g['_id'] == _formData['gstId'],
                          orElse: () => {},
                        );
                        if (gst.isNotEmpty) {
                          return gst['lable'];
                        }
                      }

                      // Otherwise, use the current gst value if it's a label
                      if (_formData['gst'] != null &&
                          _formData['gst'].toString().isNotEmpty) {
                        return _formData['gst'];
                      }

                      return null;
                    }

                    // Update form data to show the correct label
                    final currentLabel = getCurrentGstLabel();
                    if (currentLabel != null) {
                      _formData['gst'] = currentLabel;
                    }

                    return FormFieldWidgets.buildSelectField(
                      'gst',
                      'Tax Rate',
                      gstList.map((gst) => gst['lable'].toString()).toList(),
                      onChanged: (key, value) {
                        // Store both the label for display and ID for API
                        _updateFormData(key, value);

                        // Find the selected GST object and store its ID
                        final selectedGst = gstList.firstWhere(
                          (gst) => gst['lable'] == value,
                          orElse: () => {},
                        );

                        if (selectedGst.isNotEmpty) {
                          // Store the GST ID for API submission
                          _updateFormData('gstId', selectedGst['_id']);
                          // Store the tax rate for calculations
                          _updateFormData(
                            'taxRate',
                            double.tryParse(selectedGst['value'].toString()) ??
                                0,
                          );

                          print(
                            'GST Selected: ${selectedGst['lable']} - ID: ${selectedGst['_id']}',
                          );
                        }
                      },
                      formData: _formData,
                      validationErrors: _validationErrors,
                    );
                  },
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
              // _buildSectionHeader('Other Details'),
              // if (_sectionExpanded['Other Details'] == true) ...[],

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

                  // FIXED: Purchase Unit Dropdown
                  measuringUnitsAsyncValue.when(
                    data: (units) => FormFieldWidgets.buildSearchableUnitField(
                      'purchaseUnit',
                      'Purchase Unit',
                      units,
                      context,
                      onUnitSelection: _handleUnitSelection,
                      formData: _formData,
                      validationErrors: _validationErrors,
                      unitKey: 'purchaseUnit',
                      unitIdKey: 'purchaseUnit',
                      getCurrentValue: () =>
                          _getCurrentUnitDisplay('purchaseUnit', units),
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
