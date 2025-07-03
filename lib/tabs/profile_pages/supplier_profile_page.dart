// lib/suppliers/pages/supplier_profile_page.dart
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../components/page_scaffold.dart';
import '../../apis/providers/supplier_provider.dart';

class SupplierProfilePage extends ConsumerStatefulWidget {
  final String supplierId;

  const SupplierProfilePage({super.key, required this.supplierId});

  @override
  ConsumerState<SupplierProfilePage> createState() =>
      _SupplierProfilePageState();
}

class _SupplierProfilePageState extends ConsumerState<SupplierProfilePage> {
  @override
  void initState() {
    super.initState();
    _loadSupplierProfile();
  }

  Future<void> _loadSupplierProfile() async {
    await ref
        .read(supplierProfileProvider.notifier)
        .getSupplierProfile(widget.supplierId);
  }

  Future<void> _onRefresh() async {
    await _loadSupplierProfile();
  }

  void _editSupplier() {
    context.go('/suppliers/edit/${widget.supplierId}');
  }

  void _deleteSupplier() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Supplier'),
        content: const Text(
          'Are you sure you want to delete this supplier? This action cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final result = await ref
            .read(supplierActionsProvider)
            .deleteSupplier(widget.supplierId);

        if (result.success) {
          if (mounted) {
            // Remove from list state
            ref
                .read(supplierListProvider.notifier)
                .removeSupplier(widget.supplierId);

            // Show success and navigate back
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Success'),
                content: Text(
                  result.message ?? 'Supplier deleted successfully',
                ),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go('/customersuppliers');
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        } else {
          throw Exception(result.error ?? 'Failed to delete supplier');
        }
      } catch (e) {
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text('Failed to delete supplier: $e'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(supplierProfileProvider);

    return profileState.when(
      loading: () => CustomPageScaffold(
        isLoading: true,
        heading: 'Supplier Profile',
        searchController: TextEditingController(),
        showSearchField: false,
        onSearchToggle: (_) {},
        sliverList: const SliverFillRemaining(
          child: Center(child: CupertinoActivityIndicator()),
        ),
      ),
      error: (error, stack) => CustomPageScaffold(
        isLoading: false,
        heading: 'Supplier Profile',
        searchController: TextEditingController(),
        showSearchField: false,
        onSearchToggle: (_) {},
        sliverList: SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 48,
                  color: CupertinoColors.systemRed,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Profile',
                  style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: CupertinoTheme.of(context).textTheme.textStyle
                      .copyWith(color: CupertinoColors.secondaryLabel),
                ),
                const SizedBox(height: 16),
                CupertinoButton.filled(
                  onPressed: _onRefresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (supplierData) {
        if (supplierData == null) {
          return CustomPageScaffold(
            isLoading: false,
            heading: 'Supplier Profile',
            searchController: TextEditingController(),
            showSearchField: false,
            onSearchToggle: (_) {},
            sliverList: const SliverFillRemaining(
              child: Center(child: Text('No supplier data found')),
            ),
          );
        }

        return CustomPageScaffold(
          isLoading: false,
          heading: 'Supplier Profile',
          searchController: TextEditingController(),
          showSearchField: false,
          onSearchToggle: (_) {},
          onRefresh: _onRefresh,
          trailing: Row(
            children: [
              CupertinoButton(
                onPressed: _editSupplier,
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.pencil, size: 25),
              ),
              CupertinoButton(
                onPressed: _deleteSupplier,
                padding: EdgeInsets.zero,
                child: const Icon(
                  CupertinoIcons.delete,
                  size: 25,
                  color: CupertinoColors.systemRed,
                ),
              ),
            ],
          ),
          sliverList: SliverList(
            delegate: SliverChildListDelegate([
              _buildProfileHeader(supplierData),
              _buildContactInfo(supplierData),
              _buildBusinessInfo(supplierData),
              _buildAdditionalInfo(supplierData),
              const SizedBox(height: 20),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> supplierData) {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          // Profile Picture
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: CupertinoColors.systemGrey4, width: 2),
            ),
            child:
                supplierData['logo'] != null &&
                    supplierData['logo'].toString().isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      supplierData['logo'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(CupertinoIcons.building_2_fill, size: 50),
                    ),
                  )
                : const Icon(CupertinoIcons.building_2_fill, size: 50),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            supplierData['name'] ?? 'Unknown Supplier',
            style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
            textAlign: TextAlign.center,
          ),

          // Legal Name
          if (supplierData['legalName'] != null &&
              supplierData['legalName'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                supplierData['legalName'],
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  color: CupertinoColors.secondaryLabel,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Status Badge
          if (supplierData['status'] != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(supplierData['status']),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                supplierData['status'].toString().toUpperCase(),
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(Map<String, dynamic> supplierData) {
    return _buildSection(
      title: 'Contact Information',
      icon: CupertinoIcons.phone,
      children: [
        // Handle email array properly
        if (supplierData['email'] != null &&
            supplierData['email'] is List &&
            (supplierData['email'] as List).isNotEmpty)
          _buildInfoTile(
            icon: CupertinoIcons.mail,
            label: 'Email',
            value: (supplierData['email'] as List).first,
          ),
        if (supplierData['whatsAppNumber'] != null &&
            supplierData['whatsAppNumber'].toString().isNotEmpty)
          _buildInfoTile(
            icon: CupertinoIcons.phone,
            label: 'WhatsApp',
            value: supplierData['whatsAppNumber'],
          ),
        if (supplierData['contactName'] != null &&
            supplierData['contactName'].toString().isNotEmpty)
          _buildInfoTile(
            icon: CupertinoIcons.person,
            label: 'Contact Person',
            value: supplierData['contactName'],
          ),
        // Handle addresses array
        if (supplierData['addresses'] != null &&
            supplierData['addresses'] is List &&
            (supplierData['addresses'] as List).isNotEmpty)
          _buildInfoTile(
            icon: CupertinoIcons.location,
            label: 'Address',
            value: _formatAddress(supplierData['addresses'][0]),
          ),
        // Country information
        if (supplierData['countryOfRegistration'] != null)
          _buildInfoTile(
            icon: CupertinoIcons.globe,
            label: 'Country',
            value: supplierData['countryOfRegistration']['name'],
          ),
      ],
    );
  }

  Widget _buildBusinessInfo(Map<String, dynamic> supplierData) {
    return _buildSection(
      title: 'Business Information',
      icon: CupertinoIcons.building_2_fill,
      children: [
        if (supplierData['registrationNo'] != null &&
            supplierData['registrationNo'].toString().isNotEmpty)
          _buildInfoTile(
            icon: CupertinoIcons.number,
            label: 'Registration Number',
            value: supplierData['registrationNo'],
          ),
        if (supplierData['taxIdentificationNumber1'] != null &&
            supplierData['taxIdentificationNumber1'].toString().isNotEmpty)
          _buildInfoTile(
            icon: CupertinoIcons.doc_text,
            label: 'Tax ID 1',
            value: supplierData['taxIdentificationNumber1'],
          ),
        if (supplierData['taxIdentificationNumber2'] != null &&
            supplierData['taxIdentificationNumber2'].toString().isNotEmpty)
          _buildInfoTile(
            icon: CupertinoIcons.doc_text,
            label: 'Tax ID 2',
            value: supplierData['taxIdentificationNumber2'],
          ),
        if (supplierData['upiId'] != null &&
            supplierData['upiId'].toString().isNotEmpty)
          _buildInfoTile(
            icon: CupertinoIcons.creditcard,
            label: 'UPI ID',
            value: supplierData['upiId'],
          ),
        if (supplierData['gPayPhone'] != null &&
            supplierData['gPayPhone'].toString().isNotEmpty)
          _buildInfoTile(
            icon: CupertinoIcons.device_phone_portrait,
            label: 'GPay Phone',
            value: supplierData['gPayPhone'],
          ),
      ],
    );
  }

  Widget _buildAdditionalInfo(Map<String, dynamic> supplierData) {
    return _buildSection(
      title: 'Additional Information',
      icon: CupertinoIcons.info,
      children: [
        if (supplierData['displayName'] != null &&
            supplierData['displayName'].toString().isNotEmpty)
          _buildInfoTile(
            icon: CupertinoIcons.textformat,
            label: 'Display Name',
            value: supplierData['displayName'],
            maxLines: 2,
          ),
        if (supplierData['isActive'] != null)
          _buildInfoTile(
            icon: CupertinoIcons.checkmark_circle,
            label: 'Active Status',
            value: supplierData['isActive'] ? 'Active' : 'Inactive',
          ),
        // Bank accounts information
        if (supplierData['bankAccounts'] != null &&
            supplierData['bankAccounts'] is List &&
            (supplierData['bankAccounts'] as List).isNotEmpty)
          _buildInfoTile(
            icon: CupertinoIcons.building_2_fill,
            label: 'Primary Bank',
            value: _formatBankAccount(supplierData['bankAccounts'][0]),
            maxLines: 2,
          ),
        // Created date
        if (supplierData['bankAccounts'] != null &&
            supplierData['bankAccounts'] is List &&
            (supplierData['bankAccounts'] as List).isNotEmpty &&
            supplierData['bankAccounts'][0]['createdAt'] != null)
          _buildInfoTile(
            icon: CupertinoIcons.calendar,
            label: 'Account Created',
            value: _formatDate(supplierData['bankAccounts'][0]['createdAt']),
          ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: CupertinoColors.activeBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: CupertinoTheme.of(
                    context,
                  ).textTheme.navTitleTextStyle.copyWith(fontSize: 18),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required dynamic value,
    int maxLines = 1,
  }) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: CupertinoColors.systemGrey5, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: CupertinoColors.systemGrey, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: CupertinoTheme.of(context).textTheme.textStyle
                      .copyWith(
                        color: CupertinoColors.secondaryLabel,
                        fontSize: 14,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.toString(),
                  style: CupertinoTheme.of(
                    context,
                  ).textTheme.textStyle.copyWith(fontSize: 16),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    switch (status.toString().toLowerCase()) {
      case 'active':
        return CupertinoColors.activeGreen;
      case 'inactive':
        return CupertinoColors.systemRed;
      case 'pending':
        return CupertinoColors.systemOrange;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  String _formatDate(dynamic date) {
    try {
      if (date is String) {
        final dateTime = DateTime.parse(date);
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
      return date.toString();
    } catch (e) {
      return date.toString();
    }
  }

  String _formatAddress(Map<String, dynamic> address) {
    final parts = <String>[];
    if (address['line1'] != null && address['line1'].toString().isNotEmpty) {
      parts.add(address['line1'].toString());
    }
    if (address['line2'] != null && address['line2'].toString().isNotEmpty) {
      parts.add(address['line2'].toString());
    }
    if (address['city'] != null && address['city'].toString().isNotEmpty) {
      parts.add(address['city'].toString());
    }
    if (address['state'] != null && address['state']['name'] != null) {
      parts.add(address['state']['name'].toString());
    }
    if (address['code'] != null && address['code'].toString().isNotEmpty) {
      parts.add(address['code'].toString());
    }
    return parts.join(', ');
  }

  String _formatBankAccount(Map<String, dynamic> bankAccount) {
    final parts = <String>[];
    if (bankAccount['bankName'] != null) {
      parts.add(bankAccount['bankName'].toString());
    }
    if (bankAccount['accountName'] != null) {
      parts.add('(${bankAccount['accountName']})');
    }
    return parts.join(' ');
  }
}
