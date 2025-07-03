// update_legal_info_form.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test_22/apis/providers/business_commonprofile_provider.dart';
import 'package:flutter_test_22/theme_provider.dart';
import 'package:flutter_test_22/components/form_fields.dart';

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
    'Other'
  ];

  final List<String> countryOptions = [
    'India',
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Singapore',
    'United Arab Emirates',
    'Other'
  ];

  final List<String> stateOptions = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttarakhand',
    'Uttar Pradesh',
    'West Bengal',
    'Delhi',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry'
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
      formData = {
        'companyType': profile['companyType'] ?? '',
        'countryOfRegistration': profile['countryOfRegistration']?['name'] ?? '',
        'legalName': profile['legalName'] ?? '',
        'registrationNo': profile['registrationNo'] ?? '',
        'smeRegistrationFlag': profile['smeRegistrationFlag'] ?? false,
        'stateOfRegistration': profile['stateOfRegistration'] ?? '',
        'taxIdentificationNumber1': profile['taxIdentificationNumber1'] ?? '',
        'taxIdentificationNumber2': profile['taxIdentificationNumber2'] ?? '',
      };
    }
  }

  void _onFieldChanged(String key, dynamic value) {
    setState(() {
      formData[key] = value;
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
      validationErrors['countryOfRegistration'] = 'Country of registration is required';
    }

    if (formData['stateOfRegistration']?.isEmpty ?? true) {
      validationErrors['stateOfRegistration'] = 'State of registration is required';
    }

    // Optional but format-specific validations
    if (formData['registrationNo']?.isNotEmpty == true &&
        formData['registrationNo'].length < 3) {
      validationErrors['registrationNo'] = 'Registration number must be at least 3 characters';
    }

    if (formData['taxIdentificationNumber1']?.isNotEmpty == true &&
        !_isValidTaxId(formData['taxIdentificationNumber1'])) {
      validationErrors['taxIdentificationNumber1'] = 'Please enter a valid tax identification number';
    }

    if (formData['taxIdentificationNumber2']?.isNotEmpty == true &&
        !_isValidGSTNumber(formData['taxIdentificationNumber2'])) {
      validationErrors['taxIdentificationNumber2'] = 'Please enter a valid GST number';
    }

    setState(() {});
    return validationErrors.isEmpty;
  }

  bool _isValidTaxId(String taxId) {
    // Basic PAN validation pattern
    return RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(taxId);
  }

  bool _isValidGSTNumber(String gstNumber) {
    // Basic GST validation pattern
    return RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$').hasMatch(gstNumber);
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final businessProfileHelper = ref.read(businessProfileHelperProvider);
      
      // For countryOfRegistration, we need to pass the ID, not the name
      // For now, we'll use the country name and let the backend handle it
      // In a real app, you'd want to maintain a mapping of country names to IDs
      
      final success = await businessProfileHelper.updateLegalInfo(
        companyType: formData['companyType'],
        countryOfRegistration: formData['countryOfRegistration'],
        legalName: formData['legalName'],
        registrationNo: formData['registrationNo'],
        smeRegistrationFlag: formData['smeRegistrationFlag'],
        stateOfRegistration: formData['stateOfRegistration'],
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
          child: Icon(
            CupertinoIcons.back,
            color: colors.primary,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: isSubmitting || businessProfile.isUpdating ? null : _submitForm,
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
                    Container(
                      height: 0.5,
                      color: colors.border,
                    ),
                    FormFieldWidgets.buildSelectField(
                      'companyType',
                      'Company Type',
                      companyTypeOptions,
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                      isRequired: true,
                    ),
                    Container(
                      height: 0.5,
                      color: colors.border,
                    ),
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
                    FormFieldWidgets.buildSelectField(
                      'countryOfRegistration',
                      'Country of Registration',
                      countryOptions,
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                      isRequired: true,
                    ),
                    Container(
                      height: 0.5,
                      color: colors.border,
                    ),
                    FormFieldWidgets.buildSelectField(
                      'stateOfRegistration',
                      'State of Registration',
                      stateOptions,
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                      isRequired: true,
                    ),
                    Container(
                      height: 0.5,
                      color: colors.border,
                    ),
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
                    Container(
                      height: 0.5,
                      color: colors.border,
                    ),
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