import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Wareozo/components/form_fields.dart';
import 'package:Wareozo/apis/providers/customer_address_provider.dart';

// Address Section Component - Separated from Buyer Section
class AddressSection extends StatefulWidget {
  final String title; // "BILL TO" or "SHIP TO"
  final Map<String, dynamic>? selectedClient;
  final Map<String, dynamic>? selectedAddress;
  final Function(Map<String, dynamic>) onAddressSelected;
  final Function()? onAddAddress;
  final String? validationError;
  final bool showAddButton;
  final bool showChangeButton;
  final bool showTitle;

  const AddressSection({
    super.key,
    required this.title,
    required this.selectedClient,
    required this.selectedAddress,
    required this.onAddressSelected,
    this.onAddAddress,
    this.validationError,
    this.showAddButton = true,
    this.showChangeButton = true,
    this.showTitle = true,
  });

  @override
  State<AddressSection> createState() => _AddressSectionState();
}

class _AddressSectionState extends State<AddressSection> {
  void _showAddressSelection(BuildContext context) {
    if (widget.selectedClient == null) return;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => AddressSelectionSheet(
        client: widget.selectedClient!,
        selectedAddressId: widget.selectedAddress?['_id'],
        onAddressSelected: widget.onAddressSelected,
      ),
    );
  }

  void _showAddressForm(
    BuildContext context, {
    Map<String, dynamic>? existingAddress,
  }) {
    if (widget.selectedClient == null) return;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => AddressFormSheet(
        client: widget.selectedClient!,
        existingAddress: existingAddress,
        onAddressSaved: (newAddress) {
          widget.onAddressSelected(newAddress);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection(
      header: widget.showTitle
          ? Transform.translate(
              offset: const Offset(-4, 0),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.25,
                ),
              ),
            )
          : null,
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      margin: EdgeInsets.zero,
      topMargin: widget.showTitle ? 10 : 0,
      children: [
        if (widget.selectedClient == null)
          _buildNoClientTile()
        else if (widget.selectedAddress == null)
          _buildNoAddressTile(context)
        else
          _buildAddressDetailsTile(context),

        if (widget.validationError != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              widget.validationError!,
              style: const TextStyle(
                color: CupertinoColors.destructiveRed,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNoClientTile() {
    return const CupertinoListTile(
      title: Text('No Client Selected'),
      subtitle: Text('Please select a client first'),
      leading: Icon(
        CupertinoIcons.exclamationmark_triangle,
        color: CupertinoColors.systemOrange,
      ),
    );
  }

  Widget _buildNoAddressTile(BuildContext context) {
    final addresses = widget.selectedClient!['addresses'] as List? ?? [];

    return CupertinoListTile(
      title: const Text('Select Address'),
      subtitle: Text(
        addresses.isEmpty
            ? 'No addresses available'
            : 'Tap to choose an address',
      ),
      leading: const Icon(CupertinoIcons.location),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showAddButton)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showAddressForm(context),
              child: const Text('Add', style: TextStyle(fontSize: 14)),
            ),
          if (addresses.isNotEmpty) ...[
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.chevron_right),
          ],
        ],
      ),
      onTap: addresses.isNotEmpty ? () => _showAddressSelection(context) : null,
    );
  }

  Widget _buildAddressDetailsTile(BuildContext context) {
    final address = widget.selectedAddress!;
    final client = widget.selectedClient!;

    // Build company/client name
    final clientName =
        client['name'] ??
        client['firstName'] ??
        client['fullName'] ??
        'Unknown Client';

    // Build address string
    final street = address['street'] ?? address['address'] ?? '';
    final city = address['city'] ?? '';
    final state = address['state'] ?? '';
    final pincode = address['pincode'] ?? address['zipCode'] ?? '';
    final landmark = address['landmark'] ?? '';

    // Format address like in the image
    List<String> addressParts = [];
    if (street.isNotEmpty) addressParts.add(street);
    if (landmark.isNotEmpty) addressParts.add(landmark);
    if (city.isNotEmpty) addressParts.add(city);
    if (state.isNotEmpty) {
      final stateName = state is Map ? state['name'] : state.toString();
      addressParts.add(stateName);
    }
    if (pincode.isNotEmpty) addressParts.add(pincode);

    final fullAddress = addressParts.join(', ');

    return CupertinoListTile(
      leadingSize: 50,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      title: Text(
        clientName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fullAddress.isNotEmpty ? fullAddress : 'Address details incomplete',
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              height: 1.3,
            ),
          ),
          if (address['label'] != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                address['label'],
                style: const TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.location_solid,
          color: CupertinoColors.systemBlue,
          size: 20,
        ),
      ),
      trailing: widget.showChangeButton
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () =>
                      _showAddressForm(context, existingAddress: address),
                  child: const Text('Edit', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _showAddressSelection(context),
                  child: const Text('Change', style: TextStyle(fontSize: 14)),
                ),
              ],
            )
          : null,
    );
  }
}

