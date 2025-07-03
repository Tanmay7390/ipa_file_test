// customer_profile_page.dart
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../components/page_scaffold.dart';
import '../../apis/providers/customer_provider.dart';

class CustomerProfilePage extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerProfilePage({super.key, required this.customerId});

  @override
  ConsumerState<CustomerProfilePage> createState() =>
      _CustomerProfilePageState();
}

class _CustomerProfilePageState extends ConsumerState<CustomerProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic>? _customerData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCustomerProfile();
  }

  void _loadCustomerProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ref
          .read(customerActionsProvider)
          .getCustomer(widget.customerId);

      if (result.success && result.data != null) {
        setState(() {
          _customerData = result.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result.error ?? 'Failed to load customer profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Error loading customer profile: $e');
      setState(() {
        _error = 'An unexpected error occurred';
        _isLoading = false;
      });
    }
  }

  void _deleteCustomer() async {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Customer'),
        content: const Text(
          'Are you sure you want to delete this customer? This action cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                final result = await ref
                    .read(customerActionsProvider)
                    .deleteCustomer(widget.customerId);

                if (result.success) {
                  // Remove from local state
                  ref
                      .read(customerListProvider.notifier)
                      .removeCustomer(widget.customerId);

                  if (mounted) {
                    context.go('/customers');
                    showCupertinoDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: const Text('Success'),
                        content: Text(
                          result.message ?? 'Customer deleted successfully',
                        ),
                        actions: [
                          CupertinoDialogAction(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                } else {
                  throw Exception(result.error ?? 'Failed to delete customer');
                }
              } catch (e) {
                if (mounted) {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('Error'),
                      content: Text('Failed to delete customer: $e'),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_customerData?['name'] ?? 'Customer Profile'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/customersuppliers'),
          child: const Icon(CupertinoIcons.back),
        ),
        trailing: _customerData != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => context.go(
                      '/customersuppliers/one/${widget.customerId}',
                      extra: _customerData,
                    ),
                    child: const Icon(CupertinoIcons.pencil),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _deleteCustomer,
                    child: const Icon(
                      CupertinoIcons.delete,
                      color: CupertinoColors.systemRed,
                    ),
                  ),
                ],
              )
            : null,
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _error != null
            ? _buildErrorState()
            : _buildProfileContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 20),
            Text(
              'Error Loading Profile',
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            ),
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 20),
            CupertinoButton.filled(
              onPressed: _loadCustomerProfile,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_customerData == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          _buildProfileHeader(),
          const SizedBox(height: 24),

          // Basic Information
          _buildSectionCard(
            title: 'Basic Information',
            children: [
              _buildInfoRow('Name', _customerData!['name']),
              _buildInfoRow('Legal Name', _customerData!['legalName']),
              _buildInfoRow('Display Name', _customerData!['displayName']),
              _buildInfoRow('Contact Name', _customerData!['contactName']),
              _buildInfoRow('Status', _customerData!['status']),
              _buildInfoRow('Active', _customerData!['isActive']?.toString()),
            ],
          ),

          const SizedBox(height: 16),

          // Contact Information
          _buildSectionCard(
            title: 'Contact Information',
            children: [
              _buildInfoRow('WhatsApp', _customerData!['whatsAppNumber']),
              _buildInfoRow('Email', _getEmailString()),
              _buildInfoRow('Website', _customerData!['website']),
              _buildInfoRow('UPI ID', _customerData!['upiId']),
              _buildInfoRow('GPay Phone', _customerData!['gPayPhone']),
            ],
          ),

          const SizedBox(height: 16),

          // Business Information
          _buildSectionCard(
            title: 'Business Information',
            children: [
              _buildInfoRow(
                'Registration No',
                _customerData!['registrationNo'],
              ),
              _buildInfoRow(
                'Tax ID 1',
                _customerData!['taxIdentificationNumber1'],
              ),
              _buildInfoRow(
                'Tax ID 2',
                _customerData!['taxIdentificationNumber2'],
              ),
              _buildInfoRow('Business Type', _getBusinessTypeString()),
              _buildInfoRow('Country', _getCountryName()),
            ],
          ),

          const SizedBox(height: 16),

          // Addresses
          if (_hasAddresses()) _buildAddressesSection(),

          const SizedBox(height: 16),

          // Bank Accounts
          if (_hasBankAccounts()) _buildBankAccountsSection(),

          const SizedBox(height: 16),

          // Customer Type
          _buildSectionCard(
            title: 'Customer Type',
            children: [
              _buildInfoRow('Client', _customerData!['isClient']?.toString()),
              _buildInfoRow('Vendor', _customerData!['isVendor']?.toString()),
              _buildInfoRow('Agent', _customerData!['isAgent']?.toString()),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: CupertinoColors.systemGrey5,
            ),
            child:
                _customerData!['logo'] != null &&
                    _customerData!['logo'].isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.network(
                      _customerData!['logo'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        CupertinoIcons.person_fill,
                        size: 40,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  )
                : const Icon(
                    CupertinoIcons.person_fill,
                    size: 40,
                    color: CupertinoColors.systemGrey,
                  ),
          ),
          const SizedBox(width: 20),

          // Profile Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _customerData!['name'] ?? 'Unknown',
                  style: CupertinoTheme.of(
                    context,
                  ).textTheme.navLargeTitleTextStyle,
                ),
                const SizedBox(height: 4),
                Text(
                  _customerData!['legalName'] ?? '',
                  style: CupertinoTheme.of(context).textTheme.textStyle
                      .copyWith(color: CupertinoColors.secondaryLabel),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _customerData!['isActive'] == true
                        ? CupertinoColors.systemGreen.withOpacity(0.1)
                        : CupertinoColors.systemRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _customerData!['status'] ?? 'Unknown',
                    style: TextStyle(
                      color: _customerData!['isActive'] == true
                          ? CupertinoColors.systemGreen
                          : CupertinoColors.systemRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: CupertinoTheme.of(
              context,
            ).textTheme.navTitleTextStyle.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty || value == 'null')
      return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                color: CupertinoColors.secondaryLabel,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: CupertinoTheme.of(context).textTheme.textStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressesSection() {
    final addresses = _customerData!['addresses'] as List?;
    if (addresses == null || addresses.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      title: 'Addresses',
      children: addresses
          .map<Widget>((address) => _buildAddressCard(address))
          .toList(),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            address['type'] ?? 'Address',
            style: CupertinoTheme.of(
              context,
            ).textTheme.textStyle.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (address['line1'] != null && address['line1'].isNotEmpty)
            Text(address['line1']),
          if (address['line2'] != null && address['line2'].isNotEmpty)
            Text(address['line2']),
          if (address['city'] != null && address['city'].isNotEmpty)
            Text('${address['city']}, ${address['state']?['name'] ?? ''}'),
          if (address['code'] != null && address['code'].isNotEmpty)
            Text('PIN: ${address['code']}'),
          if (address['country'] != null)
            Text(address['country']['name'] ?? ''),
        ],
      ),
    );
  }

  Widget _buildBankAccountsSection() {
    final bankAccounts = _customerData!['bankAccounts'] as List?;
    if (bankAccounts == null || bankAccounts.isEmpty)
      return const SizedBox.shrink();

    return _buildSectionCard(
      title: 'Bank Accounts',
      children: [
        Text(
          '${bankAccounts.length} bank account(s) linked',
          style: CupertinoTheme.of(
            context,
          ).textTheme.textStyle.copyWith(color: CupertinoColors.secondaryLabel),
        ),
      ],
    );
  }

  String _getEmailString() {
    final emails = _customerData!['email'] as List?;
    if (emails == null || emails.isEmpty) return '';
    return emails.join(', ');
  }

  String _getBusinessTypeString() {
    final businessTypes = _customerData!['businessType'] as List?;
    if (businessTypes == null || businessTypes.isEmpty) return '';
    return businessTypes.join(', ');
  }

  String _getCountryName() {
    final country = _customerData!['countryOfRegistration'] as Map?;
    return country?['name'] ?? '';
  }

  bool _hasAddresses() {
    final addresses = _customerData!['addresses'] as List?;
    return addresses != null && addresses.isNotEmpty;
  }

  bool _hasBankAccounts() {
    final bankAccounts = _customerData!['bankAccounts'] as List?;
    return bankAccounts != null && bankAccounts.isNotEmpty;
  }
}
