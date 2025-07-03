import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../apis/providers/customer_provider.dart';
import '../../apis/providers/supplier_provider.dart';
import '../apis/providers/countries_states_currency_provider.dart';
import '../../theme_provider.dart';
import '../components/form_fields.dart';

// Customer/Supplier form sections enum
enum CustomerSupplierFormSection {
  basic,
  contact,
  business,
  addresses,
  payment,
  attachments,
}

// Extension to get section display names
extension CustomerSupplierFormSectionExtension on CustomerSupplierFormSection {
  String get displayName {
    switch (this) {
      case CustomerSupplierFormSection.basic:
        return 'Basic Information';
      case CustomerSupplierFormSection.contact:
        return 'Contact Information';
      case CustomerSupplierFormSection.business:
        return 'Business Information';
      case CustomerSupplierFormSection.addresses:
        return 'Address Information';
      case CustomerSupplierFormSection.payment:
        return 'Payment Information';
      case CustomerSupplierFormSection.attachments:
        return 'Attachments';
    }
  }

  String get name {
    switch (this) {
      case CustomerSupplierFormSection.basic:
        return 'basic';
      case CustomerSupplierFormSection.contact:
        return 'contact';
      case CustomerSupplierFormSection.business:
        return 'business';
      case CustomerSupplierFormSection.addresses:
        return 'addresses';
      case CustomerSupplierFormSection.payment:
        return 'payment';
      case CustomerSupplierFormSection.attachments:
        return 'attachments';
    }
  }

  IconData get icon {
    switch (this) {
      case CustomerSupplierFormSection.basic:
        return CupertinoIcons.person;
      case CustomerSupplierFormSection.contact:
        return CupertinoIcons.phone;
      case CustomerSupplierFormSection.business:
        return CupertinoIcons.briefcase;
      case CustomerSupplierFormSection.addresses:
        return CupertinoIcons.location;
      case CustomerSupplierFormSection.payment:
        return CupertinoIcons.creditcard;
      case CustomerSupplierFormSection.attachments:
        return CupertinoIcons.doc;
    }
  }
}

class CustomerSupplierSectionedFormPage extends ConsumerStatefulWidget {
  final String entityId; // customer or supplier ID
  final String entityType; // 'customer' or 'supplier'
  final CustomerSupplierFormSection initialSection;

  const CustomerSupplierSectionedFormPage({
    super.key,
    required this.entityId,
    required this.entityType,
    this.initialSection = CustomerSupplierFormSection.basic,
  });

  @override
  ConsumerState<CustomerSupplierSectionedFormPage> createState() =>
      _CustomerSupplierSectionedFormPageState();
}

