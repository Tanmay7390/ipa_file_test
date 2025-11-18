import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _eventCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isEventCodeStep = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _eventCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_eventCodeController.text.trim().isEmpty) {
      _showAlert('Please enter an event code');
      return;
    }
    setState(() {
      _isEventCodeStep = false;
    });
  }

  void _handleLogin() async {
    if (_passwordController.text.trim().isEmpty) {
      _showAlert('Please enter a password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(Duration(seconds: 1));

    // Dummy validation
    final eventCode = _eventCodeController.text.trim();
    final password = _passwordController.text.trim();

    // For now, accept any event code and password "123456"
    if (password == '123456' || password == 'password') {
      // Save login info
      await AuthService.saveLoginInfo(eventCode);

      // Navigate to home using GoRouter
      if (mounted) {
        context.go('/home');
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      _showAlert('Invalid password. Try "123456" or "password"');
    }
  }

  void _showAlert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _goBack() {
    setState(() {
      _isEventCodeStep = true;
      _passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button on password step
                if (!_isEventCodeStep) ...[
                  SizedBox(height: 8),
                  CupertinoButton(
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
                          'Back',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            color: CupertinoColors.activeBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                ] else
                  SizedBox(height: 60),

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
                    _isEventCodeStep
                        ? CupertinoIcons.ticket_fill
                        : CupertinoIcons.lock_fill,
                    size: 32,
                    color: CupertinoColors.white,
                  ),
                ),

                SizedBox(height: 32),

                // Title
                Text(
                  _isEventCodeStep ? 'Continue with Event Code' : 'Enter Password',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),

                SizedBox(height: 12),

                // Subtitle
                Text(
                  _isEventCodeStep
                      ? 'Enter your event code to continue.'
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
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: CupertinoTextField(
                    controller: _isEventCodeStep
                        ? _eventCodeController
                        : _passwordController,
                    placeholder: _isEventCodeStep ? 'Event Code' : 'Password',
                    placeholderStyle: TextStyle(
                      color: CupertinoColors.systemGrey2,
                      fontSize: 17,
                    ),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                    ),
                    obscureText: !_isEventCodeStep,
                    decoration: BoxDecoration(),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textInputAction: _isEventCodeStep
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onSubmitted: (_) =>
                        _isEventCodeStep ? _handleNext() : _handleLogin(),
                    autofocus: !_isEventCodeStep,
                  ),
                ),

                SizedBox(height: 32),

                // Button with iOS Blue
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    borderRadius: BorderRadius.circular(12),
                    color: _isLoading
                        ? CupertinoColors.systemGrey4
                        : CupertinoColors.activeBlue,
                    onPressed: _isLoading
                        ? null
                        : (_isEventCodeStep ? _handleNext : _handleLogin),
                    child: _isLoading
                        ? CupertinoActivityIndicator(color: CupertinoColors.white)
                        : Text(
                            _isEventCodeStep ? 'Next' : 'Log In',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.white,
                            ),
                          ),
                  ),
                ),

                if (!_isEventCodeStep) ...[
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
    );
  }
}
