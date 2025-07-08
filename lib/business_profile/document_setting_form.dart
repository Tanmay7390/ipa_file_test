// document_setting_form_page.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Wareozo/apis/providers/documentsetting_provider.dart';
import 'package:Wareozo/theme_provider.dart';
import 'package:Wareozo/components/form_fields.dart';

class DocumentSettingForm extends ConsumerStatefulWidget {
  final String? documentSettingId; // null for Add, has value for Update
  final String? documentTypeName; // for display purposes

  const DocumentSettingForm({
    Key? key,
    this.documentSettingId,
    this.documentTypeName,
  }) : super(key: key);

  @override
  ConsumerState<DocumentSettingForm> createState() =>
      _DocumentSettingFormState();
}

class _DocumentSettingFormState extends ConsumerState<DocumentSettingForm> {
  final Map<String, dynamic> _formData = {};
  final Map<String, String> _validationErrors = {};
  bool _isLoading = false;
  bool _isInitialized = false;

  // Document type options (you may want to fetch these from an API)
  final List<String> _documentTypeOptions = [
    'Quotation',
    'Invoice',
    'Credit Note',
    'Purchase Order',
    'Proforma Invoice',
    'Employee',
    'Debit Note',
    'Delivery Note',
    'Purchase Invoice',
    'Sales PO',
  ];

  final List<String> _statusOptions = ['Active', 'Inactive'];

  bool get _isEditMode => widget.documentSettingId != null;

  @override
  void initState() {
    super.initState();
    // Fetch templates and document types
    Future.microtask(() {
      ref.read(documentSettingsProvider.notifier).fetchInvoiceTemplates();
      ref.read(documentSettingsProvider.notifier).fetchDocumentTypes();
    });
    _initializeForm();
  }

  @override
  void dispose() {
    // Clean up form field controllers
    FormFieldWidgets.disposeAllControllers();
    super.dispose();
  }

