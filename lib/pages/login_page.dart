import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/oauth_config.dart';
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
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
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

  void _showDevelopmentModeDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text('OAuth Configuration Required'),
        content: Text(
          'Google Sign-In requires configuration:\n\n'
          '1. Add GoogleService-Info.plist for iOS\n'
          '2. Add google-services.json for Android\n'
          '3. Configure Firebase project\n\n'
          'See OAUTH_SETUP.md for detailed instructions.',
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _passwordError = null;
    });

    try {
      // Check if we're in development mode
      if (OAuthConfig.isDevelopmentMode) {
        // Use test token for development
        _showDevelopmentModeDialog();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Step 1: Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Step 2: Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Step 3: Get the ID token
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        setState(() {
          _isLoading = false;
          _passwordError = 'Failed to get Google authentication token';
        });
        return;
      }

      // Step 4: Send the token to your backend
      final authActions = ref.read(authActionsProvider);
      final result = await authActions.googleLogin(idToken: idToken);

      if (!mounted) return;

      if (result.success && result.data != null) {
        // Save login info to AsyncStorage (SharedPreferences)
        await AuthService.saveLoginInfo(
          email: googleUser.email,
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
          _passwordError =
              result.error ?? 'Google login failed. Please try again.';
        });

        // Sign out from Google if backend authentication failed
        await _googleSignIn.signOut();
      }
    } on PlatformException catch (e) {
      // Handle platform-specific errors (missing configuration, etc.)
      String errorMessage = 'Google Sign-In Error: ';

      if (e.code == 'channel-error' ||
          e.message?.contains('Unable to establish connection') == true) {
        errorMessage =
            'Google Sign-In is not configured. Please add GoogleService-Info.plist (iOS) and google-services.json (Android) files. See OAUTH_SETUP.md for details.';
      } else if (e.code == 'sign_in_failed') {
        errorMessage =
            'Google Sign-In failed. Please check your internet connection and try again.';
      } else if (e.code == '10') {
        errorMessage =
            'Google Sign-In configuration error. Please check SHA certificates in Firebase Console.';
      } else {
        errorMessage = 'Google Sign-In error: ${e.message ?? e.code}';
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _passwordError = errorMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _passwordError = 'An unexpected error occurred. Please try again.';
        });
      }

      // Try to sign out from Google on error
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignore sign out errors
      }
    }
  }

  void _handleMicrosoftLogin() async {
    setState(() {
      _isLoading = true;
      _passwordError = null;
    });

    try {
      // For Microsoft OAuth, we would need to implement a web-based OAuth flow
      // or use a package like flutter_microsoft_authentication
      // For now, let's show a message that this feature requires additional setup

      // Since Microsoft OAuth requires more complex setup with Azure AD,
      // we'll need to configure the app in Azure portal first

      setState(() {
        _isLoading = false;
        _passwordError =
            'Microsoft login requires additional configuration. Please contact support.';
      });

      // TODO: Implement proper Microsoft OAuth flow when Azure AD app is configured
      // This would involve:
      // 1. Registering app in Azure AD
      // 2. Getting client ID and redirect URI
      // 3. Using url_launcher to open Microsoft login page
      // 4. Handling the redirect with the access token
      // 5. Sending the token to your backend
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _passwordError = 'An unexpected error occurred. Please try again.';
        });
      }
    }
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
                          ? Color(0xFF007AFF).withOpacity(0.15)
                          : Color(0xFF0387FE).withOpacity(0.10),
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
                          ? Color(0xFF007AFF).withOpacity(0.15)
                          : Color(0xFF0387FE).withOpacity(0.10),
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
                      color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
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
                          color: isDark ? Color(0xFF007AFF) : Color(0xFF0387FE),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 32),

                  // Divider with "OR"
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: CupertinoColors.systemGrey4,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontSize: 15,
                            color: CupertinoColors.systemGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: CupertinoColors.systemGrey4,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Sign in with Google Button
                  Container(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(16),
                      onPressed: _isLoading ? null : _handleGoogleLogin,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: CupertinoColors.systemGrey4,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google Icon - using a simple "G" for now
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemRed,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Sign in with Google',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? CupertinoColors.white
                                    : CupertinoColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 12),

                  // Sign in with Microsoft Button
                  Container(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(16),
                      onPressed: _isLoading ? null : _handleMicrosoftLogin,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: CupertinoColors.systemGrey4,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Microsoft Icon - using a simple "M" for now
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemBlue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  'M',
                                  style: TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Sign in with Microsoft',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? CupertinoColors.white
                                    : CupertinoColors.black,
                              ),
                            ),
                          ],
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
