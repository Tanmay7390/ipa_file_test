// update_legal_info_form.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Wareozo/apis/providers/business_commonprofile_provider.dart';
import 'package:Wareozo/apis/providers/countries_states_currency_provider.dart';
import 'package:Wareozo/theme_provider.dart';
import 'package:Wareozo/components/form_fields.dart';

class UpdateLegalInfoForm extends ConsumerStatefulWidget {
  const UpdateLegalInfoForm({Key? key}) : super(key: key);

  @override
  ConsumerState<UpdateLegalInfoForm> createState() =>
      _UpdateLegalInfoFormState();
}

class _UpdateLegalInfoFormState extends ConsumerState<UpdateLegalInfoForm> {
  Map<String, dynamic> formData = {};
  Map<String, String> validationErrors = {};
  bool isSubmitting = false;

  // Store the selected country and state IDs
  String? selectedCountryId;
  String? selectedStateId;

  final List<String> companyTypeOptions = [
    'Private Limited Company',
    'Public Limited Company',
    'Partnership',
    'Limited Liability Partnership (LLP)',
    'Sole Proprietorship',
    'One Person Company (OPC)',
    'Non-Governmental Organization (NGO)',
    'Trust',
    'Society',
    'Cooperative Society',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    final businessProfile = ref.read(businessProfileProvider);
    final profile = businessProfile.profile;

    if (profile != null) {
      // Set the country ID and name
      if (profile['countryOfRegistration'] != null) {
        selectedCountryId = profile['countryOfRegistration']['_id'];
      }

      // For state, the API returns state as just an ID, we need to find the name
      if (profile['stateOfRegistration'] != null &&
          profile['stateOfRegistration'].isNotEmpty) {
        selectedStateId = profile['stateOfRegistration']; // Store the ID
        // Find the state name after states are loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _findStateNameFromId(profile['stateOfRegistration']);
        });
      }