// Enhanced Address Selection Sheet
class AddressSelectionSheet extends StatelessWidget {
  final Map<String, dynamic> client;
  final String? selectedAddressId;
  final Function(Map<String, dynamic>) onAddressSelected;

  const AddressSelectionSheet({
    super.key,
    required this.client,
    this.selectedAddressId,
    required this.onAddressSelected,
  });

  void _showAddressForm(
    BuildContext context, {
    Map<String, dynamic>? existingAddress,
  }) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => AddressFormSheet(
        client: client,
        existingAddress: existingAddress,
        onAddressSaved: (newAddress) {
          onAddressSelected(newAddress);
          Navigator.pop(context); // Close address form
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final addresses = client['addresses'] as List? ?? [];

    return Container(
      height: screenHeight * 0.7,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const Expanded(
                  child: Text(
                    'Select Address',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _showAddressForm(context),
                  child: const Text('Add New'),
                ),
              ],
            ),
          ),

          // Address List
          Expanded(
            child: addresses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.location,
                          size: 48,
                          color: CupertinoColors.secondaryLabel,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No addresses found',
                          style: TextStyle(
                            color: CupertinoColors.secondaryLabel,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CupertinoButton.filled(
                          onPressed: () => _showAddressForm(context),
                          child: const Text('Add Address'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: CupertinoListSection(
                      backgroundColor: CupertinoColors.systemBackground
                          .resolveFrom(context),
                      margin: EdgeInsets.zero,
                      topMargin: 0,
                      children: addresses.map<Widget>((address) {
                        final isSelected = address['_id'] == selectedAddressId;
                        final street =
                            address['street'] ?? address['address'] ?? '';
                        final city = address['city'] ?? '';
                        final state = address['state'] ?? '';
                        final pincode =
                            address['pincode'] ?? address['zipCode'] ?? '';
                        final landmark = address['landmark'] ?? '';

                        List<String> addressParts = [];
                        if (street.isNotEmpty) addressParts.add(street);
                        if (landmark.isNotEmpty) addressParts.add(landmark);
                        if (city.isNotEmpty) addressParts.add(city);
                        if (state.isNotEmpty) {
                          final stateName = state is Map
                              ? state['name']
                              : state.toString();
                          addressParts.add(stateName);
                        }
                        if (pincode.isNotEmpty) addressParts.add(pincode);

                        final fullAddress = addressParts.join(', ');

                        return CupertinoListTile(
                          onTap: () {
                            onAddressSelected(address);
                            Navigator.pop(context);
                          },
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          leading: Icon(
                            isSelected
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.circle,
                            color: isSelected
                                ? CupertinoColors.systemBlue
                                : CupertinoColors.secondaryLabel.resolveFrom(
                                    context,
                                  ),
                            size: 24,
                          ),
                          title: Text(
                            address['label'] ??
                                'Address ${addresses.indexOf(address) + 1}',
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? CupertinoColors.activeBlue
                                  : CupertinoColors.label,
                            ),
                          ),
                          subtitle: Text(
                            fullAddress.isNotEmpty
                                ? fullAddress
                                : 'Address details incomplete',
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => _showAddressForm(
                              context,
                              existingAddress: address,
                            ),
                            child: const Text(
                              'Edit',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Address Form Sheet with API Integration for Country and State
class AddressFormSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> client;
  final Map<String, dynamic>? existingAddress;
  final Function(Map<String, dynamic>) onAddressSaved;

  const AddressFormSheet({
    super.key,
    required this.client,
    this.existingAddress,
    required this.onAddressSaved,
  });

  @override
  ConsumerState<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<AddressFormSheet> {
  final Map<String, dynamic> formData = {};
  final Map<String, String> validationErrors = {};
  bool _isLoading = false;

  // Selected country ID for state filtering
  String? _selectedCountryId;

  @override
  void initState() {
    super.initState();
    if (widget.existingAddress != null) {
      final address = widget.existingAddress!;
      formData['label'] = address['label'] ?? '';
      formData['street'] = address['street'] ?? address['address'] ?? '';
      formData['landmark'] = address['landmark'] ?? '';
      formData['city'] = address['city'] ?? '';
      formData['pincode'] = address['pincode'] ?? address['zipCode'] ?? '';

      // Handle existing country and state
      if (address['country'] != null) {
        if (address['country'] is Map) {
          formData['country'] = address['country']['name'];
          _selectedCountryId =
              address['country']['_id'] ?? address['country']['id'];
        } else {
          formData['country'] = address['country'].toString();
        }
      }

      // if (address['state'] != null) {
      //   if (address['state'] is Map) {
      //     formData['state'] = address['state']['name'];
      //   } else {
      //     formData['state'] = address['state'].toString();
      //   }
      // }
    }
  }

  void _updateFormData(String key, dynamic value) {
    setState(() {
      formData[key] = value;
      validationErrors.remove(key);

      // Handle country selection and get country ID for state filtering
      if (key == 'country') {
        formData.remove('state'); // Reset state when country changes

        // Find the selected country to get its ID
        final countriesAsync = ref.read(countriesProvider);
        countriesAsync.whenData((countries) {
          final selectedCountry = countries.firstWhere(
            (country) => country['name'] == value,
            orElse: () => <String, dynamic>{},
          );
          _selectedCountryId = selectedCountry['_id'] ?? selectedCountry['id'];
        });
      }
    });
  }

  bool _validateForm() {
    validationErrors.clear();

    void checkRequired(String key, String label) {
      if (formData[key]?.toString().trim().isEmpty ?? true) {
        validationErrors[key] = '$label is required';
      }
    }

    checkRequired('street', 'Street address');
    checkRequired('city', 'City');
    checkRequired('state', 'State');
    checkRequired('pincode', 'Pincode');
    checkRequired('country', 'Country');

    return validationErrors.isEmpty;
  }

  Future<void> _saveAddress() async {
    if (!_validateForm()) {
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);

    try {
      final customerId = widget.client['_id'] ?? widget.client['id'];
      final addressActions = ref.read(addressActionsProvider);

      final addressData = {
        'label': formData['label']?.toString().trim().isEmpty ?? true
            ? 'Address'
            : formData['label'].toString().trim(),
        'street': formData['street'].toString().trim(),
        'landmark': formData['landmark']?.toString().trim() ?? '',
        'city': formData['city'].toString().trim(),
        'state': formData['state'].toString().trim(),
        'pincode': formData['pincode'].toString().trim(),
        'country': formData['country'].toString().trim(),
      };

      ApiResponse<Map<String, dynamic>> result;

      if (widget.existingAddress != null) {
        // Update existing address
        final addressId =
            widget.existingAddress!['_id'] ?? widget.existingAddress!['id'];
        result = await addressActions.updateAddress(
          customerId: customerId,
          addressId: addressId,
          addressData: addressData,
        );
      } else {
        // Create new address
        result = await addressActions.createAddress(
          customerId: customerId,
          addressData: addressData,
        );
      }

      if (result.success && result.data != null) {
        widget.onAddressSaved(result.data!);

        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        throw Exception(result.error ?? 'Failed to save address');
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save address: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isEditing = widget.existingAddress != null;

    // Watch countries and states from providers
    final countriesAsync = ref.watch(countriesProvider);
    final statesAsync = ref.watch(statesProvider);

    return Container(
      height: screenHeight * 0.9,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                Expanded(
                  child: Text(
                    isEditing ? 'Edit Address' : 'Add Address',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _isLoading ? null : _saveAddress,
                  child: _isLoading
                      ? const CupertinoActivityIndicator()
                      : const Text('Save'),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Address Details Section
                  BuildSection([
                    FormFieldWidgets.buildTextField(
                      'label',
                      'Label',
                      'text',
                      context,
                      isRequired: false,
                      onChanged: _updateFormData,
                      formData: formData,
                      validationErrors: validationErrors,
                    ),
                    FormFieldWidgets.buildTextField(
                      'street',
                      'Street Address',
                      'text',
                      context,
                      isRequired: true,
                      onChanged: _updateFormData,
                      formData: formData,
                      validationErrors: validationErrors,
                    ),
                    FormFieldWidgets.buildTextField(
                      'landmark',
                      'Landmark',
                      'text',
                      context,
                      isRequired: false,
                      onChanged: _updateFormData,
                      formData: formData,
                      validationErrors: validationErrors,
                    ),
                    FormFieldWidgets.buildTextField(
                      'city',
                      'City',
                      'text',
                      context,
                      isRequired: true,
                      onChanged: _updateFormData,
                      formData: formData,
                      validationErrors: validationErrors,
                    ),

                    // Country Select Field with API data
                    countriesAsync.when(
                      data: (countries) {
                        final countryNames = countries
                            .map<String>((country) => country['name'] as String)
                            .toList();

                        return FormFieldWidgets.buildSelectField(
                          'country',
                          'Country',
                          countryNames,
                          onChanged: _updateFormData,
                          formData: formData,
                          validationErrors: validationErrors,
                          isRequired: true,
                        );
                      },
                      loading: () => Container(
                        padding: const EdgeInsets.all(16),
                        child: const Row(
                          children: [
                            CupertinoActivityIndicator(),
                            SizedBox(width: 12),
                            Text('Loading countries...'),
                          ],
                        ),
                      ),
                      error: (error, stack) => Container(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Error loading countries: $error',
                          style: const TextStyle(
                            color: CupertinoColors.destructiveRed,
                          ),
                        ),
                      ),
                    ),

                    // State Select Field with API data
                    statesAsync.when(
                      data: (states) {
                        final stateNames = states
                            .map<String>((state) => state['name'] as String)
                            .toList();

                        return FormFieldWidgets.buildSelectField(
                          'state',
                          'State',
                          stateNames,
                          onChanged: _updateFormData,
                          formData: formData,
                          validationErrors: validationErrors,
                          isRequired: true,
                        );
                      },
                      loading: () => Container(
                        padding: const EdgeInsets.all(16),
                        child: const Row(
                          children: [
                            CupertinoActivityIndicator(),
                            SizedBox(width: 12),
                            Text('Loading states...'),
                          ],
                        ),
                      ),
                      error: (error, stack) => Container(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Error loading states: $error',
                          style: const TextStyle(
                            color: CupertinoColors.destructiveRed,
                          ),
                        ),
                      ),
                    ),

                    FormFieldWidgets.buildTextField(
                      'pincode',
                      'Pincode',
                      'number',
                      context,
                      isRequired: true,
                      onChanged: _updateFormData,
                      formData: formData,
                      validationErrors: validationErrors,
                    ),
                  ]),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
