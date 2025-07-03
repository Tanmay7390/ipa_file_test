import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../apis/core/dio_provider.dart';
import '../auth/components/auth_provider.dart';

class ClientSelectionService {
  static void showClientSelector({
    required BuildContext context,
    required WidgetRef ref,
    required Function(Map<String, dynamic>) onClientSelected,
  }) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => ClientSelectorBottomSheet(
        onClientSelected: onClientSelected,
        ref: ref,
      ),
    );
  }
}

class ClientSelectorBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onClientSelected;
  final WidgetRef ref;

  const ClientSelectorBottomSheet({
    Key? key,
    required this.onClientSelected,
    required this.ref,
  }) : super(key: key);

  @override
  _ClientSelectorBottomSheetState createState() =>
      _ClientSelectorBottomSheetState();
}

class _ClientSelectorBottomSheetState extends State<ClientSelectorBottomSheet> {
  List<Map<String, dynamic>> _clientList = [];
  List<Map<String, dynamic>> _filteredClientList = [];
  bool _isLoadingClients = false;
  String _searchQuery = '';
  int? _selectedClientIndex;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoadingClients = true;
    });

    try {
      final dio = widget.ref.read(dioProvider);
      final authState = widget.ref.read(authProvider);

      if (authState.accountId == null) {
        throw Exception('Account ID not found');
      }

      final response = await dio.get(
        'account/search',
        queryParameters: {'name': '', 'searchFor': 'buyer'},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer ${authState.token}',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<Map<String, dynamic>> clients = [];

        if (data is Map && data.containsKey('accounts')) {
          clients = List<Map<String, dynamic>>.from(data['accounts'] ?? []);
        }

        setState(() {
          _clientList = clients;
          _filteredClientList = clients;
        });
      }
    } catch (e) {
      print('Error loading clients: $e');
    } finally {
      setState(() {
        _isLoadingClients = false;
      });
    }
  }

  void _filterClients(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredClientList = _clientList;
      } else {
        _filteredClientList = _clientList.where((client) {
          final name = client['name']?.toString().toLowerCase() ?? '';
          final email = client['email']?.isNotEmpty ?? false
              ? client['email'][0].toString().toLowerCase()
              : '';
          final phone =
              client['whatsAppNumber']?.toString().toLowerCase() ?? '';

          return name.contains(query.toLowerCase()) ||
              email.contains(query.toLowerCase()) ||
              phone.contains(query.toLowerCase());
        }).toList();
      }
      _selectedClientIndex = null; // Reset selection when filtering
    });
  }

  void _showAddressSelection(int clientIndex) {
    final client = _filteredClientList[clientIndex];
    final addresses = List<Map<String, dynamic>>.from(
      client['addresses'] ?? [],
    );
    final billingAddress = addresses.firstWhere(
      (addr) => addr['type'] == 'Billing',
      orElse: () => {},
    );
    final shippingAddress = addresses.firstWhere(
      (addr) => addr['type'] == 'Shipping',
      orElse: () => {},
    );

    if (billingAddress.isEmpty && shippingAddress.isEmpty) {
      // No addresses available, just select client
      widget.onClientSelected({
        'client': client['_id'],
        'clientName': client['name'],
        'baseLocation': null,
        'baseLocationId': null,
      });
      Navigator.of(context).pop();
      return;
    }

    showCupertinoModalPopup(
      context: context,
      builder: (context) => _AddressSelectionSheet(
        client: client,
        billingAddress: billingAddress,
        shippingAddress: shippingAddress,
        onAddressSelected: widget.onClientSelected,
      ),
    );
  }

  Widget _buildAddressOption(
    String title,
    Map<String, dynamic> address,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.systemGrey4),
          borderRadius: BorderRadius.circular(12),
          color: CupertinoColors.systemBackground,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: CupertinoColors.systemBlue),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              _formatAddress(address),
              style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAddress(Map<String, dynamic> address) {
    if (address.isEmpty) return '';

    final line1 = address['line1'] ?? '';
    final line2 = address['line2'] ?? '';
    final city = address['city'] ?? '';
    final state = address['state'] is Map ? address['state']['name'] : '';
    final country = address['country'] is Map ? address['country']['name'] : '';
    final code = address['code'] ?? '';

    return '$line1, $line2, $city, $state, $country - $code'
        .replaceAll(RegExp(r', ,'), ', ')
        .replaceAll(RegExp(r'^, '), '')
        .replaceAll(RegExp(r', $'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Text(
            'Select Client',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 16),
          CupertinoSearchTextField(
            placeholder: 'Search clients...',
            onChanged: _filterClients,
          ),
          SizedBox(height: 16),
          Expanded(
            child: _isLoadingClients
                ? Center(child: CupertinoActivityIndicator())
                : _filteredClientList.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No clients found'
                          : 'No clients match your search',
                      style: TextStyle(color: CupertinoColors.systemGrey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredClientList.length,
                    itemBuilder: (context, index) {
                      final client = _filteredClientList[index];
                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedClientIndex = index;
                              });
                              _showAddressSelection(index);
                            },
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _selectedClientIndex == index
                                    ? CupertinoColors.systemGrey6
                                    : CupertinoColors.systemBackground,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  // Client avatar/icon
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: CupertinoColors.systemGrey5,
                                    ),
                                    child: _buildClientAvatar(client),
                                  ),

                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          client['name'] ?? 'Unknown Client',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        if (client['email']?.isNotEmpty ??
                                            false)
                                          Text(
                                            client['email'][0] ?? '',
                                            style: TextStyle(
                                              color: CupertinoColors.systemGrey,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        if (client['whatsAppNumber']
                                                ?.isNotEmpty ??
                                            false)
                                          Text(
                                            client['whatsAppNumber'] ?? '',
                                            style: TextStyle(
                                              color: CupertinoColors.systemGrey,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                      ],
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
                          if (index < _filteredClientList.length - 1)
                            Divider(height: 1),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientAvatar(Map<String, dynamic> client) {
    final logo = client['logo'];

    // Check if logo is a valid URL string
    if (logo != null &&
        logo is String &&
        logo.isNotEmpty &&
        (logo.startsWith('http://') || logo.startsWith('https://'))) {
      return ClipOval(
        child: Image.network(
          logo,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialsAvatar(client);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(child: CupertinoActivityIndicator());
          },
        ),
      );
    }

    // Default to initials avatar
    return _buildInitialsAvatar(client);
  }

  Widget _buildInitialsAvatar(Map<String, dynamic> client) {
    final name = client['name']?.toString() ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'C';

    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: CupertinoColors.systemGrey,
        ),
      ),
    );
  }
}

