import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with TickerProviderStateMixin {
  late AnimationController _rotationController1;
  late AnimationController _rotationController2;
  late AnimationController _rotationController3;
  late AnimationController _rotationController4;
  late AnimationController _pulseController;
  late AnimationController _centerPulseController;
  late AnimationController _centerSeesawController;

  late Animation<double> _rotation1;
  late Animation<double> _rotation2;
  late Animation<double> _rotation3;
  late Animation<double> _rotation4;
  late Animation<double> _scale1;
  late Animation<double> _scale2;
  late Animation<double> _scale3;
  late Animation<double> _scale4;
  late Animation<Offset> _position1;
  late Animation<Offset> _position2;
  late Animation<Offset> _position3;
  late Animation<Offset> _position4;
  late Animation<double> _centerScale;
  late Animation<double> _centerSeesaw;

  @override
  void initState() {
    super.initState();

    // Rotation controllers - all same duration for synchronized rotation
    _rotationController1 = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _rotationController2 = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _rotationController3 = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _rotationController4 = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    // Pulse controller for overlapping scaling
    _pulseController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    // Center circle controllers
    _centerPulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _centerSeesawController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    // Rotation animations - alternating directions
    _rotation1 = Tween<double>(begin: 0, end: 1).animate(_rotationController1);
    _rotation2 = Tween<double>(
      begin: 0,
      end: -1,
    ).animate(_rotationController2); // Counter-clockwise
    _rotation3 = Tween<double>(begin: 0, end: 1).animate(_rotationController3);
    _rotation4 = Tween<double>(
      begin: 0,
      end: -1,
    ).animate(_rotationController4); // Counter-clockwise

    // Circular motion paths - alternating directions (reduced movement)
    // Ring 1: Clockwise circular motion (left->top->right->bottom)
    _position1 =
        TweenSequence<Offset>([
          TweenSequenceItem(
            tween: Tween(begin: Offset(0, 0), end: Offset(-5, 0)),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween(begin: Offset(-5, 0), end: Offset(0, -5)),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween(begin: Offset(0, -5), end: Offset(5, 0)),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween(begin: Offset(5, 0), end: Offset(0, 5)),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween(begin: Offset(0, 5), end: Offset(0, 0)),
            weight: 1,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _rotationController1,
            curve: Curves.easeInOut,
          ),
        );

    // Ring 2: Counter-clockwise circular motion
    _position2 =
        TweenSequence<Offset>([
          TweenSequenceItem(
            tween: Tween(begin: Offset(0, 0), end: Offset(4, 0)),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween(begin: Offset(4, 0), end: Offset(0, -4)),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween(begin: Offset(0, -4), end: Offset(-4, 0)),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween(begin: Offset(-4, 0), end: Offset(0, 4)),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween(begin: Offset(0, 4), end: Offset(0, 0)),
            weight: 1,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _rotationController2,
            curve: Curves.easeInOut,
          ),
        );

    // Ring 3: Clockwise circular motion
    _position3 =
        TweenSequence<Offset>([
          TweenSequenceItem(
            tween: Tween(begin: Offset(0, 0), end: Offset(-3, 0)),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween(begin: Offset(-3, 0), end: Offset(0, -3)),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween(begin: Offset(0, -3), end: Offset(3, 0)),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween(begin: Offset(3, 0), end: Offset(0, 3)),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween(begin: Offset(0, 3), end: Offset(0, 0)),
            weight: 1,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _rotationController3,
            curve: Curves.easeInOut,
          ),
        );

    // Ring 4: Counter-clockwise circular motion
    _position4 =
        TweenSequence<Offset>([
          TweenSequenceItem(
            tween: Tween(begin: Offset(0, 0), end: Offset(2, 0)),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween(begin: Offset(2, 0), end: Offset(0, -2)),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween(begin: Offset(0, -2), end: Offset(-2, 0)),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween(begin: Offset(-2, 0), end: Offset(0, 2)),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween(begin: Offset(0, 2), end: Offset(0, 0)),
            weight: 1,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _rotationController4,
            curve: Curves.easeInOut,
          ),
        );

    // Overlapping pulse animations - reduced expansion
    _scale1 = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.03,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.03,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 4),
    ]).animate(_pulseController);

    _scale2 = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 0.5),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.03,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.03,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 3.5),
    ]).animate(_pulseController);

    _scale3 = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 1),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.03,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.03,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 3),
    ]).animate(_pulseController);

    _scale4 = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 1.5),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.03,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.03,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 2.5),
    ]).animate(_pulseController);

    // Center circle animations
    _centerScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _centerPulseController, curve: Curves.easeInOut),
    );

    _centerSeesaw = Tween<double>(begin: -0.12, end: 0.12).animate(
      CurvedAnimation(parent: _centerSeesawController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController1.dispose();
    _rotationController2.dispose();
    _rotationController3.dispose();
    _rotationController4.dispose();
    _pulseController.dispose();
    _centerPulseController.dispose();
    _centerSeesawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final illustrationSize = isTablet
        ? (screenWidth * 0.5).clamp(300.0, 450.0)
        : (screenWidth * 0.75).clamp(250.0, 350.0);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: Stack(
          children: [
            // Logo at top left
            Positioned(
              top: 20,
              left: 10,
              child: Image.asset(
                isDarkMode
                    ? 'assets/images/logo-dark-no-bg.png'
                    : 'assets/images/logo-light-no-bg.png',
                width: 110,
                height: 110,
              ),
            ),

            // Main content centered
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 600 : double.infinity,
                ),
                padding: EdgeInsets.only(
                  top: 80,
                  bottom: 140,
                  left: 24,
                  right: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Central illustration with soft gradient circles
                    SizedBox(
                      height: illustrationSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outermost circle - Medium Blue/Purple with enhanced glow
                          AnimatedBuilder(
                            animation: Listenable.merge([
                              _rotationController1,
                              _pulseController,
                            ]),
                            builder: (context, child) {
                              return Transform.translate(
                                offset: _position1.value,
                                child: Transform.rotate(
                                  angle: _rotation1.value * 2 * 3.14159,
                                  child: Transform.scale(
                                    scale: _scale1.value,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: illustrationSize,
                                          height: illustrationSize,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: isDarkMode
                                                  ? [
                                                      Color(
                                                        0xFF80C4F7,
                                                      ).withAlpha(0),
                                                      Color(
                                                        0xFF80C4F7,
                                                      ).withAlpha(190),
                                                      Color(
                                                        0xFF64B5F6,
                                                      ).withAlpha(220),
                                                      Color(
                                                        0xFF64B5F6,
                                                      ).withAlpha(0),
                                                    ]
                                                  : [
                                                      Color(
                                                        0xFFC5DDFA,
                                                      ).withAlpha(0),
                                                      Color(
                                                        0xFFC5DDFA,
                                                      ).withAlpha(220),
                                                      Color(
                                                        0xFFAAC8EE,
                                                      ).withAlpha(240),
                                                      Color(
                                                        0xFFAAC8EE,
                                                      ).withAlpha(0),
                                                    ],
                                              stops: [0.0, 0.60, 0.94, 1.0],
                                            ),
                                            boxShadow: isDarkMode
                                                ? [
                                                    BoxShadow(
                                                      color: Color(
                                                        0xFF64B5F6,
                                                      ).withAlpha(180),
                                                      blurRadius: 28,
                                                      spreadRadius: 12,
                                                    ),
                                                    BoxShadow(
                                                      color: Color(
                                                        0xFF80C4F7,
                                                      ).withAlpha(130),
                                                      blurRadius: 45,
                                                      spreadRadius: 22,
                                                    ),
                                                  ]
                                                : [
                                                    BoxShadow(
                                                      color: Color(
                                                        0xFFAAC8EE,
                                                      ).withAlpha(180),
                                                      blurRadius: 30,
                                                      spreadRadius: 12,
                                                    ),
                                                    BoxShadow(
                                                      color: Color(
                                                        0xFFC5DDFA,
                                                      ).withAlpha(120),
                                                      blurRadius: 50,
                                                      spreadRadius: 24,
                                                    ),
                                                  ],
                                          ),
                                        ),
                                        // Bubbles for rotation visibility - randomly positioned
                                        Positioned(
                                          top: illustrationSize * 0.08,
                                          left: illustrationSize * 0.35,
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: isDarkMode
                                                  ? Color(0xFF64B5F6)
                                                  : Color(0xFFAAC8EE),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isDarkMode
                                                      ? Color(
                                                          0xFF64B5F6,
                                                        ).withAlpha(120)
                                                      : Color(
                                                          0xFFAAC8EE,
                                                        ).withAlpha(100),
                                                  blurRadius: isDarkMode
                                                      ? 10
                                                      : 8,
                                                  spreadRadius: isDarkMode
                                                      ? 3
                                                      : 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: illustrationSize * 0.12,
                                          top: illustrationSize * 0.28,
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: isDarkMode
                                                  ? Color(0xFF80C4F7)
                                                  : Color(0xFFC5DDFA),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isDarkMode
                                                      ? Color(
                                                          0xFF80C4F7,
                                                        ).withAlpha(120)
                                                      : Color(
                                                          0xFFC5DDFA,
                                                        ).withAlpha(100),
                                                  blurRadius: isDarkMode
                                                      ? 8
                                                      : 6,
                                                  spreadRadius: isDarkMode
                                                      ? 2
                                                      : 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: illustrationSize * 0.22,
                                          bottom: illustrationSize * 0.18,
                                          child: Container(
                                            width: 9,
                                            height: 9,
                                            decoration: BoxDecoration(
                                              color: isDarkMode
                                                  ? Color(
                                                      0xFF64B5F6,
                                                    ).withAlpha(220)
                                                  : Color(
                                                      0xFFAAC8EE,
                                                    ).withAlpha(200),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isDarkMode
                                                      ? Color(
                                                          0xFF64B5F6,
                                                        ).withAlpha(100)
                                                      : Color(
                                                          0xFFAAC8EE,
                                                        ).withAlpha(80),
                                                  blurRadius: isDarkMode
                                                      ? 8
                                                      : 6,
                                                  spreadRadius: isDarkMode
                                                      ? 2
                                                      : 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Second circle - Medium Cyan with enhanced glow
                          AnimatedBuilder(
                            animation: Listenable.merge([
                              _rotationController2,
                              _pulseController,
                            ]),
                            builder: (context, child) {
                              return Transform.translate(
                                offset: _position2.value,
                                child: Transform.rotate(
                                  angle: _rotation2.value * 2 * 3.14159,
                                  child: Transform.scale(
                                    scale: _scale2.value,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: illustrationSize * 0.8,
                                          height: illustrationSize * 0.8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: isDarkMode
                                                  ? [
                                                      Color(
                                                        0xFF4DD0E1,
                                                      ).withAlpha(0),
                                                      Color(
                                                        0xFF4DD0E1,
                                                      ).withAlpha(200),
                                                      Color(
                                                        0xFF26C6DA,
                                                      ).withAlpha(230),
                                                      Color(
                                                        0xFF26C6DA,
                                                      ).withAlpha(0),
                                                    ]
                                                  : [
                                                      Color(
                                                        0xFFBFE9F0,
                                                      ).withAlpha(0),
                                                      Color(
                                                        0xFFBFE9F0,
                                                      ).withAlpha(220),
                                                      Color(
                                                        0xFF95DBE5,
                                                      ).withAlpha(240),
                                                      Color(
                                                        0xFF95DBE5,
                                                      ).withAlpha(0),
                                                    ],
                                              stops: [0.0, 0.60, 0.94, 1.0],
                                            ),
                                            boxShadow: isDarkMode
                                                ? [
                                                    BoxShadow(
                                                      color: Color(
                                                        0xFF26C6DA,
                                                      ).withAlpha(180),
                                                      blurRadius: 24,
                                                      spreadRadius: 10,
                                                    ),
                                                    BoxShadow(
                                                      color: Color(
                                                        0xFF4DD0E1,
                                                      ).withAlpha(130),
                                                      blurRadius: 40,
                                                      spreadRadius: 18,
                                                    ),
                                                  ]
                                                : [
                                                    BoxShadow(
                                                      color: Color(
                                                        0xFF95DBE5,
                                                      ).withAlpha(180),
                                                      blurRadius: 26,
                                                      spreadRadius: 10,
                                                    ),
                                                    BoxShadow(
                                                      color: Color(
                                                        0xFFBFE9F0,
                                                      ).withAlpha(120),
                                                      blurRadius: 45,
                                                      spreadRadius: 19,
                                                    ),
                                                  ],
                                          ),
                                        ),
                                        // Bubbles for rotation visibility - randomly positioned
                                        Positioned(
                                          left: illustrationSize * 0.15,
                                          top: illustrationSize * 0.22,
                                          child: Container(
                                            width: 11,
                                            height: 11,
                                            decoration: BoxDecoration(
                                              color: isDarkMode
                                                  ? Color(0xFF26C6DA)
                                                  : Color(0xFF95DBE5),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isDarkMode
                                                      ? Color(
                                                          0xFF26C6DA,
                                                        ).withAlpha(120)
                                                      : Color(
                                                          0xFF95DBE5,
                                                        ).withAlpha(100),
                                                  blurRadius: isDarkMode
                                                      ? 10
                                                      : 8,
                                                  spreadRadius: isDarkMode
                                                      ? 3
                                                      : 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: illustrationSize * 0.12,
                                          right: illustrationSize * 0.18,
                                          child: Container(
                                            width: 9,
                                            height: 9,
                                            decoration: BoxDecoration(
                                              color: isDarkMode
                                                  ? Color(0xFF4DD0E1)
                                                  : Color(0xFFBFE9F0),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isDarkMode
                                                      ? Color(
                                                          0xFF4DD0E1,
                                                        ).withAlpha(120)
                                                      : Color(
                                                          0xFFBFE9F0,
                                                        ).withAlpha(100),
                                                  blurRadius: isDarkMode
                                                      ? 8
                                                      : 6,
                                                  spreadRadius: isDarkMode
                                                      ? 2
                                                      : 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: illustrationSize * 0.16,
                                          left: illustrationSize * 0.32,
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: isDarkMode
                                                  ? Color(
                                                      0xFF26C6DA,
                                                    ).withAlpha(220)
                                                  : Color(
                                                      0xFF95DBE5,
                                                    ).withAlpha(200),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isDarkMode
                                                      ? Color(
                                                          0xFF26C6DA,
                                                        ).withAlpha(100)
                                                      : Color(
                                                          0xFF95DBE5,
                                                        ).withAlpha(80),
                                                  blurRadius: isDarkMode
                                                      ? 8
                                                      : 6,
                                                  spreadRadius: isDarkMode
                                                      ? 2
                                                      : 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Third circle - Medium Yellow/Orange with enhanced glow
                          AnimatedBuilder(
                            animation: Listenable.merge([
                              _rotationController3,
                              _pulseController,
                            ]),
                            builder: (context, child) {
                              return Transform.translate(
                                offset: _position3.value,
                                child: Transform.rotate(
                                  angle: _rotation3.value * 2 * 3.14159,
                                  child: Transform.scale(
                                    scale: _scale3.value,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: illustrationSize * 0.6,
                                          height: illustrationSize * 0.6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: isDarkMode
                                                  ? [
                                                      Color(
                                                        0xFFFFE97D,
                                                      ).withAlpha(0),
                                                      Color(
                                                        0xFFFFE97D,
                                                      ).withAlpha(200),
                                                      Color(
                                                        0xFFFFDD60,
                                                      ).withAlpha(230),
                                                      Color(
                                                        0xFFFFDD60,
                                                      ).withAlpha(0),
                                                    ]
                                                  : [
                                                      Color(
                                                        0xFFFFEDB3,
                                                      ).withAlpha(0),
                                                      Color(
                                                        0xFFFFEDB3,
                                                      ).withAlpha(230),
                                                      Color(
                                                        0xFFFFDD80,
                                                      ).withAlpha(250),
                                                      Color(
                                                        0xFFFFDD80,
                                                      ).withAlpha(0),
                                                    ],
                                              stops: [0.0, 0.62, 0.95, 1.0],
                                            ),
                                            boxShadow: isDarkMode
                                                ? [
                                                    BoxShadow(
                                                      color: Color(
                                                        0xFFFFDD60,
                                                      ).withAlpha(190),
                                                      blurRadius: 18,
                                                      spreadRadius: 7,
                                                    ),
                                                    BoxShadow(
                                                      color: Color(
                                                        0xFFFFE97D,
                                                      ).withAlpha(135),
                                                      blurRadius: 32,
                                                      spreadRadius: 11,
                                                    ),
                                                  ]
                                                : [
                                                    BoxShadow(
                                                      color: Color(
                                                        0xFFFFDD80,
                                                      ).withAlpha(190),
                                                      blurRadius: 18,
                                                      spreadRadius: 7,
                                                    ),
                                                    BoxShadow(
                                                      color: Color(
                                                        0xFFFFEDB3,
                                                      ).withAlpha(125),
                                                      blurRadius: 35,
                                                      spreadRadius: 12,
                                                    ),
                                                  ],
                                          ),
                                        ),
                                        // Bubbles for rotation visibility - randomly positioned
                                        Positioned(
                                          right: illustrationSize * 0.18,
                                          top: illustrationSize * 0.15,
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: isDarkMode
                                                  ? Color(0xFFFFDD60)
                                                  : Color(0xFFFFDD80),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isDarkMode
                                                      ? Color(
                                                          0xFFFFDD60,
                                                        ).withAlpha(120)
                                                      : Color(
                                                          0xFFFFDD80,
                                                        ).withAlpha(100),
                                                  blurRadius: isDarkMode
                                                      ? 10
                                                      : 8,
                                                  spreadRadius: isDarkMode
                                                      ? 3
                                                      : 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: illustrationSize * 0.14,
                                          top: illustrationSize * 0.25,
                                          child: Container(
                                            width: 9,
                                            height: 9,
                                            decoration: BoxDecoration(
                                              color: isDarkMode
                                                  ? Color(0xFFFFE97D)
                                                  : Color(0xFFFFEDB3),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isDarkMode
                                                      ? Color(
                                                          0xFFFFE97D,
                                                        ).withAlpha(120)
                                                      : Color(
                                                          0xFFFFEDB3,
                                                        ).withAlpha(100),
                                                  blurRadius: isDarkMode
                                                      ? 8
                                                      : 6,
                                                  spreadRadius: isDarkMode
                                                      ? 2
                                                      : 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: illustrationSize * 0.12,
                                          right: illustrationSize * 0.28,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: isDarkMode
                                                  ? Color(
                                                      0xFFFFDD60,
                                                    ).withAlpha(220)
                                                  : Color(
                                                      0xFFFFDD80,
                                                    ).withAlpha(200),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isDarkMode
                                                      ? Color(
                                                          0xFFFFDD60,
                                                        ).withAlpha(100)
                                                      : Color(
                                                          0xFFFFDD80,
                                                        ).withAlpha(80),
                                                  blurRadius: isDarkMode
                                                      ? 8
                                                      : 6,
                                                  spreadRadius: isDarkMode
                                                      ? 2
                                                      : 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Fourth circle - Medium Pink/Rose with enhanced glow
                          AnimatedBuilder(
                            animation: Listenable.merge([
                              _rotationController4,
                              _pulseController,
                            ]),
                            builder: (context, child) {
                              return Transform.translate(
                                offset: _position4.value,
                                child: Transform.rotate(
                                  angle: _rotation4.value * 2 * 3.14159,
                                  child: Transform.scale(
                                    scale: _scale4.value,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: illustrationSize * 0.4,
                                          height: illustrationSize * 0.4,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: isDarkMode
                                                  ? [
                                                      Color(
                                                        0xFFF06292,
                                                      ).withAlpha(0),
                                                      Color(
                                                        0xFFF06292,
                                                      ).withAlpha(200),
                                                      Color(
                                                        0xFFEC407A,
                                                      ).withAlpha(230),
                                                      Color(
                                                        0xFFEC407A,
                                                      ).withAlpha(0),
                                                    ]
                                                  : [
                                                      Color(
                                                        0xFFF8CCE0,
                                                      ).withAlpha(0),
                                                      Color(
                                                        0xFFF8CCE0,
                                                      ).withAlpha(220),
                                                      Color(
                                                        0xFFF39BBD,
                                                      ).withAlpha(240),
                                                      Color(
                                                        0xFFF39BBD,
                                                      ).withAlpha(0),
                                                    ],
                                              stops: [0.0, 0.60, 0.94, 1.0],
                                            ),
                                            boxShadow: isDarkMode
                                                ? [
                                                    BoxShadow(
                                                      color: Color(
                                                        0xFFEC407A,
                                                      ).withAlpha(160),
                                                      blurRadius: 16,
                                                      spreadRadius: 4,
                                                    ),
                                                    BoxShadow(
                                                      color: Color(
                                                        0xFFF06292,
                                                      ).withAlpha(110),
                                                      blurRadius: 28,
                                                      spreadRadius: 8,
                                                    ),
                                                  ]
                                                : [
                                                    BoxShadow(
                                                      color: Color(
                                                        0xFFF39BBD,
                                                      ).withAlpha(180),
                                                      blurRadius: 20,
                                                      spreadRadius: 6,
                                                    ),
                                                    BoxShadow(
                                                      color: Color(
                                                        0xFFF8CCE0,
                                                      ).withAlpha(120),
                                                      blurRadius: 36,
                                                      spreadRadius: 12,
                                                    ),
                                                  ],
                                          ),
                                        ),
                                        // Bubbles for rotation visibility - randomly positioned
                                        Positioned(
                                          top: illustrationSize * 0.12,
                                          left: illustrationSize * 0.18,
                                          child: Container(
                                            width: 9,
                                            height: 9,
                                            decoration: BoxDecoration(
                                              color: isDarkMode
                                                  ? Color(0xFFEC407A)
                                                  : Color(0xFFF39BBD),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isDarkMode
                                                      ? Color(
                                                          0xFFEC407A,
                                                        ).withAlpha(120)
                                                      : Color(
                                                          0xFFF39BBD,
                                                        ).withAlpha(100),
                                                  blurRadius: isDarkMode
                                                      ? 10
                                                      : 8,
                                                  spreadRadius: isDarkMode
                                                      ? 3
                                                      : 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: illustrationSize * 0.18,
                                          left: illustrationSize * 0.25,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: isDarkMode
                                                  ? Color(0xFFF06292)
                                                  : Color(0xFFF8CCE0),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isDarkMode
                                                      ? Color(
                                                          0xFFF06292,
                                                        ).withAlpha(120)
                                                      : Color(
                                                          0xFFF8CCE0,
                                                        ).withAlpha(100),
                                                  blurRadius: isDarkMode
                                                      ? 8
                                                      : 6,
                                                  spreadRadius: isDarkMode
                                                      ? 2
                                                      : 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: illustrationSize * 0.16,
                                          top: illustrationSize * 0.28,
                                          child: Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: isDarkMode
                                                  ? Color(
                                                      0xFFEC407A,
                                                    ).withAlpha(220)
                                                  : Color(
                                                      0xFFF39BBD,
                                                    ).withAlpha(200),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: isDarkMode
                                                      ? Color(
                                                          0xFFEC407A,
                                                        ).withAlpha(100)
                                                      : Color(
                                                          0xFFF39BBD,
                                                        ).withAlpha(80),
                                                  blurRadius: isDarkMode
                                                      ? 8
                                                      : 6,
                                                  spreadRadius: isDarkMode
                                                      ? 2
                                                      : 2,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Center circle with very light blue glow background and gradient icon
                          AnimatedBuilder(
                            animation: Listenable.merge([
                              _centerPulseController,
                              _centerSeesawController,
                            ]),
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _centerSeesaw.value,
                                child: Transform.scale(
                                  scale: _centerScale.value,
                                  child: Container(
                                    width: illustrationSize * 0.275,
                                    height: illustrationSize * 0.275,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Color(0xFFFFFDF5),
                                          Color(0xFFFFF9EA),
                                          Color(0xFFFFF5E0),
                                          Color(0xFFE6F3FF),
                                          Color(0xFFD9EDFF),
                                        ],
                                        stops: [0.0, 0.2, 0.4, 0.7, 1.0],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(
                                            0xFF007AFF,
                                          ).withAlpha(180),
                                          blurRadius: 35,
                                          spreadRadius: 5,
                                        ),
                                        BoxShadow(
                                          color: Color(
                                            0xFF00D4FF,
                                          ).withAlpha(130),
                                          blurRadius: 50,
                                          spreadRadius: 10,
                                        ),
                                        BoxShadow(
                                          color: isDarkMode
                                              ? Colors.black.withAlpha(80)
                                              : CupertinoColors.systemGrey
                                                    .withAlpha(51),
                                          blurRadius: isDarkMode ? 30 : 40,
                                          spreadRadius: 0,
                                          offset: Offset(
                                            0,
                                            isDarkMode ? 10 : 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                    child: ShaderMask(
                                      shaderCallback: (bounds) =>
                                          LinearGradient(
                                            colors: [
                                              Color(0xFF007AFF),
                                              Color(0xFF5856D6),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ).createShader(bounds),
                                      child: Icon(
                                        CupertinoIcons.calendar,
                                        size: illustrationSize * 0.13,
                                        color: CupertinoColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.08),

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
                              color: isDarkMode
                                  ? Color(0xFF23C061)
                                  : Color(0xFF21AA62),
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            CupertinoIcons.chevron_right,
                            size: 14,
                            color: isDarkMode
                                ? Color(0xFF23C061)
                                : Color(0xFF21AA62),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom button - positioned at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDarkMode
                        ? [
                            CupertinoColors.black.withAlpha(0),
                            CupertinoColors.black.withAlpha(200),
                            CupertinoColors.black,
                          ]
                        : [
                            CupertinoColors.white.withAlpha(0),
                            CupertinoColors.white.withAlpha(200),
                            CupertinoColors.white,
                          ],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: CupertinoButton(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    borderRadius: BorderRadius.circular(16),
                    color: isDarkMode ? Color(0xFF23C061) : Color(0xFF21AA62),
                    onPressed: () {
                      context.push('/login');
                    },
                    child: Text(
                      'Get started',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode
                            ? Color(0xFF000000)
                            : Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
