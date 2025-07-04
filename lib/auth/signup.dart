import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test_22/auth/components/auth_widgets.dart';
import 'package:flutter_test_22/apis/providers/auth_provider.dart';
import 'package:flutter_test_22/theme_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      return false;
    }
    if (_emailController.text.trim().isEmpty) {
      return false;
    }
    if (_phoneController.text.trim().isEmpty) {
      return false;
    }
    if (_passwordController.text.isEmpty) {
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      return false;
    }
    return true;
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
              // Logo
              const WareozoLogo(height: 80),

              const SizedBox(height: 30),

              // Welcome text
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: 'SF Pro Display',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Join Wareozo today',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.textSecondary,
                  fontFamily: 'SF Pro Display',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              // Name field
              AuthTextField(
                placeholder: 'Full Name',
                controller: _nameController,
                keyboardType: TextInputType.name,
                prefix: Icon(
                  CupertinoIcons.person,
                  color: colors.textSecondary,
                  size: 20,
                ),
              ),

              const SizedBox(height: 16),

              // Email field
              AuthTextField(
                placeholder: 'Email address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefix: Icon(
                  CupertinoIcons.mail,
                  color: colors.textSecondary,
                  size: 20,
                ),
              ),

              const SizedBox(height: 16),

              // Phone field
              AuthTextField(
                placeholder: 'Phone Number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefix: Icon(
                  CupertinoIcons.phone,
                  color: colors.textSecondary,
                  size: 20,
                ),
              ),

              const SizedBox(height: 16),

              // Password field
              AuthTextField(
                placeholder: 'Password',
                controller: _passwordController,
                obscureText: _obscurePassword,
                prefix: Icon(
                  CupertinoIcons.lock,
                  color: colors.textSecondary,
                  size: 20,
                ),
                suffix: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  child: Icon(
                    _obscurePassword
                        ? CupertinoIcons.eye_slash
                        : CupertinoIcons.eye,
                    color: colors.textSecondary,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Confirm password field
              AuthTextField(
                placeholder: 'Confirm Password',
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                prefix: Icon(
                  CupertinoIcons.lock,
                  color: colors.textSecondary,
                  size: 20,
                ),
                suffix: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  child: Icon(
                    _obscureConfirmPassword
                        ? CupertinoIcons.eye_slash
                        : CupertinoIcons.eye,
                    color: colors.textSecondary,
                    size: 20,
                  ),
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

              // Sign up button
              PrimaryButton(
                text: 'Create Account',
                isLoading: authState.isLoading,
                onPressed: _validateForm()
                    ? () async {
                        // First create account
                        final success = await authNotifier.signUp(
                          name: _nameController.text.trim(),
                          email: _emailController.text.trim(),
                          phone: _phoneController.text.trim(),
                          password: _passwordController.text,
                        );

                        if (success && context.mounted) {
                          // Navigate to home screen
                          context.go('/home');
                        }
                      }
                    : null,
              ),

              const SizedBox(height: 24),

              // Or divider
              Row(
                children: [
                  Expanded(child: Container(height: 1, color: colors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ),
                  Expanded(child: Container(height: 1, color: colors.border)),
                ],
              ),

              const SizedBox(height: 24),

              // Google sign up
              SocialSignInButton(
                text: 'Sign up with Google',
                iconPath: 'assets/icons/google_logo.svg',
                onPressed: () async {
                  await authNotifier.signInWithGoogle();
                },
                isLoading: authState.isLoading,
              ),

              const SizedBox(height: 16),

              // Apple sign up
              SocialSignInButton(
                text: 'Sign up with Apple',
                iconPath: 'assets/icons/apple_logo.svg',
                onPressed: () async {
                  await authNotifier.signInWithApple();
                },
                isLoading: authState.isLoading,
                isDark: true,
              ),

              const SizedBox(height: 40),

              // Sign in link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
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
