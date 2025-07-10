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
import '../components/addresses_bottom_sheet.dart';
import '../../apis/providers/agreed_services_provider.dart';

// Customer/Supplier form sections enum
enum CustomerSupplierFormSection {
  basic,
  contact,
  business,
  addresses,
  payment,
  attachments,
  agreedServices,
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
      case CustomerSupplierFormSection.agreedServices:
        return 'Agreed Services';
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
      case CustomerSupplierFormSection.agreedServices: // Add this
        return 'agreedservices';
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
      case CustomerSupplierFormSection.agreedServices:
        return CupertinoIcons.checkmark_alt;
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

  List<Map<String, dynamic>> agreedServices = [];
  bool _isAddingService = false;

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
        // Handle logo URL if it exists and is a valid string URL
        if (entityData['logo'] != null &&
            entityData['logo'] is String &&
            entityData['logo'].toString().isNotEmpty &&
            (entityData['logo'].toString().startsWith('http://') ||
                entityData['logo'].toString().startsWith('https://'))) {
          formData['logoUrl'] = entityData['logo'];
        }

        // Remove any invalid logo data that might cause issues
        if (formData['logo'] != null && formData['logo'] is! File) {
          formData.remove('logo');
        }
        // Extract contact information
        final emails = entityData['email'] as List?;
        if (emails != null && emails.isNotEmpty) {
          formData['email'] = emails.join(', ');
        } else {
          formData['email'] = '';
        }
        formData['whatsAppNumber'] = entityData['whatsAppNumber'] ?? '';

        addresses = [];

        // First, try to load from addresses array (if server returns structured data)
        if (entityData['addresses'] != null &&
            entityData['addresses'] is List) {
          addresses = List<Map<String, dynamic>>.from(
            entityData['addresses'].map(
              (addr) => {
                'id': addr['_id'],
                'type': addr['type'],
                'line1': addr['line1'] ?? '',
                'line2': addr['line2'] ?? '',
                'city': addr['city'] ?? '',
                'state': addr['state'], // Keep full state object
                'country': addr['country'], // Keep full country object
                'code': addr['code'] ?? '',
                'isActive': addr['isActive'] ?? true,
              },
            ),
          );
        } else {
          // If no structured addresses, reconstruct from flat fields

          // Load billing address from flat fields
          if ((entityData['billingAddressLine1']
                  ?.toString()
                  .trim()
                  .isNotEmpty ??
              false)) {
            final billingAddress = {
              'type': 'Billing',
              'line1': entityData['billingAddressLine1'] ?? '',
              'line2': entityData['billingAddressLine2'] ?? '',
              'city': entityData['billingAddressCity'] ?? '',
              'code': entityData['billingAddressPinCode']?.toString() ?? '',
              'isActive': true,
            };

            // Add country if exists (store ID and placeholder name for now)
            if (entityData['billingAddressCountry'] != null) {
              billingAddress['country'] = {
                '_id': entityData['billingAddressCountry'],
                'name':
                    'Country', // Placeholder - will be loaded when country dropdown opens
              };
            }

            // Add state if exists (store ID and placeholder name for now)
            if (entityData['billingAddressState'] != null) {
              billingAddress['state'] = {
                '_id': entityData['billingAddressState'],
                'name':
                    'State', // Placeholder - will be loaded when state dropdown opens
              };
            }

            addresses.add(billingAddress);
          }

          // Load shipping address from flat fields
          if ((entityData['shippingAddressLine1']
                  ?.toString()
                  .trim()
                  .isNotEmpty ??
              false)) {
            final shippingAddress = {
              'type': 'Shipping',
              'line1': entityData['shippingAddressLine1'] ?? '',
              'line2': entityData['shippingAddressLine2'] ?? '',
              'city': entityData['shippingAddressCity'] ?? '',
              'code': entityData['shippingAddressPinCode']?.toString() ?? '',
              'isActive': true,
            };

            // Add country if exists (store ID and placeholder name for now)
            if (entityData['shippingAddressCountry'] != null) {
              shippingAddress['country'] = {
                '_id': entityData['shippingAddressCountry'],
                'name':
                    'Country', // Placeholder - will be loaded when country dropdown opens
              };
            }

            // Add state if exists (store ID and placeholder name for now)
            if (entityData['shippingAddressState'] != null) {
              shippingAddress['state'] = {
                '_id': entityData['shippingAddressState'],
                'name':
                    'State', // Placeholder - will be loaded when state dropdown opens
              };
            }

            addresses.add(shippingAddress);
          }
        }