class _CustomerSupplierSectionedFormPageState
    extends ConsumerState<CustomerSupplierSectionedFormPage> {
  CustomerSupplierFormSection currentSection =
      CustomerSupplierFormSection.basic;
  Map<String, dynamic> formData = {};
  Map<String, String> validationErrors = {};
  bool isLoading = false;
  bool isInitialized = false;

  // Section-specific data lists
  List<Map<String, dynamic>> bankAccounts = [];
  List<Map<String, dynamic>> addresses = [];
  List<File> attachments = [];

  // Store original entity data to preserve other sections
  Map<String, dynamic> originalEntityData = {};

  @override
  void initState() {
    super.initState();
    currentSection = widget.initialSection;
    _initializeForm();
  }

  @override
  void dispose() {
    FormFieldWidgets.disposeAllControllers();
    super.dispose();
  }

  Future<void> _initializeForm() async {
    await _loadEntityData();
    setState(() {
      isInitialized = true;
    });
  }

  Future<void> _loadEntityData() async {
    try {
      setState(() {
        isLoading = true;
      });

      Map<String, dynamic>? entityData;

      if (widget.entityType == 'customer') {
        final response = await ref
            .read(customerActionsProvider)
            .getCustomer(widget.entityId);
        if (response.success && response.data != null) {
          entityData = response.data;
        }
      } else {
        final response = await ref
            .read(supplierProfileProvider.notifier)
            .getSupplierProfile(widget.entityId);
        if (response.success && response.data != null) {
          entityData = response.data;
        }
      }

      if (entityData != null) {
        // Store original data to preserve other sections
        originalEntityData = Map<String, dynamic>.from(entityData);

        // Map entity data to form data
        formData = {
          'name': entityData['name'] ?? '',
          'legalName': entityData['legalName'] ?? '',
          'displayName': entityData['displayName'] ?? '',
          'contactName': entityData['contactName'] ?? '',
          'isActive': entityData['isActive'] ?? true,
          'companyDesc': entityData['companyDesc'] ?? '',
          'industryVertical': entityData['industryVertical'] ?? '',
          'businessType': entityData['businessType'] ?? '',
          'status': entityData['status'] ?? '',
          'website': entityData['website'] ?? '',
          'registrationNo': entityData['registrationNo'] ?? '',
          'taxIdentificationNumber1':
              entityData['taxIdentificationNumber1'] ?? '',
          'taxIdentificationNumber2':
              entityData['taxIdentificationNumber2'] ?? '',
          'upiId': entityData['upiId'] ?? '',
          'gPayPhone': entityData['gPayPhone'] ?? '',
          'logo': null,
          'signature': null,
          'showLogoOnInvoice': entityData['showLogoOnInvoice'] ?? false,
          'showSignatureOnInvoice':
              entityData['showSignatureOnInvoice'] ?? false,
        };

        // Extract contact information
        final emails = entityData['email'] as List?;
        if (emails != null && emails.isNotEmpty) {
          formData['email'] = emails.join(', ');
        } else {
          formData['email'] = '';
        }
        formData['whatsAppNumber'] = entityData['whatsAppNumber'] ?? '';

        // Load addresses
        addresses = List<Map<String, dynamic>>.from(
          entityData['addresses']?.map(
                (addr) => {
                  'id': addr['_id'],
                  'type': addr['type'],
                  'line1': addr['line1'] ?? '',
                  'line2': addr['line2'] ?? '',
                  'city': addr['city'] ?? '',
                  'state': addr['state'],
                  'country': addr['country'],
                  'code': addr['code'] ?? '',
                  'isActive': addr['isActive'] ?? true,
                },
              ) ??
              [],
        );

        // Ensure we have billing and shipping address entries
        if (!addresses.any((a) => a['type'] == 'Billing')) {
          addresses.add({
            'type': 'Billing',
            'line1': '',
            'line2': '',
            'city': '',
            'state': null,
            'country': null,
            'code': '',
            'isActive': true,
          });
        }
        if (!addresses.any((a) => a['type'] == 'Shipping')) {
          addresses.add({
            'type': 'Shipping',
            'line1': '',
            'line2': '',
            'city': '',
            'state': null,
            'country': null,
            'code': '',
            'isActive': true,
          });
        }

        // Load bank accounts
        bankAccounts = List<Map<String, dynamic>>.from(
          entityData['bankAccounts']?.map(
                (account) => {
                  'id': account['_id'],
                  'accountName': account['accountName'] ?? '',
                  'accountNumber': account['accountNumber'] ?? '',
                  'bankName': account['bankName'] ?? '',
                  'branchName': account['branchName'] ?? '',
                  'IFSC': account['IFSC'] ?? '',
                  'accountType': account['accountType'] ?? '',
                },
              ) ??
              [],
        );
      }
    } catch (e) {
      print('Error loading entity data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onFieldChanged(String key, dynamic value) {
    setState(() {
      formData[key] = value;
      // Clear validation error when field is modified
      validationErrors.remove(key);
    });
  }

  bool _validateCurrentSection() {
    validationErrors.clear();

    switch (currentSection) {
      case CustomerSupplierFormSection.basic:
        if (formData['name']?.isEmpty ?? true) {
          validationErrors['name'] = 'Name is required';
        }
        if (formData['legalName']?.isEmpty ?? true) {
          validationErrors['legalName'] = 'Legal name is required';
        }
        break;

      case CustomerSupplierFormSection.contact:
        if (formData['email']?.isEmpty ?? true) {
          validationErrors['email'] = 'Email is required';
        }
        if (formData['whatsAppNumber']?.isEmpty ?? true) {
          validationErrors['whatsAppNumber'] = 'WhatsApp number is required';
        }
        break;

      case CustomerSupplierFormSection.business:
        if (formData['registrationNo']?.isEmpty ?? true) {
          validationErrors['registrationNo'] =
              'Registration number is required';
        }
        break;

      case CustomerSupplierFormSection.addresses:
        // Validate billing address
        final billingAddr = addresses.firstWhere(
          (addr) => addr['type'] == 'Billing',
          orElse: () => {},
        );
        if (billingAddr['line1']?.isEmpty ?? true) {
          validationErrors['billingAddressLine1'] =
              'Billing address line 1 is required';
        }
        break;

      default:
        break;
    }

    return validationErrors.isEmpty;
  }

  Future<void> _updateSection() async {
    if (!_validateCurrentSection()) {
      setState(() {});
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      // Start with original entity data to preserve other sections
      final submitData = Map<String, dynamic>.from(originalEntityData);

      // Update only the current section's data
      switch (currentSection) {
        case CustomerSupplierFormSection.basic:
          submitData.addAll({
            'name': formData['name'],
            'legalName': formData['legalName'],
            'displayName': formData['displayName'],
            'contactName': formData['contactName'],
            'isActive': formData['isActive'],
            'companyDesc': formData['companyDesc'],
            'industryVertical': formData['industryVertical'],
            'businessType': formData['businessType'],
            'status': formData['status'],
          });

          if (formData['logo'] != null && formData['logo'] is File) {
            submitData['logo'] = await MultipartFile.fromFile(
              (formData['logo'] as File).path,
              filename: 'logo.jpg',
            );
          }
          break;

        case CustomerSupplierFormSection.contact:
          // Convert email string back to array
          final emailList = formData['email']
              .toString()
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

          submitData.addAll({
            'email': emailList,
            'whatsAppNumber': formData['whatsAppNumber'],
            'website': formData['website'],
          });
          break;

        case CustomerSupplierFormSection.business:
          submitData.addAll({
            'registrationNo': formData['registrationNo'],
            'taxIdentificationNumber1': formData['taxIdentificationNumber1'],
            'taxIdentificationNumber2': formData['taxIdentificationNumber2'],
          });
          break;

        case CustomerSupplierFormSection.addresses:
          submitData['addresses'] = addresses
              .where((addr) => addr['line1']?.isNotEmpty ?? false)
              .toList();
          break;

        case CustomerSupplierFormSection.payment:
          submitData.addAll({
            'upiId': formData['upiId'],
            'gPayPhone': formData['gPayPhone'],
          });
          submitData['bankAccounts'] = bankAccounts;
          break;

        case CustomerSupplierFormSection.attachments:
          submitData.addAll({
            'showLogoOnInvoice': formData['showLogoOnInvoice'],
            'showSignatureOnInvoice': formData['showSignatureOnInvoice'],
          });

          if (formData['signature'] != null && formData['signature'] is File) {
            submitData['signature'] = await MultipartFile.fromFile(
              (formData['signature'] as File).path,
              filename: 'signature.jpg',
            );
          }
          break;
      }

      // Update entity based on type
      bool success = false;
      String? errorMessage;

      if (widget.entityType == 'customer') {
        final response = await ref
            .read(customerActionsProvider)
            .updateCustomer(widget.entityId, submitData);
        success = response.success;
        errorMessage = response.error;

        if (success) {
          // Update local state in customer list
          ref
              .read(customerListProvider.notifier)
              .updateCustomer(response.data!);
        }
      } else {
        // For suppliers
        final response = await ref
            .read(supplierActionsProvider)
            .updateSupplier(widget.entityId, submitData);
        success = response.success;
        errorMessage = response.error;

        if (success) {
          // Update local state in supplier list
          ref
              .read(supplierListProvider.notifier)
              .updateSupplier(response.data!);
        }
      }

      if (success) {
        // Show success message and go back
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: Text('${currentSection.displayName} updated successfully'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pop(); // Go back to profile page
                },
              ),
            ],
          ),
        );
      } else {
        // Show error message
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(
              errorMessage ?? 'Failed to update ${widget.entityType}',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error updating ${widget.entityType}: $e');
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: const Text('An unexpected error occurred'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildSectionContent() {
    switch (currentSection) {
      case CustomerSupplierFormSection.basic:
        return _buildBasicSection();
      case CustomerSupplierFormSection.contact:
        return _buildContactSection();
      case CustomerSupplierFormSection.business:
        return _buildBusinessSection();
      case CustomerSupplierFormSection.addresses:
        return _buildAddressesSection();
      case CustomerSupplierFormSection.payment:
        return _buildPaymentSection();
      case CustomerSupplierFormSection.attachments:
        return _buildAttachmentsSection();
    }
  }

  Widget _buildBasicSection() {
    return Column(
      children: [
        FormFieldWidgets.buildAvatarField(
          'logo',
          'Company Logo',
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
          context: context,
          initials: formData['name']?.isNotEmpty == true
              ? formData['name'].toString().substring(0, 1).toUpperCase()
              : null,
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

        FormFieldWidgets.buildTextField(
          'displayName',
          'Display Name',
          'text',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        FormFieldWidgets.buildTextField(
          'contactName',
          'Contact Person Name',
          'text',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        FormFieldWidgets.buildTextAreaField(
          'companyDesc',
          'Company Description',
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        FormFieldWidgets.buildTextField(
          'industryVertical',
          'Industry Vertical',
          'text',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        FormFieldWidgets.buildSelectField(
          'businessType',
          'Business Type',
          [
            'Private Limited',
            'Public Limited',
            'Partnership',
            'Sole Proprietorship',
            'LLP',
            'Other',
          ],
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        FormFieldWidgets.buildSelectField(
          'status',
          'Status',
          ['Active', 'Inactive', 'Pending', 'Dummy'],
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        FormFieldWidgets.buildSwitchField(
          'isActive',
          'Active',
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      children: [
        FormFieldWidgets.buildTextField(
          'email',
          'Email Addresses',
          'email',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
          isRequired: true,
        
        ),

        FormFieldWidgets.buildTextField(
          'whatsAppNumber',
          'WhatsApp Number',
          'phone',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
          isRequired: true,
        ),

        FormFieldWidgets.buildTextField(
          'website',
          'Website',
          'url',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),
      ],
    );
  }

  Widget _buildBusinessSection() {
    return Column(
      children: [
        FormFieldWidgets.buildTextField(
          'registrationNo',
          'Registration Number',
          'text',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
          isRequired: true,
        ),

        FormFieldWidgets.buildTextField(
          'taxIdentificationNumber1',
          'Tax ID 1 (GSTIN)',
          'text',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        FormFieldWidgets.buildTextField(
          'taxIdentificationNumber2',
          'Tax ID 2 (PAN)',
          'text',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),
      ],
    );
  }

  Widget _buildAddressesSection() {
    return Column(
      children: addresses.map((address) {
        final index = addresses.indexOf(address);
        final type = address['type'];
        final prefix = type.toLowerCase();

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemGrey4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$type Address',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (addresses.length > 2)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _removeAddress(index),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        size: 16,
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              FormFieldWidgets.buildTextField(
                '${prefix}Line1',
                'Address Line 1',
                'text',
                context,
                onChanged: (key, value) {
                  setState(() {
                    address['line1'] = value;
                  });
                },
                formData: {'${prefix}Line1': address['line1'] ?? ''},
                validationErrors: type == 'Billing'
                    ? {
                        'billingAddressLine1':
                            validationErrors['billingAddressLine1'] ?? '',
                      }
                    : {},
                isRequired: type == 'Billing',
                compact: true,
              ),

              FormFieldWidgets.buildTextField(
                '${prefix}Line2',
                'Address Line 2',
                'text',
                context,
                onChanged: (key, value) {
                  setState(() {
                    address['line2'] = value;
                  });
                },
                formData: {'${prefix}Line2': address['line2'] ?? ''},
                validationErrors: {},
                compact: true,
              ),

              FormFieldWidgets.buildTextField(
                '${prefix}City',
                'City',
                'text',
                context,
                onChanged: (key, value) {
                  setState(() {
                    address['city'] = value;
                  });
                },
                formData: {'${prefix}City': address['city'] ?? ''},
                validationErrors: {},
                compact: true,
              ),

              // State and Country dropdowns would go here
              // You'll need to implement these using your countries_states_provider
              FormFieldWidgets.buildTextField(
                '${prefix}PinCode',
                'Pin Code',
                'number',
                context,
                onChanged: (key, value) {
                  setState(() {
                    address['code'] = value;
                  });
                },
                formData: {'${prefix}PinCode': address['code'] ?? ''},
                validationErrors: {},
                compact: true,
              ),

              FormFieldWidgets.buildSwitchField(
                '${prefix}IsActive',
                'Active Address',
                onChanged: (key, value) {
                  setState(() {
                    address['isActive'] = value;
                  });
                },
                formData: {'${prefix}IsActive': address['isActive'] ?? true},
                validationErrors: {},
              ),
            ],
          ),
        );
      }).toList()..add(_buildAddAddressButton()as Container),
    );
  }

  Widget _buildAddAddressButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemBlue.withOpacity(0.2)),
      ),
      child: CupertinoButton(
        onPressed: _addAddress,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              CupertinoIcons.add,
              color: CupertinoColors.systemBlue,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Add Address',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addAddress() {
    setState(() {
      addresses.add({
        'type': 'Additional',
        'line1': '',
        'line2': '',
        'city': '',
        'state': null,
        'country': null,
        'code': '',
        'isActive': true,
      });
    });
  }

  void _removeAddress(int index) {
    setState(() {
      addresses.removeAt(index);
    });
  }

  Widget _buildPaymentSection() {
    return Column(
      children: [
        FormFieldWidgets.buildTextField(
          'upiId',
          'UPI ID',
          'text',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        FormFieldWidgets.buildTextField(
          'gPayPhone',
          'GPay Phone Number',
          'phone',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        _buildBankAccountsSection(),
      ],
    );
  }

  Widget _buildBankAccountsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bank Accounts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _addBankAccount,
                child: const Icon(CupertinoIcons.add, size: 20),
              ),
            ],
          ),

          ...bankAccounts.asMap().entries.map((entry) {
            final index = entry.key;
            final account = entry.value;

            return Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bank Account ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _removeBankAccount(index),
                        child: const Icon(
                          CupertinoIcons.xmark,
                          size: 16,
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                    ],
                  ),

                  FormFieldWidgets.buildTextField(
                    'accountName_$index',
                    'Account Holder Name',
                    'text',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        bankAccounts[index]['accountName'] = value;
                      });
                    },
                    formData: {
                      'accountName_$index': account['accountName'] ?? '',
                    },
                    validationErrors: {},
                    compact: true,
                  ),

                  FormFieldWidgets.buildTextField(
                    'accountNumber_$index',
                    'Account Number',
                    'number',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        bankAccounts[index]['accountNumber'] = value;
                      });
                    },
                    formData: {
                      'accountNumber_$index': account['accountNumber'] ?? '',
                    },
                    validationErrors: {},
                    compact: true,
                  ),

                  FormFieldWidgets.buildTextField(
                    'bankName_$index',
                    'Bank Name',
                    'text',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        bankAccounts[index]['bankName'] = value;
                      });
                    },
                    formData: {'bankName_$index': account['bankName'] ?? ''},
                    validationErrors: {},
                    compact: true,
                  ),

                  FormFieldWidgets.buildTextField(
                    'branchName_$index',
                    'Branch Name',
                    'text',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        bankAccounts[index]['branchName'] = value;
                      });
                    },
                    formData: {
                      'branchName_$index': account['branchName'] ?? '',
                    },
                    validationErrors: {},
                    compact: true,
                  ),

                  FormFieldWidgets.buildTextField(
                    'IFSC_$index',
                    'IFSC Code',
                    'text',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        bankAccounts[index]['IFSC'] = value;
                      });
                    },
                    formData: {'IFSC_$index': account['IFSC'] ?? ''},
                    validationErrors: {},
                    compact: true,
                  ),

                  FormFieldWidgets.buildSelectField(
                    'accountType_$index',
                    'Account Type',
                    [
                      'Savings',
                      'Current',
                      'Salary',
                      'Fixed Deposit',
                      'Recurring Deposit',
                    ],
                    onChanged: (key, value) {
                      setState(() {
                        bankAccounts[index]['accountType'] = value;
                      });
                    },
                    formData: {
                      'accountType_$index': account['accountType'] ?? '',
                    },
                    validationErrors: {},
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _addBankAccount() {
    setState(() {
      bankAccounts.add({
        'accountName': '',
        'accountNumber': '',
        'bankName': '',
        'branchName': '',
        'IFSC': '',
        'accountType': '',
      });
    });
  }

  void _removeBankAccount(int index) {
    setState(() {
      bankAccounts.removeAt(index);
    });
  }

  Widget _buildAttachmentsSection() {
    return Column(
      children: [
        FormFieldWidgets.buildAvatarField(
          'signature',
          'Signature',
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
          context: context,
          size: 120,
        ),

        FormFieldWidgets.buildSwitchField(
          'showLogoOnInvoice',
          'Show Logo on Invoice',
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        FormFieldWidgets.buildSwitchField(
          'showSignatureOnInvoice',
          'Show Signature on Invoice',
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          child: const Text(
            'Additional document uploads can be handled here. You can extend this section to include specific document types.',
            style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorProvider);

    if (!isInitialized || isLoading) {
      return CupertinoPageScaffold(
        backgroundColor: colors.background,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: colors.surface,
          middle: Text(
            'Update ${currentSection.displayName}',
            style: TextStyle(color: colors.textPrimary),
          ),
        ),
        child: Center(child: CupertinoActivityIndicator(color: colors.primary)),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surface,
        middle: Text(
          'Update ${currentSection.displayName}',
          style: TextStyle(color: colors.textPrimary),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: Icon(CupertinoIcons.back, color: colors.primary),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Section icon and title
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      currentSection.icon,
                      color: colors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSection.displayName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Update your ${currentSection.displayName.toLowerCase()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Section content
            Expanded(
              child: SingleChildScrollView(child: _buildSectionContent()),
            ),

            // Update button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  onPressed: isLoading ? null : _updateSection,
                  color: colors.primary,
                  child: isLoading
                      ? CupertinoActivityIndicator(color: CupertinoColors.white)
                      : Text(
                          'Update ${currentSection.displayName}',
                          style: const TextStyle(color: CupertinoColors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
