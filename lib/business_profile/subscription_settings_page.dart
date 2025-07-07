// lib/pages/subscription_settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Wareozo/apis/providers/subscription_provider.dart';
import 'package:Wareozo/apis/providers/business_commonprofile_provider.dart';
import 'package:Wareozo/theme_provider.dart';

class SubscriptionSettingsPage extends ConsumerStatefulWidget {
  const SubscriptionSettingsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SubscriptionSettingsPage> createState() =>
      _SubscriptionSettingsPageState();
}

class _SubscriptionSettingsPageState extends ConsumerState<SubscriptionSettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionProvider.notifier).fetchSubscriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionState = ref.watch(subscriptionProvider);
    final businessProfileState = ref.watch(businessProfileProvider);
    final colors = ref.watch(colorProvider);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(businessProfileState.profile, colors, screenSize),
            Expanded(
              child: _buildBody(subscriptionState, colors, isTablet),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(
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
                        'Update Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Choose your subscription plan',
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

  Widget _buildBody(
    SubscriptionState subscriptionState,
    WareozeColorScheme colors,
    bool isTablet,
  ) {
    if (subscriptionState.isLoading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    if (subscriptionState.error != null) {
      return _buildErrorState(subscriptionState.error!, colors);
    }

    return Column(
      children: [
        // Success message
        if (subscriptionState.successMessage != null)
          _buildSuccessMessage(subscriptionState.successMessage!, colors, isTablet),
        
        // Subscription cards
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
              child: Column(
                children: [
                  _buildSubscriptionCards(subscriptionState, colors, isTablet),
                  SizedBox(height: isTablet ? 32 : 24),
                  _buildActionButtons(subscriptionState, colors, isTablet),
                ],
              ),
            ),
          ),
        ),
      ],
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
                ref.read(subscriptionProvider.notifier).fetchSubscriptions();
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

  Widget _buildSuccessMessage(String message, WareozeColorScheme colors, bool isTablet) {
    return Container(
      margin: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.green.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(subscriptionProvider.notifier).clearMessages();
            },
            icon: Icon(
              Icons.close,
              color: Colors.green.shade600,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCards(
    SubscriptionState subscriptionState,
    WareozeColorScheme colors,
    bool isTablet,
  ) {
    final subscriptions = subscriptionState.subscriptions;
    
    if (subscriptions.isEmpty) {
      return Center(
        child: Text(
          'No subscription plans available',
          style: TextStyle(
            fontSize: 16,
            color: colors.textSecondary,
          ),
        ),
      );
    }

    return isTablet
        ? Row(
            children: subscriptions.asMap().entries.map((entry) {
              final subscription = entry.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: entry.key == 0 ? 0 : 8),
                  child: _buildSubscriptionCard(
                    subscription,
                    subscriptionState,
                    colors,
                    isTablet,
                  ),
                ),
              );
            }).toList(),
          )
        : Column(
            children: subscriptions.map((subscription) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildSubscriptionCard(
                  subscription,
                  subscriptionState,
                  colors,
                  isTablet,
                ),
              );
            }).toList(),
          );
  }

  Widget _buildSubscriptionCard(
    Subscription subscription,
    SubscriptionState subscriptionState,
    WareozeColorScheme colors,
    bool isTablet,
  ) {
    final isSelected = subscriptionState.selectedSubscriptionId == subscription.id;
    final isCurrent = subscriptionState.currentSubscriptionId == subscription.id;
    final isPopular = subscription.plan.toLowerCase() == 'plus';

    return GestureDetector(
      onTap: () {
        ref.read(subscriptionProvider.notifier).selectSubscription(subscription.id);
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.border.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header with plan name and popular badge
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isTablet ? 24.0 : 20.0),
              child: Column(
                children: [
                  if (isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '(Most popular)',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.primary,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  Text(
                    subscription.plan.toUpperCase(),
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Price
                  _buildPriceSection(subscription, colors, isTablet),
                ],
              ),
            ),
            
            // Features
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.0 : 20.0),
              child: Column(
                children: _buildFeaturesList(subscription, colors, isTablet),
              ),
            ),
            
            SizedBox(height: isTablet ? 24 : 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSection(Subscription subscription, WareozeColorScheme colors, bool isTablet) {
    if (subscription.plan.toLowerCase() == 'free') {
      return Column(
        children: [
          Text(
            '0/-',
            style: TextStyle(
              fontSize: isTablet ? 32 : 28,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          Text(
            'per month.',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: colors.textSecondary,
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Text(
            'Call us',
            style: TextStyle(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          Text(
            'for price',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: colors.textSecondary,
            ),
          ),
        ],
      );
    }
  }

  List<Widget> _buildFeaturesList(Subscription subscription, WareozeColorScheme colors, bool isTablet) {
    final planName = subscription.plan.toLowerCase();
    List<String> features = [];

    // Define features based on plan type
    switch (planName) {
      case 'free':
        features = [
          'Forever Free',
          'Free updates',
          'Up to 2 users per account',
          'Upto 1000 invoices per month',
        ];
        break;
      case 'plus':
        features = [
          'Free updates',
          'Up to 4 users per account',
          'Unlimited invoices per month',
          'Premium features available',
          '8x5 on-call support',
        ];
        break;
      case 'enterprise':
        features = [
          'Free updates',
          'Up to 4 users per account',
          'Unlimited invoices per month',
          'Premium features available',
          '24x7 on-call support',
        ];
        break;
      default:
        // Use resources from API if available
        features = subscription.resources
            .map((resource) => resource.displayName)
            .toSet()
            .toList();
    }

    return features.map((feature) {
      return Padding(
        padding: EdgeInsets.only(bottom: isTablet ? 16 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.check,
              color: Colors.green,
              size: isTablet ? 20 : 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                feature,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: colors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildActionButtons(
    SubscriptionState subscriptionState,
    WareozeColorScheme colors,
    bool isTablet,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.border),
              padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: subscriptionState.isUpdating || 
                     subscriptionState.selectedSubscriptionId == null ||
                     subscriptionState.selectedSubscriptionId == subscriptionState.currentSubscriptionId
                ? null
                : () async {
                    final success = await ref
                        .read(subscriptionProvider.notifier)
                        .updateSubscription();
                    
                    if (success) {
                      // Optionally navigate back or show additional success UI
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: subscriptionState.isUpdating
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Update',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}