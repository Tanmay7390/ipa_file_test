import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/page_scaffold.dart';
import '../theme_provider.dart';

class PrivacyPolicyPage extends ConsumerWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));

    return CustomPageScaffold(
      heading: 'Privacy Policy',
      hideLargeTitle: true,
      hideSearch: true,
      isLoading: false,
      onRefresh: () async {},
      sliverList: SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  context,
                  isDarkMode,
                  title: 'Effective Date',
                  content: 'December 13, 2024',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  isDarkMode,
                  title: 'Company',
                  content: 'Accelerate Medicine LLC',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  isDarkMode,
                  title: 'Website / App',
                  content: 'www.diseaseportal.com (DISEASE PORTAL)',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  isDarkMode,
                  title: 'Contact Email',
                  content: 'support@axlmed.com',
                ),
                const SizedBox(height: 32),

                _buildSection(
                  context,
                  isDarkMode,
                  title: '1. Introduction',
                  content:
                      'Accelerate Medicine LLC ("Accelerate Medicine," "we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, store, share, and protect your information when you use our website, mobile applications, and subscription-based digital services (collectively, the "Services").\n\nBy using our Services, you agree to this Privacy Policy.',
                ),
                const SizedBox(height: 24),

                _buildSection(
                  context,
                  isDarkMode,
                  title: '2. Information We Collect',
                  content: '',
                ),
                const SizedBox(height: 12),
                _buildSubSection(
                  context,
                  isDarkMode,
                  title: 'A. Information You Provide',
                  items: [
                    'Name',
                    'Email address',
                    'Phone number',
                    'Organization or affiliation',
                    'Login credentials',
                    'Payment and billing information (processed by third-party providers)',
                    'Subscription preferences',
                    'Customer support communications',
                  ],
                ),
                const SizedBox(height: 16),
                _buildSubSection(
                  context,
                  isDarkMode,
                  title: 'B. Automatically Collected Information',
                  items: [
                    'Device type, operating system, and app version',
                    'IP address',
                    'Usage data and interaction analytics',
                    'Cookies and similar tracking technologies (web only)',
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  isDarkMode,
                  title: 'C. Health and Sensitive Data',
                  content:
                      'Unless explicitly stated, we do not collect protected health information (PHI) under HIPAA. If any health-related information is collected in the future, it will be handled according to applicable healthcare privacy laws.',
                ),
                const SizedBox(height: 24),

                _buildSection(
                  context,
                  isDarkMode,
                  title: '3. How We Use Your Information',
                  content: 'We use your data to:',
                ),
                const SizedBox(height: 8),
                _buildBulletList(
                  context,
                  isDarkMode,
                  items: [
                    'Provide and operate our Services',
                    'Manage subscriptions and payments',
                    'Authenticate users and prevent fraud',
                    'Improve platform performance and user experience',
                    'Communicate service updates, security notices, and support responses',
                    'Comply with legal obligations',
                  ],
                ),
                const SizedBox(height: 24),

                _buildSection(
                  context,
                  isDarkMode,
                  title: '4. Subscriptions & Payments',
                  content:
                      'All payments are processed by secure third-party payment processors (e.g., Apple, Google, Stripe).\n\nWe do not store full credit card numbers on our servers.',
                ),
                const SizedBox(height: 24),

                _buildSection(
                  context,
                  isDarkMode,
                  title: '5. Data Sharing & Disclosure',
                  content:
                      'We do not sell your personal data.\n\nWe may share data only with:',
                ),
                const SizedBox(height: 8),
                _buildBulletList(
                  context,
                  isDarkMode,
                  items: [
                    'Cloud hosting providers',
                    'Payment processors',
                    'Analytics providers',
                    'Legal authorities when required by law',
                    'Business partners strictly necessary for platform functionality',
                  ],
                ),
                const SizedBox(height: 8),
                _buildBodyText(
                  context,
                  isDarkMode,
                  'All partners are contractually required to protect your data.',
                ),
                const SizedBox(height: 24),

                _buildSection(
                  context,
                  isDarkMode,
                  title: '6. Data Retention',
                  content: 'We retain personal data only as long as:',
                ),
                const SizedBox(height: 8),
                _buildBulletList(
                  context,
                  isDarkMode,
                  items: [
                    'Your account is active',
                    'Required for subscription management',
                    'Required by tax, accounting, or legal obligations',
                  ],
                ),
                const SizedBox(height: 8),
                _buildBodyText(
                  context,
                  isDarkMode,
                  'You may request deletion at any time.',
                ),
                const SizedBox(height: 24),

                _buildSection(
                  context,
                  isDarkMode,
                  title: '7. Your Privacy Rights',
                  content:
                      'Depending on your jurisdiction, you may have the right to:',
                ),
                const SizedBox(height: 8),
                _buildBulletList(
                  context,
                  isDarkMode,
                  items: [
                    'Access your data',
                    'Correct inaccurate data',
                    'Delete your data',
                    'Opt-out of marketing communications',
                    'Restrict or object to certain processing',
                  ],
                ),
                const SizedBox(height: 8),
                _buildBodyText(
                  context,
                  isDarkMode,
                  'To exercise these rights, contact: support@axlmed.com',
                ),
                const SizedBox(height: 24),

                _buildSection(
                  context,
                  isDarkMode,
                  title: '8. Security Measures',
                  content: 'We use:',
                ),
                const SizedBox(height: 8),
                _buildBulletList(
                  context,
                  isDarkMode,
                  items: [
                    'SSL encryption',
                    'Secure cloud infrastructure',
                    'Access controls',
                    'Regular security monitoring',
                  ],
                ),
                const SizedBox(height: 8),
                _buildBodyText(
                  context,
                  isDarkMode,
                  'However, no system is 100% secure, and we cannot guarantee absolute security.',
                ),
                const SizedBox(height: 24),

                _buildSection(
                  context,
                  isDarkMode,
                  title: "9. Children's Privacy",
                  content:
                      'Our Services are not intended for users under age 13. We do not knowingly collect data from children.',
                ),
                const SizedBox(height: 24),

                _buildSection(
                  context,
                  isDarkMode,
                  title: '10. International Users',
                  content:
                      'If you access our Services from outside the United States, you agree that your data will be transferred to and processed in the U.S. and other jurisdictions where our servers are located.',
                ),
                const SizedBox(height: 24),

                _buildSection(
                  context,
                  isDarkMode,
                  title: '11. Third-Party Links',
                  content:
                      'Our Services may contain links to third-party websites. We are not responsible for their privacy practices.',
                ),
                const SizedBox(height: 24),

                _buildSection(
                  context,
                  isDarkMode,
                  title: '12. App Store & Google Play Compliance',
                  content:
                      'This Privacy Policy applies to all users accessing our Services through:',
                ),
                const SizedBox(height: 8),
                _buildBulletList(
                  context,
                  isDarkMode,
                  items: [
                    'Apple App Store',
                    'Google Play Store',
                    'Web platforms',
                  ],
                ),
                const SizedBox(height: 8),
                _buildBodyText(context, isDarkMode, 'We comply with:'),
                const SizedBox(height: 8),
                _buildBulletList(
                  context,
                  isDarkMode,
                  items: [
                    'Apple App Tracking Transparency (ATT)',
                    'Google Play Data Safety Requirements',
                  ],
                ),
                const SizedBox(height: 24),

                _buildSection(
                  context,
                  isDarkMode,
                  title: '13. Changes to This Policy',
                  content:
                      'We may update this Privacy Policy at any time. Material changes will be notified via:',
                ),
                const SizedBox(height: 8),
                _buildBulletList(
                  context,
                  isDarkMode,
                  items: ['App notifications', 'Email', 'Website posting'],
                ),
                const SizedBox(height: 24),

                _buildSection(
                  context,
                  isDarkMode,
                  title: '14. Contact Information',
                  content:
                      'Accelerate Medicine LLC\nEmail: contact@axlmed.com\n\nFor support inquiries: support@axlmed.com',
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    bool isDarkMode, {
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label.resolveFrom(context),
            height: 1.4,
          ),
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubSection(
    BuildContext context,
    bool isDarkMode, {
    required String title,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label.resolveFrom(context),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    fontSize: 15,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletList(
    BuildContext context,
    bool isDarkMode, {
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 15,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildBodyText(BuildContext context, bool isDarkMode, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: CupertinoColors.label.resolveFrom(context),
      ),
    );
  }
}