        // Ensure we have billing and shipping address entries (but only if they don't exist)
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

        // Load agreed services
        agreedServices = List<Map<String, dynamic>>.from(
          entityData['agreedServices']?.map(
                (service) => {
                  'uid': service['uid'] ?? 1,
                  'serviceCategory': service['serviceCategory'] ?? '',
                  'serviceName': service['serviceName'] ?? '',
                  'serviceBudget': service['serviceBudget']?.toDouble() ?? 0.0,
                  'personnel': service['personnel'] ?? 0,
                  'startDate': service['startDate'] != null
                      ? DateTime.parse(service['startDate'])
                      : DateTime.now(),
                  'endDate': service['endDate'] != null
                      ? DateTime.parse(service['endDate'])
                      : DateTime.now().add(Duration(days: 7)),
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
          orElse: () => <String, dynamic>{}, // Return empty map instead of null
        );
        if (billingAddr.isEmpty ||
            (billingAddr['line1']?.toString().trim().isEmpty ?? true)) {
          validationErrors['billingAddress'] = 'Billing address is required';
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

      // Create section-specific data only (don't start with full original data)
      final submitData = <String, dynamic>{};

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

          // Only add logo if it's actually changed/selected
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
          final billingAddress = addresses.firstWhere(
            (addr) => addr['type'] == 'Billing',
            orElse: () => <String, dynamic>{},
          );

          final shippingAddress = addresses.firstWhere(
            (addr) => addr['type'] == 'Shipping',
            orElse: () => <String, dynamic>{},
          );

          // Add billing address as FLAT FIELDS
          if (billingAddress.isNotEmpty &&
              (billingAddress['line1']?.toString().trim().isNotEmpty ??
                  false)) {
            submitData["billingAddressLine1"] = (billingAddress['line1'] ?? '')
                .toString()
                .trim();
            submitData["billingAddressLine2"] = (billingAddress['line2'] ?? '')
                .toString()
                .trim();
            submitData["billingAddressCity"] = (billingAddress['city'] ?? '')
                .toString()
                .trim();
            submitData["billingAddressPinCode"] = (billingAddress['code'] ?? '')
                .toString()
                .trim();

            if (billingAddress['country'] != null &&
                billingAddress['country']['_id'] != null) {
              submitData["billingAddressCountry"] =
                  billingAddress['country']['_id'];
            }
            if (billingAddress['state'] != null &&
                billingAddress['state']['_id'] != null) {
              submitData["billingAddressState"] =
                  billingAddress['state']['_id'];
            }
          }

          // Add shipping address as FLAT FIELDS
          if (shippingAddress.isNotEmpty &&
              (shippingAddress['line1']?.toString().trim().isNotEmpty ??
                  false)) {
            submitData["shippingAddressLine1"] =
                (shippingAddress['line1'] ?? '').toString().trim();
            submitData["shippingAddressLine2"] =
                (shippingAddress['line2'] ?? '').toString().trim();
            submitData["shippingAddressCity"] = (shippingAddress['city'] ?? '')
                .toString()
                .trim();
            submitData["shippingAddressPinCode"] =
                (shippingAddress['code'] ?? '').toString().trim();

            if (shippingAddress['country'] != null &&
                shippingAddress['country']['_id'] != null) {
              submitData["shippingAddressCountry"] =
                  shippingAddress['country']['_id'];
            }
            if (shippingAddress['state'] != null &&
                shippingAddress['state']['_id'] != null) {
              submitData["shippingAddressState"] =
                  shippingAddress['state']['_id'];
            }
          }
          break;

        case CustomerSupplierFormSection.agreedServices:
          // First, check if user is adding a new service and auto-add it to the list
          if (_isAddingService) {
            // Validate the new service form
            bool isValid = true;
            validationErrors.removeWhere((key, value) => key.startsWith('new'));

            if ((formData['newServiceCategory'] ?? '')
                .toString()
                .trim()
                .isEmpty) {
              validationErrors['newServiceCategory'] =
                  'Service category is required';
              isValid = false;
            }

            if ((formData['newServiceName'] ?? '').toString().trim().isEmpty) {
              validationErrors['newServiceName'] = 'Service name is required';
              isValid = false;
            }

            if (!isValid) {
              setState(() {});
              return;
            }

            // Generate next UID
            int nextUid = agreedServices.isEmpty
                ? 1
                : agreedServices
                          .map((s) => s['uid'] as int)
                          .reduce((a, b) => a > b ? a : b) +
                      1;

            // Add the new service to local state first
            setState(() {
              agreedServices.add({
                'uid': nextUid,
                'serviceCategory':
                    formData['newServiceCategory']?.toString().trim() ?? '',
                'serviceName':
                    formData['newServiceName']?.toString().trim() ?? '',
                'serviceBudget':
                    double.tryParse(
                      formData['newServiceBudget']?.toString() ?? '0',
                    ) ??
                    0.0,
                'personnel':
                    int.tryParse(formData['newPersonnel']?.toString() ?? '0') ??
                    0,
                'startDate': formData['newStartDate'] ?? DateTime.now(),
                'endDate':
                    formData['newEndDate'] ??
                    DateTime.now().add(Duration(days: 7)),
                // Note: No _id field - this will be generated by server on update
              });

              // Clear the form
              _isAddingService = false;
              formData.removeWhere((key, value) => key.startsWith('new'));
              validationErrors.removeWhere(
                (key, value) => key.startsWith('new'),
              );
            });
          }

          // Now proceed with batch update if there are any services
          if (agreedServices.isNotEmpty) {
            await _updateAgreedServicesBatch();
          } else {
            // If no services, just show success
            _showSuccessDialog('Agreed services updated successfully');
          }
          return;

        case CustomerSupplierFormSection.payment:
          submitData.addAll({
            'upiId': formData['upiId'],
            'gPayPhone': formData['gPayPhone'],
          });

          // Only include bank accounts if they exist and have data
          if (bankAccounts.isNotEmpty) {
            submitData['bankAccounts'] = bankAccounts;
          }
          break;

        case CustomerSupplierFormSection.attachments:
          submitData.addAll({
            'showLogoOnInvoice': formData['showLogoOnInvoice'],
            'showSignatureOnInvoice': formData['showSignatureOnInvoice'],
          });

          // Only add signature if it's actually changed/selected
          if (formData['signature'] != null && formData['signature'] is File) {
            submitData['signature'] = await MultipartFile.fromFile(
              (formData['signature'] as File).path,
            );
          }
          break;
      }

      // Debug log to see what we're sending
      print('Sending data for ${currentSection.name}: $submitData');

      // Update entity based on type (for non-agreed services sections)
      bool success = false;
      String? errorMessage;

      if (widget.entityType == 'customer') {
        final response = await ref
            .read(customerActionsProvider)
            .updateCustomer(widget.entityId, submitData);
        success = response.success;
        errorMessage = response.error;

        if (success) {
          // Update original entity data with the new values for this section
          _updateOriginalEntityData(submitData);

          // Update local state in customer list
          if (response.data != null) {
            ref
                .read(customerListProvider.notifier)
                .updateCustomer(response.data!);
          }
        }
      } else {
        // For suppliers
        final response = await ref
            .read(supplierActionsProvider)
            .updateSupplier(widget.entityId, submitData);
        success = response.success;
        errorMessage = response.error;

        if (success) {
          // Update original entity data with the new values for this section
          _updateOriginalEntityData(submitData);

          // Update local state in supplier list
          if (response.data != null) {
            ref
                .read(supplierListProvider.notifier)
                .updateSupplier(response.data!);
          }
        }
      }

      if (success) {
        // Show success message and go back
        _showSuccessDialog(
          '${currentSection.displayName} updated successfully',
        );
      } else {
        // Show error message
        _showErrorDialog(
          errorMessage ?? 'Failed to update ${widget.entityType}',
        );
      }
    } catch (e) {
      print('Error updating ${widget.entityType}: $e');
      _showErrorDialog('An unexpected error occurred');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Add this method back to the class:
  Future<void> _updateAgreedServicesBatch() async {
    try {
      // Convert agreed services to API format
      final agreedServicesData = agreedServices
          .map(
            (service) => {
              'uid': service['uid'],
              'serviceCategory': service['serviceCategory'] ?? '',
              'serviceName': service['serviceName'] ?? '',
              'serviceBudget': service['serviceBudget'] ?? 0.0,
              'personnel': service['personnel'] ?? 0,
              'startDate': (service['startDate'] as DateTime).toIso8601String(),
              'endDate': (service['endDate'] as DateTime).toIso8601String(),
            },
          )
          .toList();

      print(
        'Batch updating ${agreedServicesData.length} agreed services for ${widget.entityId}',
      );

      // Use the agreed services provider to update all at once
      final response = await ref
          .read(agreedServicesAuthenticatedActionsProvider)
          .updateAgreedServices(
            counterPartyId: widget.entityId,
            services: agreedServicesData
                .map((data) => AgreedService.fromJson(data))
                .toList(),
          );

      if (!response.success) {
        throw Exception(response.error ?? 'Failed to update agreed services');
      }

      print('Agreed services batch update successful');

      // Reload entity data to get the server state (including generated _id fields)
      await _reloadEntityDataAfterUpdate();

      // Show success message and navigate back
      _showSuccessDialog('Agreed services updated successfully');
    } catch (e) {
      print('Error in batch update of agreed services: $e');
      _showErrorDialog('Failed to update agreed services: ${e.toString()}');
    }
  }

  void _updateOriginalEntityData(Map<String, dynamic> updatedData) {
    setState(() {
      // Update the original entity data with new values
      for (final entry in updatedData.entries) {
        // Skip file fields as they're not stored in the original data
        if (entry.value is! MultipartFile) {
          originalEntityData[entry.key] = entry.value;
        }
      }

      // For basic section, also update form data to reflect current state
      if (currentSection == CustomerSupplierFormSection.basic) {
        // Clear the logo from form data after successful upload
        formData['logo'] = null;
      }

      if (currentSection == CustomerSupplierFormSection.attachments) {
        // Clear the signature from form data after successful upload
        formData['signature'] = null;
      }
    });
  }

  // 3. Reload entity data after successful update
  Future<void> _reloadEntityDataAfterUpdate() async {
    try {
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
        setState(() {
          // Update agreed services with server response (includes _id fields)
          // Safe null handling for agreedServices
          final agreedServicesRaw = entityData!['agreedServices'];

          if (agreedServicesRaw != null && agreedServicesRaw is List) {
            agreedServices = List<Map<String, dynamic>>.from(
              agreedServicesRaw.map(
                (service) => {
                  'uid': service['uid'] ?? 1,
                  'serviceCategory': service['serviceCategory'] ?? '',
                  'serviceName': service['serviceName'] ?? '',
                  'serviceBudget': service['serviceBudget']?.toDouble() ?? 0.0,
                  'personnel': service['personnel'] ?? 0,
                  'startDate': service['startDate'] != null
                      ? DateTime.parse(service['startDate'])
                      : DateTime.now(),
                  'endDate': service['endDate'] != null
                      ? DateTime.parse(service['endDate'])
                      : DateTime.now().add(Duration(days: 7)),
                  '_id': service['_id'], // Preserve server-generated ID
                },
              ),
            );
          } else {
            // If agreedServices is null or not a List, initialize as empty
            agreedServices = [];
          }

          // Update original entity data
          originalEntityData = Map<String, dynamic>.from(entityData!);
        });

        print('Reloaded ${agreedServices.length} agreed services from server');
      }
    } catch (e) {
      print('Error reloading entity data: $e');
      // On error, don't update the state - keep the current local state
    }
  }

  // 4. Local-only add service method (no API call)
  void _addAgreedService() {
    setState(() {
      _isAddingService = true;
      // Clear form data for new service
      formData['newServiceCategory'] = '';
      formData['newServiceName'] = '';
      formData['newServiceBudget'] = '';
      formData['newPersonnel'] = '';
      formData['newStartDate'] = DateTime.now();
      formData['newEndDate'] = DateTime.now().add(Duration(days: 7));
    });
  }

  // Replace the existing _saveNewService() method with this:
  Future<void> _saveNewService() async {
    // Validate required fields
    bool isValid = true;
    validationErrors.removeWhere((key, value) => key.startsWith('new'));

    if ((formData['newServiceCategory'] ?? '').toString().trim().isEmpty) {
      validationErrors['newServiceCategory'] = 'Service category is required';
      isValid = false;
    }

    if ((formData['newServiceName'] ?? '').toString().trim().isEmpty) {
      validationErrors['newServiceName'] = 'Service name is required';
      isValid = false;
    }

    if (!isValid) {
      setState(() {});
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Generate next UID
      int nextUid = agreedServices.isEmpty
          ? 1
          : agreedServices
                    .map((s) => s['uid'] as int)
                    .reduce((a, b) => a > b ? a : b) +
                1;

      // Create new service object
      final newService = AgreedService(
        uid: nextUid,
        serviceCategory:
            formData['newServiceCategory']?.toString().trim() ?? '',
        serviceName: formData['newServiceName']?.toString().trim() ?? '',
        serviceBudget:
            double.tryParse(formData['newServiceBudget']?.toString() ?? '0') ??
            0.0,
        personnel:
            int.tryParse(formData['newPersonnel']?.toString() ?? '0') ?? 0,
        startDate: formData['newStartDate'] ?? DateTime.now(),
        endDate:
            formData['newEndDate'] ?? DateTime.now().add(Duration(days: 7)),
      );

      // Convert current local services to AgreedService objects
      final currentServices = agreedServices
          .map(
            (service) => AgreedService(
              uid: service['uid'],
              serviceCategory: service['serviceCategory'] ?? '',
              serviceName: service['serviceName'] ?? '',
              serviceBudget: service['serviceBudget']?.toDouble() ?? 0.0,
              personnel: service['personnel'] ?? 0,
              startDate: service['startDate'] ?? DateTime.now(),
              endDate:
                  service['endDate'] ?? DateTime.now().add(Duration(days: 7)),
              id: service['_id'],
            ),
          )
          .toList();

      // Add new service to the list
      final allServices = [...currentServices, newService];

      // Call agreed services API directly
      final response = await ref
          .read(agreedServicesAuthenticatedActionsProvider)
          .updateAgreedServices(
            counterPartyId: widget.entityId,
            services: allServices,
          );

      if (response.success) {
        // Reload entity data to get updated services with server IDs
        await _reloadEntityDataAfterUpdate();

        setState(() {
          // Reset form state
          _isAddingService = false;
          formData.removeWhere((key, value) => key.startsWith('new'));
          validationErrors.removeWhere((key, value) => key.startsWith('new'));
        });

        // Show success message
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: const Text('Agreed service added successfully'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      } else {
        throw Exception(response.error ?? 'Failed to add agreed service');
      }
    } catch (e) {
      print('Error adding agreed service: $e');
      _showErrorDialog('Failed to add agreed service: ${e.toString()}');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Replace the existing _removeAgreedService() method with this:
  Future<void> _removeAgreedService(int index) async {
    if (index < 0 || index >= agreedServices.length) return;

    final serviceToRemove = agreedServices[index];

    try {
      setState(() {
        isLoading = true;
      });

      // Convert current services to AgreedService objects, excluding the one to remove
      final remainingServices = agreedServices
          .asMap()
          .entries
          .where((entry) => entry.key != index)
          .map(
            (entry) => AgreedService(
              uid: entry.value['uid'],
              serviceCategory: entry.value['serviceCategory'] ?? '',
              serviceName: entry.value['serviceName'] ?? '',
              serviceBudget: entry.value['serviceBudget']?.toDouble() ?? 0.0,
              personnel: entry.value['personnel'] ?? 0,
              startDate: entry.value['startDate'] ?? DateTime.now(),
              endDate:
                  entry.value['endDate'] ??
                  DateTime.now().add(Duration(days: 7)),
              id: entry.value['_id'],
            ),
          )
          .toList();

      // Call agreed services API directly
      final response = await ref
          .read(agreedServicesAuthenticatedActionsProvider)
          .updateAgreedServices(
            counterPartyId: widget.entityId,
            services: remainingServices,
          );

      if (response.success) {
        // Update local state
        setState(() {
          agreedServices.removeAt(index);
        });

        print(
          'Removed service: ${serviceToRemove['serviceName']}. Remaining: ${agreedServices.length}',
        );
      } else {
        throw Exception(response.error ?? 'Failed to remove agreed service');
      }
    } catch (e) {
      print('Error removing agreed service: $e');
      _showErrorDialog('Failed to remove agreed service: ${e.toString()}');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // 7. Cancel add service (local only)
  void _cancelAddService() {
    setState(() {
      _isAddingService = false;
      // Clear form data
      formData.removeWhere((key, value) => key.startsWith('new'));
      validationErrors.removeWhere((key, value) => key.startsWith('new'));
    });
  }

  // 8. Helper methods for dialogs
  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: Text(message),
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

  Widget _buildAgreedServicesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Agreed Services',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isAddingService ? _cancelAddService : _addAgreedService,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isAddingService
                  ? CupertinoColors.systemRed.withOpacity(0.1)
                  : CupertinoColors.systemGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isAddingService ? CupertinoIcons.xmark : CupertinoIcons.add,
                  size: 16,
                  color: _isAddingService
                      ? CupertinoColors.systemRed
                      : CupertinoColors.systemGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  _isAddingService ? 'Cancel' : 'Add',
                  style: TextStyle(
                    color: _isAddingService
                        ? CupertinoColors.systemRed
                        : CupertinoColors.systemGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 10. Helper to check for unsaved changes
  bool _hasUnsavedChanges() {
    // Compare current agreedServices with originalEntityData
    final originalServices = originalEntityData['agreedServices'] as List?;
    if (originalServices == null && agreedServices.isEmpty) return false;
    if (originalServices == null && agreedServices.isNotEmpty) return true;
    if (originalServices != null &&
        agreedServices.length != originalServices.length)
      return true;

    // Check if any service details have changed
    // For simplicity, we'll consider any local modifications as unsaved
    return agreedServices.any((service) => service['_id'] == null);
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
      case CustomerSupplierFormSection.agreedServices:
        return _buildAgreedServicesSection();
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
          existingImageUrl: formData['logoUrl'],
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
          'Contact Name',
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

        // FormFieldWidgets.buildSelectField(
        //   'status',
        //   'Status',
        //   ['Active', 'Inactive', 'Pending', 'Dummy'],
        //   onChanged: _onFieldChanged,
        //   formData: formData,
        //   validationErrors: validationErrors,
        // ),

        // FormFieldWidgets.buildSwitchField(
        //   'isActive',
        //   'Active',
        //   onChanged: _onFieldChanged,
        //   formData: formData,
        //   validationErrors: validationErrors,
        // ),
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
          'PAN Number',
          'text',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
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
    );
  }

  Widget _buildAddressesSection() {
    return Column(
      children: [
        // Billing Address Section
        _buildAddressTypeSection('Billing'),
        const SizedBox(height: 24),

        // Shipping Address Section
        _buildAddressTypeSection('Shipping'),
      ],
    );
  }

  Widget _buildAddressTypeSection(String addressType) {
    final address = addresses.firstWhere(
      (addr) => addr['type'] == addressType,
      orElse: () => <String, dynamic>{}, // Return empty map instead of null
    );

    final hasAddressData =
        address.isNotEmpty &&
        (address['line1']?.toString().trim().isNotEmpty ?? false) &&
        (address['city']?.toString().trim().isNotEmpty ?? false) &&
        (address['code']?.toString().trim().isNotEmpty ?? false);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '$addressType Address',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),

          // Address Button or Display
          if (!hasAddressData)
            _buildAddAddressButton(addressType)
          else
            _buildAddressDisplay(address, addressType),
        ],
      ),
    );
  }

  Widget _buildAddAddressButton(String addressType) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemBlue.withOpacity(0.2)),
      ),
      child: CupertinoButton(
        onPressed: () => _showAddressBottomSheet(addressType),
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.add,
              color: CupertinoColors.systemBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Add $addressType Address',
              style: const TextStyle(
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

  Widget _buildAddressDisplay(
    Map<String, dynamic> address,
    String addressType,
  ) {
    final line1 = address['line1'] ?? '';
    final line2 = address['line2'] ?? '';
    final city = address['city'] ?? '';
    final stateName = address['state']?['name'] ?? '';
    final countryName = address['country']?['name'] ?? '';
    final pinCode = address['code']?.toString() ?? '';

    final addressParts = [
      if (line1.isNotEmpty) line1,
      if (line2.isNotEmpty) line2,
      if (city.isNotEmpty) city,
      if (stateName.isNotEmpty) stateName,
      if (countryName.isNotEmpty) countryName,
      if (pinCode.isNotEmpty) pinCode,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemGrey4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    addressType == 'Billing'
                        ? CupertinoIcons.location
                        : CupertinoIcons.location_solid,
                    color: addressType == 'Billing'
                        ? CupertinoColors.systemBlue
                        : CupertinoColors.systemPurple,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$addressType Address:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: addressType == 'Billing'
                          ? CupertinoColors.systemBlue
                          : CupertinoColors.systemPurple,
                    ),
                  ),
                ],
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: () => _showAddressBottomSheet(addressType),
                child: const Icon(
                  CupertinoIcons.pencil,
                  size: 16,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            addressParts.join(', '),
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Add this method to show the address bottom sheet
  void _showAddressBottomSheet(String addressType) {
    final addressData = <String, dynamic>{};

    // Find existing address data
    final existingAddress = addresses.firstWhere(
      (addr) => addr['type'] == addressType,
      orElse: () => <String, dynamic>{}, // Return empty map instead of null
    );

    if (existingAddress.isNotEmpty) {
      // Check if map is not empty instead of not null
      // Map existing address data to form format
      final prefix = addressType.toLowerCase();
      addressData['${prefix}AddressLine1'] = existingAddress['line1'] ?? '';
      addressData['${prefix}AddressLine2'] = existingAddress['line2'] ?? '';
      addressData['${prefix}AddressCity'] = existingAddress['city'] ?? '';
      addressData['${prefix}AddressPinCode'] =
          existingAddress['code']?.toString() ?? '';

      // Handle country
      if (existingAddress['country'] != null) {
        addressData['${prefix}AddressCountry'] =
            existingAddress['country']['name'] ?? '';
        addressData['${prefix}AddressCountryId'] =
            existingAddress['country']['_id'] ?? '';
      }

      // Handle state
      if (existingAddress['state'] != null) {
        addressData['${prefix}AddressState'] =
            existingAddress['state']['name'] ?? '';
        addressData['${prefix}AddressStateId'] =
            existingAddress['state']['_id'] ?? '';
      }
    }

    if (addressType == 'Billing') {
      AddressBottomSheetService.showBillingAddressBottomSheet(
        context: context,
        ref: ref,
        initialData: addressData,
        onAddressSelected: (selectedData) {
          _updateAddressFromBottomSheet(addressType, selectedData);
        },
      );
    } else {
      AddressBottomSheetService.showShippingAddressBottomSheet(
        context: context,
        ref: ref,
        initialData: addressData,
        onAddressSelected: (selectedData) {
          _updateAddressFromBottomSheet(addressType, selectedData);
        },
      );
    }
  }

  // Add this method to update address from bottom sheet data
  void _updateAddressFromBottomSheet(
    String addressType,
    Map<String, dynamic> bottomSheetData,
  ) {
    setState(() {
      // Remove existing address of this type
      addresses.removeWhere((addr) => addr['type'] == addressType);

      final prefix = addressType.toLowerCase();

      // Create new address object
      final newAddress = {
        'type': addressType,
        'line1': bottomSheetData['${prefix}AddressLine1'] ?? '',
        'line2': bottomSheetData['${prefix}AddressLine2'] ?? '',
        'city': bottomSheetData['${prefix}AddressCity'] ?? '',
        'code': bottomSheetData['${prefix}AddressPinCode']?.toString() ?? '',
        'isActive': true,
      };

      // Add country if provided
      if (bottomSheetData['${prefix}AddressCountryId'] != null) {
        newAddress['country'] = {
          '_id': bottomSheetData['${prefix}AddressCountryId'],
          'name': bottomSheetData['${prefix}AddressCountry'] ?? '',
        };
      }

      // Add state if provided
      if (bottomSheetData['${prefix}AddressStateId'] != null) {
        newAddress['state'] = {
          '_id': bottomSheetData['${prefix}AddressStateId'],
          'name': bottomSheetData['${prefix}AddressState'] ?? '',
        };
      }

      // Add the new address
      addresses.add(newAddress);
    });
  }

  Widget _buildAgreedServicesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with "Unsaved changes" indicator
          _buildAgreedServicesHeader(),

          // New Service Form at Top (when adding)
          if (_isAddingService)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                border: Border.all(color: CupertinoColors.systemBlue, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'New Service',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: CupertinoColors.systemBlue,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _saveNewService,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemBlue,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Add to List',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Service Category Field
                  FormFieldWidgets.buildTextField(
                    'newServiceCategory',
                    'Service Category',
                    'text',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        formData['newServiceCategory'] = value;
                      });
                    },
                    formData: formData,
                    validationErrors: validationErrors,
                  ),

