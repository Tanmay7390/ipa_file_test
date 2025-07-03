import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:flutter_test_22/components/form_fields.dart';
import '../../apis/providers/customer_provider.dart';
import '../../auth/components/auth_provider.dart';
import '../../apis/core/dio_provider.dart';
import '../../apis/core/api_urls.dart';
import '../components/addresses_bottom_sheet.dart';

class CustomerForm extends ConsumerStatefulWidget {
  final String? customerId;
  final Map<String, dynamic>? initialData; // this for pre-filling data

  const CustomerForm({super.key, this.customerId, this.initialData});

  @override
  ConsumerState<CustomerForm> createState() => _CustomerFormState();
}

enum PartyType { customer, supplier }

class _CustomerFormState extends ConsumerState<CustomerForm> {
  PartyType _selectedPartyType = PartyType.customer; // Moved here
  final Map<String, dynamic> formData = {};
  final Map<String, String> validationErrors = {};
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _sameAsBilling = false;
  bool get isEditMode => widget.customerId != null;

  // Data lists from API
  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _currencies = [];
  Map<String, String> _validationErrors = {};

  // Track if initial data has been prefilled
  bool _hasPrefilledData = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // Load dropdown data first
      await Future.wait([_loadCountries(), _loadStates(), _loadCurrencies()]);

