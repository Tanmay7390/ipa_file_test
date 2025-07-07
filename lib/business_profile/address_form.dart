// address_form_page.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Wareozo/apis/providers/address_provider.dart';
import 'package:Wareozo/apis/core/dio_provider.dart';
import 'package:Wareozo/apis/core/api_urls.dart';
import 'package:Wareozo/theme_provider.dart';
import 'package:Wareozo/components/form_fields.dart';

class AddressForm extends ConsumerStatefulWidget {
  final String? addressId; // null for Add, has value for Update

  const AddressForm({Key? key, this.addressId}) : super(key: key);

  @override
  ConsumerState<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends ConsumerState<AddressForm> {
  final Map<String, dynamic> _formData = {};
  final Map<String, String> _validationErrors = {};
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isLoadingCountries = false;
  bool _isLoadingStates = false;

  // Dynamic options from API
  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _states = [];
  List<String> _countryOptions = [];
  List<String> _stateOptions = [];

  // Address type options
  final List<String> _addressTypeOptions = [
    'Registered',
    'Office',
    'Shipping',
    'Billing',
    'Warehouse',
    'Branch',
    'Head Office',
  ];

  bool get _isEditMode => widget.addressId != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    // Clean up form field controllers
    FormFieldWidgets.disposeAllControllers();
    super.dispose();
  }

  Future<void> _initializeForm() async {
    // First load countries
    await _loadCountries();

    if (_isEditMode) {
      setState(() => _isLoading = true);

      try {
        final address = await ref
            .read(addressProvider.notifier)
            .getAddressById(widget.addressId!);

        if (address != null) {
          setState(() {
            _formData.addAll({
              'type': address['type'] ?? '',
              'line1': address['line1'] ?? '',
              'line2': address['line2'] ?? '',
              'line3': address['line3'] ?? '',
              'city': address['city'] ?? '',
              'state': address['state']?['name'] ?? '',
              'country': address['country']?['name'] ?? '',
              'code': address['code'] ?? '',
              'phone1': address['phone1'] ?? '',
              'phone2': address['phone2'] ?? '',
            });
            _isInitialized = true;
          });

          // Load states for the selected country
          if (address['country']?['_id'] != null) {
            await _loadStates(address['country']['_id']);
          }
        }
      } catch (e) {
        _showErrorDialog('Failed to load address: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      // Initialize with default values for Add mode
      setState(() {
        _formData.addAll({
          'type': 'Registered', // Default type
          'line1': '',
          'line2': '',
          'line3': '',
          'city': '',
          'state': '',
          'country': 'India', // Default country
          'code': '',
          'phone1': '',
          'phone2': '',
        });
        _isInitialized = true;
      });

      // Load states for India by default
      final indiaCountry = _countries.firstWhere(
        (country) => country['name'] == 'India',
        orElse: () => {},
      );
      if (indiaCountry['_id'] != null) {
        await _loadStates(indiaCountry['_id']);
      }
    }
  }

  Future<void> _loadCountries() async {
    setState(() => _isLoadingCountries = true);

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(ApiUrls.countries);

      if (response.statusCode == 200) {
        final List<dynamic> countriesData = response.data['countries'] ?? [];

        setState(() {
          _countries = countriesData.cast<Map<String, dynamic>>();
          _countryOptions = _countries
              .map((country) => country['name'] as String)
              .toList();
        });
      }
    } catch (e) {
      print('Error loading countries: $e');
      _showErrorDialog('Failed to load countries');
    } finally {
      setState(() => _isLoadingCountries = false);
    }
  }

  Future<void> _loadStates(String countryId) async {
    setState(() => _isLoadingStates = true);

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('${ApiUrls.states}?country_id=$countryId');

      if (response.statusCode == 200) {
        final List<dynamic> statesData = response.data['states'] ?? [];

        setState(() {
          _states = statesData.cast<Map<String, dynamic>>();
          _stateOptions = _states
              .map((state) => state['name'] as String)
              .toList();
        });
      }
    } catch (e) {
      print('Error loading states: $e');
      _showErrorDialog('Failed to load states');
    } finally {
      setState(() => _isLoadingStates = false);
    }
  }

  void _onFieldChanged(String key, dynamic value) {
    setState(() {
      _formData[key] = value;
      // Clear validation error when user starts typing
      if (_validationErrors.containsKey(key)) {
        _validationErrors.remove(key);
      }
    });

    // Load states when country changes
    if (key == 'country' && value != null) {
      final selectedCountry = _countries.firstWhere(
        (country) => country['name'] == value,
        orElse: () => {},
      );
      if (selectedCountry['_id'] != null) {
        _loadStates(selectedCountry['_id']);
        // Clear selected state when country changes
        setState(() {
          _formData['state'] = '';
        });
      }
    }
  }

