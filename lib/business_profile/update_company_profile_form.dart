// update_company_profile_form.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Wareozo/apis/providers/business_commonprofile_provider.dart';
import 'package:Wareozo/theme_provider.dart';
import 'package:Wareozo/components/form_fields.dart';

class UpdateCompanyProfileForm extends ConsumerStatefulWidget {
  const UpdateCompanyProfileForm({Key? key}) : super(key: key);

  @override
  ConsumerState<UpdateCompanyProfileForm> createState() =>
      _UpdateCompanyProfileFormState();
}

class _UpdateCompanyProfileFormState
    extends ConsumerState<UpdateCompanyProfileForm> {
  Map<String, dynamic> formData = {};
  Map<String, String> validationErrors = {};
  bool isSubmitting = false;

  final List<String> businessTypeOptions = [
    'Service',
    'Manufacturing',
    'Trading',
    'Consulting',
    'Technology',
    'Healthcare',
    'Education',
    'Finance',
    'Retail',
    'Other',
  ];

  final List<String> industryVerticalOptions = [
    'Technology',
    'Healthcare',
    'Finance',
    'Education',
    'Manufacturing',
    'Retail',
    'Consulting',
    'Real Estate',
    'Transportation',
    'Energy',
    'Agriculture',
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
      formData = {
        'name': profile['name'] ?? '',
        'legalName': profile['legalName'] ?? '',
        'displayName': profile['displayName'] ?? '',
        'companyDesc': profile['companyDesc'] ?? '',
        'industryVertical': profile['industryVertical'] ?? '',
        'businessType': List<String>.from(profile['businessType'] ?? []),
        'website': profile['website'] ?? '',
        'contactName': profile['contactName'] ?? '',
        'email': profile['email'] ?? '',
        'whatsAppNumber': profile['whatsAppNumber'] ?? '',
        'taxIdentificationNumber1': profile['taxIdentificationNumber1'] ?? '',
        'taxIdentificationNumber2': profile['taxIdentificationNumber2'] ?? '',
        'showSignatureOnInvoice': profile['showSignatureOnInvoice'] ?? false,
        'showLogoOnInvoice': profile['showLogoOnInvoice'] ?? false,
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
    if (formData['name']?.isEmpty ?? true) {
      validationErrors['name'] = 'Company name is required';
    }

    if (formData['legalName']?.isEmpty ?? true) {
      validationErrors['legalName'] = 'Legal name is required';
    }

    if (formData['displayName']?.isEmpty ?? true) {
      validationErrors['displayName'] = 'Display name is required';
    }

    if (formData['contactName']?.isEmpty ?? true) {
      validationErrors['contactName'] = 'Contact name is required';
    }

    if (formData['email']?.isEmpty ?? true) {
      validationErrors['email'] = 'Email is required';
    } else if (!_isValidEmail(formData['email'])) {
      validationErrors['email'] = 'Please enter a valid email address';
    }

    // Optional field validations
    if (formData['website']?.isNotEmpty == true &&
        !_isValidWebsite(formData['website'])) {
      validationErrors['website'] = 'Please enter a valid website URL';
    }

    if (formData['whatsAppNumber']?.isNotEmpty == true &&
        !_isValidPhoneNumber(formData['whatsAppNumber'])) {
      validationErrors['whatsAppNumber'] =
          'Please enter a valid WhatsApp number';
    }

    setState(() {});
    return validationErrors.isEmpty;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidWebsite(String website) {
    return RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    ).hasMatch(website);
  }

  bool _isValidPhoneNumber(String phone) {
    return RegExp(
      r'^\d{10,15}$',
    ).hasMatch(phone.replaceAll(RegExp(r'[^\d]'), ''));
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final businessProfileHelper = ref.read(businessProfileHelperProvider);

      final success = await businessProfileHelper.updateCompanyProfile(
        name: formData['name'],
        legalName: formData['legalName'],
        displayName: formData['displayName'],
        companyDesc: formData['companyDesc'],
        industryVertical: formData['industryVertical'],
        businessType: formData['businessType'],
        website: formData['website'],
        contactName: formData['contactName'],
        email: formData['email'],
        whatsAppNumber: formData['whatsAppNumber'],
        taxIdentificationNumber1: formData['taxIdentificationNumber1'],
        taxIdentificationNumber2: formData['taxIdentificationNumber2'],
        showSignatureOnInvoice: formData['showSignatureOnInvoice'],
        showLogoOnInvoice: formData['showLogoOnInvoice'],
      );

      if (success) {
        _showSuccessDialog();
      } else {
        final error = businessProfileHelper.error;
        _showErrorDialog(error ?? 'Failed to update company profile');
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
        content: const Text('Company profile updated successfully!'),
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
          'Update Company Profile',
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
              // Basic Information Section
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
                        'BASIC INFORMATION',
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
                      'name',
                      'Company Name',
                      'text',
                      context,
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                      isRequired: true,
                    ),
                    Container(height: 0.5, color: colors.border),
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
                    FormFieldWidgets.buildTextField(
                      'displayName',
                      'Display Name',
                      'text',
                      context,
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                      isRequired: true,
                    ),
                    Container(height: 0.5, color: colors.border),
                    FormFieldWidgets.buildTextAreaField(
                      'companyDesc',
                      'Company Description',
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                      maxLines: 4,
                      minLines: 3,
                    ),
                  ],
                ),
              ),

              // Business Details Section
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
                        'BUSINESS DETAILS',
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
                      'industryVertical',
                      'Industry Vertical',
                      industryVerticalOptions,
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                    ),
                    Container(height: 0.5, color: colors.border),
                    FormFieldWidgets.buildMultiSelectField(
                      'businessType',
                      'Business Type',
                      businessTypeOptions,
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                      isRequired: true,
                    ),
                    Container(height: 0.5, color: colors.border),
                    FormFieldWidgets.buildTextField(
                      'website',
                      'Website',
                      'text',
                      context,
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                    ),
                  ],
                ),
              ),

              // Contact Information Section
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
                        'CONTACT INFORMATION',
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
                      'contactName',
                      'Contact Name',
                      'text',
                      context,
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                      isRequired: true,
                    ),
                    Container(height: 0.5, color: colors.border),
                    FormFieldWidgets.buildTextField(
                      'email',
                      'Email',
                      'email',
                      context,
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                      isRequired: true,
                    ),
                    Container(height: 0.5, color: colors.border),
                    FormFieldWidgets.buildTextField(
                      'whatsAppNumber',
                      'WhatsApp Number',
                      'phone',
                      context,
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
                      'Tax ID Number 1',
                      'text',
                      context,
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                    ),
                    Container(height: 0.5, color: colors.border),
                    FormFieldWidgets.buildTextField(
                      'taxIdentificationNumber2',
                      'Tax ID Number 2',
                      'text',
                      context,
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                    ),
                  ],
                ),
              ),

              // Invoice Settings Section
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
                        'INVOICE SETTINGS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                          letterSpacing: 0.5,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ),
                    FormFieldWidgets.buildSwitchField(
                      'showLogoOnInvoice',
                      'Show Logo on Invoice',
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                    ),
                    Container(height: 0.5, color: colors.border),
                    FormFieldWidgets.buildSwitchField(
                      'showSignatureOnInvoice',
                      'Show Signature on Invoice',
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
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