  Future<void> _initializeForm() async {
    if (_isEditMode) {
      setState(() => _isLoading = true);

      try {
        final documentSetting = await Future.microtask(() async {
          return await ref
              .read(documentSettingsProvider.notifier)
              .getDocumentSettingsById(widget.documentSettingId!);
        });

        if (documentSetting != null) {
          setState(() {
            _formData.addAll({
              'docNumberPrefix': documentSetting['docNumberPrefix'] ?? '',
              'docSequenceNumber': documentSetting['docSequenceNumber'] ?? '',
              'docNumberLength':
                  documentSetting['docNumberLength']?.toString() ?? '',
              'termsAndConditions': documentSetting['termsAndConditions'] ?? '',
              'paymentDetails': documentSetting['paymentDetails'] ?? '',
              'paymentTermDays':
                  documentSetting['paymentTermDays']?.toString() ?? '0',
              'defaultPdfTemplate':
                  documentSetting['defaultPdfTemplate']?['template'] ?? '',
              'notes': documentSetting['notes'] ?? '',
              'footer1': documentSetting['footer1'] ?? '',
              'footer2': documentSetting['footer2'] ?? '',
              'smsAndWhatsAppText': documentSetting['smsAndWhatsAppText'] ?? '',
              'emailSubject': documentSetting['emailSubject'] ?? '', // Add this
              'emailText': documentSetting['emailText'] ?? '',
              'status': documentSetting['status'] ?? 'Active',
              'documentType': documentSetting['documentType']?['name'] ?? '',
            });
            _isInitialized = true;
          });
        }
      } catch (e) {
        _showErrorDialog('Failed to load document setting: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      // Initialize with default values for Add mode
      setState(() {
        _formData.addAll({
          'docNumberPrefix': '',
          'docSequenceNumber': '0000000001',
          'docNumberLength': '10',
          'termsAndConditions': '',
          'paymentDetails': 'Net-30',
          'paymentTermDays': '0',
          'defaultPdfTemplate': '',
          'notes': '',
          'footer1': 'Powered by Wareozo',
          'footer2': 'Powered by Wareozo',
          'smsAndWhatsAppText': '',
          'emailSubject': '', // Add this
          'emailText': '',
          'status': 'Active',
          'documentType': widget.documentTypeName ?? '',
        });
        _isInitialized = true;
      });
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
  }

  bool _validateForm() {
    _validationErrors.clear();

    // Required field validations
    if (_formData['docNumberPrefix']?.toString().trim().isEmpty ?? true) {
      _validationErrors['docNumberPrefix'] = 'Document prefix is required';
    }

    if (_formData['docSequenceNumber']?.toString().trim().isEmpty ?? true) {
      _validationErrors['docSequenceNumber'] = 'Sequence number is required';
    }

    if (_formData['docNumberLength']?.toString().trim().isEmpty ?? true) {
      _validationErrors['docNumberLength'] = 'Number length is required';
    } else {
      final length = int.tryParse(_formData['docNumberLength'].toString());
      if (length == null || length <= 0) {
        _validationErrors['docNumberLength'] =
            'Please enter a valid number length';
      }
    }

    if (_formData['documentType']?.toString().trim().isEmpty ?? true) {
      _validationErrors['documentType'] = 'Document type is required';
    }

    if (_formData['status']?.toString().trim().isEmpty ?? true) {
      _validationErrors['status'] = 'Status is required';
    }

    // Validate payment term days if provided
    if (_formData['paymentTermDays']?.toString().isNotEmpty == true) {
      final days = int.tryParse(_formData['paymentTermDays'].toString());
      if (days == null || days < 0) {
        _validationErrors['paymentTermDays'] =
            'Please enter valid payment term days';
      }
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
      // Get the template ID from template name
      final templates = ref.read(invoiceTemplatesProvider);
      String? templateId;
      if (_formData['defaultPdfTemplate']?.isNotEmpty == true) {
        final selectedTemplate = templates.firstWhere(
          (template) => template['template'] == _formData['defaultPdfTemplate'],
          orElse: () => {},
        );
        templateId = selectedTemplate['_id'];
      }

      // Get the document type ID from document type name
      final documentTypes = ref.read(documentTypesProvider);
      String? documentTypeId;
      if (_formData['documentType']?.isNotEmpty == true) {
        final selectedDocType = documentTypes.firstWhere(
          (docType) => docType['name'] == _formData['documentType'],
          orElse: () => {},
        );
        documentTypeId = selectedDocType['_id'];
      }

      // Prepare data for submission
      final submitData = {
        'docNumberPrefix': _formData['docNumberPrefix'],
        'docSequenceNumber': _formData['docSequenceNumber'],
        'docNumberLength':
            int.tryParse(_formData['docNumberLength'].toString()) ?? 10,
        'termsAndConditions': _formData['termsAndConditions'] ?? '',
        'paymentDetails': _formData['paymentDetails'] ?? '',
        'paymentTermDays':
            int.tryParse(_formData['paymentTermDays'].toString()) ?? 0,
        'defaultPdfTemplate': templateId, // Send template ID
        'notes': _formData['notes'] ?? '',
        'footer1': _formData['footer1'] ?? '',
        'footer2': _formData['footer2'] ?? '',
        'smsAndWhatsAppText': _formData['smsAndWhatsAppText'] ?? '',
        'emailSubject': _formData['emailSubject'] ?? '', // Add this
        'emailText': _formData['emailText'] ?? '',
        'status': _formData['status'] ?? 'Active',
        'documentType': documentTypeId, // Send document type ID
      };

      bool success;
      if (_isEditMode) {
        success = await ref
            .read(documentSettingsProvider.notifier)
            .updateDocumentSettings(widget.documentSettingId!, submitData);
      } else {
        success = await ref
            .read(documentSettingsProvider.notifier)
            .createDocumentSettings(submitData);
      }

      if (success) {
        _showSuccessDialog(
          _isEditMode
              ? 'Document setting updated successfully'
              : 'Document setting created successfully',
        );
      } else {
        final error = ref.read(documentSettingsProvider).error;
        _showErrorDialog(error ?? 'Failed to save document setting');
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

    if (_isLoading && !_isInitialized) {
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
              _isEditMode ? 'Update Document Setting' : 'Add Document Setting',
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
          // Document Type
          FormFieldWidgets.buildSelectField(
            'documentType',
            'Document Type',
            _documentTypeOptions,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
            isRequired: true,
          ),

          _buildDivider(colors),

          // Document Prefix
          FormFieldWidgets.buildTextField(
            'docNumberPrefix',
            'Document Prefix',
            'text',
            context,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
            isRequired: true,
          ),

          _buildDivider(colors),

          // Sequence Number
          FormFieldWidgets.buildTextField(
            'docSequenceNumber',
            'Sequence Number',
            'text',
            context,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
            isRequired: true,
          ),

          _buildDivider(colors),

          // Number Length
          FormFieldWidgets.buildTextField(
            'docNumberLength',
            'Number Length',
            'number',
            context,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
            isRequired: true,
          ),

          _buildDivider(colors),

          // Default PDF Template
          Consumer(
            builder: (context, ref, child) {
              final templates = ref.watch(invoiceTemplatesProvider);
              final templateOptions = templates
                  .map((template) => template['template']?.toString() ?? '')
                  .where((name) => name.isNotEmpty)
                  .toList();

              return FormFieldWidgets.buildSelectField(
                'defaultPdfTemplate',
                'Default PDF Template',
                templateOptions,
                onChanged: _onFieldChanged,
                formData: _formData,
                validationErrors: _validationErrors,
              );
            },
          ),

          _buildDivider(colors),

          // Footer 1
          FormFieldWidgets.buildTextField(
            'footer1',
            'Footer 1',
            'text',
            context,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
          ),

          _buildDivider(colors),

          // Footer 2
          FormFieldWidgets.buildTextField(
            'footer2',
            'Footer 2',
            'text',
            context,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
          ),

          _buildDivider(colors),

          // Payment Details
          FormFieldWidgets.buildTextField(
            'paymentDetails',
            'Payment Term',
            'text',
            context,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
          ),

          _buildDivider(colors),

          // Payment Term Days
          FormFieldWidgets.buildTextField(
            'paymentTermDays',
            'Payment Term/Expiry Days',
            'number',
            context,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
          ),

          _buildDivider(colors),

          // SMS & WhatsApp Text
          FormFieldWidgets.buildTextAreaField(
            'smsAndWhatsAppText',
            'SMS & WhatsApp Text',
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
            maxLines: 3,
            minLines: 2,
          ),

          _buildDivider(colors),

          // Email Subject (add this before Email Text)
          FormFieldWidgets.buildTextField(
            'emailSubject',
            'Email Subject',
            'text',
            context,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
          ),

          _buildDivider(colors),

          // Email Text
          FormFieldWidgets.buildTextAreaField(
            'emailText',
            'Email Text',
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
            maxLines: 3,
            minLines: 2,
          ),

          _buildDivider(colors),

          // Terms & Conditions
          FormFieldWidgets.buildTextAreaField(
            'termsAndConditions',
            'Terms & Conditions',
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
            maxLines: 4,
            minLines: 3,
          ),

          _buildDivider(colors),

          // Notes/Disclaimer
          FormFieldWidgets.buildTextAreaField(
            'notes',
            'Notes/Disclaimer',
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
            maxLines: 3,
            minLines: 2,
          ),

          _buildDivider(colors),

          // Status
          FormFieldWidgets.buildSelectField(
            'status',
            'Status',
            _statusOptions,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
            isRequired: true,
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
