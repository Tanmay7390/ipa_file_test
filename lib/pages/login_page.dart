import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../apis/providers/auth_provider.dart';
import '../providers/home_data_provider.dart';
import '../providers/user_data_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _identifierController = TextEditingController(
    text: '',
  );
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _identifierError;
  String? _passwordError;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    return value.contains('@') && value.contains('.');
  }

  bool _isValidPhone(String value) {
    // Remove any non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    // Check if it's a valid phone number (at least 10 digits)
    return digitsOnly.length >= 10;
  }

  void _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    // Validate identifier (email or phone)
    if (identifier.isEmpty) {
      setState(() {
        _identifierError = 'Please enter an email or phone number';
      });
      return;
    }

    if (!_isValidEmail(identifier) && !_isValidPhone(identifier)) {
      setState(() {
        _identifierError = 'Please enter a valid email or phone number';
      });
      return;
    }

    // Validate password
    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Please enter a password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _identifierError = null;
      _passwordError = null;
    });

    try {
      // Call the login API
      final authActions = ref.read(authActionsProvider);
      final result = await authActions.login(
        email: identifier,
        password: password,
      );

      if (!mounted) return;

      if (result.success && result.data != null) {
        // Save login info to AsyncStorage (SharedPreferences)
        await AuthService.saveLoginInfo(
          email: identifier,
          token: result.data!.token,
          homePage: result.data!.homePage,
          userData: result.data!.user,
        );

        // Refresh home page data cache
        ref.read(homePageDataProvider.notifier).refresh();

        // Refresh user data cache
        ref.read(userDataProvider.notifier).refresh();

        // Navigate to home using GoRouter with forward animation
        if (mounted) {
          context.go('/home', extra: {'fromLogin': true});
        }
      } else {
        setState(() {
          _isLoading = false;
          _passwordError = result.error ?? 'Login failed. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _passwordError = 'An unexpected error occurred. Please try again.';
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    // Prevent going back
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _onWillPop();
        }
      },
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemBackground,
        child: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 40),

                  // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/banner-logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  SizedBox(height: 32),

                  // Title
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),

                  SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'Sign in to your account to continue.',
                    style: TextStyle(
                      fontSize: 17,
                      color: CupertinoColors.systemGrey,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  SizedBox(height: 32),

                  // Email/Phone Input Field
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Color(0xFF23C061).withOpacity(0.15)
                          : Color(0xFF21AA62).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: CupertinoTextField(
                      controller: _identifierController,
                      placeholder: 'Email or Phone',
                      placeholderStyle: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 17,
                      ),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      decoration: BoxDecoration(),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        if (_identifierError != null) {
                          setState(() {
                            _identifierError = null;
                          });
                        }
                      },
                    ),
                  ),

                  // Error message for identifier
                  if (_identifierError != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8, left: 4),
                      child: Text(
                        _identifierError!,
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemRed,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                  SizedBox(height: 16),

                  // Password Input Field
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Color(0xFF23C061).withOpacity(0.15)
                          : Color(0xFF21AA62).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: CupertinoTextField(
                      controller: _passwordController,
                      placeholder: 'Password',
                      placeholderStyle: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 17,
                      ),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                      obscureText: true,
                      decoration: BoxDecoration(),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleLogin(),
                      onChanged: (_) {
                        if (_passwordError != null) {
                          setState(() {
                            _passwordError = null;
                          });
                        }
                      },
                    ),
                  ),

                  // Error message for password
                  if (_passwordError != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8, left: 4),
                      child: Text(
                        _passwordError!,
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemRed,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                  SizedBox(height: 20),

                  // Login Button
                  Container(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      borderRadius: BorderRadius.circular(16),
                      color: isDark ? Color(0xFF23C061) : Color(0xFF21AA62),
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Color(0xFF000000)
                                    : Color(0xFFFFFFFF),
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Forgot Password
                  Center(
                    child: CupertinoButton(
                      onPressed: () {
                        // Handle forgot password
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: isDark ? Color(0xFF23C061) : Color(0xFF21AA62),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
