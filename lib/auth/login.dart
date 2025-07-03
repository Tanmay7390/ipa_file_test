import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test_22/auth/components/auth_widgets.dart';
import 'package:flutter_test_22/auth/components/auth_provider.dart';
import 'package:flutter_test_22/theme_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Button delay mechanism
  bool _isSignInButtonDisabled = false;
  bool _isGoogleButtonDisabled = false;
  bool _isAppleButtonDisabled = false;
  static const Duration _buttonDelay = Duration(seconds: 2);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper method to disable button temporarily
  void _disableButtonTemporarily(String buttonType) {
    switch (buttonType) {
      case 'signin':
        setState(() => _isSignInButtonDisabled = true);
        Future.delayed(_buttonDelay, () {
          if (mounted) setState(() => _isSignInButtonDisabled = false);
        });
        break;
      case 'google':
        setState(() => _isGoogleButtonDisabled = true);
        Future.delayed(_buttonDelay, () {
          if (mounted) setState(() => _isGoogleButtonDisabled = false);
        });
        break;
      case 'apple':
        setState(() => _isAppleButtonDisabled = true);
        Future.delayed(_buttonDelay, () {
          if (mounted) setState(() => _isAppleButtonDisabled = false);
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorProvider);
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final size = MediaQuery.of(context).size;

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: size.height * 0.05),
              // Logo
              const WareozoLogo(height: 80),

              SizedBox(height: size.height * 0.03),

              // Welcome text
              Text(
                'Welcome Back',
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
                'Sign in to continue to Wareozo',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.textSecondary,
                  fontFamily: 'SF Pro Display',
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: size.height * 0.03),

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

              SizedBox(height: size.height * 0.03),

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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Login with OTP
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      context.push('/login-with-otp');
                    },
                    child: Text(
                      'Login with OTP',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ),

                  // Forgot password
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      context.push('/forgot-password');
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ),
                ],
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

              // Sign in button with delay mechanism
              PrimaryButton(
                text: 'Sign In',
                isLoading: authState.isLoading,
                isDisabled: _isSignInButtonDisabled,
                onPressed: () async {
                  // Prevent multiple rapid clicks
                  if (_isSignInButtonDisabled || authState.isLoading) return;

                  if (_emailController.text.isEmpty ||
                      _passwordController.text.isEmpty) {
                    authNotifier.setError('Please fill in all fields');
                    return;
                  }

                  // Disable button temporarily
                  _disableButtonTemporarily('signin');

                  // Clear any previous errors
                  authNotifier.clearError();

                  final success = await authNotifier.signIn(
                    email: _emailController.text.trim(),
                    password: _passwordController.text,
                  );

                  if (success && mounted) {
                    print('Login successful, navigating to /home...');
                    context.go('/home'); // ← go_router redirect
                  }

                  // If login fails, error will be shown automatically from auth state
                },
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

              // Google sign in with delay mechanism
              SocialSignInButton(
                text: 'Sign in with Google',
                iconPath: 'assets/icons/google_logo.svg',
                onPressed: () async {
                  // Prevent multiple rapid clicks
                  if (_isGoogleButtonDisabled || authState.isLoading) return;

                  // Disable button temporarily
                  _disableButtonTemporarily('google');

                  final success = await authNotifier.signInWithGoogle();
                  if (success && mounted) {
                    // Navigation will be handled automatically by the router
                    print(
                      'Google login successful, waiting for router redirect...',
                    );
                  }
                },
                isLoading: authState.isLoading,
                isDisabled: _isGoogleButtonDisabled,
              ),

              const SizedBox(height: 16),

              // Apple sign in with delay mechanism
              SocialSignInButton(
                text: 'Sign in with Apple',
                iconPath: 'assets/icons/apple_logo.svg',
                onPressed: () async {
                  // Prevent multiple rapid clicks
                  if (_isAppleButtonDisabled || authState.isLoading) return;

                  // Disable button temporarily
                  _disableButtonTemporarily('apple');

                  final success = await authNotifier.signInWithApple();
                  if (success && mounted) {
                    // Navigation will be handled automatically by the router
                    print(
                      'Apple login successful, waiting for router redirect...',
                    );
                  }
                },
                isLoading: authState.isLoading,
                isDisabled: _isAppleButtonDisabled,
                isDark: true,
              ),

              const SizedBox(height: 20),

              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 16,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      context.push('/signup');
                    },
                    child: Text(
                      'Sign Up',
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