      // If in edit mode, fetch customer data
      if (isEditMode && widget.customerId != null) {
        await _loadCustomerData(widget.customerId!);
      } else if (widget.initialData != null) {
        // If initial data is provided, prefill it
        _prefillFormData();
      }
    } catch (e) {
      log('Error loading initial data: $e');
      _showErrorDialog('Failed to load form data. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  // ADD THIS METHOD TO FETCH CUSTOMER DATA IN EDIT MODE
  Future<void> _loadCustomerData(String customerId) async {
    try {
      log('Loading customer data for ID: $customerId');

      final customerActions = ref.read(customerActionsProvider);
      final result = await customerActions.getCustomer(customerId);

      if (result.success && result.data != null) {
        log('Customer data loaded: ${result.data}');

        // Set the fetched data and prefill the form
        setState(() {
          // Don't override widget.initialData, create a local copy
          _prefillFormDataFromApi(result.data!);
        });
      } else {
        log('Failed to load customer data: ${result.error}');
        _showErrorDialog(
          'Failed to load customer data: ${result.error ?? "Unknown error"}',
        );
      }
    } catch (e) {
      log('Error loading customer data: $e');
      _showErrorDialog('Error loading customer data: $e');
    }
  }

  // ADD THIS METHOD TO PREFILL FROM API DATA
  void _prefillFormDataFromApi(Map<String, dynamic> customerData) {
    log('Prefilling form data from API with: $customerData');

    // Determine party type based on flags
    if (customerData['isVendor'] == true) {
      _selectedPartyType = PartyType.supplier;
    } else {
      _selectedPartyType = PartyType.customer;
    }

    // Basic information
    formData['name'] = customerData['name'] ?? '';
    formData['legalName'] = customerData['legalName'] ?? '';
    formData['contactName'] = customerData['contactName'] ?? '';
    formData['whatsAppNumber'] = customerData['whatsAppNumber'] ?? '';
    formData['website'] = customerData['website'] ?? '';

    // Handle email array
    if (customerData['email'] is List &&
        (customerData['email'] as List).isNotEmpty) {
      formData['email'] = customerData['email'][0];
    }

    // Registration details
    formData['registrationNo'] = customerData['registrationNo'] ?? '';
    formData['panNumber'] = customerData['taxIdentificationNumber1'] ?? '';
    formData['gstNumber'] = customerData['taxIdentificationNumber2'] ?? '';

    // Handle country of registration
    if (customerData['countryOfRegistration'] != null) {
      final countryData = customerData['countryOfRegistration'];
      if (countryData is Map) {
        formData['registrationCountry'] = countryData['name'] ?? '';
        formData['registrationCountryId'] = countryData['_id'] ?? '';
      }
    }

    // Add bank account fields for supplier
    if (_selectedPartyType == PartyType.supplier) {
      formData['upiId'] = customerData['upiId'] ?? '';
      formData['gPayPhone'] = customerData['gPayPhone'] ?? '';

      // Handle bank accounts if present
      if (customerData['bankAccounts'] != null &&
          customerData['bankAccounts'].isNotEmpty) {
        final bankAccount = customerData['bankAccounts'][0];
        formData['accountName'] = bankAccount['accountName'] ?? '';
        formData['accountNumber'] =
            bankAccount['accountNumber']?.toString() ?? '';
        formData['bankName'] = bankAccount['bankName'] ?? '';
        formData['branchName'] = bankAccount['branchName'] ?? '';
        formData['ifscCode'] = bankAccount['IFSC'] ?? '';

        // Handle currency
        if (bankAccount['currency'] is Map) {
          formData['currency'] = bankAccount['currency']['name'] ?? '';
          formData['currencyId'] = bankAccount['currency']['_id'] ?? '';
        } else if (bankAccount['currency'] is String) {
          // If it's just the ID, find the matching currency
          final currency = _currencies.firstWhere(
            (c) => c['_id'] == bankAccount['currency'],
            orElse: () => {},
          );
          if (currency.isNotEmpty) {
            formData['currency'] = currency['name'] ?? '';
            formData['currencyId'] = currency['_id'] ?? '';
          }
        }
      }
    }

    // Handle addresses - Map API data to form fields
    if (customerData['addresses'] is List) {
      final addresses = customerData['addresses'] as List;

      // Find billing address
      final billingAddress = addresses.firstWhere(
        (addr) => addr['type'] == 'Billing',
        orElse: () => null,
      );

      if (billingAddress != null) {
        formData['billingAddressLine1'] = billingAddress['line1'] ?? '';
        formData['billingAddressLine2'] = billingAddress['line2'] ?? '';
        formData['billingAddressCity'] = billingAddress['city'] ?? '';
        formData['billingAddressPinCode'] =
            billingAddress['code']?.toString() ?? '';

        // Handle billing country
        if (billingAddress['country'] is Map) {
          formData['billingAddressCountry'] =
              billingAddress['country']['name'] ?? '';
          formData['billingAddressCountryId'] =
              billingAddress['country']['_id'] ?? '';
        }

        // Handle billing state
        if (billingAddress['state'] is Map) {
          formData['billingAddressState'] =
              billingAddress['state']['name'] ?? '';
          formData['billingAddressStateId'] =
              billingAddress['state']['_id'] ?? '';
        }
      }

      // Find shipping address
      final shippingAddress = addresses.firstWhere(
        (addr) => addr['type'] == 'Shipping',
        orElse: () => null,
      );

      if (shippingAddress != null) {
        formData['shippingAddressLine1'] = shippingAddress['line1'] ?? '';
        formData['shippingAddressLine2'] = shippingAddress['line2'] ?? '';
        formData['shippingAddressCity'] = shippingAddress['city'] ?? '';
        formData['shippingAddressPinCode'] =
            shippingAddress['code']?.toString() ?? '';

        // Handle shipping country
        if (shippingAddress['country'] is Map) {
          formData['shippingAddressCountry'] =
              shippingAddress['country']['name'] ?? '';
          formData['shippingAddressCountryId'] =
              shippingAddress['country']['_id'] ?? '';
        }

        // Handle shipping state
        if (shippingAddress['state'] is Map) {
          formData['shippingAddressState'] =
              shippingAddress['state']['name'] ?? '';
          formData['shippingAddressStateId'] =
              shippingAddress['state']['_id'] ?? '';
        }

        // Check if shipping address is same as billing
        _sameAsBilling = _isAddressSame(billingAddress, shippingAddress);
      }
    }

    // Update address display strings
    _updateAddressDisplayStrings();

    // Mark as prefilled
    _hasPrefilledData = true;

    log('Form data after prefilling from API: $formData');
  }

  void _prefillFormData() {
    // Only prefill once and only if we have initial data and dropdown data is loaded
    if (_hasPrefilledData || widget.initialData == null || _countries.isEmpty) {
      return;
    }

    log('Prefilling form data with: ${widget.initialData}');

    setState(() {
      final data = widget.initialData!;

      // Determine party type based on flags
      if (data['isVendor'] == true) {
        _selectedPartyType = PartyType.supplier;
      } else {
        _selectedPartyType = PartyType.customer;
      }

      // Basic information
      formData['name'] = data['name'] ?? '';
      formData['legalName'] = data['legalName'] ?? '';
      formData['contactName'] = data['contactName'] ?? '';
      formData['whatsAppNumber'] = data['whatsAppNumber'] ?? '';
      formData['website'] = data['website'] ?? '';

      // Handle email array
      if (data['email'] is List && (data['email'] as List).isNotEmpty) {
        formData['email'] = data['email'][0];
      }

      // Registration details
      formData['registrationNo'] = data['registrationNo'] ?? '';
      formData['panNumber'] = data['taxIdentificationNumber1'] ?? '';
      formData['gstNumber'] = data['taxIdentificationNumber2'] ?? '';

      // Handle country of registration
      if (data['countryOfRegistration'] != null) {
        final countryData = data['countryOfRegistration'];
        if (countryData is Map) {
          formData['registrationCountry'] = countryData['name'] ?? '';
          formData['registrationCountryId'] = countryData['_id'] ?? '';
        }
      }

      // Add bank account fields for supplier
      if (_selectedPartyType == PartyType.supplier) {
        formData['upiId'] = data['upiId'] ?? '';
        formData['gPayPhone'] = data['gPayPhone'] ?? '';

        // Handle bank accounts if present
        if (data['bankAccounts'] != null && data['bankAccounts'].isNotEmpty) {
          final bankAccount = data['bankAccounts'][0];
          formData['accountName'] = bankAccount['accountName'] ?? '';
          formData['accountNumber'] =
              bankAccount['accountNumber']?.toString() ?? '';
          formData['bankName'] = bankAccount['bankName'] ?? '';
          formData['branchName'] = bankAccount['branchName'] ?? '';
          formData['ifscCode'] = bankAccount['IFSC'] ?? '';

          // Handle currency
          if (bankAccount['currency'] is Map) {
            formData['currency'] = bankAccount['currency']['name'] ?? '';
            formData['currencyId'] = bankAccount['currency']['_id'] ?? '';
          } else if (bankAccount['currency'] is String) {
            // If it's just the ID, find the matching currency
            final currency = _currencies.firstWhere(
              (c) => c['_id'] == bankAccount['currency'],
              orElse: () => {},
            );
            if (currency.isNotEmpty) {
              formData['currency'] = currency['name'] ?? '';
              formData['currencyId'] = currency['_id'] ?? '';
            }
          }
        }
      }

      // Handle addresses - Map API data to form fields
      if (data['addresses'] is List) {
        final addresses = data['addresses'] as List;

        // Find billing address
        final billingAddress = addresses.firstWhere(
          (addr) => addr['type'] == 'Billing',
          orElse: () => null,
        );

        if (billingAddress != null) {
          formData['billingAddressLine1'] = billingAddress['line1'] ?? '';
          formData['billingAddressLine2'] = billingAddress['line2'] ?? '';
          formData['billingAddressCity'] = billingAddress['city'] ?? '';
          formData['billingAddressPinCode'] =
              billingAddress['code']?.toString() ?? '';

          // Handle billing country
          if (billingAddress['country'] is Map) {
            formData['billingAddressCountry'] =
                billingAddress['country']['name'] ?? '';
            formData['billingAddressCountryId'] =
                billingAddress['country']['_id'] ?? '';
          }

          // Handle billing state
          if (billingAddress['state'] is Map) {
            formData['billingAddressState'] =
                billingAddress['state']['name'] ?? '';
            formData['billingAddressStateId'] =
                billingAddress['state']['_id'] ?? '';
          }
        }

        // Find shipping address
        final shippingAddress = addresses.firstWhere(
          (addr) => addr['type'] == 'Shipping',
          orElse: () => null,
        );

        if (shippingAddress != null) {
          formData['shippingAddressLine1'] = shippingAddress['line1'] ?? '';
          formData['shippingAddressLine2'] = shippingAddress['line2'] ?? '';
          formData['shippingAddressCity'] = shippingAddress['city'] ?? '';
          formData['shippingAddressPinCode'] =
              shippingAddress['code']?.toString() ?? '';

          // Handle shipping country
          if (shippingAddress['country'] is Map) {
            formData['shippingAddressCountry'] =
                shippingAddress['country']['name'] ?? '';
            formData['shippingAddressCountryId'] =
                shippingAddress['country']['_id'] ?? '';
          }

          // Handle shipping state
          if (shippingAddress['state'] is Map) {
            formData['shippingAddressState'] =
                shippingAddress['state']['name'] ?? '';
            formData['shippingAddressStateId'] =
                shippingAddress['state']['_id'] ?? '';
          }

          // Check if shipping address is same as billing
          _sameAsBilling = _isAddressSame(billingAddress, shippingAddress);
        }
      }

      // Update address display strings
      _updateAddressDisplayStrings();

      // Mark as prefilled
      _hasPrefilledData = true;

      log('Form data after prefilling: $formData');
    });
  }

  // Add this method to handle party type changes
  void _onPartyTypeChanged(PartyType? newType) {
    if (newType == null) return;

    setState(() {
      _selectedPartyType = newType;

      // Clear bank account fields when switching to customer
      if (newType == PartyType.customer) {
        formData.remove('upiId');
        formData.remove('gPayPhone');
        formData.remove('accountName');
        formData.remove('accountNumber');
        formData.remove('bankName');
        formData.remove('branchName');
        formData.remove('ifscCode');
        formData.remove('currency');
        formData.remove('currencyId');
      }
    });
  }

  bool _isAddressSame(
    Map<String, dynamic>? billing,
    Map<String, dynamic>? shipping,
  ) {
    if (billing == null || shipping == null) return false;

    return billing['line1'] == shipping['line1'] &&
        billing['line2'] == shipping['line2'] &&
        billing['city'] == shipping['city'] &&
        billing['code'] == shipping['code'] &&
        billing['country']?['_id'] == shipping['country']?['_id'] &&
        billing['state']?['_id'] == shipping['state']?['_id'];
  }

  Future<void> _loadCurrencies() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(ApiUrls.currencies);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        if (data is Map && data['currencies'] != null) {
          setState(() {
            _currencies = List<Map<String, dynamic>>.from(data['currencies']);
          });
          log('Currencies loaded: ${_currencies.length}');
        }
      }
    } catch (e) {
      log('Error loading currencies: $e');
      // Provide fallback data
      _currencies = [
        {
          "_id": "62a4b0ceb628fb10ac97ce0e",
          "code": "INR",
          "name": "Rupee",
          "country": {"_id": "6294a09293c5957e81702e19", "name": "India"},
        },
      ];
    }
  }

  Future<void> _loadCountries() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(ApiUrls.countries);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        // Handle the actual API response structure
        if (data is Map && data['countries'] != null) {
          setState(() {
            _countries = List<Map<String, dynamic>>.from(data['countries']);
          });
          log('Countries loaded: ${_countries.length}');
        } else if (data is Map &&
            data['success'] == true &&
            data['data'] != null) {
          // Fallback for the old structure
          setState(() {
            _countries = List<Map<String, dynamic>>.from(data['data']);
          });
          log('Countries loaded: ${_countries.length}');
        } else if (data is List) {
          // Direct array response
          setState(() {
            _countries = List<Map<String, dynamic>>.from(data);
          });
          log('Countries loaded: ${_countries.length}');
        }
      }
    } catch (e) {
      log('Error loading countries: $e');
      // Provide fallback data
      _countries = [
        {
          "_id": "6294a09293c5957e81702e19",
          "name": "India",
          "code1": "IN",
          "code2": "+91",
        },
      ];
    }
  }

  Future<void> _loadStates() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(ApiUrls.states);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        // Handle the actual API response structure
        if (data is Map && data['states'] != null) {
          setState(() {
            _states = List<Map<String, dynamic>>.from(data['states']);
          });
          log('States loaded: ${_states.length}');
        } else if (data is Map &&
            data['success'] == true &&
            data['data'] != null) {
          // Fallback for the old structure
          setState(() {
            _states = List<Map<String, dynamic>>.from(data['data']);
          });
          log('States loaded: ${_states.length}');
        } else if (data is List) {
          // Direct array response
          setState(() {
            _states = List<Map<String, dynamic>>.from(data);
          });
          log('States loaded: ${_states.length}');
        }
      }
    } catch (e) {
      log('Error loading states: $e');
      // Provide fallback data
      _states = [
        {
          "_id": "64418308ed36956a1d4fef2a",
          "name": "Maharashtra",
          "tin": "27",
          "stateCode": "MH",
        },
      ];
    }
  }

  void _updateFormDataWithMapping(
    String key,
    String displayValue,
    String idValue,
  ) {
    setState(() {
      formData[key] = displayValue; // Store display name for UI
      formData['${key}Id'] = idValue; // Store ID for API
      validationErrors.remove(key);
    });
    log('Form data updated: $key = $displayValue (ID: $idValue)');
    log('Full form data after update: $formData');
  }

  void _updateFormData(String key, dynamic value) {
    setState(() {
      formData[key] = value;
      validationErrors.remove(key);
    });
    log('Form data updated: $key = $value');
    log('Current form data: $formData');
  }

  // Address helper methods
  void _updateAddressDisplayStrings() {
    // Update billing address display string
    if (_hasAddressData('billingAddress')) {
      formData['billingAddress'] = _formatBillingAddress(formData);
    }

    // Update shipping address display string
    if (_hasAddressData('shippingAddress')) {
      formData['shippingAddress'] = _formatShippingAddress(formData);
    }
  }

  bool _hasAddressData(String addressType) {
    if (addressType == 'billingAddress') {
      final line1 = formData['billingAddressLine1']?.toString().trim();
      final city = formData['billingAddressCity']?.toString().trim();
      final country = formData['billingAddressCountry']?.toString().trim();
      final pincode = formData['billingAddressPinCode']?.toString().trim();

      log('Checking billing address data:');
      log('  line1: "$line1"');
      log('  city: "$city"');
      log('  country: "$country"');
      log('  pincode: "$pincode"');

      return (line1?.isNotEmpty ?? false) &&
          (city?.isNotEmpty ?? false) &&
          (country?.isNotEmpty ?? false) &&
          (pincode?.isNotEmpty ?? false);
    } else if (addressType == 'shippingAddress') {
      final line1 = formData['shippingAddressLine1']?.toString().trim();
      final city = formData['shippingAddressCity']?.toString().trim();
      final country = formData['shippingAddressCountry']?.toString().trim();
      final pincode = formData['shippingAddressPinCode']?.toString().trim();

      log('Checking shipping address data:');
      log('  line1: "$line1"');
      log('  city: "$city"');
      log('  country: "$country"');
      log('  pincode: "$pincode"');

      return (line1?.isNotEmpty ?? false) &&
          (city?.isNotEmpty ?? false) &&
          (country?.isNotEmpty ?? false) &&
          (pincode?.isNotEmpty ?? false);
    }
    return false;
  }

  String _formatBillingAddress(Map<String, dynamic> addressData) {
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

  String _formatShippingAddress(Map<String, dynamic> addressData) {
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

  void _showAddressForm(String addressType) {
    log('Opening address form for: $addressType');
    log('Current formData before address form: $formData');

    if (addressType == 'billingAddress') {
      AddressBottomSheetService.showBillingAddressBottomSheet(
        context: context,
        ref: ref,
        initialData: formData,
        onAddressSelected: (addressData) {
          log('Billing address selected with data: $addressData');

          setState(() {
            // Merge the address data
            formData.addAll(addressData);

            log('FormData after billing address merge: $formData');

            // Update display strings
            _updateAddressDisplayStrings();

            // If same as billing is checked, copy to shipping
            if (_sameAsBilling) {
              log('Copying billing to shipping because _sameAsBilling is true');
              _copyBillingToShipping();
            }
          });

          log('Final formData after billing address processing: $formData');
        },
      );
    } else if (addressType == 'shippingAddress') {
      AddressBottomSheetService.showShippingAddressBottomSheet(
        context: context,
        ref: ref,
        initialData: formData,
        onAddressSelected: (addressData) {
          log('Shipping address selected with data: $addressData');

          setState(() {
            // Merge the address data
            formData.addAll(addressData);

            log('FormData after shipping address merge: $formData');

            // Update display strings
            _updateAddressDisplayStrings();
          });

          log('Final formData after shipping address processing: $formData');
        },
      );
    }
  }

  void _toggleSameAsBilling(bool value) {
    setState(() {
      _sameAsBilling = value;

      if (value) {
        _copyBillingToShipping();
      } else {
        // Clear shipping address when unchecked
        formData.remove('shippingAddressLine1');
        formData.remove('shippingAddressLine2');
        formData.remove('shippingAddressCity');
        formData.remove('shippingAddressState');
        formData.remove('shippingAddressStateId');
        formData.remove('shippingAddressCountry');
        formData.remove('shippingAddressCountryId');
        formData.remove('shippingAddressPinCode');
        formData.remove('shippingAddress');

        log('Cleared shipping address data');
      }
    });
  }

  void _copyBillingToShipping() {
    log('Copying billing address to shipping address...');
    log('Before copy - billing data:');
    log('  billingAddressLine1: "${formData['billingAddressLine1']}"');
    log('  billingAddressCity: "${formData['billingAddressCity']}"');
    log('  billingAddressCountry: "${formData['billingAddressCountry']}"');

    // Copy billing address to shipping address (both display names and IDs)
    formData['shippingAddressLine1'] = formData['billingAddressLine1'] ?? '';
    formData['shippingAddressLine2'] = formData['billingAddressLine2'] ?? '';
    formData['shippingAddressCity'] = formData['billingAddressCity'] ?? '';
    formData['shippingAddressState'] = formData['billingAddressState'] ?? '';
    formData['shippingAddressStateId'] =
        formData['billingAddressStateId'] ?? '';
    formData['shippingAddressCountry'] =
        formData['billingAddressCountry'] ?? '';
    formData['shippingAddressCountryId'] =
        formData['billingAddressCountryId'] ?? '';
    formData['shippingAddressPinCode'] =
        formData['billingAddressPinCode'] ?? '';

    _updateAddressDisplayStrings();

    log('After copy - shipping data:');
    log('  shippingAddressLine1: "${formData['shippingAddressLine1']}"');
    log('  shippingAddressCity: "${formData['shippingAddressCity']}"');
    log('  shippingAddressCountry: "${formData['shippingAddressCountry']}"');
    log('Complete formData after copy: $formData');
  }

  Widget _buildAddressButton(String text, String addressType, bool isRequired) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: CupertinoButton(
        onPressed: () => _showAddressForm(addressType),
        padding: EdgeInsets.zero,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _validationErrors.containsKey(addressType)
                  ? CupertinoColors.systemRed
                  : CupertinoColors.systemGrey4,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: CupertinoColors.systemBackground,
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.location,
                color: CupertinoColors.systemGrey,
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _hasAddressData(addressType) ? 'Address Added' : text,
                  style: TextStyle(
                    color: _hasAddressData(addressType)
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

  Widget _buildSameAsBillingCheckbox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: () => _toggleSameAsBilling(!_sameAsBilling),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _sameAsBilling
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.systemGrey3,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
                color: _sameAsBilling
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemBackground,
              ),
              child: _sameAsBilling
                  ? const Icon(
                      CupertinoIcons.check_mark,
                      size: 16,
                      color: CupertinoColors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleSameAsBilling(!_sameAsBilling),
              child: const Text(
                'Same as billing address',
                style: TextStyle(fontSize: 16, color: CupertinoColors.label),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _validateForm() {
    validationErrors.clear();

    void checkRequired(String key, String label) {
      if (formData[key]?.toString().trim().isEmpty ?? true) {
        validationErrors[key] = '$label is required';
      }
    }

    // Required fields validation
    checkRequired('name', 'Name');

    // Enhanced billing address validation
    log('Validating billing address...');
    if (!_hasAddressData('billingAddress')) {
      validationErrors['billingAddress'] = 'Billing address is required';
      log('Billing address validation failed - marking as required');

      // Log what we actually have for debugging
      log('Current billing address data in formData:');
      [
        'billingAddressLine1',
        'billingAddressCity',
        'billingAddressCountry',
        'billingAddressPinCode',
      ].forEach((key) {
        log('  $key: "${formData[key]}"');
      });
    } else {
      log('Billing address validation passed');
    }

    // Email validation if provided
    if (formData['email']?.toString().isNotEmpty == true) {
      final emailPattern = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
      if (!emailPattern.hasMatch(formData['email'])) {
        validationErrors['email'] = 'Please enter a valid email address';
      }
    }

    // Phone validation if provided
    // if (formData['whatsAppNumber']?.toString().isNotEmpty == true) {
    //   final phonePattern = RegExp(r'^\d{10}$');
    //   if (!phonePattern.hasMatch(formData['whatsAppNumber'])) {
    //     validationErrors['whatsAppNumber'] =
    //         'Please enter a valid 10-digit phone number';
    //   }
    // }

    log('Final validation errors: $validationErrors');
    return validationErrors.isEmpty;
  }

  Future<void> _saveForm() async {
    log('Save form called - ${isEditMode ? 'Edit' : 'Create'} mode');
    log('Current form data: $formData');
    log('Customer ID: ${widget.customerId}'); // ADD THIS LOG

    if (!_validateForm()) {
      log('Form validation failed: $validationErrors');
      setState(() {});
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ref.read(authProvider);
      final accountId = authState.accountId;

      log('Account ID: $accountId');

      if (accountId == null) {
        _showErrorDialog('No account ID found. Please login again.');
        return;
      }

      // Build customer data map
      final customerData = _buildCustomerData(accountId);
      log('Customer data to be sent: $customerData');

      // Call API based on mode
      final customerActions = ref.read(customerActionsProvider);
      final ApiResponse<Map<String, dynamic>> result;

      if (isEditMode) {
        log('Calling updateCustomer API with ID: ${widget.customerId}');
        result = await customerActions.updateCustomer(
          widget.customerId!,
          customerData,
        );
      } else {
        log('Calling createCustomer API...');
        result = await customerActions.createCustomer(customerData);
      }

      log(
        'API result: ${result.success}, message: ${result.message}, error: ${result.error}',
      );

      if (result.success && result.data != null) {
        // Update local state
        if (isEditMode) {
          ref.read(customerListProvider.notifier).updateCustomer(result.data!);
          log('Customer updated in local state');
        } else {
          ref.read(customerListProvider.notifier).addCustomer(result.data!);
          log('Customer added to local state');
        }

        // Show success dialog
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: const Text('Success'),
              content: Text(
                result.message ??
                    '${isEditMode ? 'Customer updated' : 'Customer created'} successfully!',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context)
                    ..pop()
                    ..pop(),
                ),
              ],
            ),
          );
        }
      } else {
        log('API call failed: ${result.error}');
        _showErrorDialog(
          result.error ??
              'Failed to ${isEditMode ? 'update' : 'create'} customer',
        );
      }
    } catch (e, stackTrace) {
      log('Error ${isEditMode ? 'updating' : 'creating'} customer: $e');
      log('Stack trace: $stackTrace');
      _showErrorDialog(
        'An error occurred while ${isEditMode ? 'updating' : 'creating'} customer: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _buildCustomerData(String accountId) {
    log('Building customer data with formData: $formData');
    log('Checking address data before building customer data...');

    // Check billing address data availability
    final hasBillingAddress = _hasAddressData('billingAddress');
    log('Has billing address: $hasBillingAddress');

    // Check shipping address data availability
    final hasShippingAddress = _hasAddressData('shippingAddress');
    log('Has shipping address: $hasShippingAddress');
    log('Same as billing: $_sameAsBilling');

    // CRITICAL FIX: Ensure proper boolean values are sent
    final isSupplier = _selectedPartyType == PartyType.supplier;
    final isCustomer = _selectedPartyType == PartyType.customer;

    log('Party Type Determination:');
    log('_selectedPartyType: ${_selectedPartyType.name}');
    log('isSupplier: $isSupplier');
    log('isCustomer: $isCustomer');

    // Build the base customer data
    final customerData = <String, dynamic>{
      "counterPartyOfAccount": accountId,
      "isVendor": isSupplier,
      "isClient": isCustomer,
      "isAgent": false,
      "name": formData['name'],
      "legalName": formData['legalName']?.toString().isEmpty == true
          ? formData['name']
          : formData['legalName'],
      "isActive": true,
      "businessType": <String>[],
      "registrationNo": formData['registrationNo'] ?? '',
      "taxIdentificationNumber1": formData['panNumber'] ?? '',
      "taxIdentificationNumber2": formData['gstNumber'] ?? '',
      "contactName": formData['contactName'] ?? '',
      "website": formData['website'] ?? '',
      "email": formData['email']?.toString().isEmpty == true
          ? <String>[]
          : <String>[formData['email']],
      "whatsAppNumber": formData['whatsAppNumber'] ?? '',
      "countryOfRegistration":
          formData['registrationCountryId'] ?? formData['registrationCountry'],
      "status": "Active",
      "buyerSellerAgent": isSupplier ? "Seller" : "Buyer",
      "displayName": formData['name'] ?? '',
      "logo": "",
      "buyer": <String>[],
      "supplier": <String>[],
      "attachments": <String>[],
      "documentSettings": <String>[],
      "agreedServices": <String>[],
    };

    // ADD BILLING ADDRESS DATA AS FLAT FIELDS (like website)
    if (hasBillingAddress) {
      customerData["billingAddressLine1"] =
          (formData['billingAddressLine1'] ?? '').toString().trim();
      customerData["billingAddressLine2"] =
          (formData['billingAddressLine2'] ?? '').toString().trim();
      customerData["billingAddressCity"] =
          (formData['billingAddressCity'] ?? '').toString().trim();
      customerData["billingAddressPinCode"] =
          (formData['billingAddressPinCode'] ?? '').toString().trim();

      // Add billing country and state IDs
      final billingCountryId = formData['billingAddressCountryId']
          ?.toString()
          .trim();
      if (billingCountryId != null && billingCountryId.isNotEmpty) {
        customerData["billingAddressCountry"] = billingCountryId;
      }

      final billingStateId = formData['billingAddressStateId']
          ?.toString()
          .trim();
      if (billingStateId != null && billingStateId.isNotEmpty) {
        customerData["billingAddressState"] = billingStateId;
      }

      log('Added billing address as flat fields:');
      log('  billingAddressLine1: "${customerData["billingAddressLine1"]}"');
      log('  billingAddressCity: "${customerData["billingAddressCity"]}"');
      log(
        '  billingAddressCountry: "${customerData["billingAddressCountry"]}"',
      );
      log(
        '  billingAddressPinCode: "${customerData["billingAddressPinCode"]}"',
      );
    } else {
      log('WARNING: No billing address data found!');
    }

    // ADD SHIPPING ADDRESS DATA AS FLAT FIELDS (like website)
    if (_sameAsBilling || hasShippingAddress) {
      customerData["shippingAddressLine1"] =
          (formData['shippingAddressLine1'] ?? '').toString().trim();
      customerData["shippingAddressLine2"] =
          (formData['shippingAddressLine2'] ?? '').toString().trim();
      customerData["shippingAddressCity"] =
          (formData['shippingAddressCity'] ?? '').toString().trim();
      customerData["shippingAddressPinCode"] =
          (formData['shippingAddressPinCode'] ?? '').toString().trim();

      // Add shipping country and state IDs
      final shippingCountryId = formData['shippingAddressCountryId']
          ?.toString()
          .trim();
      if (shippingCountryId != null && shippingCountryId.isNotEmpty) {
        customerData["shippingAddressCountry"] = shippingCountryId;
      }

      final shippingStateId = formData['shippingAddressStateId']
          ?.toString()
          .trim();
      if (shippingStateId != null && shippingStateId.isNotEmpty) {
        customerData["shippingAddressState"] = shippingStateId;
      }

      log('Added shipping address as flat fields:');
      log('  shippingAddressLine1: "${customerData["shippingAddressLine1"]}"');
      log('  shippingAddressCity: "${customerData["shippingAddressCity"]}"');
      log(
        '  shippingAddressCountry: "${customerData["shippingAddressCountry"]}"',
      );
      log(
        '  shippingAddressPinCode: "${customerData["shippingAddressPinCode"]}"',
      );
    } else {
      log(
        'No shipping address to add (not same as billing and no explicit shipping data)',
      );
    }

    // Add supplier-specific fields
    if (isSupplier) {
      customerData["upiId"] = formData['upiId'] ?? '';
      customerData["gPayPhone"] = formData['gPayPhone'] ?? '';

      // Add bank account data if provided
      if (formData['accountName']?.toString().isNotEmpty == true ||
          formData['accountNumber']?.toString().isNotEmpty == true) {
        customerData["bankAccountDetails"] = {
          "accountName": formData['accountName'] ?? '',
          "accountNumber": formData['accountNumber'] ?? '',
          "bankName": formData['bankName'] ?? '',
          "branchName": formData['branchName'] ?? '',
          "IFSC": formData['ifscCode'] ?? '',
          "currency": formData['currencyId'] ?? '',
        };
      }
    }

    log('Final customer data with flat address format: $customerData');

    // Verify the address data is present
    log('VERIFICATION - Address fields in final payload:');
    if (customerData.containsKey('billingAddressLine1')) {
      log('✓ Billing address fields present');
      log('  billingAddressLine1: "${customerData['billingAddressLine1']}"');
      log('  billingAddressCity: "${customerData['billingAddressCity']}"');
      log(
        '  billingAddressCountry: "${customerData['billingAddressCountry']}"',
      );
    } else {
      log('✗ Billing address fields MISSING');
    }

    if (customerData.containsKey('shippingAddressLine1')) {
      log('✓ Shipping address fields present');
      log('  shippingAddressLine1: "${customerData['shippingAddressLine1']}"');
      log('  shippingAddressCity: "${customerData['shippingAddressCity']}"');
      log(
        '  shippingAddressCountry: "${customerData['shippingAddressCountry']}"',
      );
    } else {
      log('✗ Shipping address fields not included');
    }

    return customerData;
  }

  // Add this widget method for the party type selector
  Widget _buildPartyTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: CupertinoSlidingSegmentedControl<PartyType>(
              groupValue: _selectedPartyType,
              onValueChanged: _onPartyTypeChanged,
              children: const {
                PartyType.customer: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Buyer'),
                ),
                PartyType.supplier: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Supplier'),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountSection() {
    if (_selectedPartyType != PartyType.supplier) {
      return const SizedBox.shrink();
    }

    return _buildSection(title: 'BANK ACCOUNT DETAILS', [
      FormFieldWidgets.buildTextField(
        'accountName',
        'Account Holder Name',
        'text',
        context,
        onChanged: _updateFormData,
        formData: formData,
        validationErrors: validationErrors,
      ),
      FormFieldWidgets.buildTextField(
        'accountNumber',
        'Account Number',
        'number',
        context,
        onChanged: _updateFormData,
        formData: formData,
        validationErrors: validationErrors,
      ),
      FormFieldWidgets.buildTextField(
        'bankName',
        'Bank Name',
        'text',
        context,
        onChanged: _updateFormData,
        formData: formData,
        validationErrors: validationErrors,
      ),
      FormFieldWidgets.buildTextField(
        'branchName',
        'Branch Name',
        'text',
        context,
        onChanged: _updateFormData,
        formData: formData,
        validationErrors: validationErrors,
      ),
      FormFieldWidgets.buildTextField(
        'ifscCode',
        'IFSC Code',
        'text',
        context,
        onChanged: _updateFormData,
        formData: formData,
        validationErrors: validationErrors,
      ),
      FormFieldWidgets.buildSelectField(
        'currency',
        'Currency',
        _currencies
            .map((currency) => '${currency['name']} (${currency['code']})')
            .toList(),
        onChanged: (key, value) {
          log('Currency selected: $value');
          final selectedCurrency = _currencies.firstWhere(
            (currency) => '${currency['name']} (${currency['code']})' == value,
            orElse: () => _currencies.isNotEmpty ? _currencies.first : {},
          );
          _updateFormDataWithMapping(key, value, selectedCurrency['_id']);
        },
        formData: formData,
        validationErrors: validationErrors,
      ),
      FormFieldWidgets.buildTextField(
        'upiId',
        'UPI ID',
        'text',
        context,
        onChanged: _updateFormData,
        formData: formData,
        validationErrors: validationErrors,
      ),
      FormFieldWidgets.buildTextField(
        'gPayPhone',
        'GPay Phone Number',
        'phone',
        context,
        onChanged: _updateFormData,
        formData: formData,
        validationErrors: validationErrors,
      ),
    ], initiallyExpanded: false);
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('Loading...')),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          isEditMode
              ? (_selectedPartyType == PartyType.supplier
                    ? 'Edit Supplier'
                    : 'Edit Customer')
              : (_selectedPartyType == PartyType.supplier
                    ? 'New Supplier'
                    : 'New Customer'),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isLoading ? null : _saveForm,
          child: _isLoading
              ? const CupertinoActivityIndicator()
              : Text(isEditMode ? 'Update' : 'Save'),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Party Type Selector (only show if not in edit mode)
              if (!isEditMode)
                _buildSection(title: 'PARTY TYPE', [_buildPartyTypeSelector()]),

              // Basic Information Section
              _buildSection(title: 'BASIC INFORMATION', [
                FormFieldWidgets.buildTextField(
                  'name',
                  'Name',
                  'text',
                  context,
                  isRequired: true,
                  onChanged: _updateFormData,
                  formData: formData,
                  validationErrors: validationErrors,
                ),
                FormFieldWidgets.buildTextField(
                  'legalName',
                  'Legal Name',
                  'text',
                  context,
                  onChanged: _updateFormData,
                  formData: formData,
                  validationErrors: validationErrors,
                ),
                FormFieldWidgets.buildTextField(
                  'contactName',
                  'Contact Name',
                  'text',
                  context,
                  onChanged: _updateFormData,
                  formData: formData,
                  validationErrors: validationErrors,
                ),
                FormFieldWidgets.buildTextField(
                  'whatsAppNumber',
                  'WhatsApp No.',
                  'phone',
                  context,
                  onChanged: _updateFormData,
                  formData: formData,
                  validationErrors: validationErrors,
                ),
                FormFieldWidgets.buildTextField(
                  'email',
                  'Email Add.',
                  'email',
                  context,
                  onChanged: _updateFormData,
                  formData: formData,
                  validationErrors: validationErrors,
                ),
                FormFieldWidgets.buildTextField(
                  'website',
                  'Website',
                  'url',
                  context,
                  onChanged: _updateFormData,
                  formData: formData,
                  validationErrors: validationErrors,
                ),
              ]),

              // Registration & Legal Section
              _buildSection(title: 'REGISTRATION & LEGAL', [
                FormFieldWidgets.buildTextField(
                  'registrationNo',
                  'Company Reg. No.',
                  'text',
                  context,
                  onChanged: _updateFormData,
                  formData: formData,
                  validationErrors: validationErrors,
                ),
                FormFieldWidgets.buildSelectField(
                  'registrationCountry',
                  'Country of Reg.',
                  _countries
                      .map((country) => country['name'] as String)
                      .toList(),
                  onChanged: (key, value) {
                    log('Registration country selected: $value');
                    final selectedCountry = _countries.firstWhere(
                      (country) => country['name'] == value,
                      orElse: () =>
                          _countries.isNotEmpty ? _countries.first : {},
                    );
                    _updateFormDataWithMapping(
                      key,
                      value,
                      selectedCountry['_id'],
                    );
                  },
                  formData: formData,
                  validationErrors: validationErrors,
                ),
                FormFieldWidgets.buildSelectField(
                  'registrationState',
                  'State of Reg.',
                  _states.map((state) => state['name'] as String).toList(),
                  onChanged: (key, value) {
                    log('Registration state selected: $value');
                    final selectedState = _states.firstWhere(
                      (state) => state['name'] == value,
                      orElse: () => _states.isNotEmpty ? _states.first : {},
                    );
                    _updateFormDataWithMapping(
                      key,
                      value,
                      selectedState['_id'],
                    );
                  },
                  formData: formData,
                  validationErrors: validationErrors,
                ),
                FormFieldWidgets.buildTextField(
                  'panNumber',
                  'PAN No.',
                  'text',
                  context,
                  onChanged: _updateFormData,
                  formData: formData,
                  validationErrors: validationErrors,
                ),
                FormFieldWidgets.buildTextField(
                  'gstNumber',
                  'GST No.',
                  'text',
                  context,
                  onChanged: _updateFormData,
                  formData: formData,
                  validationErrors: validationErrors,
                ),
              ], initiallyExpanded: false),

              // Bank Account Section (only for suppliers)
              _buildBankAccountSection(),

              // Billing Address Section Header
              _buildSection(
                title: 'BILLING ADDRESS',
                [],
                initiallyExpanded: false,
              ),
 
              // Billing Address Button (outside section)
              _buildAddressButton(
                'Add Billing Address +',
                'billingAddress',
                true,
              ),

              // Display Current Billing Address if added
              if (_hasAddressData('billingAddress'))
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
                            'Billing Address:',
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
                        _formatBillingAddress(formData),
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),

              // Shipping Address Section Header
              _buildSection(
                title: 'SHIPPING ADDRESS',
                [],
                initiallyExpanded: false,
              ),

              // Show "Same as billing" checkbox only after billing address is added
              if (_hasAddressData('billingAddress'))
                _buildSameAsBillingCheckbox(),

              // Shipping Address Button (outside section, only if not same as billing)
              if (!_sameAsBilling)
                _buildAddressButton(
                  'Add Shipping Address +',
                  'shippingAddress',
                  false,
                ),

              // Display Current Shipping Address if added or copied from billing
              if (_hasAddressData('shippingAddress') || _sameAsBilling)
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
                            'Shipping Address:',
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
                        _sameAsBilling
                            ? _formatBillingAddress(formData)
                            : _formatShippingAddress(formData),
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

class CollapsibleSection extends StatefulWidget {
  final List<Widget> fields;
  final String title;
  final bool compact;
  final bool initiallyExpanded;

  const CollapsibleSection({
    super.key,
    required this.fields,
    this.title = '',
    this.compact = false,
    this.initiallyExpanded = true,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _iconAnimation;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title.isNotEmpty)
          GestureDetector(
            onTap: widget.fields.isNotEmpty ? _toggleExpansion : null,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 16,
                bottom: 8,
                top: 8,
              ),
              child: Transform.translate(
                offset: const Offset(-4, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SF Pro Display',
                          letterSpacing: 0.25,
                          fontSize: 13,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                    if (widget.fields.isNotEmpty)
                      AnimatedBuilder(
                        animation: _iconAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _iconAnimation.value * 3.14159,
                            child: const Icon(
                              CupertinoIcons.chevron_right,
                              size: 16,
                              color: CupertinoColors.systemGrey2,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        if (widget.fields.isNotEmpty)
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: -1.0,
            child: CupertinoListSection(
              backgroundColor: CupertinoColors.systemBackground.resolveFrom(
                context,
              ),
              dividerMargin: widget.compact ? 0 : 100,
              margin: EdgeInsets.zero,
              topMargin: 0,
              additionalDividerMargin: widget.compact ? 0 : 30,
              children: widget.fields,
            ),
          ),
      ],
    );
  }
}

// Helper method to build sections
Widget _buildSection(
  List<Widget> fields, {
  String title = '',
  bool compact = false,
  bool initiallyExpanded = true,
}) {
  return CollapsibleSection(
    fields: fields,
    title: title,
    compact: compact,
    initiallyExpanded: initiallyExpanded,
  );
}
