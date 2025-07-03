import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test_22/auth/components/auth_widgets.dart';
import 'package:flutter_test_22/auth/components/auth_provider.dart';
import 'package:flutter_test_22/theme_provider.dart';
import 'dart:async';

class OTPVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final String phone;
  final String type; // 'email' or 'phone'
  final String flowType; // 'signup', 'login-otp', 'forgot-password'

  const OTPVerificationScreen({
    super.key,
    this.email = '',
    this.phone = '',
    required this.type,
    required this.flowType,
  });

  @override
  ConsumerState<OTPVerificationScreen> createState() =>
      _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends ConsumerState<OTPVerificationScreen> {
  String _otp = '';
  Timer? _timer;
  int _resendTimer = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();

    // Debug print to check received parameters
    print('OTP Screen - Email: ${widget.email}');
    print('OTP Screen - Phone: ${widget.phone}');
    print('OTP Screen - Type: ${widget.type}');
    print('OTP Screen - Flow Type: ${widget.flowType}');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTimer = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  String get _contactInfo {
    // Only email is supported for OTP
    return widget.email.isNotEmpty ? widget.email : widget.phone;
  }

  String get _maskedContact {
    final contact = _contactInfo;
    if (widget.type == 'email' && contact.contains('@')) {
      final parts = contact.split('@');
      if (parts.length == 2) {
        final name = parts[0];
        final domain = parts[1];
        final maskedName = name.length > 2
            ? '${name.substring(0, 2)}${'*' * (name.length - 2)}'
            : name;
        return '$maskedName@$domain';
      }
    }
    return contact;
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
                'Verify OTP',
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
                'We sent a verification code to',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.textSecondary,
                  fontFamily: 'SF Pro Display',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              Text(
                _maskedContact,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  fontFamily: 'SF Pro Display',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // OTP Input
              OTPInputField(
                onChanged: (otp) {
                  setState(() {
                    _otp = otp;
                  });
                },
                length: 6,
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

              // Verify button
              PrimaryButton(
                text: 'Verify OTP',
                isLoading: authState.isLoading,
                onPressed: _otp.length == 6
                    ? () async {
                        final success = await authNotifier.verifyOTP(
                          otp: _otp,
                          contact: _contactInfo,
                          type: widget.type,
                        );

                        if (success && context.mounted) {
                          // Handle different flow types
                          switch (widget.flowType) {
                            case 'signup':
                              // Navigate to phone verification if email was verified first
                              if (widget.type == 'email' &&
                                  widget.phone.isNotEmpty) {
                                context.pushReplacement(
                                  '/otp-verification',
                                  extra: {
                                    'phone': widget.phone,
                                    'type': 'phone',
                                    'flowType': 'signup-phone',
                                  },
                                );
                              } else {
                                // Complete signup - navigate to home
                                context.go('/home');
                              }
                              break;
                            case 'signup-phone':
                              // Complete signup after phone verification
                              context.go('/home');
                              break;
                            case 'login-otp':
                              // Complete OTP login
                              context.go('/home');
                              break;
                            case 'forgot-password':
                              // Navigate to reset password screen
                              context.push(
                                '/reset-password',
                                extra: {
                                  'contact': _contactInfo,
                                  'type': widget.type,
                                },
                              );
                              break;
                          }
                        }
                      }
                    : null,
              ),

              const SizedBox(height: 24),

              // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code? ",
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 16,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  if (_canResend)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        final success = await authNotifier.sendOTP(
                          contact: _contactInfo,
                          type: 'email', // Always email for OTP
                        );
                        if (success) {
                          _startResendTimer();
                        }
                      },
                      child: Text(
                        'Resend',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    )
                  else
                    Text(
                      'Resend in ${_resendTimer}s',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 16,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Change contact method
              CupertinoButton(
                onPressed: () {
                  context.pop();
                },
                child: Text(
                  'Change email address',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
