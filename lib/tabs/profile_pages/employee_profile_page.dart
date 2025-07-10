import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:developer';
import '../../apis/providers/employee_provider.dart';
import '../../theme_provider.dart';
import '../../router.dart';
import '../../forms/employee_profile_update_form.dart';

// Extension for firstOrNull if not available
extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class EmployeeProfilePage extends ConsumerStatefulWidget {
  final String employeeId;

  const EmployeeProfilePage({super.key, required this.employeeId});

  @override
  ConsumerState<EmployeeProfilePage> createState() =>
      _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends ConsumerState<EmployeeProfilePage> {
  Map<String, dynamic>? employeeData;
  bool isLoading = true;
  String? error;

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    if (url.toLowerCase() == 'null') return false;
    if (!url.startsWith('http://') && !url.startsWith('https://')) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
  }

  Future<void> _loadEmployeeData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final response = await ref
          .read(employeeActionsProvider)
          .getEmployee(widget.employeeId);

      if (response.success && response.data != null) {
        setState(() {
          employeeData = response.data;
          isLoading = false;
        });
      } else {
        setState(() {
          error = response.error ?? 'Failed to load employee data';
          isLoading = false;
        });
      }
    } catch (e) {
      log('Error loading employee data: $e');
      setState(() {
        error = 'An error occurred while loading employee data';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorProvider);

    if (isLoading) {
      return CupertinoPageScaffold(
        backgroundColor: colors.background,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: colors.surface,
          middle: Text(
            'Employee Profile',
            style: TextStyle(color: colors.textPrimary),
          ),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => context.pop(),
            child: Icon(CupertinoIcons.back, color: colors.primary),
          ),
        ),
        child: Center(child: CupertinoActivityIndicator(color: colors.primary)),
      );
    }

    if (error != null) {
      return CupertinoPageScaffold(
        backgroundColor: colors.background,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: colors.surface,
          middle: Text(
            'Employee Profile',
            style: TextStyle(color: colors.textPrimary),
          ),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => context.pop(),
            child: Icon(CupertinoIcons.back, color: colors.primary),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 48,
                color: colors.error,
              ),
              const SizedBox(height: 16),
              Text(
                error!,
                style: TextStyle(color: colors.textSecondary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CupertinoButton(
                onPressed: _loadEmployeeData,
                child: Text('Retry', style: TextStyle(color: colors.primary)),
              ),
            ],
          ),
        ),
      );
    }

    final employee = employeeData!;
    final employeeName = employee['name'] ?? 'Unknown Employee';
    final employeeId = employee['empId'] ?? employee['_id'] ?? '';
    final employeePhoto = employee['photo'];

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surface,
        middle: Text(employeeName, style: TextStyle(color: colors.textPrimary)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: Icon(CupertinoIcons.back, color: colors.primary),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: Text(
                  'Download',
                  style: TextStyle(color: colors.textPrimary),
                ),
                content: Text(
                  'Download employee profile as PDF?',
                  style: TextStyle(color: colors.textSecondary),
                ),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                  CupertinoDialogAction(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Implement download functionality
                    },
                    child: Text(
                      'Download',
                      style: TextStyle(color: colors.primary),
                    ),
                  ),
                ],
              ),
            );
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              CupertinoIcons.cloud_download,
              color: colors.primary,
              size: 18,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Employee Header Section
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Profile Photo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.border, width: 2),
                      ),
                      child: _isValidImageUrl(employeePhoto)
                          ? ClipOval(
                              child: Image.network(
                                employeePhoto!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    CupertinoIcons.person_fill,
                                    size: 48,
                                    color: colors.textSecondary,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              CupertinoIcons.person_fill,
                              size: 48,
                              color: colors.textSecondary,
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Employee Name
                    Text(
                      employeeName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),

                    if (employeeId.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        employeeId,
                        style: TextStyle(
                          fontSize: 16,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Client Information (if exists)
            if (employee['client'] != null) ...[
              SliverToBoxAdapter(child: _buildSectionHeader('CLIENT', colors)),
              SliverToBoxAdapter(
                child: _buildClientSection(employee['client'], colors),
              ),
            ],

            // Base Location
            if (employee['baseLocation'] != null) ...[
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  'Base Location',
                  colors,
                  showAsterisk: true,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildBaseLocationSection(
                  employee['baseLocation'],
                  colors,
                ),
              ),
            ],

            // Main Sections Header
            SliverToBoxAdapter(child: _buildSectionHeader('GENERAL', colors)),

            // Section Items
            SliverToBoxAdapter(
              child: _buildSectionItem(
                icon: CupertinoIcons.person,
                title: 'Personal',
                subtitle: _getPersonalSubtitle(employee),
                onTap: () => _navigateToPersonalDetails(employee, context),
                colors: colors,
              ),
            ),

            SliverToBoxAdapter(
              child: _buildSectionItem(
                icon: CupertinoIcons.location,
                title: 'Address',
                subtitle: _getAddressSubtitle(employee),
                onTap: () => _navigateToAddressDetails(employee, context),
                colors: colors,
              ),
            ),

            SliverToBoxAdapter(
              child: _buildSectionItem(
                icon: CupertinoIcons.group,
                title: 'Family & Dependents',
                subtitle: _getFamilySubtitle(employee),
                onTap: () => _navigateToFamilyDetails(employee, context),
                colors: colors,
              ),
            ),

            // Other Sections Header
            SliverToBoxAdapter(child: _buildSectionHeader('OTHER', colors)),

            SliverToBoxAdapter(
              child: _buildSectionItem(
                icon: CupertinoIcons.person_crop_rectangle,
                title: 'Emergency Contacts',
                subtitle: _getEmergencyContactsSubtitle(employee),
                onTap: () => _navigateToEmergencyContacts(employee, context),
                colors: colors,
              ),
            ),

            SliverToBoxAdapter(
              child: _buildSectionItem(
                icon: CupertinoIcons.book,
                title: 'Education',
                subtitle: _getEducationSubtitle(employee),
                onTap: () => _navigateToEducationDetails(employee, context),
                colors: colors,
              ),
            ),

            SliverToBoxAdapter(
              child: _buildSectionItem(
                icon: CupertinoIcons.briefcase,
                title: 'Employment & Experience',
                subtitle: _getEmploymentSubtitle(employee),
                onTap: () => _navigateToEmploymentDetails(employee, context),
                colors: colors,
              ),
            ),

            SliverToBoxAdapter(
              child: _buildSectionItem(
                icon: CupertinoIcons.rectangle_stack,
                title: 'Compliance & Uniform Details',
                subtitle: _getUniformSubtitle(employee),
                onTap: () => _navigateToUniformDetails(employee, context),
                colors: colors,
              ),
            ),

            // Attachments Header
            SliverToBoxAdapter(
              child: _buildSectionHeader('ATTACHMENTS', colors),
            ),

            SliverToBoxAdapter(
              child: _buildSectionItem(
                icon: CupertinoIcons.doc,
                title: 'KYC Documents',
                subtitle: _getKYCSubtitle(employee),
                onTap: () => _navigateToKYCDocuments(employee, context),
                colors: colors,
              ),
            ),

            SliverToBoxAdapter(
              child: _buildSectionItem(
                icon: CupertinoIcons.doc,
                title: 'Additional Documents',
                subtitle: _getAdditionalDocsSubtitle(employee),
                onTap: () => _navigateToAdditionalDocuments(employee, context),
                colors: colors,
              ),
            ),

            SliverToBoxAdapter(
              child: _buildSectionItem(
                icon: CupertinoIcons.doc_text,
                title: 'PVC & BVC',
                subtitle: _getPVCBVCSubtitle(employee),
                onTap: () => _navigateToPVCBVC(employee, context),
                colors: colors,
              ),
            ),

            SliverToBoxAdapter(
              child: _buildSectionItem(
                icon: CupertinoIcons.hand_raised,
                title: 'Thumb & Signature',
                subtitle: _getThumbSignatureSubtitle(employee),
                onTap: () => _navigateToThumbSignature(employee, context),
                colors: colors,
              ),
            ),

            SliverToBoxAdapter(
              child: _buildSectionItem(
                icon: CupertinoIcons.doc_text_fill,
                title: 'BGV Consent Form',
                subtitle: _getBGVConsentSubtitle(employee),
                onTap: () => _navigateToBGVConsent(employee, context),
                colors: colors,
              ),
            ),

            SliverToBoxAdapter(
              child: _buildSectionItem(
                icon: CupertinoIcons.doc_text_fill,
                title: 'Terms & Conditions',
                subtitle: _getTermsConditionsSubtitle(employee),
                onTap: () => _navigateToTermsConditions(employee, context),
                colors: colors,
              ),
            ),

            // Settings Header
            SliverToBoxAdapter(child: _buildSectionHeader('SETTINGS', colors)),

            SliverToBoxAdapter(
              child: _buildSectionItem(
                icon: CupertinoIcons.settings,
                title: 'Settings',
                subtitle: 'Customize with settings',
                onTap: () => _navigateToSettings(employee, context),
                colors: colors,
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  // Helper methods to generate dynamic subtitles
  String _getPersonalSubtitle(Map<String, dynamic> employee) {
    final name = employee['name'] ?? '';
    final email = employee['personalEmail'] ?? '';
    final phone = employee['primaryPhone'] ?? '';

    List<String> info = [];
    if (name.isNotEmpty) info.add(name);
    if (email.isNotEmpty) info.add(email);
    if (phone.isNotEmpty) info.add(phone);

    return info.isEmpty ? 'Add personal information' : info.join(' • ');
  }

  String _getAddressSubtitle(Map<String, dynamic> employee) {
    final addresses = employee['addresses'] as List? ?? [];
    if (addresses.isEmpty) return 'Add address information';

    return '${addresses.length} address${addresses.length > 1 ? 'es' : ''} added';
  }

  String _getFamilySubtitle(Map<String, dynamic> employee) {
    final dependents = employee['dependents'] as List? ?? [];
    if (dependents.isEmpty) return 'Add family & dependents information';

    return '${dependents.length} dependent${dependents.length > 1 ? 's' : ''} added';
  }

  String _getEmergencyContactsSubtitle(Map<String, dynamic> employee) {
    final emergencyPhones = employee['emergencyPhones'] as List? ?? [];
    if (emergencyPhones.isEmpty) return 'Add emergency contacts';

    return '${emergencyPhones.length} contact${emergencyPhones.length > 1 ? 's' : ''} added';
  }

  String _getEducationSubtitle(Map<String, dynamic> employee) {
    final education = employee['education'] as List? ?? [];
    if (education.isEmpty) return 'Add education details';

    return '${education.length} education record${education.length > 1 ? 's' : ''} added';
  }

  String _getEmploymentSubtitle(Map<String, dynamic> employee) {
    final prevEmployment = employee['prevEmployment'] as List? ?? [];
    final currentEmp = employee['empId'] != null ? 1 : 0;
    final total = currentEmp + prevEmployment.length;

    if (total == 0) return 'Add employment details';
    return '$total employment record${total > 1 ? 's' : ''} added';
  }

  String _getUniformSubtitle(Map<String, dynamic> employee) {
    final uniform = employee['uniform'] as List? ?? [];
    if (uniform.isEmpty) return 'Add uniform details';

    return '${uniform.length} uniform item${uniform.length > 1 ? 's' : ''} added';
  }

  String _getKYCSubtitle(Map<String, dynamic> employee) {
    final attachments = employee['attachments'] as List? ?? [];
    final kycDocs = attachments
        .where(
          (doc) => [
            'aadharCard',
            'panCard',
            'passbook',
          ].contains(doc['attachmentLabel']),
        )
        .toList();

    if (kycDocs.isEmpty) return 'Add KYC documents';
    return '${kycDocs.length} KYC document${kycDocs.length > 1 ? 's' : ''} uploaded';
  }

  String _getAdditionalDocsSubtitle(Map<String, dynamic> employee) {
    final attachments = employee['attachments'] as List? ?? [];
    final additionalDocs = attachments
        .where(
          (doc) => ![
            'aadharCard',
            'panCard',
            'passbook',
            'pvc',
            'signature',
            'bgvConsentPhoto',
            'termsAndConditionPhoto',
          ].contains(doc['attachmentLabel']),
        )
        .toList();

    if (additionalDocs.isEmpty) return 'Add additional documents';
    return '${additionalDocs.length} additional document${additionalDocs.length > 1 ? 's' : ''} uploaded';
  }

  String _getPVCBVCSubtitle(Map<String, dynamic> employee) {
    final attachments = employee['attachments'] as List? ?? [];
    final pvcDocs = attachments
        .where((doc) => doc['attachmentLabel'] == 'pvc')
        .toList();

    if (pvcDocs.isEmpty) return 'Add PVC & BVC documents';
    return '${pvcDocs.length} PVC document${pvcDocs.length > 1 ? 's' : ''} uploaded';
  }

  String _getThumbSignatureSubtitle(Map<String, dynamic> employee) {
    final signature = employee['signature'];
    final attachments = employee['attachments'] as List? ?? [];
    final signatureDocs = attachments
        .where((doc) => doc['attachmentLabel'] == 'signature')
        .toList();

    if (signature == null && signatureDocs.isEmpty)
      return 'Add thumb & signature';
    return 'Thumb & signature added';
  }

  String _getBGVConsentSubtitle(Map<String, dynamic> employee) {
    final attachments = employee['attachments'] as List? ?? [];
    final bgvDocs = attachments
        .where((doc) => doc['attachmentLabel'] == 'bgvConsentPhoto')
        .toList();

    if (bgvDocs.isEmpty) return 'Add BGV consent form';
    return 'BGV consent form uploaded';
  }

  String _getTermsConditionsSubtitle(Map<String, dynamic> employee) {
    final attachments = employee['attachments'] as List? ?? [];
    final termsDocs = attachments
        .where((doc) => doc['attachmentLabel'] == 'termsAndConditionPhoto')
        .toList();

    if (termsDocs.isEmpty) return 'Add terms & conditions';
    return 'Terms & conditions uploaded';
  }

  Widget _buildSectionHeader(
    String title,
    WareozeColorScheme colors, {
    bool showAsterisk = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          if (showAsterisk) ...[
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClientSection(
    Map<String, dynamic> client,
    WareozeColorScheme colors,
  ) {
    final clientName = client['name'] ?? '';
    final contactName = client['contactName'] ?? '';
    final emails = client['email'] as List? ?? [];
    final phone = client['whatsAppNumber'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                if (contactName.isNotEmpty ||
                    emails.isNotEmpty ||
                    phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (contactName.isNotEmpty) contactName,
                      if (emails.isNotEmpty) emails.first,
                      if (phone.isNotEmpty) phone,
                    ].join(' | '),
                    style: TextStyle(fontSize: 14, color: colors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              CupertinoIcons.refresh,
              color: colors.primary,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaseLocationSection(
    Map<String, dynamic> location,
    WareozeColorScheme colors,
  ) {
    final line1 = location['line1'] ?? '';
    final line2 = location['line2'] ?? '';
    final city = location['city'] ?? '';
    final state = location['state']?['name'] ?? '';
    final code = location['code'] ?? '';

    final addressParts = [
      if (line1.isNotEmpty) line1,
      if (line2.isNotEmpty) line2,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (code.isNotEmpty) code,
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        addressParts.join(', '),
        style: TextStyle(fontSize: 16, color: colors.textPrimary, height: 1.4),
      ),
    );
  }

  Widget _buildSectionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required WareozeColorScheme colors,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
                    const SizedBox(height: 2),
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

  // Navigation methods - Fixed to use widget.employeeId
  void _navigateToPersonalDetails(
    Map<String, dynamic> employee,
    BuildContext context,
  ) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => EmployeePersonalDetailsPage(
          employee: employee,
          employeeId: widget.employeeId,
        ),
      ),
    );
  }

  void _navigateToAddressDetails(
    Map<String, dynamic> employee,
    BuildContext context,
  ) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => EmployeeAddressDetailsPage(
          employee: employee,
          employeeId: widget.employeeId,
        ),
      ),
    );
  }

  void _navigateToFamilyDetails(
    Map<String, dynamic> employee,
    BuildContext context,
  ) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => EmployeeFamilyDetailsPage(
          employee: employee,
          employeeId: widget.employeeId,
        ),
      ),
    );
  }

  void _navigateToEmergencyContacts(
    Map<String, dynamic> employee,
    BuildContext context,
  ) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => EmployeeEmergencyContactsPage(
          employee: employee,
          employeeId: widget.employeeId,
        ),
      ),
    );
  }

  void _navigateToEducationDetails(
    Map<String, dynamic> employee,
    BuildContext context,
  ) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => EmployeeEducationDetailsPage(
          employee: employee,
          employeeId: widget.employeeId,
        ),
      ),
    );
  }

  void _navigateToEmploymentDetails(
    Map<String, dynamic> employee,
    BuildContext context,
  ) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => EmployeeEmploymentDetailsPage(
          employee: employee,
          employeeId: widget.employeeId,
        ),
      ),
    );
  }

  void _navigateToUniformDetails(
    Map<String, dynamic> employee,
    BuildContext context,
  ) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => EmployeeUniformDetailsPage(
          employee: employee,
          employeeId: widget.employeeId,
        ),
      ),
    );
  }

  void _navigateToKYCDocuments(
    Map<String, dynamic> employee,
    BuildContext context,
  ) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => EmployeeKYCDocumentsPage(
          employee: employee,
          employeeId: widget.employeeId,
        ),
      ),
    );
  }

  void _navigateToAdditionalDocuments(
    Map<String, dynamic> employee,
    BuildContext context,
  ) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => EmployeeAdditionalDocumentsPage(
          employee: employee,
          employeeId: widget.employeeId,
        ),
      ),
    );
  }

  void _navigateToPVCBVC(Map<String, dynamic> employee, BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => EmployeePVCBVCPage(
          employee: employee,
          employeeId: widget.employeeId,
        ),
      ),
    );
  }

  void _navigateToThumbSignature(
    Map<String, dynamic> employee,
    BuildContext context,
  ) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => EmployeeThumbSignaturePage(
          employee: employee,
          employeeId: widget.employeeId,
        ),
      ),
    );
  }

  void _navigateToBGVConsent(
    Map<String, dynamic> employee,
    BuildContext context,
  ) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => EmployeeBGVConsentPage(
          employee: employee,
          employeeId: widget.employeeId,
        ),
      ),
    );
  }

  void _navigateToTermsConditions(
    Map<String, dynamic> employee,
    BuildContext context,
  ) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => EmployeeTermsConditionsPage(
          employee: employee,
          employeeId: widget.employeeId,
        ),
      ),
    );
  }

  void _navigateToSettings(
    Map<String, dynamic> employee,
    BuildContext context,
  ) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => EmployeeSettingsPage(
          employee: employee,
          employeeId: widget.employeeId,
        ),
      ),
    );
  }
}