                  // Service Name Field
                  FormFieldWidgets.buildTextField(
                    'newServiceName',
                    'Service Name',
                    'text',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        formData['newServiceName'] = value;
                      });
                    },
                    formData: formData,
                    validationErrors: validationErrors,
                  ),

                  // Service Budget Field
                  FormFieldWidgets.buildTextField(
                    'newServiceBudget',
                    'Service Budget (₹)',
                    'number',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        formData['newServiceBudget'] = value;
                      });
                    },
                    formData: formData,
                    validationErrors: validationErrors,
                  ),

                  // Personnel Field
                  FormFieldWidgets.buildTextField(
                    'newPersonnel',
                    'Personnel Required',
                    'number',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        formData['newPersonnel'] = value;
                      });
                    },
                    formData: formData,
                    validationErrors: validationErrors,
                  ),
                  // Start Date Field (separate column)
                  FormFieldWidgets.buildDateField(
                    'newStartDate',
                    'Start Date',
                    context: context,
                    onChanged: (key, value) {
                      setState(() {
                        formData['newStartDate'] = value;
                      });
                    },
                    formData: formData,
                    validationErrors: validationErrors,
                  ),

                  // End Date Field (separate column)
                  FormFieldWidgets.buildDateField(
                    'newEndDate',
                    'End Date',
                    context: context,
                    onChanged: (key, value) {
                      setState(() {
                        formData['newEndDate'] = value;
                      });
                    },
                    formData: formData,
                    validationErrors: validationErrors,
                  ),
                ],
              ),
            ),

          // Empty state or existing services list
          if (agreedServices.isEmpty && !_isAddingService)
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_alt,
                      size: 32,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No agreed services added',
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "Add" to create a new service agreement',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey2,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (agreedServices.isNotEmpty)
            // Services List
            Column(
              children: [
                // Table header (like web)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Service',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Category',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Budget',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Personnel',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        child: Text(
                          '',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ), // Delete column
                    ],
                  ),
                ),

                // Services rows (like web table)
                ...agreedServices.asMap().entries.map((entry) {
                  final index = entry.key;
                  final service = entry.value;
                  final isNewService =
                      service['_id'] ==
                      null; // Check if this is a locally added service

                  return Container(
                    margin: const EdgeInsets.only(top: 1),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isNewService
                          ? CupertinoColors.systemBlue.withOpacity(
                              0.05,
                            ) // Highlight new services
                          : CupertinoColors.systemBackground,
                      border: Border.all(
                        color: isNewService
                            ? CupertinoColors.systemBlue.withOpacity(0.3)
                            : CupertinoColors.systemGrey4,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service['serviceName'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isNewService
                                      ? CupertinoColors.systemBlue
                                      : CupertinoColors.label,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_formatDate(service['startDate'])} - ${_formatDate(service['endDate'])}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            service['serviceCategory'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.label,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '₹${service['serviceBudget']?.toString() ?? '0'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.label,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            service['personnel']?.toString() ?? '0',
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.label,
                            ),
                          ),
                        ),
                        Container(
                          width: 40,
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => _removeAgreedService(index),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemRed.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                CupertinoIcons.xmark,
                                size: 16,
                                color: CupertinoColors.systemRed,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 20),

                // Summary footer (like web)
                if (agreedServices.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Services: ${agreedServices.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),

                        if (_hasUnsavedChanges())
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Click "Update Agreed Services" to save changes',
                              style: TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.systemOrange,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // Helper method to format dates
  String _formatDate(dynamic date) {
    if (date == null) return 'Not set';

    DateTime dateTime;
    if (date is DateTime) {
      dateTime = date;
    } else if (date is String) {
      try {
        dateTime = DateTime.parse(date);
      } catch (e) {
        return 'Invalid date';
      }
    } else {
      return 'Invalid date';
    }

    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
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
