import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../apis/core/dio_provider.dart';
import '../apis/core/api_urls.dart';
import 'form_fields.dart';

// Address type enum
enum AddressType { billing, shipping }

// Countries and states providers
final countriesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get(ApiUrls.countries);
    return List<Map<String, dynamic>>.from(response.data['countries'] ?? []);
  } catch (e) {
    throw Exception('Failed to load countries: $e');
  }
});

final statesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      countryId,
    ) async {
      final dio = ref.read(dioProvider);
      try {
        final response = await dio.get(
          '${ApiUrls.states}?country_id=$countryId',
        );
        return List<Map<String, dynamic>>.from(response.data['states'] ?? []);
      } catch (e) {
        throw Exception('Failed to load states: $e');
      }
    });

// Address data provider
final addressDataProvider =
    StateProvider.family<Map<String, dynamic>, AddressType>((ref, type) => {});

// Address Bottom Sheet Service
class AddressBottomSheetService {
  static void showBillingAddressBottomSheet({
    required BuildContext context,
    required WidgetRef ref,
    Map<String, dynamic>? initialData,
    required Function(Map<String, dynamic>) onAddressSelected,
  }) {
    _showAddressBottomSheet(
      context: context,
      ref: ref,
      type: AddressType.billing,
      initialData: initialData,
      onAddressSelected: onAddressSelected,
    );
  }

  static void showShippingAddressBottomSheet({
    required BuildContext context,
    required WidgetRef ref,
    Map<String, dynamic>? initialData,
    required Function(Map<String, dynamic>) onAddressSelected,
  }) {
    _showAddressBottomSheet(
      context: context,
      ref: ref,
      type: AddressType.shipping,
      initialData: initialData,
      onAddressSelected: onAddressSelected,
    );
  }

  static void _showAddressBottomSheet({
    required BuildContext context,
    required WidgetRef ref,
    required AddressType type,
    Map<String, dynamic>? initialData,
    required Function(Map<String, dynamic>) onAddressSelected,
  }) {
    // Initialize with existing data if provided
    if (initialData != null) {
      ref.read(addressDataProvider(type).notifier).state =
          Map<String, dynamic>.from(initialData);
    } else {
      ref.read(addressDataProvider(type).notifier).state = {};
    }

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) =>
          AddressBottomSheet(type: type, onAddressSelected: onAddressSelected),
    );
  }
}

// Address Bottom Sheet Widget
class AddressBottomSheet extends ConsumerStatefulWidget {
  final AddressType type;
  final Function(Map<String, dynamic>) onAddressSelected;

  const AddressBottomSheet({
    Key? key,
    required this.type,
    required this.onAddressSelected,
  }) : super(key: key);

  @override
  ConsumerState<AddressBottomSheet> createState() => _AddressBottomSheetState();
}

class _AddressBottomSheetState extends ConsumerState<AddressBottomSheet> {
  Map<String, dynamic> formData = {};
  Map<String, String> validationErrors = {};

  String? selectedCountryId;
  String? selectedStateId;
  List<String> countryOptions = [];
  List<String> stateOptions = [];
  Map<String, String> countryIdMap = {}; // name -> id mapping
  Map<String, String> stateIdMap = {}; // name -> id mapping

  @override
  void initState() {
    super.initState();
    final initialData = ref.read(addressDataProvider(widget.type));

    // Initialize form data
    formData = Map<String, dynamic>.from(initialData);

    // Load countries on init
    _loadCountries();
  }

  String _getPrefix() {
    return widget.type == AddressType.billing ? 'billing' : 'shipping';
  }

  String _getTitle() {
    return widget.type == AddressType.billing
        ? 'Billing Address'
        : 'Shipping Address';
  }

  void _updateFormData(String key, dynamic value) {
    setState(() {
      formData[key] = value;
      validationErrors.remove(key); // Clear validation error when user types
    });

    // Update the provider
    ref.read(addressDataProvider(widget.type).notifier).state = formData;
  }

  Future<void> _loadCountries() async {
    final countriesAsync = ref.read(countriesProvider);

    countriesAsync.when(
      data: (countries) {
        setState(() {
          countryOptions = countries.map((c) => c['name'].toString()).toList();
          countryIdMap = {
            for (var country in countries)
              country['name'].toString(): country['_id'].toString(),
          };
        });

        // If there's a pre-selected country, load its states
        final selectedCountryName = formData['${_getPrefix()}AddressCountry'];
        if (selectedCountryName != null &&
            countryIdMap.containsKey(selectedCountryName)) {
          selectedCountryId = countryIdMap[selectedCountryName];
          _loadStates(selectedCountryId!);
        }
      },
      loading: () {},
      error: (error, stack) {
        _showErrorAlert('Failed to load countries: ${error.toString()}');
      },
    );
  }

  Future<void> _loadStates(String countryId) async {
    try {
      final statesAsync = await ref.read(statesProvider(countryId).future);
      setState(() {
        stateOptions = statesAsync.map((s) => s['name'].toString()).toList();
        stateIdMap = {
          for (var state in statesAsync)
            state['name'].toString(): state['_id'].toString(),
        };
      });

      // Clear state selection if country changed
      if (selectedCountryId != countryId) {
        _updateFormData('${_getPrefix()}AddressState', null);
        selectedStateId = null;
      }

      selectedCountryId = countryId;
    } catch (e) {
      _showErrorAlert('Failed to load states: ${e.toString()}');
    }
  }