// Personal Details Page - Fixed employeeId
class EmployeePersonalDetailsPage extends ConsumerWidget {
  final Map<String, dynamic> employee;
  final String employeeId;
  final VoidCallback? onEdit;

  const EmployeePersonalDetailsPage({
    super.key,
    required this.employee,
    required this.employeeId,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);
    final employeeName = employee['name'] ?? 'Unknown';

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surface,
        middle: Text(
          'Personal Details',
          style: TextStyle(color: colors.textPrimary),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(CupertinoIcons.back, color: colors.primary),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/employee/update/$employeeId/personal'),
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
                'Full Name',
                employee['name'] ?? 'Not provided',
                colors,
              ),
              _buildDetailRow(
                'Employee ID',
                employee['empId'] ?? 'Not provided',
                colors,
              ),
              _buildDetailRow(
                'Personal Email',
                employee['personalEmail'] ?? 'Not provided',
                colors,
              ),
              _buildDetailRow(
                'Primary Phone',
                _formatPhone(employee['primaryPhone']),
                colors,
              ),
              _buildDetailRow(
                'Alternate Phone',
                _formatPhone(employee['alternatePhone']),
                colors,
              ),
              _buildDetailRow(
                'Gender',
                _formatGender(employee['gender']),
                colors,
              ),
              _buildDetailRow(
                'Date of Birth',
                _formatDate(employee['dob']),
                colors,
              ),
              _buildDetailRow('Age', _calculateAge(employee['dob']), colors),
              _buildDetailRow(
                'Marital Status',
                employee['isMarried'] == true ? 'Married' : 'Unmarried',
                colors,
              ),

              if (employee['languages'] != null &&
                  (employee['languages'] as List).isNotEmpty)
                _buildDetailRow(
                  'Languages',
                  (employee['languages'] as List).join(', '),
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

  String _calculateAge(dynamic dob) {
    if (dob == null) return 'Not provided';
    try {
      DateTime dateOfBirth = DateTime.parse(dob.toString());
      final now = DateTime.now();
      final age = now.year - dateOfBirth.year;
      final isBeforeBirthday =
          now.month < dateOfBirth.month ||
          (now.month == dateOfBirth.month && now.day < dateOfBirth.day);
      return '${isBeforeBirthday ? age - 1 : age} years';
    } catch (e) {
      return 'Not provided';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not provided';
    try {
      DateTime dateTime = DateTime.parse(date.toString());
      final months = [
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
      return '${dateTime.day.toString().padLeft(2, '0')} ${months[dateTime.month - 1]} ${dateTime.year}';
    } catch (e) {
      return 'Not provided';
    }
  }

  String _formatGender(dynamic gender) {
    if (gender == null) return 'Not provided';
    final genderStr = gender.toString().toLowerCase();
    return genderStr[0].toUpperCase() + genderStr.substring(1);
  }

  String _formatPhone(dynamic phone) {
    if (phone == null) return 'Not provided';
    final phoneStr = phone.toString();
    if (phoneStr.isEmpty) return 'Not provided';
    return '+91 $phoneStr';
  }
}

// Employment Details Page - Fixed employeeId
class EmployeeEmploymentDetailsPage extends ConsumerWidget {
  final Map<String, dynamic> employee;
  final String employeeId;

  const EmployeeEmploymentDetailsPage({
    super.key,
    required this.employee,
    required this.employeeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);
    final prevEmployment = employee['prevEmployment'] as List? ?? [];

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surface,
        middle: Text(
          'Employment & Experience',
          style: TextStyle(color: colors.textPrimary),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(CupertinoIcons.back, color: colors.primary),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () =>
              context.go('/employee/update/$employeeId/employment'),
          child: Icon(CupertinoIcons.pencil, color: colors.primary, size: 20),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Employment Section
              Text(
                'Current Employment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildCurrentEmploymentCard(employee, colors, context),

              const SizedBox(height: 24),

              // Previous Employment Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Previous Experience',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () =>
                        context.go('/employee/update/$employeeId/employment'),
                    child: Icon(
                      CupertinoIcons.add,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (prevEmployment.isEmpty)
                _buildEmptyExperienceState(colors)
              else
                ...prevEmployment
                    .map(
                      (emp) =>
                          _buildPreviousEmploymentCard(emp, colors, context),
                    )
                    .toList(),

              const SizedBox(height: 16),
              _buildAddExperienceButton(colors, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentEmploymentCard(
    Map<String, dynamic> employee,
    WareozeColorScheme colors,
    BuildContext context, // Add context parameter
  ) {
    final empId = employee['empId'] ?? 'Not assigned';
    final createdAt = employee['createdAt'];
    final joinDate = createdAt != null
        ? _formatDate(createdAt)
        : 'Not specified';

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
          Row(
            children: [
              Expanded(child: _buildDetailColumn('Employee ID', empId, colors)),
              const SizedBox(width: 20),
              Expanded(
                child: _buildDetailColumn('Join Date', joinDate, colors),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDetailColumn('Status', 'Active', colors)),
              const SizedBox(width: 20),
              Expanded(
                child: _buildDetailColumn(
                  'Department',
                  'Not specified',
                  colors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyExperienceState(WareozeColorScheme colors) {
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
          Icon(CupertinoIcons.briefcase, size: 32, color: colors.textSecondary),
          const SizedBox(height: 8),
          Text(
            'No previous experience added',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousEmploymentCard(
    Map<String, dynamic> employment,
    WareozeColorScheme colors,
    BuildContext context, // Add context parameter
  ) {
    final companyName = employment['companyName'] ?? 'Not specified';
    final designation = employment['designation'] ?? 'Not specified';
    final startDate = _formatDate(employment['startDate']);
    final endDate = _formatDate(employment['endDate']);

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
              Expanded(
                child: Text(
                  companyName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Row(
                children: [
                  _buildActionButton(
                    CupertinoIcons.pencil,
                    colors.primary,
                    colors,
                    () => context.go('/employee/update/$employeeId/employment'),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    CupertinoIcons.xmark,
                    colors.error,
                    colors,
                    () {
                      // Delete employment - implement in update form
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Designation', designation, colors),
          Row(
            children: [
              Expanded(
                child: _buildDetailColumn('Start Date', startDate, colors),
              ),
              const SizedBox(width: 20),
              Expanded(child: _buildDetailColumn('End Date', endDate, colors)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    Color color,
    WareozeColorScheme colors,
    VoidCallback onPressed,
  ) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  Widget _buildAddExperienceButton(
    WareozeColorScheme colors,
    BuildContext context,
  ) {
    // Add context parameter
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withOpacity(0.2)),
      ),
      child: CupertinoButton(
        onPressed: () => context.go('/employee/update/$employeeId/employment'),
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.add, color: colors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Add Previous Experience',
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

  Widget _buildDetailRow(
    String label,
    String value,
    WareozeColorScheme colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

  Widget _buildDetailColumn(
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
        Text(value, style: TextStyle(fontSize: 14, color: colors.textPrimary)),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not specified';
    try {
      DateTime dateTime = DateTime.parse(date.toString());
      final months = [
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
      return '${dateTime.day.toString().padLeft(2, '0')} ${months[dateTime.month - 1]} ${dateTime.year}';
    } catch (e) {
      return 'Not specified';
    }
  }
}

// Employee Address Details Page - Fixed employeeId and navigation
class EmployeeAddressDetailsPage extends ConsumerWidget {
  final Map<String, dynamic> employee;
  final String employeeId;

  const EmployeeAddressDetailsPage({
    super.key,
    required this.employee,
    required this.employeeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);
    final addresses = employee['addresses'] as List? ?? [];

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surface,
        middle: Text(
          'Address Details',
          style: TextStyle(color: colors.textPrimary),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(CupertinoIcons.back, color: colors.primary),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/employee/update/$employeeId/addresses'),
          child: Icon(CupertinoIcons.add, color: colors.primary, size: 20),
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
            'Add your present and permanent address',
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
        onPressed: () => context.go('/employee/update/$employeeId/addresses'),
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
              Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () =>
                        context.go('/employee/update/$employeeId/addresses'),
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
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      // Delete address - implement in update form
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        CupertinoIcons.xmark,
                        color: colors.error,
                        size: 16,
                      ),
                    ),
                  ),
                ],
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

// Employee Education Details Page - Fixed employeeId and navigation
class EmployeeEducationDetailsPage extends ConsumerWidget {
  final Map<String, dynamic> employee;
  final String employeeId;

  const EmployeeEducationDetailsPage({
    super.key,
    required this.employee,
    required this.employeeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);
    final education = employee['education'] as List? ?? [];

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surface,
        middle: Text(
          'Education Details',
          style: TextStyle(color: colors.textPrimary),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(CupertinoIcons.back, color: colors.primary),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/employee/update/$employeeId/education'),
          child: Icon(CupertinoIcons.add, color: colors.primary, size: 20),
        ),
      ),
      child: SafeArea(
        child: education.isEmpty
            ? _buildEmptyState(colors, context)
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: education.length + 1,
                itemBuilder: (context, index) {
                  if (index == education.length) {
                    return _buildAddButton(colors, context);
                  }
                  return _buildEducationCard(education[index], colors, context);
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
          Icon(CupertinoIcons.book, size: 48, color: colors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No education records',
            style: TextStyle(fontSize: 18, color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your education qualifications',
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
        onPressed: () => context.go('/employee/update/$employeeId/education'),
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.add, color: colors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Add Education',
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

  Widget _buildEducationCard(
    Map<String, dynamic> education,
    WareozeColorScheme colors,
    BuildContext context,
  ) {
    final course = education['course'] ?? 'Not specified';
    final college = education['college'] ?? 'Not specified';
    final university = education['university'] ?? 'Not specified';
    final percentage = education['percentage']?.toString() ?? 'Not specified';
    final passingYear =
        education['passing_year']?.toString() ?? 'Not specified';

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
              Expanded(
                child: Text(
                  course,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () =>
                        context.go('/employee/update/$employeeId/education'),
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
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      // Delete education - implement in update form
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        CupertinoIcons.xmark,
                        color: colors.error,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('College', college, colors),
          _buildDetailRow('University', university, colors),
          Row(
            children: [
              Expanded(
                child: _buildDetailColumn('Percentage', '$percentage%', colors),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildDetailColumn('Passing Year', passingYear, colors),
              ),
            ],
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
      padding: const EdgeInsets.only(bottom: 8),
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

  Widget _buildDetailColumn(
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
        Text(value, style: TextStyle(fontSize: 14, color: colors.textPrimary)),
      ],
    );
  }
}

// Emergency Contacts Page - Fixed employeeId and navigation
class EmployeeEmergencyContactsPage extends ConsumerWidget {
  final Map<String, dynamic> employee;
  final String employeeId;

  const EmployeeEmergencyContactsPage({
    super.key,
    required this.employee,
    required this.employeeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);
    final emergencyPhones = employee['emergencyPhones'] as List? ?? [];

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surface,
        middle: Text(
          'Emergency Contacts',
          style: TextStyle(color: colors.textPrimary),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(CupertinoIcons.back, color: colors.primary),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/employee/update/$employeeId/contact'),
          child: Icon(CupertinoIcons.add, color: colors.primary, size: 20),
        ),
      ),
      child: SafeArea(
        child: emergencyPhones.isEmpty
            ? _buildEmptyState(colors, context)
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: emergencyPhones.length + 1,
                itemBuilder: (context, index) {
                  if (index == emergencyPhones.length) {
                    return _buildAddButton(colors, context);
                  }
                  return _buildContactCard(
                    emergencyPhones[index],
                    colors,
                    context,
                  );
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
          Icon(
            CupertinoIcons.person_crop_rectangle,
            size: 48,
            color: colors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No emergency contacts',
            style: TextStyle(fontSize: 18, color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Add contacts for emergency situations',
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
        onPressed: () => context.go('/employee/update/$employeeId/contact'),
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.add, color: colors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Add Emergency Contact',
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

  Widget _buildContactCard(
    Map<String, dynamic> contact,
    WareozeColorScheme colors,
    BuildContext context,
  ) {
    final name = contact['name'] ?? 'Not specified';
    final relation = contact['relation'] ?? 'Not specified';
    final phone = contact['phone'] ?? 'Not specified';

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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              CupertinoIcons.person_crop_circle,
              color: colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$relation • $phone',
                  style: TextStyle(fontSize: 14, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () =>
                    context.go('/employee/update/$employeeId/contact'),
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
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  // Delete contact - implement in update form
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    CupertinoIcons.xmark,
                    color: colors.error,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Employee Family & Dependents Details Page - Fixed employeeId and navigation
class EmployeeFamilyDetailsPage extends ConsumerWidget {
  final Map<String, dynamic> employee;
  final String employeeId;

  const EmployeeFamilyDetailsPage({
    super.key,
    required this.employee,
    required this.employeeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);
    final dependents = employee['dependents'] as List? ?? [];

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surface,
        middle: Text(
          'Family & Dependents',
          style: TextStyle(color: colors.textPrimary),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(CupertinoIcons.back, color: colors.primary),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.go('/employee/update/$employeeId/family'),
          child: Icon(CupertinoIcons.add, color: colors.primary, size: 20),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Spouse Information Section (if married)
            if (employee['isMarried'] == true) ...[
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SPOUSE INFORMATION',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              CupertinoIcons.heart,
                              color: colors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  employee['spouseName'] ?? 'Not provided',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  employee['spousePhone'] ?? 'Not provided',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => context.go(
                              '/employee/update/$employeeId/family',
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
                    ),
                  ],
                ),
              ),
            ],

            // Dependents Section Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DEPENDENTS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () =>
                        context.go('/employee/update/$employeeId/family'),
                    child: Icon(
                      CupertinoIcons.add,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Dependents List
            Expanded(
              child: dependents.isEmpty
                  ? _buildEmptyState(colors, context)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: dependents.length + 1,
                      itemBuilder: (context, index) {
                        if (index == dependents.length) {
                          return _buildAddButton(colors, context);
                        }
                        return _buildDependentCard(
                          dependents[index],
                          colors,
                          context,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(WareozeColorScheme colors, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.group, size: 48, color: colors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No dependents added',
            style: TextStyle(fontSize: 18, color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Add family members and dependents',
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
        onPressed: () => context.go('/employee/update/$employeeId/family'),
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.add, color: colors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Add Family Member',
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

  Widget _buildDependentCard(
    Map<String, dynamic> dependent,
    WareozeColorScheme colors,
    BuildContext context,
  ) {
    final name = dependent['name'] ?? 'Not specified';
    final relation = dependent['relation'] ?? 'Not specified';
    final age = dependent['age']?.toString() ?? 'Not specified';

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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              CupertinoIcons.person_2,
              color: colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$relation • Age: $age',
                  style: TextStyle(fontSize: 14, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () =>
                    context.go('/employee/update/$employeeId/family'),
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
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  // Delete dependent - implement in update form
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    CupertinoIcons.xmark,
                    color: colors.error,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Employee Uniform Details Page - Fixed employeeId and navigation
class EmployeeUniformDetailsPage extends ConsumerWidget {
  final Map<String, dynamic> employee;
  final String employeeId;

  const EmployeeUniformDetailsPage({
    super.key,
    required this.employee,
    required this.employeeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);
    final uniform = employee['uniform'] as List? ?? [];

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surface,
        middle: Text(
          'Compliance & Uniform Details',
          style: TextStyle(color: colors.textPrimary),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(CupertinoIcons.back, color: colors.primary),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () =>
              context.go('/employee/update/$employeeId/compliance'),
          child: Icon(CupertinoIcons.add, color: colors.primary, size: 20),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Compliance Information Section
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COMPLIANCE INFORMATION',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                CupertinoIcons.checkmark_shield,
                                color: colors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Compliance Status',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    employee['isCompliance'] == true
                                        ? 'Compliant'
                                        : 'Not Compliant',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: employee['isCompliance'] == true
                                          ? colors.primary
                                          : colors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => context.go(
                                '/employee/update/$employeeId/compliance',
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
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildComplianceDetailColumn(
                                'Nominee Name',
                                employee['nomineeName'] ?? 'Not provided',
                                colors,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildComplianceDetailColumn(
                                'Nominee Relation',
                                employee['nomineeRelation'] ?? 'Not provided',
                                colors,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Uniform Items Section Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'UNIFORM ITEMS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () =>
                        context.go('/employee/update/$employeeId/compliance'),
                    child: Icon(
                      CupertinoIcons.add,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Uniform Items List
            Expanded(
              child: uniform.isEmpty
                  ? _buildEmptyState(colors, context)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: uniform.length + 1,
                      itemBuilder: (context, index) {
                        if (index == uniform.length) {
                          return _buildAddButton(colors, context);
                        }
                        return _buildUniformCard(
                          uniform[index],
                          colors,
                          context,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this helper method to the EmployeeUniformDetailsPage class
  Widget _buildComplianceDetailColumn(
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
        Text(value, style: TextStyle(fontSize: 14, color: colors.textPrimary)),
      ],
    );
  }

  Widget _buildEmptyState(WareozeColorScheme colors, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.rectangle_stack,
            size: 48,
            color: colors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No uniform items',
            style: TextStyle(fontSize: 18, color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Add uniform items and quantities',
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
        onPressed: () => context.go('/employee/update/$employeeId/compliance'),
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.add, color: colors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Add Uniform Item',
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

  Widget _buildUniformCard(
    Map<String, dynamic> uniformItem,
    WareozeColorScheme colors,
    BuildContext context,
  ) {
    final item = uniformItem['item'] ?? 'Not specified';
    final quantity = uniformItem['quantity']?.toString() ?? '0';

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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              CupertinoIcons.rectangle_stack,
              color: colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Quantity: $quantity',
                  style: TextStyle(fontSize: 14, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () =>
                    context.go('/employee/update/$employeeId/compliance'),
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
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  // Delete uniform item - implement in update form
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    CupertinoIcons.xmark,
                    color: colors.error,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Employee KYC Documents Page - Fixed employeeId and navigation
class EmployeeKYCDocumentsPage extends ConsumerWidget {
  final Map<String, dynamic> employee;
  final String employeeId;

  const EmployeeKYCDocumentsPage({
    super.key,
    required this.employee,
    required this.employeeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);
    final attachments = employee['attachments'] as List? ?? [];

    // Filter KYC documents
    final kycDocs = attachments
        .where(
          (doc) => [
            'aadharCard',
            'panCard',
            'passbook',
          ].contains(doc['attachmentLabel']),
        )
        .toList();

    final kycTypes = [
      {
        'label': 'aadharCard',
        'displayName': 'Aadhar Card',
        'icon': CupertinoIcons.doc_plaintext,
      },
      {
        'label': 'panCard',
        'displayName': 'PAN Card',
        'icon': CupertinoIcons.doc_plaintext,
      },
      {
        'label': 'passbook',
        'displayName': 'Bank Passbook',
        'icon': CupertinoIcons.doc_plaintext,
      },
    ];

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surface,
        middle: Text(
          'KYC Documents',
          style: TextStyle(color: colors.textPrimary),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(CupertinoIcons.back, color: colors.primary),
        ),
      ),
      child: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: kycTypes.length,
          itemBuilder: (context, index) {
            final kycType = kycTypes[index];
            final existingDoc = kycDocs.isNotEmpty
                ? kycDocs
                          .where(
                            (doc) => doc['attachmentLabel'] == kycType['label'],
                          )
                          .isNotEmpty
                      ? kycDocs
                            .where(
                              (doc) =>
                                  doc['attachmentLabel'] == kycType['label'],
                            )
                            .first
                      : null
                : null;

            return _buildKYCDocumentCard(
              kycType['displayName'] as String,
              kycType['icon'] as IconData,
              existingDoc,
              colors,
              context,
              employeeId,
            );
          },
        ),
      ),
    );
  }

  Widget _buildKYCDocumentCard(
    String documentName,
    IconData icon,
    Map<String, dynamic>? document,
    WareozeColorScheme colors,
    BuildContext context, // Add context parameter
    String employeeId, // Add employeeId parameter
  ) {
    final isUploaded = document != null;
    final status = document?['status'] ?? 'PENDING';
    final url = document?['url'];

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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isUploaded
                  ? colors.primary.withOpacity(0.1)
                  : colors.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isUploaded ? colors.primary : colors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  documentName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isUploaded
                      ? 'Status: ${_getStatusText(status)}'
                      : 'Not uploaded',
                  style: TextStyle(
                    fontSize: 14,
                    color: _getStatusColor(status, colors),
                  ),
                ),
              ],
            ),
          ),
          if (isUploaded) ...[
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                // View document
                if (url != null) {
                  // Open document viewer
                }
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  CupertinoIcons.eye,
                  color: colors.primary,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () =>
                context.go('/employee/update/$employeeId/attachments'),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isUploaded
                    ? CupertinoIcons.arrow_2_circlepath
                    : CupertinoIcons.cloud_upload,
                color: colors.primary,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      case 'PENDING':
      default:
        return 'Pending';
    }
  }

  Color _getStatusColor(String status, WareozeColorScheme colors) {
    switch (status) {
      case 'APPROVED':
        return colors.primary;
      case 'REJECTED':
        return colors.error;
      case 'PENDING':
      default:
        return colors.textSecondary;
    }
  }
}

// Placeholder classes for remaining pages - Updated with employeeId and context
class EmployeeAdditionalDocumentsPage extends ConsumerWidget {
  final Map<String, dynamic> employee;
  final String employeeId;

  const EmployeeAdditionalDocumentsPage({
    super.key,
    required this.employee,
    required this.employeeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Additional Documents'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () =>
              context.go('/employee/update/$employeeId/attachments'),
          child: const Icon(CupertinoIcons.add, size: 20),
        ),
      ),
      child: Center(
        child: Text('Additional Documents for ${employee['name']}'),
      ),
    );
  }
}

class EmployeePVCBVCPage extends ConsumerWidget {
  final Map<String, dynamic> employee;
  final String employeeId;

  const EmployeePVCBVCPage({
    super.key,
    required this.employee,
    required this.employeeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('PVC & BVC'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () =>
              context.go('/employee/update/$employeeId/attachments'),
          child: const Icon(CupertinoIcons.add, size: 20),
        ),
      ),
      child: Center(child: Text('PVC & BVC for ${employee['name']}')),
    );
  }
}

class EmployeeThumbSignaturePage extends ConsumerWidget {
  final Map<String, dynamic> employee;
  final String employeeId;

  const EmployeeThumbSignaturePage({
    super.key,
    required this.employee,
    required this.employeeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Thumb & Signature'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () =>
              context.go('/employee/update/$employeeId/attachments'),
          child: const Icon(CupertinoIcons.add, size: 20),
        ),
      ),
      child: Center(child: Text('Thumb & Signature for ${employee['name']}')),
    );
  }
}

class EmployeeBGVConsentPage extends ConsumerWidget {
  final Map<String, dynamic> employee;
  final String employeeId;

  const EmployeeBGVConsentPage({
    super.key,
    required this.employee,
    required this.employeeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('BGV Consent Form'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () =>
              context.go('/employee/update/$employeeId/attachments'),
          child: const Icon(CupertinoIcons.add, size: 20),
        ),
      ),
      child: Center(child: Text('BGV Consent for ${employee['name']}')),
    );
  }
}

class EmployeeTermsConditionsPage extends ConsumerWidget {
  final Map<String, dynamic> employee;
  final String employeeId;

  const EmployeeTermsConditionsPage({
    super.key,
    required this.employee,
    required this.employeeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Terms & Conditions'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () =>
              context.go('/employee/update/$employeeId/attachments'),
          child: const Icon(CupertinoIcons.add, size: 20),
        ),
      ),
      child: Center(child: Text('Terms & Conditions for ${employee['name']}')),
    );
  }
}

class EmployeeSettingsPage extends ConsumerWidget {
  final Map<String, dynamic> employee;
  final String employeeId;

  const EmployeeSettingsPage({
    super.key,
    required this.employee,
    required this.employeeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Settings')),
      child: Center(child: Text('Settings for ${employee['name']}')),
    );
  }
}
