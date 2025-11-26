import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController(text: 'abc@mail.com');
  final TextEditingController _passwordController = TextEditingController();
  bool _isEmailStep = true;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleNext() {
    final email = _emailController.text.trim();

    // Simple email validation
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Please enter an email';
      });
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _emailError = 'Please enter a valid email address';
      });
      return;
    }

    setState(() {
      _emailError = null;
      _isEmailStep = false;
    });
  }

  void _handleLogin() async {
    if (_passwordController.text.trim().isEmpty) {
      setState(() {
        _passwordError = 'Please enter a password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _passwordError = null;
    });

    // Simulate API call
    await Future.delayed(Duration(seconds: 1));

    // Dummy validation
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // For now, accept any email and password "123456"
    if (password == '123456' || password == 'password') {
      // Save login info
      await AuthService.saveLoginInfo(email);

      // Navigate to home using GoRouter with forward animation
      if (mounted) {
        context.go('/home', extra: {'fromLogin': true});
      }
    } else {
      setState(() {
        _isLoading = false;
        _passwordError = 'Invalid password. Try "123456" or "password"';
      });
    }
  }

  void _goBack() {
    if (_isEmailStep) {
      // Go back to onboarding
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/onboarding');
      }
    } else {
      // Go back to email step
      setState(() {
        _isEmailStep = true;
        _passwordController.clear();
        _passwordError = null;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isEmailStep) {
      // If on password step, go back to email step
      setState(() {
        _isEmailStep = true;
        _passwordController.clear();
        _passwordError = null;
      });
      return false;
    }
    // If on email step, go back to onboarding
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/onboarding');
    }
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
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _goBack,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.chevron_left,
                size: 28,
                color: CupertinoColors.activeBlue,
              ),
              SizedBox(width: 4),
              Text(
                _isEmailStep ? 'Back' : 'Back',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: CupertinoColors.activeBlue,
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40),

                // Icon with gradient
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFFD700),
                        Color(0xFFFF9500),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFF9500).withAlpha(77),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isEmailStep
                        ? CupertinoIcons.mail_solid
                        : CupertinoIcons.lock_fill,
                    size: 32,
                    color: CupertinoColors.white,
                  ),
                ),

                SizedBox(height: 32),

                // Title
                Text(
                  _isEmailStep ? 'Continue with Email' : 'Enter Password',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),

                SizedBox(height: 12),

                // Subtitle
                Text(
                  _isEmailStep
                      ? 'Enter your email to continue.'
                      : 'Enter your password to sign in.',
                  style: TextStyle(
                    fontSize: 17,
                    color: CupertinoColors.systemGrey,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                SizedBox(height: 32),

                // Input Field
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? CupertinoColors.systemGrey6.darkColor
                        : CupertinoColors.systemGrey6.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: CupertinoTextField(
                    controller: _isEmailStep
                        ? _emailController
                        : _passwordController,
                    placeholder: _isEmailStep ? 'Email' : 'Password',
                    placeholderStyle: TextStyle(
                      color: CupertinoColors.systemGrey2,
                      fontSize: 17,
                    ),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                    obscureText: !_isEmailStep,
                    keyboardType: _isEmailStep ? TextInputType.emailAddress : TextInputType.text,
                    decoration: BoxDecoration(),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textInputAction: _isEmailStep
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onSubmitted: (_) =>
                        _isEmailStep ? _handleNext() : _handleLogin(),
                    autofocus: !_isEmailStep,
                    onChanged: (_) {
                      // Clear errors on typing
                      if (_isEmailStep && _emailError != null) {
                        setState(() {
                          _emailError = null;
                        });
                      } else if (!_isEmailStep && _passwordError != null) {
                        setState(() {
                          _passwordError = null;
                        });
                      }
                    },
                  ),
                ),

                // Error message
                if ((_isEmailStep && _emailError != null) || (!_isEmailStep && _passwordError != null))
                  Padding(
                    padding: EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      _isEmailStep ? _emailError! : _passwordError!,
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemRed,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                SizedBox(height: 32),

                // Button with gradient effect
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: _isLoading
                        ? null
                        : LinearGradient(
                            colors: [
                              Color(0xFFFFD700),
                              Color(0xFFFF9500),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: _isLoading ? CupertinoColors.systemGrey4 : null,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _isLoading
                        ? null
                        : [
                            BoxShadow(
                              color: Color(0xFFFF9500).withAlpha(77),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    borderRadius: BorderRadius.circular(14),
                    color: Color(0x00000000),
                    onPressed: _isLoading
                        ? null
                        : (_isEmailStep ? _handleNext : _handleLogin),
                    child: _isLoading
                        ? CupertinoActivityIndicator(color: CupertinoColors.white)
                        : Text(
                            _isEmailStep ? 'Next' : 'Log In',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.white,
                            ),
                          ),
                  ),
                ),

                if (!_isEmailStep) ...[
                  SizedBox(height: 16),
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
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                    ),
                  ),
                ],

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
