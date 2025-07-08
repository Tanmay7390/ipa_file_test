// update_company_profile_form.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Wareozo/apis/providers/business_commonprofile_provider.dart';
import 'package:Wareozo/theme_provider.dart';
import 'package:Wareozo/components/form_fields.dart';
import 'dart:io';

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

  final List<String> businessTypeOptions = ['Service', 'Product', 'Consulting'];

  final List<String> industryVerticalOptions = [
    'Aerospace (aircraft manufacturing)',
    'Agriculture',
    'Chemical (manufacturing)',
    'Computers',
    'Construction',
    'Defense',
    'Energy (production, distribution)',
    'Entertainment',
    'Financial',
    'Food',
    'Health Care',
    'Hospitality',
    'Information',
    'Manufacturing',
    'Mass Media',
    'Telecommunications',
    'Transport',
    'Real Estate',
    'Water',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    final businessProfile = ref.read(businessProfileProvider);
    final profile = businessProfile.profile;

    // Helper function to safely get string values
    String _safeString(dynamic value) {
      if (value == null ||
          value == 'undefined' ||
          value.toString().trim().isEmpty) {
        return '';
      }
      return value.toString();
    }

    // Helper function to safely get list values
    List<String> _safeList(dynamic value) {
      if (value == null || value == 'undefined') {
        return [];
      }
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    // Helper function to safely get boolean values
    bool _safeBool(dynamic value) {
      if (value == null || value == 'undefined') {
        return false;
      }
      if (value is bool) {
        return value;
      }
      return false;
    }

    if (profile != null) {
      formData = {
        'name': _safeString(profile['name']),
        'legalName': _safeString(profile['legalName']),
        'displayName': _safeString(profile['displayName']),
        'companyDesc': _safeString(profile['companyDesc']),
        'industryVertical': _safeString(profile['industryVertical']),
        'businessType': _safeList(profile['businessType']),
        'website': _safeString(profile['website']),
        'contactName': _safeString(profile['contactName']),
        'email': _safeString(profile['email']),
        'whatsAppNumber': _safeString(profile['whatsAppNumber']),
        'taxIdentificationNumber1': _safeString(
          profile['taxIdentificationNumber1'],
        ),
        'taxIdentificationNumber2': _safeString(
          profile['taxIdentificationNumber2'],
        ),
        'showSignatureOnInvoice': _safeBool(profile['showSignatureOnInvoice']),
        'showLogoOnInvoice': _safeBool(profile['showLogoOnInvoice']),
        // Add current logo and signature URLs for display
        'currentLogoUrl': profile['logo'],
        'currentSignatureUrl': profile['signature'],
        // File objects for new uploads (will be null initially)
        'logoFile': null,
        'signatureFile': null,
      };
    }
  }

  // Helper function to clean string values - more robust
  String? cleanString(String? value) {
    if (value == null ||
        value == 'undefined' ||
        value == 'null' ||
        value.trim().isEmpty) {
      return null;
    }
    return value.trim();
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

    // Optional field validations
    if (formData['website']?.isNotEmpty == true &&
        !_isValidWebsite(formData['website'])) {
      validationErrors['website'] = 'Please enter a valid website URL';
    }

    setState(() {});
    return validationErrors.isEmpty;
  }

  bool _isValidWebsite(String website) {
    return RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    ).hasMatch(website);
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final businessProfileHelper = ref.read(businessProfileHelperProvider);

      // Debug: Print form data before submission
      print('Form data being submitted:');
      formData.forEach((key, value) {
        if (key != 'logoFile' &&
            key != 'signatureFile' &&
            key != 'currentLogoUrl' &&
            key != 'currentSignatureUrl') {
          print('  $key: $value');
        }
      });
      print('Logo file: ${formData['logoFile']?.path ?? 'No file'}');
      print('Signature file: ${formData['signatureFile']?.path ?? 'No file'}');

      final success = await businessProfileHelper.updateCompanyProfileWithFiles(
        name: formData['name']?.toString(),
        legalName: formData['legalName']?.toString(),
        displayName: formData['displayName']?.toString(),
        companyDesc: formData['companyDesc']?.toString(),
        industryVertical: formData['industryVertical']?.toString(),
        businessType: formData['businessType'] != null
            ? List<String>.from(formData['businessType'])
            : null,
        website: formData['website']?.toString(),
        contactName: formData['contactName']?.toString(),
        email: formData['email']?.toString(),
        whatsAppNumber: formData['whatsAppNumber']?.toString(),
        taxIdentificationNumber1: formData['taxIdentificationNumber1']
            ?.toString(),
        taxIdentificationNumber2: formData['taxIdentificationNumber2']
            ?.toString(),
        showSignatureOnInvoice: formData['showSignatureOnInvoice'] as bool?,
        showLogoOnInvoice: formData['showLogoOnInvoice'] as bool?,
        logoFile: formData['logoFile'] as File?,
        signatureFile: formData['signatureFile'] as File?,
      );

      if (success) {
        _showSuccessDialog();
      } else {
        final error = businessProfileHelper.error;
        _showErrorDialog(error ?? 'Failed to update company profile');
      }
    } catch (e) {
      print('Exception in _submitForm: $e');
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

  String _getLogoInitials() {
    final name = formData['name']?.toString() ?? '';
    if (name.isEmpty) return 'L';
    return name.substring(0, 1).toUpperCase();
  }

  String _getSignatureInitials() {
    final contactName = formData['contactName']?.toString() ?? '';
    if (contactName.isEmpty) return 'S';
    return contactName.substring(0, 1).toUpperCase();
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
              // Logo and Signature Upload Section
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
                        'BRANDING',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                          letterSpacing: 0.5,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ),
                    // Logo Upload Field
                    _buildImageUploadField(
                      'logoFile',
                      'Company Logo',
                      formData['currentLogoUrl'],
                      _getLogoInitials(),
                      colors,
                    ),
                    Container(height: 0.5, color: colors.border),
                    // Signature Upload Field
                    _buildImageUploadField(
                      'signatureFile',
                      'Digital Signature',
                      formData['currentSignatureUrl'],
                      _getSignatureInitials(),
                      colors,
                    ),
                  ],
                ),
              ),

              // Basic Information Section
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
                      'Tax ID #1(PAN for India)',
                      'text',
                      context,
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                    ),
                    Container(height: 0.5, color: colors.border),
                    FormFieldWidgets.buildTextField(
                      'taxIdentificationNumber2',
                      'Tax ID #2(GSTIN for India)',
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

  Widget _buildImageUploadField(
    String key,
    String label,
    String? currentUrl,
    String initials,
    WareozeColorScheme colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'SF Pro Display',
                letterSpacing: 0.25,
                color: colors.textPrimary,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildImageDisplay(key, currentUrl, initials, colors),
          ),
        ],
      ),
    );
  }

  Widget _buildImageDisplay(
    String key,
    String? currentUrl,
    String initials,
    WareozeColorScheme colors,
  ) {
    File? selectedFile = formData[key];

    return Row(
      children: [
        // Current image display
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.primary.withOpacity(0.1),
            border: Border.all(color: colors.border, width: 1),
            image: selectedFile != null
                ? DecorationImage(
                    image: FileImage(selectedFile),
                    fit: BoxFit.cover,
                  )
                : currentUrl != null
                ? DecorationImage(
                    image: NetworkImage(currentUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: selectedFile == null && currentUrl == null
              ? Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: colors.primary,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.25,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
        ),
        SizedBox(width: 16),
        // Upload buttons
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CupertinoButton(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: colors.primary,
                child: Text(
                  selectedFile != null || currentUrl != null
                      ? 'Change'
                      : 'Upload',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.25,
                    fontSize: 14,
                  ),
                ),
                onPressed: () => _showImagePickerOptions(key),
              ),
              if (selectedFile != null || currentUrl != null)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: CupertinoButton(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'Remove',
                      style: TextStyle(
                        color: CupertinoColors.systemRed,
                        fontFamily: 'SF Pro Display',
                        letterSpacing: 0.25,
                        fontSize: 14,
                      ),
                    ),
                    onPressed: () => _onFieldChanged(key, null),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showImagePickerOptions(String key) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Select Image'),
        actions: [
          CupertinoActionSheetAction(
            child: Text('Camera'),
            onPressed: () {
              Navigator.pop(context);
              FormFieldWidgets.buildAvatarField(
                key,
                '',
                onChanged: _onFieldChanged,
                formData: formData,
                validationErrors: validationErrors,
                context: context,
              );
            },
          ),
          CupertinoActionSheetAction(
            child: Text('Gallery'),
            onPressed: () {
              Navigator.pop(context);
              // You can implement gallery picker here
              // For now, using the avatar field method
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text('Cancel'),
          onPressed: () => Navigator.pop(context),
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