  void _onCountryChanged(String? countryName) {
    if (countryName != null && countryIdMap.containsKey(countryName)) {
      final countryId = countryIdMap[countryName]!;
      // Store both name and ID
      _updateFormData('${_getPrefix()}AddressCountry', countryName);
      _updateFormData('${_getPrefix()}AddressCountryId', countryId);

      // Clear state selection and load new states
      _updateFormData('${_getPrefix()}AddressState', null);
      _updateFormData('${_getPrefix()}AddressStateId', null);
      setState(() {
        stateOptions = [];
        stateIdMap = {};
      });

      _loadStates(countryId);
    }
  }

  void _onStateChanged(String? stateName) {
    if (stateName != null && stateIdMap.containsKey(stateName)) {
      final stateId = stateIdMap[stateName]!;
      // Store both name and ID
      _updateFormData('${_getPrefix()}AddressState', stateName);
      _updateFormData('${_getPrefix()}AddressStateId', stateId);
    }
  }

  void _showErrorAlert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  bool _isFormValid() {
    return (formData['${_getPrefix()}AddressLine1'] ?? '')
            .toString()
            .isNotEmpty &&
        formData['${_getPrefix()}AddressCountry'] != null &&
        formData['${_getPrefix()}AddressState'] != null &&
        (formData['${_getPrefix()}AddressCity'] ?? '').toString().isNotEmpty &&
        (formData['${_getPrefix()}AddressPinCode'] ?? '').toString().isNotEmpty;
  }

  void _validateForm() {
    setState(() {
      validationErrors.clear();

      if ((formData['${_getPrefix()}AddressLine1'] ?? '').toString().isEmpty) {
        validationErrors['${_getPrefix()}AddressLine1'] =
            'Address Line 1 is required';
      }

      if (formData['${_getPrefix()}AddressCountry'] == null) {
        validationErrors['${_getPrefix()}AddressCountry'] =
            'Country is required';
      }

      if (formData['${_getPrefix()}AddressState'] == null) {
        validationErrors['${_getPrefix()}AddressState'] = 'State is required';
      }

      if ((formData['${_getPrefix()}AddressCity'] ?? '').toString().isEmpty) {
        validationErrors['${_getPrefix()}AddressCity'] = 'City is required';
      }

      if ((formData['${_getPrefix()}AddressPinCode'] ?? '')
          .toString()
          .isEmpty) {
        validationErrors['${_getPrefix()}AddressPinCode'] =
            'Pincode is required';
      }
    });
  }

  void _onAddPressed() {
    _validateForm();

    if (validationErrors.isNotEmpty) {
      return;
    }

    // Convert pincode to int if it's a string
    final pincodeValue = formData['${_getPrefix()}AddressPinCode'];
    if (pincodeValue is String && pincodeValue.isNotEmpty) {
      formData['${_getPrefix()}AddressPinCode'] =
          int.tryParse(pincodeValue) ?? 0;
    }

    widget.onAddressSelected(formData);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.62,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: CupertinoColors.separator),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(CupertinoIcons.xmark),
                ),
                Text(
                  _getTitle(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.25,
                  ),
                ),
                const SizedBox(width: 44),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Address Line 1
                  FormFieldWidgets.buildTextField(
                    '${_getPrefix()}AddressLine1',
                    'Line 1',
                    'text',
                    context,
                    onChanged: _updateFormData,
                    formData: formData,
                    validationErrors: validationErrors,
                    isRequired: true,
                  ),

                  // Address Line 2
                  FormFieldWidgets.buildTextField(
                    '${_getPrefix()}AddressLine2',
                    'Line 2',
                    'text',
                    context,
                    onChanged: _updateFormData,
                    formData: formData,
                    validationErrors: validationErrors,
                    isRequired: false,
                  ),

                  // Country Dropdown
                  FormFieldWidgets.buildSelectField(
                    '${_getPrefix()}AddressCountry',
                    'Country',
                    countryOptions,
                    onChanged: (key, value) {
                      _updateFormData(key, value);
                      _onCountryChanged(value);
                    },
                    formData: formData,
                    validationErrors: validationErrors,
                    isRequired: true,
                  ),

                  // State Dropdown
                  FormFieldWidgets.buildSelectField(
                    '${_getPrefix()}AddressState',
                    'State',
                    stateOptions,
                    onChanged: (key, value) {
                      _updateFormData(key, value);
                      _onStateChanged(value);
                    },
                    formData: formData,
                    validationErrors: validationErrors,
                    isRequired: true,
                  ),

                  // City
                  FormFieldWidgets.buildTextField(
                    '${_getPrefix()}AddressCity',
                    'City',
                    'text',
                    context,
                    onChanged: _updateFormData,
                    formData: formData,
                    validationErrors: validationErrors,
                    isRequired: true,
                  ),

                  // Pincode
                  FormFieldWidgets.buildTextField(
                    '${_getPrefix()}AddressPinCode',
                    'Pincode',
                    'number',
                    context,
                    onChanged: _updateFormData,
                    formData: formData,
                    validationErrors: validationErrors,
                    isRequired: true,
                  ),

                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),

          // Add Button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: const Color(0xFF2E8B57),
                onPressed: _onAddPressed,
                child: const Text(
                  'Add',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.25,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
