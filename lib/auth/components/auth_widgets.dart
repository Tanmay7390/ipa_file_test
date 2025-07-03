import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test_22/theme_provider.dart';

// Custom text field widget
class AuthTextField extends ConsumerWidget {
  final String placeholder;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefix;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.placeholder,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefix,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 16,
          fontFamily: 'SF Pro Display',
        ),
        placeholderStyle: TextStyle(
          color: colors.textSecondary,
          fontSize: 16,
          fontFamily: 'SF Pro Display',
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        prefix: prefix != null
            ? Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    prefix!,
                    const SizedBox(width: 8), // 👈 space between icon and text
                  ],
                ),
              )
            : null,

        suffix: suffix != null
            ? Padding(padding: const EdgeInsets.only(right: 16), child: suffix)
            : null,
        padding: EdgeInsets.symmetric(
          vertical: 16,
          horizontal: prefix != null || suffix != null ? 0 : 16,
        ),
      ),
    );
  }
}

// Social sign in button with disabled state support
class SocialSignInButton extends ConsumerWidget {
  final String text;
  final String iconPath;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDark;
  final bool isDisabled; // New parameter for disabled state

  const SocialSignInButton({
    super.key,
    required this.text,
    required this.iconPath,
    required this.onPressed,
    this.isLoading = false,
    this.isDark = false,
    this.isDisabled = false, // Default to false
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);
    final bool buttonDisabled = isLoading || isDisabled;

    return CupertinoButton(
      onPressed: buttonDisabled ? null : onPressed,
      padding: EdgeInsets.zero,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: buttonDisabled
              ? (isDark
                    ? colors.textSecondary
                    : colors.surface.withOpacity(0.6))
              : (isDark ? colors.textPrimary : colors.surface),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: buttonDisabled
                ? colors.textSecondary.withOpacity(0.5)
                : colors.textPrimary,
            width: 1,
          ),
        ),
        child: isLoading
            ? Center(
                child: CupertinoActivityIndicator(
                  color: isDark ? colors.surface : colors.textPrimary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (iconPath.isNotEmpty) ...[
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: buttonDisabled ? 0.5 : 1.0,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: iconPath.endsWith('.svg')
                            ? SvgPicture.asset(iconPath)
                            : Image.asset(iconPath, width: 24, height: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: buttonDisabled
                          ? (isDark
                                ? colors.surface.withOpacity(0.5)
                                : colors.textPrimary.withOpacity(0.5))
                          : (isDark ? colors.surface : colors.textPrimary),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF Pro Display',
                    ),
                    child: Text(text),
                  ),
                ],
              ),
      ),
    );
  }
}

// Primary button with disabled state support
class PrimaryButton extends ConsumerWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled; // New parameter for disabled state

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false, // Default to false
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);
    final bool buttonDisabled = isLoading || isDisabled;

    return CupertinoButton(
      onPressed: buttonDisabled ? null : onPressed,
      padding: EdgeInsets.zero,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: buttonDisabled
              ? colors.primary.withOpacity(0.6)
              : colors.primary,
          borderRadius: BorderRadius.circular(28),
          boxShadow: buttonDisabled
              ? []
              : [
                  BoxShadow(
                    color: colors.primary.withOpacity(0.6), // Glow color
                    blurRadius: 16, // Glow spread
                    spreadRadius: 2,
                    offset: const Offset(0, 2), // Shadow position
                  ),
                ],
        ),
        child: isLoading
            ? const Center(
                child: CupertinoActivityIndicator(color: CupertinoColors.white),
              )
            : Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: buttonDisabled
                        ? CupertinoColors.white.withOpacity(0.7)
                        : CupertinoColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                  ),
                  child: Text(text),
                ),
              ),
      ),
    );
  }
}

// OTP input field
class OTPInputField extends ConsumerStatefulWidget {
  final Function(String) onChanged;
  final int length;

  const OTPInputField({super.key, required this.onChanged, this.length = 6});

  @override
  ConsumerState<OTPInputField> createState() => _OTPInputFieldState();
}

class _OTPInputFieldState extends ConsumerState<OTPInputField> {
  late List<TextEditingController> controllers;
  late List<FocusNode> focusNodes;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    focusNodes = List.generate(widget.length, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        widget.length,
        (index) => SizedBox(
          width: 48,
          height: 56,
          child: CupertinoTextField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              fontFamily: 'SF Pro Display',
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: focusNodes[index].hasFocus
                    ? colors.primary
                    : colors.border,
                width: 2,
              ),
            ),
            onChanged: (value) {
              if (value.length == 1) {
                if (index < widget.length - 1) {
                  focusNodes[index + 1].requestFocus();
                } else {
                  focusNodes[index].unfocus();
                }
              } else if (value.isEmpty && index > 0) {
                focusNodes[index - 1].requestFocus();
              }

              // Collect all values and notify parent
              String otp = controllers.map((c) => c.text).join();
              widget.onChanged(otp);
            },
          ),
        ),
      ),
    );
  }
}

// Logo widget
class WareozoLogo extends ConsumerWidget {
  final double height;

  const WareozoLogo({super.key, this.height = 80});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: height,
      child: Center(
        child: Image.asset(
          'assets/logos/wareozo-half-black.png',
          height: height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
