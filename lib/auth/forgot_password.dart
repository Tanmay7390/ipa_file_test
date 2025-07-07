import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:Wareozo/auth/components/auth_widgets.dart';
import 'package:Wareozo/apis/providers/auth_provider.dart';
import 'package:Wareozo/theme_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _contactController = TextEditingController();
  String _selectedMethod = 'email'; // 'email' or 'phone'

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorProvider);
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.background,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: Icon(CupertinoIcons.back, color: colors.textPrimary),
        ),
        middle: Text(
          'Reset Password',
          style: TextStyle(
            color: colors.textPrimary,
            fontFamily: 'SF Pro Display',
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Logo
              const WareozoLogo(height: 80),

              const SizedBox(height: 40),

              // Title
              Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: 'SF Pro Display',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'Choose how you\'d like to reset your password',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.textSecondary,
                  fontFamily: 'SF Pro Display',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Method selection
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  children: [
                    // Email option
                    CupertinoButton(
                      padding: const EdgeInsets.all(16),
                      onPressed: () {
                        setState(() {
                          _selectedMethod = 'email';
                          _contactController.clear();
                        });
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedMethod == 'email'
                                    ? colors.primary
                                    : colors.border,
                                width: 2,
                              ),
                            ),
                            child: _selectedMethod == 'email'
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: colors.primary,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            CupertinoIcons.mail,
                            color: colors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                ),
                                Text(
                                  'Reset via email address',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 14,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      height: 1,
                      color: colors.border,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),

                    // Phone option
                    CupertinoButton(
                      padding: const EdgeInsets.all(16),
                      onPressed: () {
                        setState(() {
                          _selectedMethod = 'phone';
                          _contactController.clear();
                        });
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedMethod == 'phone'
                                    ? colors.primary
                                    : colors.border,
                                width: 2,
                              ),
                            ),
                            child: _selectedMethod == 'phone'
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: colors.primary,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            CupertinoIcons.phone,
                            color: colors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Phone Number',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                ),
                                Text(
                                  'Reset via SMS',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 14,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Contact input field
              AuthTextField(
                placeholder: _selectedMethod == 'email'
                    ? 'Enter your email address'
                    : 'Enter your phone number',
                controller: _contactController,
                keyboardType: _selectedMethod == 'email'
                    ? TextInputType.emailAddress
                    : TextInputType.phone,
                prefix: Icon(
                  _selectedMethod == 'email'
                      ? CupertinoIcons.mail
                      : CupertinoIcons.phone,
                  color: colors.textSecondary,
                  size: 20,
                ),
              ),

              const SizedBox(height: 24),

              // Error message
              if (authState.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.error.withOpacity(0.3)),
                  ),
                  child: Text(
                    authState.error!,
                    style: TextStyle(
                      color: colors.error,
                      fontSize: 14,
                      fontFamily: 'SF Pro Display',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Send reset button
              PrimaryButton(
                text: 'Send Reset Code',
                isLoading: authState.isLoading,
                onPressed: _contactController.text.trim().isNotEmpty
                    ? () async {
                        final success = await authNotifier.sendOTP(
                          contact: _contactController.text.trim(),
                          type: _selectedMethod,
                        );

                        if (success && context.mounted) {
                          context.push(
                            '/otp-verification',
                            extra: {
                              _selectedMethod == 'email' ? 'email' : 'phone':
                                  _contactController.text.trim(),
                              'type': _selectedMethod,
                              'flowType': 'forgot-password',
                            },
                          );
                        }
                      }
                    : null,
              ),

              const SizedBox(height: 40),

              // Back to login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Remember your password? ',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 16,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      context.pop();
                    },
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