  bool _validateForm() {
    _validationErrors.clear();

    // Required field validations
    if (_formData['type']?.toString().trim().isEmpty ?? true) {
      _validationErrors['type'] = 'Address type is required';
    }

    if (_formData['line1']?.toString().trim().isEmpty ?? true) {
      _validationErrors['line1'] = 'Address line 1 is required';
    }

    if (_formData['city']?.toString().trim().isEmpty ?? true) {
      _validationErrors['city'] = 'City is required';
    }

    if (_formData['state']?.toString().trim().isEmpty ?? true) {
      _validationErrors['state'] = 'State is required';
    }

    if (_formData['country']?.toString().trim().isEmpty ?? true) {
      _validationErrors['country'] = 'Country is required';
    }

    if (_formData['code']?.toString().trim().isEmpty ?? true) {
      _validationErrors['code'] = 'Postal code is required';
    }

    setState(() {});
    return _validationErrors.isEmpty;
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) {
      _showErrorDialog('Please fix the errors in the form');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Find the selected country and state IDs
      final selectedCountry = _countries.firstWhere(
        (country) => country['name'] == _formData['country'],
        orElse: () => {},
      );

      final selectedState = _states.firstWhere(
        (state) => state['name'] == _formData['state'],
        orElse: () => {},
      );

      // Prepare data for submission
      final submitData = {
        'type': _formData['type'],
        'line1': _formData['line1'],
        'line2': _formData['line2'] ?? '',
        'line3': _formData['line3'] ?? '',
        'city': _formData['city'],
        'state': selectedState['_id'],
        'country': selectedCountry['_id'],
        'code': _formData['code'],
        'phone1': _formData['phone1'] ?? '',
        'phone2': _formData['phone2'] ?? '',
        'isActive': true,
      };

      bool success;
      if (_isEditMode) {
        success = await ref
            .read(addressProvider.notifier)
            .updateAddress(widget.addressId!, submitData);
      } else {
        success = await ref
            .read(addressProvider.notifier)
            .createAddress(submitData);
      }

      if (success) {
        _showSuccessDialog(
          _isEditMode
              ? 'Address updated successfully'
              : 'Address created successfully',
        );
      } else {
        final error = ref.read(addressProvider).error;
        _showErrorDialog(error ?? 'Failed to save address');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Success'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorProvider);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    if ((_isLoading && !_isInitialized) || _isLoadingCountries) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Center(child: CupertinoActivityIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(colors, screenSize),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _buildForm(colors, isTablet),
              ),
            ),
            _buildBottomButtons(colors, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(WareozeColorScheme colors, Size screenSize) {
    return Container(
      height: kToolbarHeight,
      color: colors.surface,
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.only(left: 16),
            child: Icon(CupertinoIcons.back, color: colors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              _isEditMode ? 'Update Address' : 'Add Address',
              style: TextStyle(
                fontSize: screenSize.width * 0.045,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(WareozeColorScheme colors, bool isTablet) {
    return Container(
      margin: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.border,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Address Type
          FormFieldWidgets.buildSelectField(
            'type',
            'Address Type',
            _addressTypeOptions,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
            isRequired: true,
          ),

          _buildDivider(colors),

          // Address Line 1
          FormFieldWidgets.buildTextField(
            'line1',
            'Address Line 1',
            'text',
            context,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
            isRequired: true,
          ),

          _buildDivider(colors),

          // Address Line 2
          FormFieldWidgets.buildTextField(
            'line2',
            'Address Line 2',
            'text',
            context,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
          ),

          _buildDivider(colors),

          // Address Line 3
          FormFieldWidgets.buildTextField(
            'line3',
            'Address Line 3',
            'text',
            context,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
          ),

          _buildDivider(colors),

          // City
          FormFieldWidgets.buildTextField(
            'city',
            'City',
            'text',
            context,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
            isRequired: true,
          ),

          _buildDivider(colors),

          // Country
          FormFieldWidgets.buildSelectField(
            'country',
            'Country',
            _countryOptions,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
            isRequired: true,
          ),

          _buildDivider(colors),

          // State
          _isLoadingStates
              ? Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          'State',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'SF Pro Display',
                            letterSpacing: 0.25,
                            color: CupertinoColors.black,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Center(child: CupertinoActivityIndicator()),
                      ),
                    ],
                  ),
                )
              : FormFieldWidgets.buildSelectField(
                  'state',
                  'State',
                  _stateOptions,
                  onChanged: _onFieldChanged,
                  formData: _formData,
                  validationErrors: _validationErrors,
                  isRequired: true,
                ),

          _buildDivider(colors),

          // Postal Code
          FormFieldWidgets.buildTextField(
            'code',
            'Postal Code',
            'text',
            context,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
            isRequired: true,
          ),

          _buildDivider(colors),

          // Phone 1
          FormFieldWidgets.buildTextField(
            'phone1',
            'Phone 1',
            'phone',
            context,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
          ),

          _buildDivider(colors),

          // Phone 2
          FormFieldWidgets.buildTextField(
            'phone2',
            'Phone 2',
            'phone',
            context,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
          ),

          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDivider(WareozeColorScheme colors) {
    return Container(
      height: 0.5,
      color: colors.border,
      margin: EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildBottomButtons(WareozeColorScheme colors, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              onPressed: () => Navigator.pop(context),
              color: colors.border.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: CupertinoButton(
              onPressed: _isLoading ? null : _submitForm,
              color: colors.primary,
              borderRadius: BorderRadius.circular(8),
              child: _isLoading
                  ? CupertinoActivityIndicator()
                  : Text(
                      _isEditMode ? 'Update' : 'Create',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
