import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test_22/auth/components/auth_widgets.dart';
import 'package:flutter_test_22/apis/providers/auth_provider.dart';
import 'package:flutter_test_22/theme_provider.dart';

class LoginWithOTPScreen extends ConsumerStatefulWidget {
  const LoginWithOTPScreen({super.key});

  @override
  ConsumerState<LoginWithOTPScreen> createState() => _LoginWithOTPScreenState();
}

class _LoginWithOTPScreenState extends ConsumerState<LoginWithOTPScreen> {
  final _emailController =
      TextEditingController(); // Changed from contact to email

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorProvider);
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return CupertinoPageScaffold(
      backgroundColor: colors.background,

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
                'Quick Login',
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
                'Enter your email to receive OTP for quick login',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.textSecondary,
                  fontFamily: 'SF Pro Display',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 80),

              // Email input field only
              AuthTextField(
                placeholder: 'Enter your email address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefix: Icon(
                  CupertinoIcons.mail,
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

              // Send OTP button
              PrimaryButton(
                text: 'Send OTP',
                isLoading: authState.isLoading,
                onPressed: () async {
                  // Validate email first
                  final email = _emailController.text.trim();

                  if (email.isEmpty) {
                    // Show error for empty email
                    authNotifier.setError('Please enter your email address');
                    return;
                  }

                  if (!_isValidEmail(email)) {
                    // Show error for invalid email
                    authNotifier.setError('Please enter a valid email address');
                    return;
                  }

                  // Clear any existing errors
                  authNotifier.clearError();

                  print('Send OTP button pressed');
                  print('Email: $email');

                  final success = await authNotifier.sendOTP(
                    contact: email,
                    type: 'email', // Always email for login with OTP
                  );

                  print('Send OTP success: $success');

                  if (success && context.mounted) {
                    final Map<String, dynamic> extraData = {
                      'email': email,
                      'type': 'email',
                      'flowType': 'login-otp',
                    };

                    print(
                      'Navigating to OTP verification with data: $extraData',
                    );
                    context.push('/otp-verification', extra: extraData);
                  }
                },
              ),
              const SizedBox(height: 40),

              // Back to login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Want to use password? ',
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