      formData = {
        'companyType': profile['companyType'] ?? '',
        'countryOfRegistration':
            profile['countryOfRegistration']?['name'] ?? '',
        'legalName': profile['legalName'] ?? '',
        'registrationNo': profile['registrationNo'] ?? '',
        'smeRegistrationFlag': profile['smeRegistrationFlag'] ?? false,
        'stateOfRegistration': '', // Will be set by _findStateNameFromId
        'taxIdentificationNumber1': profile['taxIdentificationNumber1'] ?? '',
        'taxIdentificationNumber2': profile['taxIdentificationNumber2'] ?? '',
      };
    }
  }

  void _findStateNameFromId(String stateId) {
    final statesAsync = ref.read(statesDropdownProvider);
    statesAsync.whenData((states) {
      final matchingState = states.firstWhere(
        (state) => state['id'] == stateId,
        orElse: () => <String, String>{},
      );
      if (matchingState.isNotEmpty) {
        setState(() {
          formData['stateOfRegistration'] = matchingState['name'] ?? '';
        });
      }
    });
  }

  void _onFieldChanged(String key, dynamic value) {
    setState(() {
      formData[key] = value;

      // Handle country selection - find the country ID
      if (key == 'countryOfRegistration') {
        final countriesAsync = ref.read(countriesDropdownProvider);
        countriesAsync.whenData((countries) {
          final selectedCountry = countries.firstWhere(
            (country) => country['name'] == value,
            orElse: () => <String, String>{},
          );
          if (selectedCountry.isNotEmpty) {
            selectedCountryId = selectedCountry['id'];
            print(
              'Selected country: ${selectedCountry['name']} with ID: ${selectedCountry['id']}',
            );
          } else {
            print('Country not found: $value');
            selectedCountryId = null;
          }
        });
      }

      // Handle state selection - find the state ID
      if (key == 'stateOfRegistration') {
        final statesAsync = ref.read(statesDropdownProvider);
        statesAsync.whenData((states) {
          final selectedState = states.firstWhere(
            (state) => state['name'] == value,
            orElse: () => <String, String>{},
          );
          if (selectedState.isNotEmpty) {
            selectedStateId = selectedState['id'];
            print(
              'Selected state: ${selectedState['name']} with ID: ${selectedState['id']}',
            );
          } else {
            print('State not found: $value');
            selectedStateId = null;
          }
        });
      }

      // Clear validation error for this field when user starts typing
      if (validationErrors.containsKey(key)) {
        validationErrors.remove(key);
      }
    });
  }

  bool _validateForm() {
    validationErrors.clear();

    // Required field validations
    if (formData['legalName']?.isEmpty ?? true) {
      validationErrors['legalName'] = 'Legal name is required';
    }

    if (formData['companyType']?.isEmpty ?? true) {
      validationErrors['companyType'] = 'Company type is required';
    }

    if (formData['countryOfRegistration']?.isEmpty ?? true) {
      validationErrors['countryOfRegistration'] =
          'Country of registration is required';
    } else if (selectedCountryId == null) {
      validationErrors['countryOfRegistration'] =
          'Please select a valid country';
    }

    if (formData['stateOfRegistration']?.isEmpty ?? true) {
      validationErrors['stateOfRegistration'] =
          'State of registration is required';
    } else if (selectedStateId == null) {
      validationErrors['stateOfRegistration'] = 'Please select a valid state';
    }

    // Optional field validations
    if (formData['registrationNo']?.isNotEmpty == true &&
        formData['registrationNo'].length < 3) {
      validationErrors['registrationNo'] =
          'Registration number must be at least 3 characters';
    }

    setState(() {});
    return validationErrors.isEmpty;
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final businessProfileHelper = ref.read(businessProfileHelperProvider);

      // Debug logging
      print('=== Submitting Legal Info ===');
      print('Company Type: ${formData['companyType']}');
      print('Country Name: ${formData['countryOfRegistration']}');
      print('Country ID: $selectedCountryId');
      print('State Name: ${formData['stateOfRegistration']}');
      print('State ID: $selectedStateId');
      print('Legal Name: ${formData['legalName']}');
      print('Registration No: ${formData['registrationNo']}');
      print('SME Flag: ${formData['smeRegistrationFlag']}');
      print('PAN: ${formData['taxIdentificationNumber1']}');
      print('GST: ${formData['taxIdentificationNumber2']}');

      // Prepare the data with correct IDs for country and state
      final success = await businessProfileHelper.updateLegalInfo(
        companyType: formData['companyType'],
        countryOfRegistration: selectedCountryId, // Send ID instead of name
        legalName: formData['legalName'],
        registrationNo: formData['registrationNo'],
        smeRegistrationFlag: formData['smeRegistrationFlag'],
        stateOfRegistration: selectedStateId, // Send ID instead of name
        taxIdentificationNumber1: formData['taxIdentificationNumber1'],
        taxIdentificationNumber2: formData['taxIdentificationNumber2'],
      );

      if (success) {
        _showSuccessDialog();
      } else {
        final error = businessProfileHelper.error;
        _showErrorDialog(error ?? 'Failed to update legal information');
      }
    } catch (e) {
      _showErrorDialog('An unexpected error occurred: $e');
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: const Text('Legal information updated successfully!'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryDropdown() {
    final countriesAsync = ref.watch(countriesDropdownProvider);

    return countriesAsync.when(
      data: (countries) {
        final countryNames = countries
            .map((country) => country['name']!)
            .toList();
        return FormFieldWidgets.buildSelectField(
          'countryOfRegistration',
          'Country of Registration',
          countryNames,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
          isRequired: true,
        );
      },
      loading: () => Container(
        height: 60,
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (error, stack) => Container(
        height: 60,
        child: Center(
          child: Text(
            'Error loading countries',
            style: TextStyle(color: CupertinoColors.destructiveRed),
          ),
        ),
      ),
    );
  }

  Widget _buildStateDropdown() {
    final statesAsync = ref.watch(statesDropdownProvider);

    return statesAsync.when(
      data: (states) {
        final stateNames = states.map((state) => state['name']!).toList();
        return FormFieldWidgets.buildSelectField(
          'stateOfRegistration',
          'State of Registration',
          stateNames,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
          isRequired: true,
        );
      },
      loading: () => Container(
        height: 60,
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (error, stack) => Container(
        height: 60,
        child: Center(
          child: Text(
            'Error loading states',
            style: TextStyle(color: CupertinoColors.destructiveRed),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorProvider);
    final businessProfile = ref.watch(businessProfileProvider);

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surface,
        middle: Text(
          'Update Legal Information',
          style: TextStyle(
            color: colors.textPrimary,
            fontFamily: 'SF Pro Display',
            letterSpacing: 0.25,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(CupertinoIcons.back, color: colors.primary),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: isSubmitting || businessProfile.isUpdating
              ? null
              : _submitForm,
          child: isSubmitting || businessProfile.isUpdating
              ? CupertinoActivityIndicator()
              : Text(
                  'Save',
                  style: TextStyle(
                    color: colors.primary,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Legal Entity Information Section
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colors.border.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'LEGAL ENTITY INFORMATION',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                          letterSpacing: 0.5,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ),
                    FormFieldWidgets.buildTextField(
                      'legalName',
                      'Legal Name',
                      'text',
                      context,
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                      isRequired: true,
                    ),
                    Container(height: 0.5, color: colors.border),
                    FormFieldWidgets.buildSelectField(
                      'companyType',
                      'Company Type',
                      companyTypeOptions,
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                      isRequired: true,
                    ),
                    Container(height: 0.5, color: colors.border),
                    FormFieldWidgets.buildTextField(
                      'registrationNo',
                      'Registration Number',
                      'text',
                      context,
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                    ),
                  ],
                ),
              ),

              // Registration Details Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colors.border.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'REGISTRATION DETAILS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                          letterSpacing: 0.5,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ),
                    _buildCountryDropdown(),
                    Container(height: 0.5, color: colors.border),
                    _buildStateDropdown(),
                    Container(height: 0.5, color: colors.border),
                    FormFieldWidgets.buildSwitchField(
                      'smeRegistrationFlag',
                      'SME Registration',
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                    ),
                  ],
                ),
              ),

              // Tax Information Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colors.border.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'TAX INFORMATION',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                          letterSpacing: 0.5,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ),
                    FormFieldWidgets.buildTextField(
                      'taxIdentificationNumber1',
                      'PAN Number',
                      'text',
                      context,
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                    ),
                    Container(height: 0.5, color: colors.border),
                    FormFieldWidgets.buildTextField(
                      'taxIdentificationNumber2',
                      'GST Number',
                      'text',
                      context,
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                    ),
                  ],
                ),
              ),

              // Information Note
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      CupertinoIcons.info_circle,
                      color: colors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Important Note',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                              fontFamily: 'SF Pro Display',
                              letterSpacing: 0.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please ensure all legal information is accurate as it will be used for official documents and compliance purposes.',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.textSecondary,
                              fontFamily: 'SF Pro Display',
                              letterSpacing: 0.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100), // Extra space for better scrolling
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    FormFieldWidgets.disposeAllControllers();
    super.dispose();
  }
}
