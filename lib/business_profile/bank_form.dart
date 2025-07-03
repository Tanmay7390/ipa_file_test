// bank_form_page.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test_22/apis/providers/bankaccount_provider.dart';
import 'package:flutter_test_22/theme_provider.dart';
import 'package:flutter_test_22/components/form_fields.dart';

class BankForm extends ConsumerStatefulWidget {
  final String? bankId; // null for Add, has value for Update
  
  const BankForm({
    Key? key,
    this.bankId,
  }) : super(key: key);

  @override
  ConsumerState<BankForm> createState() => _BankFormState();
}

class _BankFormState extends ConsumerState<BankForm> {
  final Map<String, dynamic> _formData = {};
  final Map<String, String> _validationErrors = {};
  bool _isLoading = false;
  bool _isInitialized = false;

  // Country and Currency options (you may want to fetch these from an API)
  final List<String> _countryOptions = [
    'India',
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Germany',
    'France',
    'Japan',
    'Singapore',
    'UAE'
  ];

  final List<String> _currencyOptions = [
    'INR - Indian Rupee',
    'USD - US Dollar',
    'GBP - British Pound',
    'CAD - Canadian Dollar',
    'AUD - Australian Dollar',
    'EUR - Euro',
    'JPY - Japanese Yen',
    'SGD - Singapore Dollar',
    'AED - UAE Dirham'
  ];

  bool get _isEditMode => widget.bankId != null;

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
    if (_isEditMode) {
      setState(() => _isLoading = true);
      
      try {
        final bank = await ref
            .read(bankAccountProvider.notifier)
            .getBankById(widget.bankId!);
            
        if (bank != null) {
          setState(() {
            _formData.addAll({
              'bankName': bank['bankName'] ?? '',
              'branchName': bank['branchName'] ?? '',
              'IFSC': bank['IFSC'] ?? '',
              'SWIFT': bank['SWIFT'] ?? '',
              'MICR': bank['MICR'] ?? '',
              'IBAN': bank['IBAN'] ?? '',
              'accountNumber': bank['accountNumber'] ?? '',
              'accountName': bank['accountName'] ?? '',
              'country': bank['country']?['name'] ?? '',
              'currency': bank['currency']?['name'] != null 
                  ? '${bank['currency']['code']} - ${bank['currency']['name']}'
                  : '',
            });
            _isInitialized = true;
          });
        }
      } catch (e) {
        _showErrorDialog('Failed to load bank account: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      // Initialize with default values for Add mode
      setState(() {
        _formData.addAll({
          'bankName': '',
          'branchName': '',
          'IFSC': '',
          'SWIFT': '',
          'MICR': '',
          'IBAN': '',
          'accountNumber': '',
          'accountName': '',
          'country': 'India', // Default country
          'currency': 'INR - Indian Rupee', // Default currency
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
    if (_formData['bankName']?.toString().trim().isEmpty ?? true) {
      _validationErrors['bankName'] = 'Bank name is required';
    }

    if (_formData['branchName']?.toString().trim().isEmpty ?? true) {
      _validationErrors['branchName'] = 'Branch name is required';
    }

    if (_formData['IFSC']?.toString().trim().isEmpty ?? true) {
      _validationErrors['IFSC'] = 'IFSC code is required';
    }

    if (_formData['accountNumber']?.toString().trim().isEmpty ?? true) {
      _validationErrors['accountNumber'] = 'Account number is required';
    }

    if (_formData['accountName']?.toString().trim().isEmpty ?? true) {
      _validationErrors['accountName'] = 'Account name is required';
    }

    if (_formData['country']?.toString().trim().isEmpty ?? true) {
      _validationErrors['country'] = 'Country is required';
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
      // Prepare data for submission
      final submitData = {
        'bankName': _formData['bankName'],
        'branchName': _formData['branchName'],
        'IFSC': _formData['IFSC'],
        'SWIFT': _formData['SWIFT'] ?? '',
        'MICR': _formData['MICR'] ?? '',
        'IBAN': _formData['IBAN'] ?? '',
        'accountNumber': _formData['accountNumber'],
        'accountName': _formData['accountName'],
        'country': _formData['country'],
        'currency': _formData['currency'],
        'isActive': true,
        'status': 'Active',
      };

      bool success;
      if (_isEditMode) {
        success = await ref
            .read(bankAccountProvider.notifier)
            .updateBankAccount(widget.bankId!, submitData);
      } else {
        success = await ref
            .read(bankAccountProvider.notifier)
            .createBankAccount(submitData);
      }

      if (success) {
        _showSuccessDialog(_isEditMode 
            ? 'Bank account updated successfully' 
            : 'Bank account created successfully');
      } else {
        final error = ref.read(bankAccountProvider).error;
        _showErrorDialog(error ?? 'Failed to save bank account');
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
        body: Center(
          child: CupertinoActivityIndicator(),
        ),
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
              _isEditMode ? 'Update Bank Account' : 'Add Bank Account',
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
          // Bank Name
          FormFieldWidgets.buildTextField(
            'bankName',
            'Bank Name',
            'text',
            context,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
            isRequired: true,
          ),

          _buildDivider(colors),

          // Branch Name  
          FormFieldWidgets.buildTextField(
            'branchName',
            'Branch Name',
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

          // Currency
          FormFieldWidgets.buildSelectField(
            'currency',
            'Currency',
            _currencyOptions,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
            isRequired: false,
          ),

          _buildDivider(colors),

          // IFSC Code
          FormFieldWidgets.buildTextField(
            'IFSC',
            'IFSC Code',
            'text',
            context,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
            isRequired: true,
          ),

          _buildDivider(colors),

          // SWIFT Code
          FormFieldWidgets.buildTextField(
            'SWIFT',
            'SWIFT Code',
            'text',
            context,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
          ),

          _buildDivider(colors),

          // MICR Code
          FormFieldWidgets.buildTextField(
            'MICR',
            'MICR Code',
            'text',
            context,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
          ),

          _buildDivider(colors),

          // IBAN
          FormFieldWidgets.buildTextField(
            'IBAN',
            'IBAN',
            'text',
            context,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
          ),

          _buildDivider(colors),

          // Account Number
          FormFieldWidgets.buildTextField(
            'accountNumber',
            'Account Number',
            'text',
            context,
            onChanged: _onFieldChanged,
            formData: _formData,
            validationErrors: _validationErrors,
            isRequired: true,
          ),

          _buildDivider(colors),

          // Account Name
          FormFieldWidgets.buildTextField(
            'accountName',
            'Account Name',
            'text',
            context,
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