class _AddressSelectionSheet extends StatefulWidget {
  final Map<String, dynamic> client;
  final Map<String, dynamic> billingAddress;
  final Map<String, dynamic> shippingAddress;
  final Function(Map<String, dynamic>) onAddressSelected;

  const _AddressSelectionSheet({
    Key? key,
    required this.client,
    required this.billingAddress,
    required this.shippingAddress,
    required this.onAddressSelected,
  }) : super(key: key);

  @override
  _AddressSelectionSheetState createState() => _AddressSelectionSheetState();
}

class _AddressSelectionSheetState extends State<_AddressSelectionSheet> {
  String? _selectedAddressType;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Select Base Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Client: ${widget.client['name']}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.systemGrey,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                if (widget.billingAddress.isNotEmpty)
                  _buildRadioAddressOption(
                    'Billing Address',
                    widget.billingAddress,
                    CupertinoIcons.doc_text,
                    'billing',
                  ),
                if (widget.billingAddress.isNotEmpty &&
                    widget.shippingAddress.isNotEmpty)
                  SizedBox(height: 12),
                if (widget.shippingAddress.isNotEmpty)
                  _buildRadioAddressOption(
                    'Shipping Address',
                    widget.shippingAddress,
                    CupertinoIcons.cube_box_fill,
                    'shipping',
                  ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: CupertinoButton(
                  color: CupertinoColors.systemBlue,
                  child: Text(
                    'Select',
                    style: TextStyle(color: CupertinoColors.white),
                  ),
                  onPressed: _selectedAddressType != null
                      ? _handleAddressSelection
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadioAddressOption(
    String title,
    Map<String, dynamic> address,
    IconData icon,
    String addressType,
  ) {
    final isSelected = _selectedAddressType == addressType;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAddressType = addressType;
        });
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? CupertinoColors.systemBlue
                : CupertinoColors.systemGrey4,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? CupertinoColors.systemBlue.withOpacity(0.1)
              : CupertinoColors.systemBackground,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Radio button
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? CupertinoColors.systemBlue
                          : CupertinoColors.systemGrey3,
                      width: 2,
                    ),
                    color: isSelected
                        ? CupertinoColors.systemBlue
                        : CupertinoColors.systemBackground,
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: CupertinoColors.white,
                            ),
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 12),
                Icon(icon, size: 18, color: CupertinoColors.systemBlue),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.only(left: 32),
              child: Text(
                _formatAddress(address),
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAddressSelection() {
    if (_selectedAddressType == null) return;

    final selectedAddress = _selectedAddressType == 'billing'
        ? widget.billingAddress
        : widget.shippingAddress;

    widget.onAddressSelected({
      'client': widget.client['_id'],
      'clientId': widget.client['_id'],
      'clientName': widget.client['name'],
      'baseLocation': _formatAddress(selectedAddress),
      'baseLocationId': selectedAddress['_id'],
    });

    Navigator.of(context).pop(); // Close address selection
    Navigator.of(context).pop(); // Close client selection
  }

  String _formatAddress(Map<String, dynamic> address) {
    if (address.isEmpty) return '';

    final line1 = address['line1'] ?? '';
    final line2 = address['line2'] ?? '';
    final city = address['city'] ?? '';
    final state = address['state'] is Map ? address['state']['name'] : '';
    final country = address['country'] is Map ? address['country']['name'] : '';
    final code = address['code'] ?? '';

    return '$line1, $line2, $city, $state, $country - $code'
        .replaceAll(RegExp(r', ,'), ', ')
        .replaceAll(RegExp(r'^, '), '')
        .replaceAll(RegExp(r', $'), '');
  }
}
