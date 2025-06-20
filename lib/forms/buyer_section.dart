import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test_22/apis/providers/customer_provider.dart';
// import 'package:smooth_sheets/smooth_sheets.dart';

// Updated Buyer Selection Section Component with API integration and address handling
class BuyerSelectionSection extends ConsumerStatefulWidget {
  final Map<String, dynamic>? selectedClient;
  final Function(Map<String, dynamic>) onClientSelected;
  final String? validationError;
  final String? accountId;

  const BuyerSelectionSection({
    super.key,
    required this.selectedClient,
    required this.onClientSelected,
    this.validationError,
    this.accountId,
  });

  @override
  ConsumerState<BuyerSelectionSection> createState() =>
      _BuyerSelectionSectionState();
}

class _BuyerSelectionSectionState extends ConsumerState<BuyerSelectionSection> {
  @override
  void initState() {
    super.initState();
    // Load customers when component initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomers();
    });
  }

  void _loadCustomers() {
    ref
        .read(customerListProvider.notifier)
        .loadCustomers(page: 0, refresh: true, accountId: widget.accountId);
  }

  void _showClientSelection(BuildContext context) {
    showCupertinoSheet(
      context: context,
      pageBuilder: (context) => ClientSelectionSheet(
        onClientSelected: (client) {
          // Auto-select first address if available
          if (client['addresses'] != null && client['addresses'].isNotEmpty) {
            client['selectedAddress'] = client['addresses'][0];
          }
          widget.onClientSelected(client);
        },
        selectedClientId: widget.selectedClient?['_id'],
      ),
    );
  }

  void _showAddressSelection(BuildContext context) {
    showCupertinoSheet(
      context: context,
      pageBuilder: (context) => AddressSelectionSheet(
        client: widget.selectedClient!,
        onAddressSelected: (address) {
          final updatedClient = Map<String, dynamic>.from(
            widget.selectedClient!,
          );
          updatedClient['selectedAddress'] = address;
          widget.onClientSelected(updatedClient);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection(
      header: Transform.translate(
        offset: const Offset(-4, 0),
        child: const Text(
          'BUYER',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'SF Pro Display',
            letterSpacing: 0.25,
          ),
        ),
      ),
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      margin: EdgeInsets.zero,
      topMargin: 10,
      children: [
        if (widget.selectedClient == null)
          _buildSelectClientTile(context)
        else ...[
          _buildSelectedClientTile(context),
          if (widget.selectedClient!['addresses'] != null &&
              widget.selectedClient!['addresses'].isNotEmpty)
            _buildAddressTile(context),
        ],

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

  Widget _buildSelectClientTile(BuildContext context) {
    return CupertinoListTile(
      title: const Text('Select Client'),
      subtitle: const Text('Tap to choose a client'),
      trailing: const Icon(CupertinoIcons.chevron_right),
      onTap: () => _showClientSelection(context),
    );
  }

  Widget _buildSelectedClientTile(BuildContext context) {
    // Handle different possible field names for client data
    final clientName =
        widget.selectedClient!['name'] ??
        widget.selectedClient!['firstName'] ??
        widget.selectedClient!['fullName'] ??
        'Unknown Client';

    final clientEmail =
        widget.selectedClient!['email'] ??
        widget.selectedClient!['emailAddress'] ??
        'No email';

    return CupertinoListTile(
      title: Text(clientName),
      subtitle: Text(clientEmail.toString()),
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _showClientSelection(context),
        child: const Text('Change', style: TextStyle(fontSize: 14)),
      ),
    );
  }

  Widget _buildAddressTile(BuildContext context) {
    final selectedAddress = widget.selectedClient!['selectedAddress'];
    final addresses = widget.selectedClient!['addresses'] as List;

    String addressText = 'No address selected';
    if (selectedAddress != null) {
      final street =
          selectedAddress['street'] ?? selectedAddress['address'] ?? '';
      final city = selectedAddress['city'] ?? '';
      final state = selectedAddress['state'] ?? '';
      addressText = '$street, $city, $state'.replaceAll(
        RegExp(r'^,\s*|,\s*$'),
        '',
      );
      if (addressText.isEmpty) addressText = 'Address selected';
    }

    return CupertinoListTile(
      leading: const Icon(CupertinoIcons.location),
      title: const Text('Delivery Address'),
      subtitle: Text(addressText),
      trailing: addresses.length > 1
          ? const Icon(CupertinoIcons.chevron_right)
          : null,
      onTap: addresses.length > 1 ? () => _showAddressSelection(context) : null,
    );
  }
}

// Updated Client Selection Sheet with API integration
class ClientSelectionSheet extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onClientSelected;
  final String? selectedClientId;

  const ClientSelectionSheet({
    super.key,
    required this.onClientSelected,
    this.selectedClientId,
  });

  @override
  ConsumerState<ClientSelectionSheet> createState() =>
      _ClientSelectionSheetState();
}

class _ClientSelectionSheetState extends ConsumerState<ClientSelectionSheet> {
  String searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreCustomers();
    }
  }

  void _loadMoreCustomers() {
    final customerState = ref.read(customerListProvider);
    customerState.whenData((data) {
      if (data.hasMore && !data.isLoadingMore) {
        ref
            .read(customerListProvider.notifier)
            .loadCustomers(
              page: data.currentPage + 1,
              searchQuery: searchQuery.isEmpty ? null : searchQuery,
            );
      }
    });
  }

  void _performSearch(String query) {
    setState(() {
      searchQuery = query;
    });

    // Debounce search to avoid too many API calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (searchQuery == query) {
        ref
            .read(customerListProvider.notifier)
            .loadCustomers(
              page: 0,
              refresh: true,
              searchQuery: query.isEmpty ? null : query,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final customerState = ref.watch(customerListProvider);

    return Container(
      height: screenHeight * 0.94,
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
                    'Select Client',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 60),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: CupertinoSearchTextField(
              placeholder: 'Search clients...',
              onChanged: _performSearch,
            ),
          ),

          // Client List
          Expanded(
            child: customerState.when(
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 48,
                      color: CupertinoColors.destructiveRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading clients',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: CupertinoColors.secondaryLabel,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton.filled(
                      onPressed: () {
                        ref
                            .read(customerListProvider.notifier)
                            .loadCustomers(page: 0, refresh: true);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (customerData) {
                if (customerData.customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.person_2,
                          size: 48,
                          color: CupertinoColors.secondaryLabel,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty
                              ? 'No clients found'
                              : 'No matching clients',
                          style: const TextStyle(
                            color: CupertinoColors.secondaryLabel,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      CupertinoListSection(
                        backgroundColor: CupertinoColors.systemBackground
                            .resolveFrom(context),
                        margin: EdgeInsets.zero,
                        topMargin: 0,
                        children: customerData.customers.map((client) {
                          final isSelected =
                              client['_id'] == widget.selectedClientId;

                          // Handle different possible field names
                          final clientName = client['name'];

                          final clientEmail =
                              client['email'] ??
                              client['emailAddress'] ??
                              'No email';

                          final clientPhone =
                              client['phone'] ??
                              client['whatsAppNumber'] ??
                              client['mobile'] ??
                              'No phone';

                          final addressCount = client['addresses']?.length ?? 0;

                          return CupertinoListTile(
                            onTap: () {
                              widget.onClientSelected(client);
                              Navigator.pop(context);
                            },
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            leading: Icon(
                              isSelected
                                  ? CupertinoIcons.smallcircle_fill_circle
                                  : CupertinoIcons.circle,
                              color: isSelected
                                  ? CupertinoColors.systemBlue
                                  : CupertinoColors.secondaryLabel.resolveFrom(
                                      context,
                                    ),
                              size: 30,
                            ),
                            title: Text(
                              clientName,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? CupertinoColors.activeBlue
                                    : CupertinoColors.label,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$clientEmail • $clientPhone',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                                  ),
                                ),
                                if (addressCount > 0)
                                  Text(
                                    '$addressCount address${addressCount > 1 ? 'es' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: CupertinoColors.systemBlue,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      // Loading more indicator
                      if (customerData.isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: CupertinoActivityIndicator(),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Address Selection Sheet
class AddressSelectionSheet extends StatelessWidget {
  final Map<String, dynamic> client;
  final Function(Map<String, dynamic>) onAddressSelected;

  const AddressSelectionSheet({
    super.key,
    required this.client,
    required this.onAddressSelected,
  });

  void _showAddressForm(
    BuildContext context, {
    Map<String, dynamic>? existingAddress,
  }) {
    showCupertinoSheet(
      context: context,
      pageBuilder: (context) => AddressFormSheet(
        client: client,
        existingAddress: existingAddress,
        onAddressSaved: (newAddress) {
          // Refresh the address list by calling onAddressSelected with the new/updated address
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
    final selectedAddressId = client['selectedAddress']?['_id'];

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
                  child: const Text('Add'),
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

                        String fullAddress = [
                          street,
                          city,
                          state,
                          pincode,
                        ].where((s) => s.toString().isNotEmpty).join(', ');

                        if (fullAddress.isEmpty)
                          fullAddress = 'Address details unavailable';

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
                                ? CupertinoIcons.smallcircle_fill_circle
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
                            fullAddress,
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

// Address Form Sheet
class AddressFormSheet extends StatefulWidget {
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
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  final _labelController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _landmarkController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingAddress != null) {
      _labelController.text = widget.existingAddress!['label'] ?? '';
      _streetController.text =
          widget.existingAddress!['street'] ??
          widget.existingAddress!['address'] ??
          '';
      _cityController.text = widget.existingAddress!['city'] ?? '';
      _stateController.text = widget.existingAddress!['state'] ?? '';
      _pincodeController.text =
          widget.existingAddress!['pincode'] ??
          widget.existingAddress!['zipCode'] ??
          '';
      _landmarkController.text = widget.existingAddress!['landmark'] ?? '';
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_streetController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _stateController.text.trim().isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Incomplete Information'),
          content: const Text(
            'Please fill in all required fields (Street, City, State).',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create address object
      final addressData = {
        '_id':
            widget.existingAddress?['_id'] ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'label': _labelController.text.trim().isEmpty
            ? 'Home'
            : _labelController.text.trim(),
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'landmark': _landmarkController.text.trim(),
      };

      // Here you would typically make an API call to save the address
      // await ref.read(customerProvider.notifier).saveAddress(widget.client['_id'], addressData);

      // For now, simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      widget.onAddressSaved(addressData);

      if (mounted) {
        Navigator.pop(context);
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
              child: CupertinoListSection(
                backgroundColor: CupertinoColors.systemBackground.resolveFrom(
                  context,
                ),
                margin: const EdgeInsets.all(16),
                children: [
                  CupertinoTextFormFieldRow(
                    controller: _labelController,
                    placeholder: 'Home, Office, etc.',
                    prefix: const Text('Label'),
                  ),
                  CupertinoTextFormFieldRow(
                    controller: _streetController,
                    placeholder: 'Street address *',
                    prefix: const Text('Street'),
                    maxLines: 2,
                  ),
                  CupertinoTextFormFieldRow(
                    controller: _cityController,
                    placeholder: 'City *',
                    prefix: const Text('City'),
                  ),
                  CupertinoTextFormFieldRow(
                    controller: _stateController,
                    placeholder: 'State *',
                    prefix: const Text('State'),
                  ),
                  CupertinoTextFormFieldRow(
                    controller: _pincodeController,
                    placeholder: 'Pincode',
                    prefix: const Text('Pincode'),
                    keyboardType: TextInputType.number,
                  ),
                  CupertinoTextFormFieldRow(
                    controller: _landmarkController,
                    placeholder: 'Nearby landmark',
                    prefix: const Text('Landmark'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
