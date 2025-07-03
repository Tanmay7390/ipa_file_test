import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../components/page_scaffold.dart';
import '../../theme_provider.dart';
import '../../apis/providers/customer_provider.dart';
import '../../apis/providers/supplier_provider.dart';
import '../../forms/customersupplier_update_form.dart';

class CustomerSupplierProfilePage extends ConsumerStatefulWidget {
  final String entityId;
  final String entityType; // 'customer' or 'supplier'
  final Map<String, dynamic>? entityData;

  const CustomerSupplierProfilePage({
    super.key,
    required this.entityId,
    required this.entityType,
    this.entityData,
  });

  @override
  ConsumerState<CustomerSupplierProfilePage> createState() =>
      _CustomerSupplierProfilePageState();
}

class _CustomerSupplierProfilePageState
    extends ConsumerState<CustomerSupplierProfilePage> {
  bool _isLoading = false;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _data = widget.entityData;
    if (_data == null) {
      _loadProfileData();
    }
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      if (widget.entityType == 'customer') {
        final result = await ref
            .read(customerActionsProvider)
            .getCustomer(widget.entityId);
        if (result.success && result.data != null) {
          setState(() => _data = result.data);
        }
      } else {
        final result = await ref
            .read(supplierProfileProvider.notifier)
            .getSupplierProfile(widget.entityId);
        if (result.success && result.data != null) {
          setState(() => _data = result.data);
        }
      }
    } catch (e) {
      log('Error loading profile data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorProvider);

    return CustomPageScaffold(
      isLoading: _isLoading,
      heading: _data?['name'] ?? '${widget.entityType.capitalize()} Profile',
      searchController: TextEditingController(),
      showSearchField: false,
      onSearchToggle: (_) {},
      trailing: Row(
        children: [
          CupertinoButton(
            onPressed: () => _deleteEntity(),
            padding: EdgeInsets.zero,
            child: Icon(CupertinoIcons.delete, size: 25, color: colors.error),
          ),
        ],
      ),
      sliverList: SliverList(
        delegate: SliverChildListDelegate([
          _buildProfileHeader(colors),
          _buildSectionHeader('CLIENT INFORMATION', colors),
          _buildBasicInformationSection(colors),
          _buildContactInformationSection(colors),
          _buildBusinessInformationSection(colors),
          _buildAddressInformationSection(colors),
          _buildPaymentBankingSection(colors),
          _buildSectionHeader('ATTACHMENTS', colors),
          _buildAttachmentsDocumentsSection(colors),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _buildProfileHeader(WareozeColorScheme colors) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.border.withOpacity(0.1),
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
              border: Border.all(color: colors.border, width: 2),
            ),
            child:
                _data?['logo'] != null && _data!['logo'].toString().isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      _data!['logo'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        widget.entityType == 'customer'
                            ? CupertinoIcons.person_fill
                            : CupertinoIcons.building_2_fill,
                        size: 50,
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                : Icon(
                    widget.entityType == 'customer'
                        ? CupertinoIcons.person_fill
                        : CupertinoIcons.building_2_fill,
                    size: 50,
                    color: colors.textSecondary,
                  ),
          ),
          const SizedBox(height: 16),

          // Name and Legal Name
          Text(
            _data?['name'] ?? 'Unknown ${widget.entityType.capitalize()}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          if (_data?['legalName'] != null &&
              _data!['legalName'].toString().isNotEmpty &&
              _data!['legalName'] != _data!['name'])
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _data!['legalName'],
                style: TextStyle(color: colors.textSecondary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),

          // Registration Number
          if (_data?['registrationNo'] != null &&
              _data!['registrationNo'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Reg: ${_data!['registrationNo']}',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Status
          if (_data?['status'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _data?['isActive'] == true
                      ? colors.success.withOpacity(0.1)
                      : colors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _data!['status'],
                  style: TextStyle(
                    color: _data?['isActive'] == true
                        ? colors.success
                        : colors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, WareozeColorScheme colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSectionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required WareozeColorScheme colors,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.border.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: colors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
              Icon(
                CupertinoIcons.chevron_right,
                color: colors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInformationSection(WareozeColorScheme colors) {
    return _buildSectionTile(
      title: 'Basic Information',
      subtitle: 'Company name, legal name, contact person details',
      icon: CupertinoIcons.person_circle,
      colors: colors,
      onTap: () => _navigateToBasicInformationDetails(),
    );
  }

  Widget _buildContactInformationSection(WareozeColorScheme colors) {
    final email = (_data?['email'] as List?)?.isNotEmpty == true
        ? (_data!['email'] as List).first.toString()
        : 'Not provided';
    final phone = _data?['whatsAppNumber']?.toString() ?? 'Not provided';

    return _buildSectionTile(
      title: 'Contact Information',
      subtitle: 'Email: $email • Phone: $phone',
      icon: CupertinoIcons.phone,
      colors: colors,
      onTap: () => _navigateToContactInformationDetails(),
    );
  }

  Widget _buildBusinessInformationSection(WareozeColorScheme colors) {
    final regNo = _data?['registrationNo']?.toString() ?? '';
    final taxId1 = _data?['taxIdentificationNumber1']?.toString() ?? '';
    final taxId2 = _data?['taxIdentificationNumber2']?.toString() ?? '';

    List<String> businessInfo = [];
    if (regNo.isNotEmpty) businessInfo.add('Reg: $regNo');
    if (taxId1.isNotEmpty) businessInfo.add('GSTIN');
    if (taxId2.isNotEmpty) businessInfo.add('PAN');

    return _buildSectionTile(
      title: 'Business Information',
      subtitle: businessInfo.isNotEmpty
          ? businessInfo.join(' • ')
          : 'Registration, Tax IDs, Business type',
      icon: CupertinoIcons.briefcase,
      colors: colors,
      onTap: () => _navigateToBusinessInformationDetails(),
    );
  }

  Widget _buildAddressInformationSection(WareozeColorScheme colors) {
    final addressCount = (_data?['addresses'] as List?)?.length ?? 0;

    return _buildSectionTile(
      title: 'Address Information',
      subtitle: addressCount > 0
          ? '$addressCount address${addressCount > 1 ? 'es' : ''}'
          : 'Billing, shipping and other addresses',
      icon: CupertinoIcons.location,
      colors: colors,
      onTap: () => _navigateToAddressInformationDetails(),
    );
  }

  Widget _buildPaymentBankingSection(WareozeColorScheme colors) {
    final bankAccountCount = (_data?['bankAccounts'] as List?)?.length ?? 0;
    final upiId = _data?['upiId']?.toString() ?? '';
    final hasPaymentInfo = bankAccountCount > 0 || upiId.isNotEmpty;

    return _buildSectionTile(
      title: 'Payment & Banking',
      subtitle: hasPaymentInfo
          ? '$bankAccountCount bank account${bankAccountCount != 1 ? 's' : ''}${upiId.isNotEmpty ? ' • UPI configured' : ''}'
          : 'Banking Information, UPI details...',
      icon: CupertinoIcons.creditcard,
      colors: colors,
      onTap: () => _navigateToPaymentBankingDetails(),
    );
  }

  Widget _buildAttachmentsDocumentsSection(WareozeColorScheme colors) {
    final attachmentCount = (_data?['attachments'] as List?)?.length ?? 0;
    final hasLogo = _data?['logo']?.toString().isNotEmpty == true;
    final hasSignature = _data?['signature']?.toString().isNotEmpty == true;

    List<String> attachmentInfo = [];
    if (hasLogo) attachmentInfo.add('Logo');
    if (hasSignature) attachmentInfo.add('Signature');
    if (attachmentCount > 0) attachmentInfo.add('$attachmentCount docs');

    return _buildSectionTile(
      title: 'Attachments & Documents',
      subtitle: attachmentInfo.isNotEmpty
          ? attachmentInfo.join(' • ')
          : 'Logo, Signature, Documents',
      icon: CupertinoIcons.doc,
      colors: colors,
      onTap: () => _navigateToAttachmentsDocumentsDetails(),
    );
  }

  // Navigation methods to detail pages
  void _navigateToBasicInformationDetails() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => BasicInformationDetailsPage(
          entityData: _data,
          entityId: widget.entityId,
          entityType: widget.entityType,
        ),
      ),
    );
  }

  void _navigateToContactInformationDetails() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => ContactInformationDetailsPage(
          entityData: _data,
          entityId: widget.entityId,
          entityType: widget.entityType,
        ),
      ),
    );
  }

  void _navigateToBusinessInformationDetails() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => BusinessInformationDetailsPage(
          entityData: _data,
          entityId: widget.entityId,
          entityType: widget.entityType,
        ),
      ),
    );
  }

  void _navigateToAddressInformationDetails() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => AddressInformationDetailsPage(
          entityData: _data,
          entityId: widget.entityId,
          entityType: widget.entityType,
        ),
      ),
    );
  }

  void _navigateToPaymentBankingDetails() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => PaymentBankingDetailsPage(
          entityData: _data,
          entityId: widget.entityId,
          entityType: widget.entityType,
        ),
      ),
    );
  }

  void _navigateToAttachmentsDocumentsDetails() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => AttachmentsDocumentsDetailsPage(
          entityData: _data,
          entityId: widget.entityId,
          entityType: widget.entityType,
        ),
      ),
    );
  }

  void _deleteEntity() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Delete ${widget.entityType.capitalize()}'),
        content: Text(
          'Are you sure you want to delete this ${widget.entityType}? This action cannot be undone.',
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

    if (confirmed == true) {
      try {
        if (widget.entityType == 'customer') {
          await ref
              .read(customerActionsProvider)
              .deleteCustomer(widget.entityId);
        } else {
          await ref
              .read(supplierActionsProvider)
              .deleteSupplier(widget.entityId);
        }

        if (mounted) {
          context.go('/customersuppliers');
        }
      } catch (e) {
        _showErrorDialog('Failed to delete ${widget.entityType}: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
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

// =================
// DETAIL PAGES
// =================

// Basic Information Details Page
// Basic Information Details Page
class BasicInformationDetailsPage extends ConsumerWidget {
  final Map<String, dynamic>? entityData;
  final String entityId;
  final String entityType;

  const BasicInformationDetailsPage({
    super.key,
    required this.entityData,
    required this.entityId,
    required this.entityType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surface,
        middle: Text(
          'Basic Information',
          style: TextStyle(color: colors.textPrimary),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(CupertinoIcons.back, color: colors.primary),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go(
            '/customersuppliers/update/$entityId/basic?type=$entityType',
          ),
          child: Icon(CupertinoIcons.pencil, color: colors.primary, size: 20),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                'Company Name',
                entityData?['name']?.toString() ?? 'Not provided',
                colors,
              ),
              _buildDetailRow(
                'Legal Name',
                entityData?['legalName']?.toString() ?? 'Not provided',
                colors,
              ),
              _buildDetailRow(
                'Display Name',
                entityData?['displayName']?.toString() ?? 'Not provided',
                colors,
              ),
              _buildDetailRow(
                'Contact Person',
                entityData?['contactName']?.toString() ?? 'Not provided',
                colors,
              ),
              _buildDetailRow(
                'Company Description',
                entityData?['companyDesc']?.toString() ?? 'Not provided',
                colors,
              ),
              _buildDetailRow(
                'Industry Vertical',
                entityData?['industryVertical']?.toString() ?? 'Not provided',
                colors,
              ),
              _buildDetailRow(
                'Business Type',
                _getBusinessTypeString(entityData?['businessType']),
                colors,
              ),
              _buildDetailRow(
                'Status',
                entityData?['status']?.toString() ?? 'Not provided',
                colors,
              ),
              _buildDetailRow(
                'Active',
                entityData?['isActive'] == true ? 'Yes' : 'No',
                colors,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getBusinessTypeString(dynamic businessType) {
    if (businessType == null) {
      return 'Not provided';
    }

    if (businessType is List) {
      if (businessType.isEmpty) {
        return 'Not provided';
      }
      return businessType.map((e) => e.toString()).join(', ');
    }

    return businessType.toString();
  }

  Widget _buildDetailRow(
    String label,
    String value,
    WareozeColorScheme colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// Contact Information Details Page
class ContactInformationDetailsPage extends ConsumerWidget {
  final Map<String, dynamic>? entityData;
  final String entityId;
  final String entityType;

  const ContactInformationDetailsPage({
    super.key,
    required this.entityData,
    required this.entityId,
    required this.entityType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);
    final emails = entityData?['email'] as List? ?? [];
    final emailString = emails.join(', ');

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surface,
        middle: Text(
          'Contact Information',
          style: TextStyle(color: colors.textPrimary),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(CupertinoIcons.back, color: colors.primary),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go(
            '/customersuppliers/update/$entityId/contact?type=$entityType',
          ),
          child: Icon(CupertinoIcons.pencil, color: colors.primary, size: 20),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                'Email Addresses',
                emailString.isNotEmpty ? emailString : 'Not provided',
                colors,
              ),
              _buildDetailRow(
                'WhatsApp Number',
                entityData?['whatsAppNumber'] ?? 'Not provided',
                colors,
              ),
              _buildDetailRow(
                'Website',
                entityData?['website'] ?? 'Not provided',
                colors,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    WareozeColorScheme colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// Business Information Details Page
class BusinessInformationDetailsPage extends ConsumerWidget {
  final Map<String, dynamic>? entityData;
  final String entityId;
  final String entityType;

  const BusinessInformationDetailsPage({
    super.key,
    required this.entityData,
    required this.entityId,
    required this.entityType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surface,
        middle: Text(
          'Business Information',
          style: TextStyle(color: colors.textPrimary),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(CupertinoIcons.back, color: colors.primary),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go(
            '/customersuppliers/update/$entityId/business?type=$entityType',
          ),
          child: Icon(CupertinoIcons.pencil, color: colors.primary, size: 20),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                'Registration Number',
                entityData?['registrationNo'] ?? 'Not provided',
                colors,
              ),
              _buildDetailRow(
                'Tax ID 1 (GSTIN)',
                entityData?['taxIdentificationNumber1'] ?? 'Not provided',
                colors,
              ),
              _buildDetailRow(
                'Tax ID 2 (PAN)',
                entityData?['taxIdentificationNumber2'] ?? 'Not provided',
                colors,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    WareozeColorScheme colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// Address Information Details Page
class AddressInformationDetailsPage extends ConsumerWidget {
  final Map<String, dynamic>? entityData;
  final String entityId;
  final String entityType;

  const AddressInformationDetailsPage({
    super.key,
    required this.entityData,
    required this.entityId,
    required this.entityType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);
    final addresses = entityData?['addresses'] as List? ?? [];

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surface,
        middle: Text(
          'Address Information',
          style: TextStyle(color: colors.textPrimary),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(CupertinoIcons.back, color: colors.primary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.go(
                '/customersuppliers/update/$entityId/addresses?type=$entityType',
              ),
              child: Icon(CupertinoIcons.add, color: colors.primary, size: 20),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.go(
                '/customersuppliers/update/$entityId/addresses?type=$entityType',
              ),
              child: Icon(
                CupertinoIcons.pencil,
                color: colors.primary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: addresses.isEmpty
            ? _buildEmptyState(colors, context)
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: addresses.length + 1, // +1 for add button
                itemBuilder: (context, index) {
                  if (index == addresses.length) {
                    return _buildAddButton(colors, context);
                  }
                  return _buildAddressCard(addresses[index], colors, context);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState(WareozeColorScheme colors, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.location, size: 48, color: colors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No addresses added',
            style: TextStyle(fontSize: 18, color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Add billing and shipping addresses',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 24),
          _buildAddButton(colors, context),
        ],
      ),
    );
  }

  Widget _buildAddButton(WareozeColorScheme colors, BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withOpacity(0.2)),
      ),
      child: CupertinoButton(
        onPressed: () => context.go(
          '/customersuppliers/update/$entityId/addresses?type=$entityType',
        ),
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.add, color: colors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Add Address',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(
    Map<String, dynamic> address,
    WareozeColorScheme colors,
    BuildContext context,
  ) {
    final type = address['type'] ?? 'Address';
    final line1 = address['line1'] ?? '';
    final line2 = address['line2'] ?? '';
    final city = address['city'] ?? '';
    final state = address['state']?['name'] ?? '';
    final code = address['code'] ?? '';

    final addressParts = [
      if (line1.isNotEmpty) line1,
      if (line2.isNotEmpty) line2,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (code.isNotEmpty) code,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => context.go(
                  '/customersuppliers/update/$entityId/addresses?type=$entityType',
                ),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    CupertinoIcons.pencil,
                    color: colors.primary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            addressParts.join(', '),
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// Payment & Banking Details Page
class PaymentBankingDetailsPage extends ConsumerWidget {
  final Map<String, dynamic>? entityData;
  final String entityId;
  final String entityType;

  const PaymentBankingDetailsPage({
    super.key,
    required this.entityData,
    required this.entityId,
    required this.entityType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);
    final bankAccounts = entityData?['bankAccounts'] as List? ?? [];

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surface,
        middle: Text(
          'Payment & Banking',
          style: TextStyle(color: colors.textPrimary),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(CupertinoIcons.back, color: colors.primary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.go(
                '/customersuppliers/update/$entityId/payment?type=$entityType',
              ),
              child: Icon(CupertinoIcons.add, color: colors.primary, size: 20),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.go(
                '/customersuppliers/update/$entityId/payment?type=$entityType',
              ),
              child: Icon(
                CupertinoIcons.pencil,
                color: colors.primary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Information Section
              _buildPaymentInfoSection(colors),

              const SizedBox(height: 24),

              // Bank Accounts Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bank Accounts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => context.go(
                      '/customersuppliers/update/$entityId/payment?type=$entityType',
                    ),
                    child: Icon(
                      CupertinoIcons.add,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (bankAccounts.isEmpty)
                _buildEmptyBankAccountsState(colors)
              else
                ...bankAccounts.map(
                  (account) => _buildBankAccountCard(account, context, colors),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentInfoSection(WareozeColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            'UPI ID',
            entityData?['upiId'] ?? 'Not provided',
            colors,
          ),
          _buildDetailRow(
            'GPay Phone',
            entityData?['gPayPhone'] ?? 'Not provided',
            colors,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBankAccountsState(WareozeColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.creditcard,
            size: 32,
            color: colors.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            'No bank accounts added',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountCard(
    Map<String, dynamic> account,
    context,
    WareozeColorScheme colors,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                account['bankName'] ?? 'Bank Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => context.go(
                  '/customersuppliers/update/$entityId/payment?type=$entityType',
                ),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    CupertinoIcons.pencil,
                    color: colors.primary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Account Name',
            account['accountName'] ?? 'Not provided',
            colors,
          ),
          _buildDetailRow(
            'Account Number',
            account['accountNumber'] ?? 'Not provided',
            colors,
          ),
          _buildDetailRow(
            'IFSC Code',
            account['IFSC'] ?? 'Not provided',
            colors,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    WareozeColorScheme colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 14, color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}

// Attachments & Documents Details Page
class AttachmentsDocumentsDetailsPage extends ConsumerWidget {
  final Map<String, dynamic>? entityData;
  final String entityId;
  final String entityType;

  const AttachmentsDocumentsDetailsPage({
    super.key,
    required this.entityData,
    required this.entityId,
    required this.entityType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);
    final attachments = entityData?['attachments'] as List? ?? [];

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surface,
        middle: Text(
          'Attachments & Documents',
          style: TextStyle(color: colors.textPrimary),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(CupertinoIcons.back, color: colors.primary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.go(
                '/customersuppliers/update/$entityId/attachments?type=$entityType',
              ),
              child: Icon(CupertinoIcons.add, color: colors.primary, size: 20),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.go(
                '/customersuppliers/update/$entityId/attachments?type=$entityType',
              ),
              child: Icon(
                CupertinoIcons.pencil,
                color: colors.primary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo & Signature Section
              _buildLogoSignatureSection(colors),

              const SizedBox(height: 24),

              // Documents Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Documents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => context.go(
                      '/customersuppliers/update/$entityId/attachments?type=$entityType',
                    ),
                    child: Icon(
                      CupertinoIcons.add,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (attachments.isEmpty)
                _buildEmptyDocumentsState(colors)
              else
                ...attachments.map((doc) => _buildDocumentCard(doc, colors)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSignatureSection(WareozeColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Logo & Signature',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            'Logo',
            entityData?['logo'] != null ? 'Uploaded' : 'Not uploaded',
            colors,
          ),
          _buildDetailRow(
            'Signature',
            entityData?['signature'] != null ? 'Uploaded' : 'Not uploaded',
            colors,
          ),
          _buildDetailRow(
            'Show Logo on Invoice',
            entityData?['showLogoOnInvoice'] == true ? 'Yes' : 'No',
            colors,
          ),
          _buildDetailRow(
            'Show Signature on Invoice',
            entityData?['showSignatureOnInvoice'] == true ? 'Yes' : 'No',
            colors,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDocumentsState(WareozeColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(CupertinoIcons.doc, size: 32, color: colors.textSecondary),
          const SizedBox(height: 8),
          Text(
            'No documents uploaded',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(
    Map<String, dynamic> document,
    WareozeColorScheme colors,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.doc_text, color: colors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document['originalname'] ?? 'Document',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                if (document['attachmentLabel'] != null)
                  Text(
                    document['attachmentLabel'],
                    style: TextStyle(fontSize: 14, color: colors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    WareozeColorScheme colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 14, color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
