import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

import './components/social_button.dart';

class Login1 extends StatelessWidget {
  const Login1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get screen size safely
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
          child: SizedBox(
            height: size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 1),

                // Logo section
                _buildLogo(size),
                SizedBox(height: size.height * 0.03),

                // Email & password section
                _buildEmailTextField(size),
                SizedBox(height: size.height * 0.02),

                _buildPasswordTextField(size),
                SizedBox(height: size.height * 0.03),

                // Sign in button
                _buildSignInButton(size),
                SizedBox(height: size.height * 0.03),

                // Divider with text
                _buildSignInWithText(),
                SizedBox(height: size.height * 0.03),

                // Social login buttons
                LoginSocialButton(
                  iconPath: 'assets/icons/google_logo.svg',
                  text: 'Sign in with Google',
                  size: size,
                  textColor: Colors.black,
                  backgroundColor: Colors.white,
                ),
                SizedBox(height: size.height * 0.02),

                LoginSocialButton(
                  iconPath: 'assets/icons/apple_logo.svg',
                  text: 'Sign in with Apple',
                  size: size,
                  textColor: Colors.white,
                  backgroundColor: const Color(0xFF000000),
                ),

                const Spacer(flex: 2),

                // Footer
                _buildFooterText(size),
                SizedBox(height: size.height * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(Size size) {
    // Make logo responsive but with reasonable min/max sizes
    final logoSize = (size.height * 0.08).clamp(50.0, 120.0);

    return Center(
      child: SvgPicture.asset(
        'assets/icons/logo.svg',
        height: logoSize,
        width: logoSize,
        // Add placeholder for missing asset
        placeholderBuilder: (context) => Container(
          height: logoSize,
          width: logoSize,
          decoration: BoxDecoration(
            color: const Color(0xFF21899C),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.login, color: Colors.white, size: 40),
        ),
      ),
    );
  }

  Widget _buildEmailTextField(Size size) {
    final fieldHeight = (size.height * 0.07).clamp(50.0, 80.0);
    final fontSize = (size.width * 0.04).clamp(14.0, 18.0);
    final labelFontSize = (size.width * 0.03).clamp(11.0, 14.0);

    return Container(
      alignment: Alignment.center,
      height: fieldHeight,
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(width: 1.0, color: const Color(0xFFEFEFEF)),
      ),
      child: TextField(
        style: GoogleFonts.inter(
          fontSize: fontSize,
          color: const Color(0xFF15224F),
        ),
        maxLines: 1,
        cursorColor: const Color(0xFF15224F),
        decoration: InputDecoration(
          labelText: 'Email/ Phone number',
          labelStyle: GoogleFonts.inter(
            fontSize: labelFontSize,
            color: const Color(0xFF969AA8),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildPasswordTextField(Size size) {
    final fieldHeight = (size.height * 0.07).clamp(50.0, 80.0);
    final fontSize = (size.width * 0.04).clamp(14.0, 18.0);
    final labelFontSize = (size.width * 0.03).clamp(11.0, 14.0);

    return Container(
      alignment: Alignment.center,
      height: fieldHeight,
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(width: 1.0, color: const Color(0xFFEFEFEF)),
      ),
      child: TextField(
        style: GoogleFonts.inter(
          fontSize: fontSize,
          color: const Color(0xFF15224F),
        ),
        maxLines: 1,
        obscureText: true,
        keyboardType: TextInputType.visiblePassword,
        cursorColor: const Color(0xFF15224F),
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: GoogleFonts.inter(
            fontSize: labelFontSize,
            color: const Color(0xFF969AA8),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildSignInButton(Size size) {
    final buttonHeight = (size.height * 0.07).clamp(50.0, 80.0);
    final fontSize = (size.width * 0.04).clamp(14.0, 18.0);

    return Container(
      alignment: Alignment.center,
      height: buttonHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50.0),
        color: const Color(0xFF21899C),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C2E84).withOpacity(0.2),
            offset: const Offset(0, 15.0),
            blurRadius: 60.0,
          ),
        ],
      ),
      child: Text(
        'Sign in',
        style: GoogleFonts.inter(
          fontSize: fontSize,
          color: Colors.white,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSignInWithText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(child: Divider(color: Color(0xFFEFEFEF), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Or Sign in with',
            style: GoogleFonts.inter(
              fontSize: 12.0,
              color: const Color(0xFF969AA8),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFEFEFEF), thickness: 1)),
      ],
    );
  }

  Widget _buildFooterText(Size size) {
    final fontSize = (size.width * 0.03).clamp(11.0, 14.0);

    return Center(
      child: Text.rich(
        TextSpan(
          style: GoogleFonts.inter(
            fontSize: fontSize,
            color: const Color(0xFF3B4C68),
          ),
          children: const [
            TextSpan(text: 'Don\'t have an account? '),
            TextSpan(
              text: 'Sign up',
              style: TextStyle(
                color: Color(0xFF21899C),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
