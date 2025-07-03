import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginSocialButton extends StatelessWidget {
  final Size size;
  final String iconPath;
  final String text;
  final Color textColor;
  final Color backgroundColor;

  const LoginSocialButton({
    Key? key,
    required this.size,
    required this.iconPath,
    required this.text,
    required this.textColor,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions safely
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate responsive dimensions
    final buttonHeight = (screenHeight * 0.07).clamp(50.0, 70.0);
    final fontSize = (screenWidth * 0.04).clamp(14.0, 16.0);
    final iconSize = (buttonHeight * 0.4).clamp(20.0, 28.0);

    return Container(
      height: buttonHeight,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50.0),
        border: Border.all(width: 1.0, color: const Color(0xFF134140)),
        color: backgroundColor,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              height: iconSize,
              width: iconSize,
              // Add error handling for missing assets
              placeholderBuilder: (context) => Icon(
                Icons.image,
                size: iconSize,
                color: const Color(0xFF134140),
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Flexible(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: fontSize,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
