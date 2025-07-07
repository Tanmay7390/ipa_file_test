import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../components/page_scaffold.dart';
import '../../theme_provider.dart';
import '../../apis/providers/customer_provider.dart';
import '../../apis/providers/supplier_provider.dart';
import '../../forms/customersupplier_profile_update_form.dart';
import '../../components/addresses_bottom_sheet.dart';

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
          _buildSectionHeader('AGREED SERVICES', colors),
          _buildAgreedServicesSection(colors),
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

  Widget _buildAgreedServicesSection(WareozeColorScheme colors) {
    final agreedServices =
        (_data?['agreedServices'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return _buildSectionTile(
      title: 'Agreed Services',
      subtitle: agreedServices.isNotEmpty
          ? '${agreedServices.length} service${agreedServices.length != 1 ? 's' : ''} configured'
          : 'Service agreements and contracts',
      icon: CupertinoIcons.checkmark_alt,
      colors: colors,
      onTap: () => _navigateToAgreedServicesDetails(),
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

  void _navigateToAgreedServicesDetails() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => AgreedServicesDetailsPage(
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

class AddressInformationDetailsPage extends ConsumerStatefulWidget {
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
  ConsumerState<AddressInformationDetailsPage> createState() =>
      _AddressInformationDetailsPageState();
}

class _AddressInformationDetailsPageState
    extends ConsumerState<AddressInformationDetailsPage> {
  List<Map<String, dynamic>> addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  void _loadAddresses() {
    final addressList = widget.entityData?['addresses'] as List? ?? [];
    addresses = List<Map<String, dynamic>>.from(addressList);

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
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorProvider);

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
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Billing Address Section
              _buildAddressTypeSection('Billing', colors),
              const SizedBox(height: 24),

              // Shipping Address Section
              _buildAddressTypeSection('Shipping', colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressTypeSection(
    String addressType,
    WareozeColorScheme colors,
  ) {
    final address = addresses.firstWhere(
      (addr) => addr['type'] == addressType,
      orElse: () => <String, dynamic>{},
    );

    final hasAddressData =
        address.isNotEmpty &&
        (address['line1']?.toString().trim().isNotEmpty ?? false) &&
        (address['city']?.toString().trim().isNotEmpty ?? false) &&
        (address['code']?.toString().trim().isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '$addressType Address',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ),

        // Address Content
        if (!hasAddressData)
          _buildAddAddressButton(addressType, colors)
        else
          _buildAddressDisplay(address, addressType, colors),
      ],
    );
  }

  Widget _buildAddAddressButton(String addressType, WareozeColorScheme colors) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withOpacity(0.2)),
      ),
      child: CupertinoButton(
        onPressed: () => _showAddressBottomSheet(addressType),
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.add, color: colors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Add $addressType Address',
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

  Widget _buildAddressDisplay(
    Map<String, dynamic> address,
    String addressType,
    WareozeColorScheme colors,
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
              Row(
                children: [
                  Icon(
                    addressType == 'Billing'
                        ? CupertinoIcons.location
                        : CupertinoIcons.location_solid,
                    color: addressType == 'Billing'
                        ? colors.primary
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
                          ? colors.primary
                          : CupertinoColors.systemPurple,
                    ),
                  ),
                ],
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: () => _showAddressBottomSheet(addressType),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    CupertinoIcons.pencil,
                    size: 16,
                    color: colors.primary,
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

  // Show address bottom sheet directly
  void _showAddressBottomSheet(String addressType) {
    final addressData = <String, dynamic>{};

    // Find existing address data
    final existingAddress = addresses.firstWhere(
      (addr) => addr['type'] == addressType,
      orElse: () => <String, dynamic>{},
    );

    if (existingAddress.isNotEmpty) {
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

  // Update address from bottom sheet data and save to backend
  void _updateAddressFromBottomSheet(
    String addressType,
    Map<String, dynamic> bottomSheetData,
  ) async {
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

    // Save to backend
    await _saveAddressesToBackend();
  }

  Future<void> _saveAddressesToBackend() async {
    try {
      // Prepare data for backend using the FLAT FIELDS approach (like your working form)
      final submitData = Map<String, dynamic>.from(widget.entityData ?? {});

      // Remove the nested addresses array - don't send it
      submitData.remove('addresses');

      // Find billing and shipping addresses
      final billingAddress = addresses.firstWhere(
        (addr) => addr['type'] == 'Billing',
        orElse: () => <String, dynamic>{},
      );

      final shippingAddress = addresses.firstWhere(
        (addr) => addr['type'] == 'Shipping',
        orElse: () => <String, dynamic>{},
      );

      // Add billing address as FLAT FIELDS (matching your working form)
      if (billingAddress.isNotEmpty &&
          (billingAddress['line1']?.toString().trim().isNotEmpty ?? false)) {
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

        // Add country and state as JUST THE IDs (like your working form)
        if (billingAddress['country'] != null &&
            billingAddress['country']['_id'] != null) {
          submitData["billingAddressCountry"] =
              billingAddress['country']['_id'];
        }
        if (billingAddress['state'] != null &&
            billingAddress['state']['_id'] != null) {
          submitData["billingAddressState"] = billingAddress['state']['_id'];
        }

        print('Added billing address as flat fields:');
        print('  billingAddressLine1: "${submitData["billingAddressLine1"]}"');
        print('  billingAddressCity: "${submitData["billingAddressCity"]}"');
        print(
          '  billingAddressCountry: "${submitData["billingAddressCountry"]}"',
        );
      }

      // Add shipping address as FLAT FIELDS (matching your working form)
      if (shippingAddress.isNotEmpty &&
          (shippingAddress['line1']?.toString().trim().isNotEmpty ?? false)) {
        submitData["shippingAddressLine1"] = (shippingAddress['line1'] ?? '')
            .toString()
            .trim();
        submitData["shippingAddressLine2"] = (shippingAddress['line2'] ?? '')
            .toString()
            .trim();
        submitData["shippingAddressCity"] = (shippingAddress['city'] ?? '')
            .toString()
            .trim();
        submitData["shippingAddressPinCode"] = (shippingAddress['code'] ?? '')
            .toString()
            .trim();

        // Add country and state as JUST THE IDs (like your working form)
        if (shippingAddress['country'] != null &&
            shippingAddress['country']['_id'] != null) {
          submitData["shippingAddressCountry"] =
              shippingAddress['country']['_id'];
        }
        if (shippingAddress['state'] != null &&
            shippingAddress['state']['_id'] != null) {
          submitData["shippingAddressState"] = shippingAddress['state']['_id'];
        }

        print('Added shipping address as flat fields:');
        print(
          '  shippingAddressLine1: "${submitData["shippingAddressLine1"]}"',
        );
        print('  shippingAddressCity: "${submitData["shippingAddressCity"]}"');
        print(
          '  shippingAddressCountry: "${submitData["shippingAddressCountry"]}"',
        );
      }

      print('Final submit data (flat fields approach): $submitData');

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
        // Show success message
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: const Text('Address updated successfully'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
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
            content: Text(errorMessage ?? 'Failed to update address'),
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
      print('Error updating address: $e');
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
    }
  }
}

// Agreed Services Details Page
class AgreedServicesDetailsPage extends ConsumerWidget {
  final Map<String, dynamic>? entityData;
  final String entityId;
  final String entityType;

  const AgreedServicesDetailsPage({
    super.key,
    required this.entityData,
    required this.entityId,
    required this.entityType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);
    final agreedServices =
        (entityData?['agreedServices'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surface,
        middle: Text(
          'Agreed Services',
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
                '/customersuppliers/update/$entityId/agreedservices?type=$entityType',
              ),
              child: Icon(CupertinoIcons.add, color: colors.primary, size: 20),
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
              if (agreedServices.isEmpty)
                _buildEmptyServicesState(colors)
              else
                ...agreedServices.map(
                  (service) => _buildServiceCard(service, colors),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyServicesState(WareozeColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.checkmark_alt,
            size: 32,
            color: colors.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            'No agreed services',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    Map<String, dynamic> service,
    WareozeColorScheme colors,
  ) {
    final startDate = service['startDate'] != null
        ? DateTime.parse(service['startDate'])
        : null;
    final endDate = service['endDate'] != null
        ? DateTime.parse(service['endDate'])
        : null;

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
                service['serviceCategory'] ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'UID: ${service['uid']}',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            service['serviceName'] ?? '',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildServiceDetailItem(
                  'Service Budget',
                  '₹${service['serviceBudget']?.toString() ?? '0'}',
                  colors,
                ),
              ),
              Expanded(
                child: _buildServiceDetailItem(
                  'Personnel',
                  service['personnel']?.toString() ?? '0',
                  colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildServiceDetailItem(
                  'Start Date',
                  startDate != null
                      ? '${startDate.day.toString().padLeft(2, '0')} ${_getMonthName(startDate.month)} ${startDate.year}'
                      : 'Not set',
                  colors,
                ),
              ),
              Expanded(
                child: _buildServiceDetailItem(
                  'End Date',
                  endDate != null
                      ? '${endDate.day.toString().padLeft(2, '0')} ${_getMonthName(endDate.month)} ${endDate.year}'
                      : 'Not set',
                  colors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetailItem(
    String label,
    String value,
    WareozeColorScheme colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
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
