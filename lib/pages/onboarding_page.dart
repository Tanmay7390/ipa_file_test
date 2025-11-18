import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final illustrationSize = (screenWidth * 0.75).clamp(280.0, 380.0);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SizedBox(height: 40),

                // Logo/App Name
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF007AFF),
                            Color(0xFF5856D6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        CupertinoIcons.calendar,
                        color: CupertinoColors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'EventHub',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.05),

                // Central illustration with soft gradient circles
                SizedBox(
                  height: illustrationSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                    // Outermost circle - Light Blue/Purple
                    Container(
                      width: illustrationSize,
                      height: illustrationSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFFE8F4FF).withAlpha(0),
                            Color(0xFFE8F4FF).withAlpha(179),
                            Color(0xFFD4E4FF).withAlpha(204),
                          ],
                          stops: [0.3, 0.7, 1.0],
                        ),
                      ),
                    ),
                    // Second circle - Light Cyan
                    Container(
                      width: illustrationSize * 0.8,
                      height: illustrationSize * 0.8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFFE0F7FA).withAlpha(0),
                            Color(0xFFE0F7FA).withAlpha(179),
                            Color(0xFFB2EBF2).withAlpha(204),
                          ],
                          stops: [0.3, 0.7, 1.0],
                        ),
                      ),
                    ),
                    // Third circle - Light Yellow/Peach
                    Container(
                      width: illustrationSize * 0.6,
                      height: illustrationSize * 0.6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFFFFF9E6).withAlpha(0),
                            Color(0xFFFFF3CD).withAlpha(179),
                            Color(0xFFFFE0B2).withAlpha(204),
                          ],
                          stops: [0.3, 0.7, 1.0],
                        ),
                      ),
                    ),
                    // Fourth circle - Light Pink/Rose
                    Container(
                      width: illustrationSize * 0.4,
                      height: illustrationSize * 0.4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFFFCE4EC).withAlpha(0),
                            Color(0xFFFCE4EC).withAlpha(153),
                            Color(0xFFF8BBD0).withAlpha(179),
                          ],
                          stops: [0.3, 0.7, 1.0],
                        ),
                      ),
                    ),

                    // Center white circle with shadow
                    Container(
                      width: illustrationSize * 0.275,
                      height: illustrationSize * 0.275,
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withAlpha(51),
                            blurRadius: 40,
                            spreadRadius: 0,
                            offset: Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Icon(
                        CupertinoIcons.calendar,
                        size: illustrationSize * 0.13,
                        color: CupertinoColors.black,
                      ),
                    ),
                  ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.05),

              // Title
              Text(
                'We\'ve got\nyou covered.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),

              SizedBox(height: 20),

              // Description
              Text(
                'Seamless event management with real-time\nupdates, interactive schedules, and networking\nopportunities. Access 24/7 event support.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.systemGrey,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),

              SizedBox(height: 16),

              // Learn more link (optional)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  // Handle learn more
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Learn about our features',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              // Get started button - iOS Blue
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  borderRadius: BorderRadius.circular(14),
                  color: CupertinoColors.activeBlue,
                  onPressed: () {
                    context.go('/login');
                  },
                  child: Text(
                    'Get started',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
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
    );
  }
}
