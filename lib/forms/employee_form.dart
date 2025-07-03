import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../components/form_fields.dart';
import '../../apis/providers/employee_provider.dart';
import '../../apis/core/dio_provider.dart';
import '../../auth/components/auth_provider.dart';
import '../components/addresses_bottom_sheet.dart';
import '../components/client_selection_sheet.dart';
import 'package:image_picker/image_picker.dart';

class EmployeeForm extends ConsumerStatefulWidget {
  final String? employeeId;
  final Map<String, dynamic>? initialData;

  const EmployeeForm({Key? key, this.employeeId, this.initialData})
    : super(key: key);

  @override
  _EmployeeFormState createState() => _EmployeeFormState();
}

class _EmployeeFormState extends ConsumerState<EmployeeForm> {
  final Map<String, dynamic> _formData = {};
  final Map<String, String> _validationErrors = {};

  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;
  String _employeeId = '';
  bool _isLoadingEmployeeId = false;
  bool _isSameAsPresentAddress = false;

  bool get _isEditMode => widget.employeeId != null;
  bool _isLoadingEmployeeData = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndInitialize();
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _checkAuthAndInitialize() {
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated && authState.accountId != null) {
      if (_isEditMode) {
        _loadEmployeeData();
      } else {
        _generateEmployeeId();
      }
    } else {
      _showErrorDialog('Please login to continue');
    }
  }

  // Generate Employee ID
  Future<void> _generateEmployeeId() async {
    setState(() {
      _isLoadingEmployeeId = true;
    });

    try {
      final dio = ref.read(dioProvider);
      final authState = ref.read(authProvider);

      if (authState.accountId == null) {
        throw Exception('Account ID not found');
      }

      final response = await dio.get(
        'employee/emp-seq-number',
        queryParameters: {'voucherType': 'Employee'},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer ${authState.token}',
          },
        ),
      );

      print(
        'API Response: ${response.data}',
      ); // Check if response.data contains employeeNumber
      setState(() {
        _employeeId = response.data['employeeNumber']?.toString() ?? 'EMP001';
        print('Assigned Employee ID: $_employeeId'); // Verify the value is set
      });
    } catch (e) {
      print('Error generating employee ID: $e');
      setState(() {
        _employeeId = 'EMP001';
      });
    } finally {
      setState(() {
        _isLoadingEmployeeId = false;
      });
    }
  }

  Future<void> _loadEmployeeData() async {
    if (widget.employeeId == null) return;

    setState(() {
      _isLoadingEmployeeData = true;
    });

    try {
      final employeeActions = ref.read(employeeActionsProvider);
      final result = await employeeActions.getEmployee(widget.employeeId!);

      if (result.success && result.data != null) {
        final employeeData = result.data!;

        print('Employee data loaded: $employeeData'); // Debug print

        // Clear existing form data
        _formData.clear();

        // Basic info - ensure proper string conversion
        _formData['name'] = employeeData['name']?.toString().trim() ?? '';
        _employeeId = employeeData['empId'] ?? '';
        _formData['gender'] = employeeData['gender']?.toString() ?? '';
        _formData['personalEmail'] =
            employeeData['personalEmail']?.toString().trim() ?? '';
        _formData['primaryPhone'] =
            employeeData['primaryPhone']?.toString().trim() ?? '';

        // Client info
        if (employeeData['client'] != null && employeeData['client'] is Map) {
          _formData['clientId'] = employeeData['client']['_id'];
          _formData['client'] = employeeData['client']['name'];
        }

        // Base location
        if (employeeData['baseLocation'] != null &&
            employeeData['baseLocation'] is Map) {
          _formData['baseLocationId'] = employeeData['baseLocation']['_id'];
          _formData['baseLocation'] = _formatAddressFromObject(
            employeeData['baseLocation'],
          );
        }

        // Dates - handle ISO date strings
        if (employeeData['dob'] != null) {
          try {
            _formData['dob'] = DateTime.parse(employeeData['dob']);
          } catch (e) {
            print('Error parsing dob: $e');
          }
        }

        // Handle salary array - IMPROVED handling for empty/null values
        if (employeeData['salary'] != null && employeeData['salary'] is List) {
          final salaryList = List<Map<String, dynamic>>.from(
            employeeData['salary'],
          );
          if (salaryList.isNotEmpty) {
            final activeSalary = salaryList.firstWhere(
              (sal) => sal['active'] == true,
              orElse: () => salaryList.first,
            );

            // IMPROVED: Handle salary values - check for actual content, not just null
            var grossSalary = activeSalary['grossSalary'];
            var ctc = activeSalary['ctc'];
            var assessmentYear = activeSalary['assessmentYear'];

            // Convert to string and check if it's meaningful data
            _formData['grossSalary'] =
                (grossSalary != null &&
                    grossSalary.toString().trim().isNotEmpty &&
                    grossSalary.toString().trim() != 'null')
                ? grossSalary.toString().trim()
                : '';

            _formData['ctc'] =
                (ctc != null &&
                    ctc.toString().trim().isNotEmpty &&
                    ctc.toString().trim() != 'null')
                ? ctc.toString().trim()
                : '';

            _formData['assessmentYear'] =
                (assessmentYear != null &&
                    assessmentYear.toString().trim().isNotEmpty &&
                    assessmentYear.toString().trim() != 'null')
                ? assessmentYear.toString().trim()
                : '';
          }
        } else {
          // Initialize with empty values if no salary data
          _formData['grossSalary'] = '';
          _formData['ctc'] = '';
          _formData['assessmentYear'] = '';
        }

        if (employeeData['dateOfJoining'] != null) {
          try {
            _formData['dateOfJoining'] = DateTime.parse(
              employeeData['dateOfJoining'],
            );
          } catch (e) {
            print('Error parsing dateOfJoining: $e');
          }
        }

        if (employeeData['dateofResign'] != null) {
          try {
            _formData['dateofResign'] = DateTime.parse(
              employeeData['dateofResign'],
            );
          } catch (e) {
            print('Error parsing dateofResign: $e');
          }
        }

        // Employment details
        _formData['reasonOfResign'] =
            employeeData['reasonOfResign']?.toString().trim() ?? '';

        // Languages
        if (employeeData['languages'] != null &&
            employeeData['languages'] is List) {
          _formData['languages'] = List<String>.from(employeeData['languages']);
        }

        // Address data - map from API format to form format
        _mapAddressDataFromAPI(employeeData);

        // Set formatted address strings for display
        _updateAddressDisplayStrings();

        // Check if addresses are the same
        _checkAndSetSameAddressFlag();

        print('Form data after mapping: $_formData'); // Debug print
        _debugFormFields();

        // IMPORTANT: Update controllers AFTER form data is set
        _updateControllers();

        // Force a rebuild to ensure UI reflects the updated controller values
        setState(() {});
      } else {
        _showErrorDialog(result.error ?? 'Failed to load employee data');
      }
    } catch (e) {
      print('Error loading employee data: $e');
      _showErrorDialog('An error occurred while loading employee data');
    } finally {
      setState(() {
        _isLoadingEmployeeData = false;
      });
    }
  }

  void _debugFormFields() {
    print('=== DEBUG FORM FIELDS ===');
    print('Name: ${_formData['name']}');
    print('Email: ${_formData['personalEmail']}');
    print('Phone: ${_formData['primaryPhone']}');
    print('Gross Salary: ${_formData['grossSalary']}');
    print('CTC: ${_formData['ctc']}');
    print('Assessment: ${_formData['assessmentYear']}');
    print('==========================');
  }

  void _initializeControllers() {
    final fieldsToControl = [
      'name',
      'personalEmail',
      'primaryPhone',
      'grossSalary',
      'ctc',
      'assessmentYear',
      'reasonOfResign',
    ];

    for (String field in fieldsToControl) {
      _controllers[field] = TextEditingController();
    }
  }

  void _updateControllers() {
    // Ensure controllers exist before updating them
    _controllers['name']?.text = _formData['name']?.toString() ?? '';
    _controllers['personalEmail']?.text =
        _formData['personalEmail']?.toString() ?? '';
    _controllers['primaryPhone']?.text =
        _formData['primaryPhone']?.toString() ?? '';
    _controllers['grossSalary']?.text =
        _formData['grossSalary']?.toString() ?? '';
    _controllers['ctc']?.text = _formData['ctc']?.toString() ?? '';
    _controllers['assessmentYear']?.text =
        _formData['assessmentYear']?.toString() ?? '';
    _controllers['reasonOfResign']?.text =
        _formData['reasonOfResign']?.toString() ?? '';

    // Debug: Print controller values to verify they're set correctly
    print('=== CONTROLLER VALUES AFTER UPDATE ===');
    print('Name controller: ${_controllers['name']?.text}');
    print('Email controller: ${_controllers['personalEmail']?.text}');
    print('Phone controller: ${_controllers['primaryPhone']?.text}');
    print('Gross Salary controller: ${_controllers['grossSalary']?.text}');
    print('CTC controller: ${_controllers['ctc']?.text}');
    print('Assessment controller: ${_controllers['assessmentYear']?.text}');
    print('=====================================');
  }

  void _updateAddressDisplayStrings() {
    // Update present address display string
    if (_hasAddressData('presentAddress')) {
      _formData['presentAddress'] = _formatPresentAddress(_formData);
    }

    // Update permanent address display string
    if (_hasAddressData('permanentAddress')) {
      _formData['permanentAddress'] = _formatPermanentAddress(_formData);
    }
  }

  void _checkAndSetSameAddressFlag() {
    // Check if shipping address is same as billing address
    final billingLine1 = _formData['billingAddressLine1'] ?? '';
    final shippingLine1 = _formData['shippingAddressLine1'] ?? '';
    final billingCity = _formData['billingAddressCity'] ?? '';
    final shippingCity = _formData['shippingAddressCity'] ?? '';
    final billingPinCode = _formData['billingAddressPinCode']?.toString() ?? '';
    final shippingPinCode =
        _formData['shippingAddressPinCode']?.toString() ?? '';

    if (billingLine1.isNotEmpty && shippingLine1.isNotEmpty) {
      _isSameAsPresentAddress =
          (billingLine1 == shippingLine1 &&
          billingCity == shippingCity &&
          billingPinCode == shippingPinCode);
    }
  }

  void _mapAddressDataFromAPI(Map<String, dynamic> employeeData) {
    // Handle addresses array from API response
    if (employeeData['addresses'] != null &&
        employeeData['addresses'] is List) {
      final addresses = List<Map<String, dynamic>>.from(
        employeeData['addresses'],
      );

      // Find Present Address (billing)
      final presentAddress = addresses.firstWhere(
        (addr) => addr['type'] == 'Present Address',
        orElse: () => <String, dynamic>{},
      );

      if (presentAddress.isNotEmpty) {
        _formData['billingAddressLine1'] = presentAddress['line1'] ?? '';
        _formData['billingAddressLine2'] = presentAddress['line2'] ?? '';
        _formData['billingAddressCity'] = presentAddress['city'] ?? '';
        _formData['billingAddressPinCode'] =
            presentAddress['code']?.toString() ?? '';

        // Handle state and country objects
        if (presentAddress['state'] != null && presentAddress['state'] is Map) {
          _formData['billingAddressState'] = presentAddress['state']['name'];
          _formData['billingAddressStateId'] = presentAddress['state']['_id'];
        }

        if (presentAddress['country'] != null &&
            presentAddress['country'] is Map) {
          _formData['billingAddressCountry'] =
              presentAddress['country']['name'];
          _formData['billingAddressCountryId'] =
              presentAddress['country']['_id'];
        }
      }

      // Find Permanent Address (shipping)
      final permanentAddress = addresses.firstWhere(
        (addr) => addr['type'] == 'Permanent Address',
        orElse: () => <String, dynamic>{},
      );

      if (permanentAddress.isNotEmpty) {
        _formData['shippingAddressLine1'] = permanentAddress['line1'] ?? '';
        _formData['shippingAddressLine2'] = permanentAddress['line2'] ?? '';
        _formData['shippingAddressCity'] = permanentAddress['city'] ?? '';
        _formData['shippingAddressPinCode'] =
            permanentAddress['code']?.toString() ?? '';

        // Handle state and country objects
        if (permanentAddress['state'] != null &&
            permanentAddress['state'] is Map) {
          _formData['shippingAddressState'] = permanentAddress['state']['name'];
          _formData['shippingAddressStateId'] =
              permanentAddress['state']['_id'];
        }

        if (permanentAddress['country'] != null &&
            permanentAddress['country'] is Map) {
          _formData['shippingAddressCountry'] =
              permanentAddress['country']['name'];
          _formData['shippingAddressCountryId'] =
              permanentAddress['country']['_id'];
        }
      }
    }

    // Handle photo URL if it exists and is a valid string URL
    if (employeeData['photo'] != null &&
        employeeData['photo'] is String &&
        employeeData['photo'].toString().isNotEmpty &&
        (employeeData['photo'].toString().startsWith('http://') ||
            employeeData['photo'].toString().startsWith('https://'))) {
      _formData['photoUrl'] = employeeData['photo'];
    }

    // Remove any invalid photo data that might cause issues
    if (_formData['photo'] != null && _formData['photo'] is! File) {
      _formData.remove('photo');
    }
  }

  String _formatAddressFromObject(Map<String, dynamic> address) {
    final line1 = address['line1'] ?? '';
    final line2 = address['line2'] ?? '';
    final city = address['city'] ?? '';
    final state = address['state'] is Map ? address['state']['name'] ?? '' : '';
    final country = address['country'] is Map
        ? address['country']['name'] ?? ''
        : '';
    final code = address['code']?.toString() ?? '';

    return '$line1, $line2, $city, $state, $country - $code'
        .replaceAll(RegExp(r', ,'), ', ')
        .replaceAll(RegExp(r'^, '), '')
        .replaceAll(RegExp(r', $'), '');
  }

  // Handle form field changes
  void _onFieldChanged(String key, dynamic value) {
    setState(() {
      // For photo field, only allow File objects
      if (key == 'photo' && value != null && value is! File) {
        print(
          'Warning: Photo field only accepts File objects, received: ${value.runtimeType}',
        );
        return;
      }

      _formData[key] = value;
      _validationErrors.remove(key);

      // IMPORTANT: Update the corresponding controller when form data changes
      if (_controllers.containsKey(key) && value is String) {
        _controllers[key]?.text = value;
      }
    });
  }

  // Validate form
  bool _validateForm() {
    _validationErrors.clear();
    print('Current form data: $_formData');
    print('Employee ID: $_employeeId');

    if (_formData['name']?.toString().trim().isEmpty ?? true) {
      _validationErrors['name'] = 'Name is required';
    }

    if (_formData['clientId']?.toString().trim().isEmpty ?? true) {
      _validationErrors['client'] = 'Client is required';
    }

    if (_formData['gender']?.toString().trim().isEmpty ?? true) {
      _validationErrors['gender'] = 'Gender is required';
    }

    if (_formData['dob'] == null) {
      _validationErrors['dob'] = 'Date of Birth is required';
    }

    if (_formData['personalEmail']?.toString().trim().isEmpty ?? true) {
      _validationErrors['personalEmail'] = 'Email is required';
    }

    if (_formData['primaryPhone']?.toString().trim().isEmpty ?? true) {
      _validationErrors['primaryPhone'] = 'Phone is required';
    }

    if (_formData['grossSalary']?.toString().trim().isEmpty ?? true) {
      _validationErrors['grossSalary'] = 'Gross Salary is required';
    }

    if (_formData['ctc']?.toString().trim().isEmpty ?? true) {
      _validationErrors['ctc'] = 'CTC is required';
    }

    if (_formData['assessmentYear']?.toString().trim().isEmpty ?? true) {
      _validationErrors['assessmentYear'] = 'Assessment is required';
    }

    if (_formData['dateOfJoining'] == null) {
      _validationErrors['dateOfJoining'] = 'Joining Date is required';
    }
    // Debug: Print validation errors
    print('Validation errors: $_validationErrors');
    setState(() {});
    return _validationErrors.isEmpty;
  }

  // Submit form
  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ref.read(authProvider);

      if (authState.accountId == null || authState.token == null) {
        throw Exception('Authentication information missing');
      }

      // Prepare form data with all required fields
      final submitData = <String, dynamic>{};

      // Required fields with validation
      final name = _formData['name']?.toString().trim();
      if (name?.isNotEmpty ?? false) {
        submitData['name'] = name;
      }

      if (_employeeId.isNotEmpty) {
        submitData['empId'] = _employeeId;
      }

      final gender = _formData['gender']?.toString();
      if (gender?.isNotEmpty ?? false) {
        submitData['gender'] = gender;
      }

      final phone = _formData['primaryPhone']?.toString().trim();
      if (phone?.isNotEmpty ?? false) {
        submitData['primaryPhone'] = phone;
      }

      submitData['account'] = authState.accountId;

      // Handle photo upload properly
      if (_formData['photo'] != null && _formData['photo'] is File) {
        final file = _formData['photo'] as File;
        final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
        final fileUpload = await MultipartFile.fromFile(
          file.path,
          filename: 'employee_photo.${file.path.split('.').last}',
          contentType: MediaType.parse(mimeType),
        );
        submitData['photo'] = fileUpload;
      }

      // Convert DateTime to string for API
      if (_formData['dob'] != null) {
        submitData['dob'] = _formatDateForApi(_formData['dob']);
      }

      // Client field - must be ObjectId
      final clientId = _formData['clientId']?.toString().trim();
      if (clientId?.isNotEmpty ?? false) {
        submitData['client'] = clientId;
      }

      // Base Location - must be ObjectId if present
      final baseLocationId = _formData['baseLocationId']?.toString().trim();
      if (baseLocationId?.isNotEmpty ?? false) {
        submitData['baseLocation'] = baseLocationId;
      }

      // Personal details
      final email = _formData['personalEmail']?.toString().trim();
      if (email?.isNotEmpty ?? false) {
        submitData['personalEmail'] = email;
      }

      // Salary details
      final grossSalary = _formData['grossSalary']?.toString().trim();
      if (grossSalary?.isNotEmpty ?? false) {
        submitData['grossSalary'] = grossSalary;
      }

      final ctc = _formData['ctc']?.toString().trim();
      if (ctc?.isNotEmpty ?? false) {
        submitData['ctc'] = ctc;
      }

      final assessmentYear = _formData['assessmentYear']?.toString().trim();
      if (assessmentYear?.isNotEmpty ?? false) {
        submitData['assessmentYear'] = assessmentYear;
      }

      // Employment dates
      if (_formData['dateOfJoining'] != null) {
        submitData['dateOfJoining'] = _formatDateForApi(
          _formData['dateOfJoining'],
        );
      }
      if (_formData['dateofResign'] != null) {
        submitData['dateofResign'] = _formatDateForApi(
          _formData['dateofResign'],
        );
      }

      final reasonOfResign = _formData['reasonOfResign']?.toString().trim();
      if (reasonOfResign?.isNotEmpty ?? false) {
        submitData['reasonOfResign'] = reasonOfResign;
      }

      // Languages
      if (_formData['languages'] != null && _formData['languages'] is List) {
        final languages = _formData['languages'] as List;
        if (languages.isNotEmpty) {
          submitData['languages'] = languages;
        }
      }

      // Address handling - ensure we send IDs for country/state
      // Billing Address (Present Address)
      final billingLine1 = _formData['billingAddressLine1']?.toString().trim();
      if (billingLine1?.isNotEmpty ?? false) {
        submitData['billingAddressLine1'] = billingLine1;
      }

      final billingLine2 = _formData['billingAddressLine2']?.toString().trim();
      if (billingLine2?.isNotEmpty ?? false) {
        submitData['billingAddressLine2'] = billingLine2;
      }

      final billingCity = _formData['billingAddressCity']?.toString().trim();
      if (billingCity?.isNotEmpty ?? false) {
        submitData['billingAddressCity'] = billingCity;
      }

      final billingCountryId = _formData['billingAddressCountryId']
          ?.toString()
          .trim();
      if (billingCountryId?.isNotEmpty ?? false) {
        submitData['billingAddressCountry'] = billingCountryId;
      }

      final billingStateId = _formData['billingAddressStateId']
          ?.toString()
          .trim();
      if (billingStateId?.isNotEmpty ?? false) {
        submitData['billingAddressState'] = billingStateId;
      }

      final billingPinCode = _formData['billingAddressPinCode']
          ?.toString()
          .trim();
      if (billingPinCode?.isNotEmpty ?? false) {
        submitData['billingAddressPinCode'] = billingPinCode;
      }

      // Shipping Address (Permanent Address)
      final shippingLine1 = _formData['shippingAddressLine1']
          ?.toString()
          .trim();
      if (shippingLine1?.isNotEmpty ?? false) {
        submitData['shippingAddressLine1'] = shippingLine1;
      }

      final shippingLine2 = _formData['shippingAddressLine2']
          ?.toString()
          .trim();
      if (shippingLine2?.isNotEmpty ?? false) {
        submitData['shippingAddressLine2'] = shippingLine2;
      }

      final shippingCity = _formData['shippingAddressCity']?.toString().trim();
      if (shippingCity?.isNotEmpty ?? false) {
        submitData['shippingAddressCity'] = shippingCity;
      }

      final shippingCountryId = _formData['shippingAddressCountryId']
          ?.toString()
          .trim();
      if (shippingCountryId?.isNotEmpty ?? false) {
        submitData['shippingAddressCountry'] = shippingCountryId;
      }

      final shippingStateId = _formData['shippingAddressStateId']
          ?.toString()
          .trim();
      if (shippingStateId?.isNotEmpty ?? false) {
        submitData['shippingAddressState'] = shippingStateId;
      }

      final shippingPinCode = _formData['shippingAddressPinCode']
          ?.toString()
          .trim();
      if (shippingPinCode?.isNotEmpty ?? false) {
        submitData['shippingAddressPinCode'] = shippingPinCode;
      }

      // Validation check - ensure we have minimum required data
      if (submitData.isEmpty) {
        throw Exception('No data to submit');
      }

      print('Final submit data keys: ${submitData.keys.toList()}');
      print('Submit data length: ${submitData.length}');

      final employeeActions = ref.read(employeeActionsProvider);
      late ApiResponse<Map<String, dynamic>> result;

      if (_isEditMode) {
        result = await employeeActions.updateEmployee(
          widget.employeeId!,
          submitData,
        );
      } else {
        result = await employeeActions.createEmployee(submitData);
      }

      if (result.success) {
        // Refresh employee list
        try {
          ref.read(employeeListProvider.notifier).refresh();
        } catch (e) {
          print('Error refreshing employee list: $e');
        }

        // Simply navigate back - no dialog needed since operation was successful
        Navigator.of(context).pop();
      } else {
        _showErrorDialog(
          result.error ??
              (_isEditMode
                  ? 'Failed to update employee'
                  : 'Failed to create employee'),
        );
      }
    } catch (e) {
      print('Error submitting form: $e');
      _showErrorDialog('An unexpected error occurred: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Success'),
        content: Text('Employee created successfully'),
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

  Future<void> _pickImage() async {
    try {
      showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) => CupertinoActionSheet(
          title: Text('Select Photo'),
          actions: [
            CupertinoActionSheetAction(
              child: Text('Camera'),
              onPressed: () async {
                Navigator.pop(context);
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (image != null) {
                  _onFieldChanged('photo', File(image.path));
                }
              },
            ),
            CupertinoActionSheetAction(
              child: Text('Gallery'),
              onPressed: () async {
                Navigator.pop(context);
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (image != null) {
                  _onFieldChanged('photo', File(image.path));
                }
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state to rebuild when authentication changes
    final authState = ref.watch(authProvider);

    // Show loading if not initialized or loading employee data
    if (!authState.isInitialized || _isLoadingEmployeeData) {
      return CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    // Show error if not authenticated
    if (!authState.isAuthenticated) {
      return CupertinoPageScaffold(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Please login to continue'),
              SizedBox(height: 20),
              CupertinoButton(
                child: Text('Go to Login'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isEditMode ? 'Edit Employee' : 'Create Employee'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: _isLoading
            ? CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                child: Text(_isEditMode ? 'Update' : 'Save'),
                onPressed: _submitForm,
              ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Employee ID Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                color: CupertinoColors.systemGrey6,
                child: Center(
                  child: Text(
                    _isLoadingEmployeeId
                        ? 'Loading...'
                        : 'EMPLOYEE ID: $_employeeId',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.systemGrey,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

              // Photo and Name in one row
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    // Photo on left with camera icon
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: CupertinoColors.systemGrey5,
                              border: Border.all(
                                color: CupertinoColors.systemGrey4,
                                width: 1,
                              ),
                            ),
                            child: _buildPhotoWidget(), // Use the new method
                          ),
                          // Camera icon overlay
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: CupertinoColors.systemBlue,
                                border: Border.all(
                                  color: CupertinoColors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                CupertinoIcons.camera_fill,
                                color: CupertinoColors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 16),

                    // Name field on right
                    Expanded(
                      child: FormFieldWidgets.buildTextField(
                        'name',
                        'Full Name',
                        'text',
                        context,
                        onChanged: _onFieldChanged,
                        formData: _formData,
                        validationErrors: _validationErrors,
                        isRequired: true,
                        compact: true,
                        controller: _controllers['name'],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10),

              // Client Selection
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                child: CupertinoButton(
                  onPressed: _showClientSelector,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  color: (_formData['clientId']?.isNotEmpty ?? false)
                      ? CupertinoColors.systemBlue
                      : CupertinoColors.systemGreen,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        (_formData['clientId']?.isNotEmpty ?? false)
                            ? CupertinoIcons.checkmark_alt
                            : CupertinoIcons.add,
                        color: CupertinoColors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        _formData['client']?.isNotEmpty ?? false
                            ? _formData['client']!
                            : 'Add Client +',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_validationErrors.containsKey('client'))
                Padding(
                  padding: EdgeInsets.only(top: 8, left: 20, right: 20),
                  child: Text(
                    _validationErrors['client']!,
                    style: TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 14,
                    ),
                  ),
                ),
              // Selected Client Base Location Display
              if (_formData['baseLocation']?.isNotEmpty ?? false)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: CupertinoColors.systemGreen.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.location_solid,
                            color: CupertinoColors.systemGreen,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Selected Base Location:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.systemGreen,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formData['baseLocation']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 30),

              // General Details Section
              _buildSectionHeader('GENERAL DETAILS'),

              FormFieldWidgets.buildSelectField(
                'gender',
                'Gender',
                ['Male', 'Female', 'Other'],
                onChanged: _onFieldChanged,
                formData: _formData,
                validationErrors: _validationErrors,
                isRequired: true,
              ),

              FormFieldWidgets.buildDateField(
                'dob',
                'Date of Birth',
                context: context,
                onChanged: _onFieldChanged,
                formData: _formData,
                validationErrors: _validationErrors,
                isRequired: true,
                maximumDate: DateTime.now(),
              ),

              SizedBox(height: 20),

              // Languages Section
              _buildSectionHeader('LANGUAGES'),

              FormFieldWidgets.buildMultiSelectField(
                'languages',
                'Select Languages',
                [
                  'English',
                  'Hindi',
                  'Marathi',
                  'Telugu',
                  'Tamil',
                  'Bengali',
                  'Gujarati',
                  'Kannada',
                  'Malayalam',
                  'Punjabi',
                ],
                onChanged: _onFieldChanged,
                formData: _formData,
                validationErrors: _validationErrors,
              ),

              SizedBox(height: 20),

              // Contact Details Section
              _buildSectionHeader('CONTACT DETAILS'),

              FormFieldWidgets.buildTextField(
                'personalEmail',
                'Email',
                'email',
                context,
                onChanged: _onFieldChanged,
                formData: _formData,
                validationErrors: _validationErrors,
                isRequired: true,
                controller: _controllers['personalEmail'],
              ),

              FormFieldWidgets.buildTextField(
                'primaryPhone',
                'Phone',
                'phone',
                context,
                onChanged: _onFieldChanged,
                formData: _formData,
                validationErrors: _validationErrors,
                isRequired: true,
                controller: _controllers['primaryPhone'],
              ),

              SizedBox(height: 20),

              // Address Section
              _buildSectionHeader('ADDRESS DETAILS'),

              _buildAddressButton(
                'Add Present Address +',
                'presentAddress',
                false,
              ),
              // Display Current Address if added
              if (_hasAddressData('presentAddress'))
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.location,
                            color: CupertinoColors.systemBlue,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Present Address:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.systemBlue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatPresentAddress(_formData),
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),

              // Checkbox for same address
              if (_hasAddressData('presentAddress'))
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleSameAddress,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _isSameAsPresentAddress
                                  ? CupertinoColors.systemBlue
                                  : CupertinoColors.systemGrey3,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            color: _isSameAsPresentAddress
                                ? CupertinoColors.systemBlue
                                : CupertinoColors.systemBackground,
                          ),
                          child: _isSameAsPresentAddress
                              ? Icon(
                                  CupertinoIcons.check_mark,
                                  size: 16,
                                  color: CupertinoColors.white,
                                )
                              : null,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _toggleSameAddress,
                          child: Text(
                            'Permanent address same as Present Address',
                            style: TextStyle(
                              fontSize: 16,
                              color: CupertinoColors.label,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Permanent Address Button - only show if checkbox is not checked
              if (!_isSameAsPresentAddress)
                _buildAddressButton(
                  'Add Permanent Address +',
                  'permanentAddress',
                  true,
                ),

              // Display Permanent Address if added or copied from present
              if (_hasAddressData('permanentAddress') ||
                  _isSameAsPresentAddress)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.location_solid,
                            color: CupertinoColors.systemPurple,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Permanent Address:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.systemPurple,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        _isSameAsPresentAddress
                            ? _formatPresentAddress(_formData)
                            : _formatPermanentAddress(_formData),
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 20),

              // Employment Details Section
              _buildSectionHeader('EMPLOYMENT DETAILS'),

              FormFieldWidgets.buildTextField(
                'grossSalary',
                'Gross Salary',
                'text',
                context,
                onChanged: _onFieldChanged,
                formData: _formData,
                validationErrors: _validationErrors,
                isRequired: true,
                controller: _controllers['grossSalary'],
              ),

              FormFieldWidgets.buildTextField(
                'ctc',
                'CTC',
                'text',
                context,
                onChanged: _onFieldChanged,
                formData: _formData,
                validationErrors: _validationErrors,
                isRequired: true,
                controller: _controllers['ctc'],
              ),

              FormFieldWidgets.buildTextField(
                'assessmentYear',
                'Assessment',
                'text',
                context,
                onChanged: _onFieldChanged,
                formData: _formData,
                validationErrors: _validationErrors,
                isRequired: true,
                controller: _controllers['assessmentYear'],
              ),

              FormFieldWidgets.buildDateField(
                'dateOfJoining',
                'Joining Date',
                context: context,
                onChanged: _onFieldChanged,
                formData: _formData,
                validationErrors: _validationErrors,
                isRequired: true,
              ),

              FormFieldWidgets.buildDateField(
                'dateofResign',
                'Resign Date',
                context: context,
                onChanged: _onFieldChanged,
                formData: _formData,
                validationErrors: _validationErrors,
                minimumDate: _formData['dateOfJoining'],
              ),

              FormFieldWidgets.buildTextAreaField(
                'reasonOfResign',
                'Enter Reason of Resign',
                onChanged: _onFieldChanged,
                formData: _formData,
                validationErrors: _validationErrors,
              ),

              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.systemGrey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildAddressButton(String text, String key, bool isRequired) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: CupertinoButton(
        onPressed: () => _showAddressForm(key),
        padding: EdgeInsets.zero,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _validationErrors.containsKey(key)
                  ? CupertinoColors.systemRed
                  : CupertinoColors.systemGrey4, // Changed to lighter grey
              width: 1, // Reduced border width
            ),
            borderRadius: BorderRadius.circular(8),
            color: CupertinoColors.systemBackground,
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.location,
                color: CupertinoColors.systemGrey,
                size: 18, // Smaller icon
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _hasAddressData(key) ? 'Address Added' : text,
                  style: TextStyle(
                    color: _hasAddressData(key)
                        ? CupertinoColors.systemGreen
                        : CupertinoColors.systemGrey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    color: CupertinoColors.systemRed,
                    fontSize: 16,
                  ),
                ),
              Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoColors.systemGrey,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoWidget() {
    // Check if there's a new photo file
    if (_formData['photo'] != null && _formData['photo'] is File) {
      return ClipOval(
        child: Image.file(
          _formData['photo'] as File,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialsAvatar();
          },
        ),
      );
    }

    // Check if there's an existing photo URL - Fixed to handle invalid URLs
    if (_formData['photoUrl'] != null && _formData['photoUrl'] is String) {
      final photoUrl = _formData['photoUrl'] as String;
      if (photoUrl.isNotEmpty &&
          (photoUrl.startsWith('http://') || photoUrl.startsWith('https://'))) {
        return ClipOval(
          child: Image.network(
            photoUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildInitialsAvatar();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(child: CupertinoActivityIndicator());
            },
          ),
        );
      }
    }

    // Default to initials
    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
    return Center(
      child: Text(
        (_formData['name']?.isNotEmpty ?? false)
            ? _formData['name']![0].toUpperCase()
            : 'UU',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: CupertinoColors.systemGrey,
        ),
      ),
    );
  }

  // this helper method to check if address data exists:
  bool _hasAddressData(String addressType) {
    if (addressType == 'presentAddress') {
      return _formData['billingAddressLine1']?.isNotEmpty ?? false;
    } else if (addressType == 'permanentAddress') {
      return _formData['shippingAddressLine1']?.isNotEmpty ?? false;
    }
    return false;
  }

  void _showClientSelector() {
    ClientSelectionService.showClientSelector(
      context: context,
      ref: ref,
      onClientSelected: (clientData) {
        setState(() {
          _validationErrors.remove('client');
          _formData['client'] = clientData['clientName'];
          _formData['clientId'] =
              clientData['clientId'] ?? clientData['client'];
          _formData['baseLocation'] = clientData['baseLocation'];
          _formData['baseLocationId'] = clientData['baseLocationId'];

          print('Client selected: ${clientData['clientName']}');
          print('Client ID: ${_formData['clientId']}');
          print('Base Location ID: ${_formData['baseLocationId']}');
        });
      },
    );
  }

  //  the _showAddressForm method with this implementation:
  void _showAddressForm(String addressType) {
    if (addressType == 'presentAddress') {
      // Use billing address for present address
      AddressBottomSheetService.showBillingAddressBottomSheet(
        context: context,
        ref: ref,
        initialData: _formData,
        onAddressSelected: (addressData) {
          setState(() {
            _formData.addAll(addressData);
            _formData['presentAddress'] = _formatPresentAddress(addressData);
          });
        },
      );
    } else if (addressType == 'permanentAddress') {
      // Use shipping address for permanent address
      AddressBottomSheetService.showShippingAddressBottomSheet(
        context: context,
        ref: ref,
        initialData: _formData,
        onAddressSelected: (addressData) {
          setState(() {
            _formData.addAll(addressData);
            _formData['permanentAddress'] = _formatPermanentAddress(
              addressData,
            );
          });
        },
      );
    }
  }

  // these helper methods to format addresses:
  String _formatPresentAddress(Map<String, dynamic> addressData) {
    final line1 = addressData['billingAddressLine1'] ?? '';
    final line2 = addressData['billingAddressLine2'] ?? '';
    final city = addressData['billingAddressCity'] ?? '';
    final state = addressData['billingAddressState'] ?? '';
    final country = addressData['billingAddressCountry'] ?? '';
    final pincode = addressData['billingAddressPinCode']?.toString() ?? '';

    return '$line1, $line2, $city, $state, $country - $pincode'
        .replaceAll(RegExp(r', ,'), ', ')
        .replaceAll(RegExp(r'^, '), '')
        .replaceAll(RegExp(r', $'), '');
  }

  String _formatPermanentAddress(Map<String, dynamic> addressData) {
    final line1 = addressData['shippingAddressLine1'] ?? '';
    final line2 = addressData['shippingAddressLine2'] ?? '';
    final city = addressData['shippingAddressCity'] ?? '';
    final state = addressData['shippingAddressState'] ?? '';
    final country = addressData['shippingAddressCountry'] ?? '';
    final pincode = addressData['shippingAddressPinCode']?.toString() ?? '';

    return '$line1, $line2, $city, $state, $country - $pincode'
        .replaceAll(RegExp(r', ,'), ', ')
        .replaceAll(RegExp(r'^, '), '')
        .replaceAll(RegExp(r', $'), '');
  }

  void _toggleSameAddress() {
    setState(() {
      _isSameAsPresentAddress = !_isSameAsPresentAddress;

      if (_isSameAsPresentAddress) {
        // Copy present address data to permanent address fields
        _formData['shippingAddressLine1'] = _formData['billingAddressLine1'];
        _formData['shippingAddressLine2'] = _formData['billingAddressLine2'];
        _formData['shippingAddressCity'] = _formData['billingAddressCity'];
        _formData['shippingAddressCountry'] =
            _formData['billingAddressCountry'];
        _formData['shippingAddressCountryId'] =
            _formData['billingAddressCountryId'];
        _formData['shippingAddressState'] = _formData['billingAddressState'];
        _formData['shippingAddressStateId'] =
            _formData['billingAddressStateId'];
        _formData['shippingAddressPinCode'] =
            _formData['billingAddressPinCode'];
        _formData['permanentAddress'] = _formData['presentAddress'];
      } else {
        // Clear permanent address fields
        _formData.remove('shippingAddressLine1');
        _formData.remove('shippingAddressLine2');
        _formData.remove('shippingAddressCity');
        _formData.remove('shippingAddressCountry');
        _formData.remove('shippingAddressCountryId');
        _formData.remove('shippingAddressState');
        _formData.remove('shippingAddressStateId');
        _formData.remove('shippingAddressPinCode');
        _formData.remove('permanentAddress');
      }
    });
  }
}
