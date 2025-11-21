import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aesurg26/theme_provider.dart';
import 'package:aesurg26/drawer.dart';
import 'package:aesurg26/components/page_scaffold.dart';
import 'package:go_router/go_router.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomPageScaffold(
      heading: 'AESURG 2026',
      hideLargeTitle: false,
      hideSearch: true,
      isLoading: false,
      leading: _buildLeading(context, ref),
      trailing: _buildTrailing(context, ref),
      sliverList: SliverList(
        delegate: SliverChildListDelegate([
          // Logos Section
          _buildLogosSection(context, ref),

          // Hero Section
          _buildHeroSection(context, ref),

          // Quick Actions
          const SizedBox(height: 25),
          _buildQuickActions(context, ref),

          // Featured Content
          const SizedBox(height: 25),
          _buildFeaturedSessions(context, ref),

          // Stats Card
          const SizedBox(height: 25),
          _buildStatsCard(context, ref),

          // CTA Section
          const SizedBox(height: 25),
          _buildCTASection(context, ref),

          // Bottom Spacing
          const SizedBox(height: 25),
        ]),
      ),
    );
  }

  Widget _buildLeading(BuildContext context, WidgetRef ref) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));
    final iconColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.8);

    void toggleDrawer() {
      context.visitAncestorElements((element) {
        if (element.widget is HomeScreenWithDrawer ||
            element.widget is StandaloneDrawerWrapper) {
          final state = element as StatefulElement;
          (state.state as dynamic).toggleDrawer();
          return false;
        }
        return true;
      });
    }

    return Transform(
      transform: Matrix4.translationValues(-10, 0, 0),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: toggleDrawer,
        child: Icon(CupertinoIcons.sidebar_left, color: iconColor, size: 24),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context, WidgetRef ref) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));
    final iconColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.8);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 0),
          onPressed: () => context.go('/notifications'),
          child: Icon(CupertinoIcons.bell, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 0),
          onPressed: () => context.go('/profile'),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                width: 1.5,
              ),
              image: const DecorationImage(
                image: NetworkImage('https://i.imgur.com/QCNbOAo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogosSection(BuildContext context, WidgetRef ref) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));
    final textColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.85);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          // Single Logo (AESURG)
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset('assets/images/image2.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),
          // IAAPS Text
          Text(
            'Annual Conference of',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Indian Association of Aesthetic Plastic Surgeons',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, WidgetRef ref) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));
    final cardTextPrimary = isDarkMode
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.9);
    final cardTextSecondary = isDarkMode
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Title
          Text(
            'INITIATE. INNOVATE. INSPIRE.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: 'SF Pro Display',
              color: isDarkMode
                  ? const Color(0xFF60A5FA)
                  : const Color(0xFF2563EB),
              height: 1.1,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 20),
          // Event Info Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                        : const Color(0xFFDEEBFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
                          : const Color(0xFF3B82F6).withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          CupertinoIcons.calendar,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '22-26',
                        style: TextStyle(
                          color: cardTextPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SF Pro Display',
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        'January 2026',
                        style: TextStyle(
                          color: cardTextSecondary,
                          fontSize: 11,
                          fontFamily: 'SF Pro Display',
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF7C2D12).withValues(alpha: 0.3)
                        : const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode
                          ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                          : const Color(0xFFEF4444).withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          CupertinoIcons.location_solid,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Mumbai',
                        style: TextStyle(
                          color: cardTextPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SF Pro Display',
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        'Westin Hotel',
                        style: TextStyle(
                          color: cardTextSecondary,
                          fontSize: 11,
                          fontFamily: 'SF Pro Display',
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));
    final textColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Access',
            style: TextStyle(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.black.withValues(alpha: 0.9),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go('/more'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDarkMode
                            ? [
                                const Color(0xFF059669).withValues(alpha: 0.4),
                                const Color(0xFF047857).withValues(alpha: 0.3),
                              ]
                            : [
                                const Color(0xFF6EE7B7),
                                const Color(0xFF34D399),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.map_pin_ellipse,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Venue',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SF Pro Display',
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go('/more'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDarkMode
                            ? [
                                const Color(0xFFEA580C).withValues(alpha: 0.4),
                                const Color(0xFFC2410C).withValues(alpha: 0.3),
                              ]
                            : [
                                const Color(0xFFFDBA74),
                                const Color(0xFFFB923C),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFF97316).withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFF97316,
                          ).withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFF97316,
                                ).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.map,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Floor Map',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SF Pro Display',
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSessions(BuildContext context, WidgetRef ref) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));
    final textColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Sessions',
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.2,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/agenda'),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: isDarkMode
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF3B82F6),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSessionCard(
            context,
            ref,
            'Rhinoplasty Masterclass',
            'Dr. Sarah Johnson',
            'Thu, 10:30 AM',
            CupertinoIcons.scissors,
            [0xFF6366F1, 0xFF8B5CF6],
          ),
          const SizedBox(height: 12),
          _buildSessionCard(
            context,
            ref,
            'Body Contouring Techniques',
            'Dr. Michael Chen',
            'Thu, 02:00 PM',
            CupertinoIcons.sparkles,
            [0xFFEC4899, 0xFFF43F5E],
          ),
          const SizedBox(height: 12),
          _buildSessionCard(
            context,
            ref,
            'Facial Aesthetics Workshop',
            'Dr. Emily Davis',
            'Fri, 09:00 AM',
            CupertinoIcons.heart_fill,
            [0xFF10B981, 0xFF059669],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    WidgetRef ref,
    String title,
    String speaker,
    String time,
    IconData icon,
    List<int> gradientColors,
  ) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));
    final cardBg = isDarkMode
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white;
    final cardBorder = isDarkMode
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);
    final textPrimary = isDarkMode
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.9);
    final textSecondary = isDarkMode
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
                  : const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: const Color(0xFF7C3AED), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  speaker,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(CupertinoIcons.clock, color: textSecondary, size: 16),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, WidgetRef ref) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [const Color(0xFF1E3A8A), const Color(0xFF7C3AED)]
              : [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('500+', 'Attendees', CupertinoIcons.person_2),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildStatItem('50+', 'Speakers', CupertinoIcons.mic),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildStatItem('30+', 'Sessions', CupertinoIcons.square_list),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String number, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          number,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'SF Pro Display',
            letterSpacing: 0.2,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            fontFamily: 'SF Pro Display',
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCTASection(BuildContext context, WidgetRef ref) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = ref.watch(isDarkModeProvider(systemBrightness));
    final cardBg = isDarkMode
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white;
    final cardBorder = isDarkMode
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);
    final iconColor = isDarkMode
        ? Colors.white
        : Colors.black.withValues(alpha: 0.7);
    final textPrimary = isDarkMode
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.9);
    final textSecondary = isDarkMode
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.6);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Icon(CupertinoIcons.qrcode, color: iconColor, size: 64),
          const SizedBox(height: 20),
          Text(
            'Ready to Check In?',
            style: TextStyle(
              color: textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Scan your QR code at the venue entrance',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
              fontFamily: 'SF Pro Display',
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'Show My QR Code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
