// business_profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Wareozo/apis/providers/business_commonprofile_provider.dart';
import 'package:Wareozo/apis/providers/bankaccount_provider.dart';
import 'package:Wareozo/apis/providers/address_provider.dart';
import 'package:Wareozo/apis/providers/documentsetting_provider.dart';
import 'package:Wareozo/theme_provider.dart';
import 'document_setting_form.dart';
import 'bank_form.dart';
import 'address_form.dart';
import 'subscription_settings_page.dart';

class BusinessProfilePage extends ConsumerStatefulWidget {
  const BusinessProfilePage({Key? key}) : super(key: key);

  @override
  ConsumerState<BusinessProfilePage> createState() =>
      _BusinessProfilePageState();
}

class _BusinessProfilePageState extends ConsumerState<BusinessProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(businessProfileProvider.notifier).fetchBusinessProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessProfileState = ref.watch(businessProfileProvider);
    final colors = ref.watch(colorProvider);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(colors, screenSize),
            Expanded(child: _buildBody(businessProfileState, colors, isTablet)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(WareozeColorScheme colors, Size screenSize) {
    return Container(
      height: kToolbarHeight,
      color: colors.surface,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'Business Profile',
            style: TextStyle(
              fontSize: screenSize.width * 0.045,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    dynamic businessProfileState,
    WareozeColorScheme colors,
    bool isTablet,
  ) {
    if (businessProfileState.isLoading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    if (businessProfileState.error != null) {
      return _buildErrorState(businessProfileState.error!, colors);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32.0 : 16.0,
          vertical: 16.0,
        ),
        child: Column(
          children: [
            _buildProfileHeader(businessProfileState.profile, colors, isTablet),
            SizedBox(height: isTablet ? 32 : 24),
            _buildBusinessInformationSection(colors, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, WareozeColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(businessProfileProvider.notifier)
                    .fetchBusinessProfile();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    Map<String, dynamic>? profile,
    WareozeColorScheme colors,
    bool isTablet,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.border,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAvatar(profile, colors, isTablet),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            profile?['legalName'] ?? 'Unknown User',
            style: TextStyle(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            profile?['email'] ?? '',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    Map<String, dynamic>? profile,
    WareozeColorScheme colors,
    bool isTablet,
  ) {
    final radius = isTablet ? 60.0 : 50.0;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.border, width: 2),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: colors.primary.withOpacity(0.1),
        backgroundImage: profile?['logo'] != null
            ? NetworkImage(profile!['logo'])
            : null,
        child: profile?['logo'] == null
            ? Icon(Icons.business, size: radius * 0.8, color: colors.primary)
            : null,
      ),
    );
  }

  Widget _buildBusinessInformationSection(
    WareozeColorScheme colors,
    bool isTablet,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.border,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
            child: Text(
              'BUSINESS INFORMATION',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ..._buildMenuItems(colors, isTablet),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems(WareozeColorScheme colors, bool isTablet) {
    final menuItems = [
      _MenuItem(
        icon: Icons.business,
        title: 'Company Profile',
        onTap: () => _navigateToPage(const CompanyProfileDetailPage()),
      ),
      _MenuItem(
        icon: Icons.assignment,
        title: 'Registration and Legal',
        onTap: () => _navigateToPage(const RegistrationLegalDetailPage()),
      ),
      _MenuItem(
        icon: Icons.payment,
        title: 'Payment',
        onTap: () => _navigateToPage(const PaymentDetailPage()),
      ),
      _MenuItem(
        icon: Icons.account_balance,
        title: 'Bank List',
        onTap: () => _navigateToPage(const BankListDetailPage()),
      ),
      _MenuItem(
        icon: Icons.home,
        title: 'Address List',
        onTap: () => _navigateToPage(const AddressListDetailPage()),
      ),
      _MenuItem(
        icon: Icons.settings,
        title: 'Settings',
        onTap: () => _navigateToPage(const SubscriptionSettingsPage()),
      ),
      _MenuItem(
        icon: Icons.description,
        title: 'Document Settings',
        onTap: () => _navigateToPage(const DocumentSettingsDetailPage()),
      ),
    ];

    return menuItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isLast = index == menuItems.length - 1;

      return _buildSectionItem(
        icon: item.icon,
        title: item.title,
        onTap: item.onTap,
        colors: colors,
        isTablet: isTablet,
        isLast: isLast,
      );
    }).toList();
  }

  void _navigateToPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  Widget _buildSectionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required WareozeColorScheme colors,
    required bool isTablet,
    required bool isLast,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32.0 : 24.0,
          vertical: isTablet ? 20.0 : 16.0,
        ),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: colors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 12.0 : 10.0),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: colors.primary,
                size: isTablet ? 28 : 24,
              ),
            ),
            SizedBox(width: isTablet ? 20 : 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: colors.primary,
              size: isTablet ? 20 : 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _MenuItem({required this.icon, required this.title, required this.onTap});
}

// Base Detail Page Widget
abstract class BaseDetailPage extends ConsumerWidget {
  const BaseDetailPage({Key? key}) : super(key: key);

  String get pageTitle;
  Widget buildContent(
    BuildContext context,
    WidgetRef ref,
    WareozeColorScheme colors,
    bool isTablet,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessProfileState = ref.watch(businessProfileProvider);
    final colors = ref.watch(colorProvider);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildDetailAppBar(
              context,
              businessProfileState.profile,
              colors,
              screenSize,
            ),
            _buildPageHeader(context, colors, isTablet),
            Expanded(child: buildContent(context, ref, colors, isTablet)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailAppBar(
    BuildContext context,
    Map<String, dynamic>? profile,
    WareozeColorScheme colors,
    Size screenSize,
  ) {
    return Container(
      color: colors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border, width: 1),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: colors.primary.withOpacity(0.1),
                    backgroundImage: profile?['logo'] != null
                        ? NetworkImage(profile!['logo'])
                        : null,
                    child: profile?['logo'] == null
                        ? Icon(Icons.business, size: 20, color: colors.primary)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile?['contactName'] ?? 'Unknown User',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        profile?['email'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Update the method signature to accept context
  Widget _buildPageHeader(
    BuildContext context,
    WareozeColorScheme colors,
    bool isTablet,
  ) {
    // Define which pages should have edit buttons
    final hasEditButton = [
      'Company Profile',
      'Registration and Legal',
      'Payment Information',
    ].contains(pageTitle);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
      margin: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.border,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            pageTitle,
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          if (hasEditButton) ...[
            InkWell(
              onTap: () => _navigateToEditPage(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.edit,
                  color: colors.primary,
                  size: isTablet ? 24 : 20,
                ),
              ),
            ),
            SizedBox(width: isTablet ? 12 : 8),
          ],
          Icon(
            Icons.arrow_forward_ios,
            color: colors.primary,
            size: isTablet ? 20 : 16,
          ),
        ],
      ),
    );
  }

  // Add this method to BaseDetailPage
  void _navigateToEditPage(BuildContext context) {
    String route;
    switch (pageTitle) {
      case 'Company Profile':
        route = '/update-company-profile';
        break;
      case 'Registration and Legal':
        route = '/update-legal-info';
        break;
      case 'Payment Information':
        route = '/update-payment-info';
        break;
      default:
        return;
    }

    // Use GoRouter navigation
    context.push(route);
  }
}

// Company Profile Detail Page
class CompanyProfileDetailPage extends BaseDetailPage {
  const CompanyProfileDetailPage({Key? key}) : super(key: key);

  @override
  String get pageTitle => 'Company Profile';

  @override
  Widget buildContent(
    BuildContext context,
    WidgetRef ref,
    WareozeColorScheme colors,
    bool isTablet,
  ) {
    final businessProfileState = ref.watch(businessProfileProvider);
    final profile = businessProfileState.profile;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.0 : 16.0),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.border,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDetailRow(
                'Brand Name',
                profile?['name'] ?? '',
                colors,
                isTablet,
              ),
              _buildDetailRow(
                'Contact Name',
                profile?['contactName'] ?? '',
                colors,
                isTablet,
              ),
              _buildDetailRow(
                'Display Name',
                profile?['displayName'] ?? '',
                colors,
                isTablet,
              ),
              _buildDetailRow(
                'Email',
                profile?['email'] ?? '',
                colors,
                isTablet,
              ),
              _buildDetailRow(
                'Legal Name',
                profile?['legalName'] ?? '',
                colors,
                isTablet,
              ),
              _buildDetailRow(
                'WhatsApp Number',
                profile?['whatsAppNumber'] ?? '',
                colors,
                isTablet,
              ),
              _buildDetailRow(
                'Company Description',
                profile?['companyDesc'] ?? '',
                colors,
                isTablet,
              ),
              _buildDetailRow(
                'Tax Identification #1',
                profile?['taxIdentificationNumber1'] ?? '',
                colors,
                isTablet,
              ),
              _buildDetailRow(
                'Website',
                profile?['website'] ?? '',
                colors,
                isTablet,
              ),
              _buildDetailRow(
                'Tax Identification #2',
                profile?['taxIdentificationNumber2'] ?? '',
                colors,
                isTablet,
                isLast: true,
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
    bool isTablet, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : (isTablet ? 28 : 24)),
      child: Container(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.left,
            ),
            SizedBox(height: isTablet ? 8 : 6),
            Container(
              width: double.infinity,
              child: Text(
                value.isEmpty ? '-' : value,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Registration and Legal Detail Page
class RegistrationLegalDetailPage extends BaseDetailPage {
  const RegistrationLegalDetailPage({Key? key}) : super(key: key);

  @override
  String get pageTitle => 'Registration and Legal';

  @override
  Widget buildContent(
    BuildContext context,
    WidgetRef ref,
    WareozeColorScheme colors,
    bool isTablet,
  ) {
    final businessProfileState = ref.watch(businessProfileProvider);
    final profile = businessProfileState.profile;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.0 : 16.0),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.border,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDetailRow(
                'Company Type',
                profile?['companyType'] ?? '',
                colors,
                isTablet,
              ),
              _buildDetailRow(
                'Country of Registration',
                profile?['countryOfRegistration']?['name'] ?? '',
                colors,
                isTablet,
              ),
              _buildDetailRow(
                'Legal Name',
                profile?['legalName'] ?? '',
                colors,
                isTablet,
              ),
              _buildDetailRow(
                'Registration No',
                profile?['registrationNo'] ?? '',
                colors,
                isTablet,
              ),
              _buildDetailRow(
                'SME Registration Flag',
                (profile?['smeRegistrationFlag'] ?? false) ? 'Yes' : 'No',
                colors,
                isTablet,
              ),
              _buildDetailRow(
                'State of Registration',
                profile?['stateOfRegistration'] ?? '',
                colors,
                isTablet,
              ),
              _buildDetailRow(
                'Tax Identification #1',
                profile?['taxIdentificationNumber1'] ?? '',
                colors,
                isTablet,
              ),
              _buildDetailRow(
                'Tax Identification #2',
                profile?['taxIdentificationNumber2'] ?? '',
                colors,
                isTablet,
                isLast: true,
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
    bool isTablet, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : (isTablet ? 28 : 24)),
      child: Container(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.left,
            ),
            SizedBox(height: isTablet ? 8 : 6),
            Container(
              width: double.infinity,
              child: Text(
                value.isEmpty ? '-' : value,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Payment Detail Page
class PaymentDetailPage extends BaseDetailPage {
  const PaymentDetailPage({Key? key}) : super(key: key);

  @override
  String get pageTitle => 'Payment Information';

  @override
  Widget buildContent(
    BuildContext context,
    WidgetRef ref,
    WareozeColorScheme colors,
    bool isTablet,
  ) {
    final businessProfileState = ref.watch(businessProfileProvider);
    final profile = businessProfileState.profile;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.0 : 16.0),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.border,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDetailRow(
                'GPay Phone',
                profile?['gPayPhone'] ?? '',
                colors,
                isTablet,
              ),
              _buildDetailRow(
                'GPay Phone Verified',
                (profile?['gPayPhoneVerifiedFlag'] ?? false) ? 'Yes' : 'No',
                colors,
                isTablet,
              ),
              _buildDetailRow(
                'UPI ID',
                profile?['upiId'] ?? '',
                colors,
                isTablet,
              ),
              _buildQRCodeRow(
                'QR Code',
                profile?['qrCodeUrl'] ?? '',
                colors,
                isTablet,
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
    bool isTablet, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : (isTablet ? 28 : 24)),
      child: Container(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.left,
            ),
            SizedBox(height: isTablet ? 8 : 6),
            Container(
              width: double.infinity,
              child: Text(
                value.isEmpty ? '-' : value,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildQRCodeRow(
  String label,
  String imageUrl,
  WareozeColorScheme colors,
  bool isTablet,
) {
  return Padding(
    padding: EdgeInsets.only(bottom: 0),
    child: Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.left,
          ),
          SizedBox(height: isTablet ? 12 : 8),
          imageUrl.isEmpty
              ? Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: colors.border.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'No QR Code',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
                  ),
                )
              : Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: colors.primary,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colors.error.withOpacity(0.1),
                          child: Center(
                            child: Icon(
                              Icons.error_outline,
                              color: colors.error,
                              size: isTablet ? 32 : 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ],
      ),
    ),
  );
}

// Bank List Detail Page
class BankListDetailPage extends ConsumerStatefulWidget {
  const BankListDetailPage({Key? key}) : super(key: key);

  @override
  ConsumerState<BankListDetailPage> createState() => _BankListDetailPageState();
}

class _BankListDetailPageState extends ConsumerState<BankListDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bankAccountProvider.notifier).fetchBankAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessProfileState = ref.watch(businessProfileProvider);
    final bankAccountState = ref.watch(bankAccountProvider);
    final colors = ref.watch(colorProvider);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildDetailAppBar(
              context,
              businessProfileState.profile,
              colors,
              screenSize,
            ),
            _buildPageHeader(colors, isTablet),
            Expanded(child: _buildBankList(bankAccountState, colors, isTablet)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailAppBar(
    BuildContext context,
    Map<String, dynamic>? profile,
    WareozeColorScheme colors,
    Size screenSize,
  ) {
    return Container(
      color: colors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border, width: 1),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: colors.primary.withOpacity(0.1),
                    backgroundImage: profile?['logo'] != null
                        ? NetworkImage(profile!['logo'])
                        : null,
                    child: profile?['logo'] == null
                        ? Icon(Icons.business, size: 20, color: colors.primary)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile?['contactName'] ?? 'Unknown User',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        profile?['email'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(WareozeColorScheme colors, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
      margin: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.border,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Bank Accounts',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.arrow_forward_ios,
            color: colors.primary,
            size: isTablet ? 20 : 16,
          ),
        ],
      ),
    );
  }

  Widget _buildBankList(
    dynamic bankAccountState,
    WareozeColorScheme colors,
    bool isTablet,
  ) {
    if (bankAccountState.isLoading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    if (bankAccountState.bankAccounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: colors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No bank accounts found',
              style: TextStyle(fontSize: 18, color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            // Add Bank Account Button
            ElevatedButton.icon(
              onPressed: () => _navigateToFormPage(null),
              icon: Icon(Icons.add),
              label: Text('Add Bank Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Add Bank Account Button at the top
        Container(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.0 : 16.0),
          margin: EdgeInsets.only(bottom: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToFormPage(null),
              icon: Icon(Icons.add),
              label: Text('Add Bank Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        // Existing bank accounts list
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.0 : 16.0),
            itemCount: bankAccountState.bankAccounts.length,
            itemBuilder: (context, index) {
              final bank = bankAccountState.bankAccounts[index];
              return Container(
                margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
                padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colors.border,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isTablet ? 12.0 : 10.0),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.account_balance,
                            color: colors.primary,
                            size: isTablet ? 28 : 24,
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                        Expanded(
                          child: Text(
                            bank['bankName'] ?? 'Unknown Bank',
                            style: TextStyle(
                              fontSize: isTablet ? 20 : 18,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        // Edit Button
                        IconButton(
                          onPressed: () => _navigateToFormPage(bank['_id']),
                          icon: Icon(
                            Icons.edit,
                            color: colors.primary,
                            size: isTablet ? 24 : 20,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    _buildBankDetailRow(
                      'Account Name',
                      bank['accountName'] ?? '',
                      colors,
                      isTablet,
                    ),
                    _buildBankDetailRow(
                      'Account Number',
                      bank['accountNumber'] ?? '',
                      colors,
                      isTablet,
                    ),
                    _buildBankDetailRow(
                      'Branch Name',
                      bank['branchName'] ?? '',
                      colors,
                      isTablet,
                    ),
                    _buildBankDetailRow(
                      'IFSC',
                      bank['IFSC'] ?? '',
                      colors,
                      isTablet,
                    ),
                    if (bank['SWIFT']?.isNotEmpty == true)
                      _buildBankDetailRow(
                        'SWIFT',
                        bank['SWIFT'],
                        colors,
                        isTablet,
                      ),
                    if (bank['MICR']?.isNotEmpty == true)
                      _buildBankDetailRow(
                        'MICR',
                        bank['MICR'],
                        colors,
                        isTablet,
                      ),
                    if (bank['IBAN']?.isNotEmpty == true)
                      _buildBankDetailRow(
                        'IBAN',
                        bank['IBAN'],
                        colors,
                        isTablet,
                      ),
                    if (bank['country']?['name']?.isNotEmpty == true)
                      _buildBankDetailRow(
                        'Country',
                        bank['country']['name'],
                        colors,
                        isTablet,
                      ),
                    if (bank['currency']?['name']?.isNotEmpty == true)
                      _buildBankDetailRow(
                        'Currency',
                        '${bank['currency']['code']} - ${bank['currency']['name']}',
                        colors,
                        isTablet,
                        isLast: true,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToFormPage(String? bankId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BankForm(bankId: bankId)),
    );
  }

  Widget _buildBankDetailRow(
    String label,
    String value,
    WareozeColorScheme colors,
    bool isTablet, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : (isTablet ? 16 : 12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isTablet ? 140 : 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Address List Detail Page
class AddressListDetailPage extends ConsumerStatefulWidget {
  const AddressListDetailPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AddressListDetailPage> createState() =>
      _AddressListDetailPageState();
}

class _AddressListDetailPageState extends ConsumerState<AddressListDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addressProvider.notifier).fetchAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessProfileState = ref.watch(businessProfileProvider);
    final addressState = ref.watch(addressProvider);
    final colors = ref.watch(colorProvider);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildDetailAppBar(
              context,
              businessProfileState.profile,
              colors,
              screenSize,
            ),
            _buildPageHeader(colors, isTablet),
            Expanded(child: _buildAddressList(addressState, colors, isTablet)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailAppBar(
    BuildContext context,
    Map<String, dynamic>? profile,
    WareozeColorScheme colors,
    Size screenSize,
  ) {
    return Container(
      color: colors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border, width: 1),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: colors.primary.withOpacity(0.1),
                    backgroundImage: profile?['logo'] != null
                        ? NetworkImage(profile!['logo'])
                        : null,
                    child: profile?['logo'] == null
                        ? Icon(Icons.business, size: 20, color: colors.primary)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile?['contactName'] ?? 'Unknown User',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        profile?['email'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(WareozeColorScheme colors, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
      margin: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.border,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Addresses',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.arrow_forward_ios,
            color: colors.primary,
            size: isTablet ? 20 : 16,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList(
    dynamic addressState,
    WareozeColorScheme colors,
    bool isTablet,
  ) {
    if (addressState.isLoading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    if (addressState.addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 64,
              color: colors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No addresses found',
              style: TextStyle(fontSize: 18, color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            // Add Address Button
            ElevatedButton.icon(
              onPressed: () => _navigateToFormPage(null),
              icon: Icon(Icons.add),
              label: Text('Add Address'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Add Address Button at the top
        Container(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.0 : 16.0),
          margin: EdgeInsets.only(bottom: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToFormPage(null),
              icon: Icon(Icons.add),
              label: Text('Add Address'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        // Existing addresses list
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.0 : 16.0),
            itemCount: addressState.addresses.length,
            itemBuilder: (context, index) {
              final address = addressState.addresses[index];
              return Container(
                margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
                padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colors.border,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isTablet ? 12.0 : 10.0),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: colors.primary,
                            size: isTablet ? 28 : 24,
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                        Expanded(
                          child: Text(
                            address['type'] ?? 'Address',
                            style: TextStyle(
                              fontSize: isTablet ? 20 : 18,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        // Edit Button
                        IconButton(
                          onPressed: () => _navigateToFormPage(address['_id']),
                          icon: Icon(
                            Icons.edit,
                            color: colors.primary,
                            size: isTablet ? 24 : 20,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    if (address['line1']?.isNotEmpty == true)
                      _buildAddressDetailRow(
                        'Line 1',
                        address['line1'],
                        colors,
                        isTablet,
                      ),
                    if (address['line2']?.isNotEmpty == true)
                      _buildAddressDetailRow(
                        'Line 2',
                        address['line2'],
                        colors,
                        isTablet,
                      ),
                    if (address['line3']?.isNotEmpty == true)
                      _buildAddressDetailRow(
                        'Line 3',
                        address['line3'],
                        colors,
                        isTablet,
                      ),
                    _buildAddressDetailRow(
                      'City',
                      address['city'] ?? '',
                      colors,
                      isTablet,
                    ),
                    _buildAddressDetailRow(
                      'State',
                      address['state']?['name'] ?? '',
                      colors,
                      isTablet,
                    ),
                    _buildAddressDetailRow(
                      'Country',
                      address['country']?['name'] ?? '',
                      colors,
                      isTablet,
                    ),
                    _buildAddressDetailRow(
                      'Postal Code',
                      address['code'] ?? '',
                      colors,
                      isTablet,
                    ),
                    if (address['phone1']?.isNotEmpty == true)
                      _buildAddressDetailRow(
                        'Phone 1',
                        address['phone1'],
                        colors,
                        isTablet,
                      ),
                    if (address['phone2']?.isNotEmpty == true)
                      _buildAddressDetailRow(
                        'Phone 2',
                        address['phone2'],
                        colors,
                        isTablet,
                        isLast: true,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToFormPage(String? addressId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressForm(addressId: addressId),
      ),
    );
  }

  Widget _buildAddressDetailRow(
    String label,
    String value,
    WareozeColorScheme colors,
    bool isTablet, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : (isTablet ? 16 : 12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isTablet ? 120 : 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Document Settings Detail Page
class DocumentSettingsDetailPage extends ConsumerStatefulWidget {
  const DocumentSettingsDetailPage({Key? key}) : super(key: key);

  @override
  ConsumerState<DocumentSettingsDetailPage> createState() =>
      _DocumentSettingsDetailPageState();
}

class _DocumentSettingsDetailPageState
    extends ConsumerState<DocumentSettingsDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentSettingsProvider.notifier).fetchDocumentSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessProfileState = ref.watch(businessProfileProvider);
    final documentSettingsState = ref.watch(documentSettingsProvider);
    final colors = ref.watch(colorProvider);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildDetailAppBar(
              context,
              businessProfileState.profile,
              colors,
              screenSize,
            ),
            _buildPageHeader(colors, isTablet),
            Expanded(
              child: _buildDocumentSettingsList(
                documentSettingsState,
                colors,
                isTablet,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailAppBar(
    BuildContext context,
    Map<String, dynamic>? profile,
    WareozeColorScheme colors,
    Size screenSize,
  ) {
    return Container(
      color: colors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border, width: 1),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: colors.primary.withOpacity(0.1),
                    backgroundImage: profile?['logo'] != null
                        ? NetworkImage(profile!['logo'])
                        : null,
                    child: profile?['logo'] == null
                        ? Icon(Icons.business, size: 20, color: colors.primary)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile?['contactName'] ?? 'Unknown User',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        profile?['email'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(WareozeColorScheme colors, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
      margin: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.border,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Document Settings',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.arrow_forward_ios,
            color: colors.primary,
            size: isTablet ? 20 : 16,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSettingsList(
    dynamic documentSettingsState,
    WareozeColorScheme colors,
    bool isTablet,
  ) {
    if (documentSettingsState.isLoading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    if (documentSettingsState.documentSettings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: colors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No document settings found',
              style: TextStyle(fontSize: 18, color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            // Add Document Setting Button
            ElevatedButton.icon(
              onPressed: () => _navigateToFormPage(null, null),
              icon: Icon(Icons.add),
              label: Text('Add Document Setting'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Add Document Setting Button at the top
        Container(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.0 : 16.0),
          margin: EdgeInsets.only(bottom: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToFormPage(null, null),
              icon: Icon(Icons.add),
              label: Text('Add Document Setting'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        // Existing list
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.0 : 16.0),
            itemCount: documentSettingsState.documentSettings.length,
            itemBuilder: (context, index) {
              final docSetting = documentSettingsState.documentSettings[index];
              return Container(
                margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
                padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colors.border,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isTablet ? 12.0 : 10.0),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.description,
                            color: colors.primary,
                            size: isTablet ? 28 : 24,
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                        Expanded(
                          child: Text(
                            docSetting['documentType']?['name'] ?? 'Document',
                            style: TextStyle(
                              fontSize: isTablet ? 20 : 18,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        // Edit Button
                        IconButton(
                          onPressed: () => _navigateToFormPage(
                            docSetting['_id'],
                            docSetting['documentType']?['name'],
                          ),
                          icon: Icon(
                            Icons.edit,
                            color: colors.primary,
                            size: isTablet ? 24 : 20,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    _buildDocDetailRow(
                      'Prefix',
                      docSetting['docNumberPrefix'] ?? '',
                      colors,
                      isTablet,
                    ),
                    _buildDocDetailRow(
                      'Sequence Number',
                      docSetting['docSequenceNumber'] ?? '',
                      colors,
                      isTablet,
                    ),
                    _buildDocDetailRow(
                      'Number Length',
                      docSetting['docNumberLength']?.toString() ?? '',
                      colors,
                      isTablet,
                    ),
                    _buildDocDetailRow(
                      'Payment Details',
                      docSetting['paymentDetails'] ?? '',
                      colors,
                      isTablet,
                    ),
                    _buildDocDetailRow(
                      'Payment Term Days',
                      docSetting['paymentTermDays']?.toString() ?? '',
                      colors,
                      isTablet,
                    ),
                    _buildDocDetailRow(
                      'Terms & Conditions',
                      docSetting['termsAndConditions'] ?? '',
                      colors,
                      isTablet,
                    ),
                    _buildDocDetailRow(
                      'Footer 1',
                      docSetting['footer1'] ?? '',
                      colors,
                      isTablet,
                    ),
                    _buildDocDetailRow(
                      'Footer 2',
                      docSetting['footer2'] ?? '',
                      colors,
                      isTablet,
                      isLast: true,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToFormPage(
    String? documentSettingId,
    String? documentTypeName,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentSettingForm(
          documentSettingId: documentSettingId,
          documentTypeName: documentTypeName,
        ),
      ),
    );
  }

  Widget _buildDocDetailRow(
    String label,
    String value,
    WareozeColorScheme colors,
    bool isTablet, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : (isTablet ? 16 : 12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isTablet ? 160 : 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
