import 'package:flutter/cupertino.dart';
import 'package:axlmed/drawer.dart';
import 'package:axlmed/tabs/home_tab.dart';
import 'package:axlmed/tabs/company_tab.dart';
import 'package:axlmed/tabs/speakers_tab.dart';
import 'package:axlmed/tabs/people_tab_improved.dart';
import 'package:axlmed/tabs/exhibitors_tab.dart';
import 'package:axlmed/tabs/trials_tab.dart';
import 'package:axlmed/tabs/funds_tab.dart';
import 'package:axlmed/pages/settings_page.dart';
import 'package:axlmed/pages/notifications_page.dart';
import 'package:axlmed/pages/profile_page.dart';
import 'package:axlmed/pages/privacy_policy_page.dart';
import 'package:axlmed/pages/login_page.dart';
import 'package:axlmed/services/auth_service.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login', // Changed from '/onboarding'
  redirect: (context, state) async {
    final isLoggedIn = await AuthService.isLoggedIn();
    final isLogin = state.matchedLocation == '/login';

    // If logged in and trying to access login, redirect to home
    if (isLoggedIn && isLogin) {
      return '/home';
    }

    // If not logged in and trying to access protected routes, redirect to login
    if (!isLoggedIn && !isLogin) {
      return '/login';
    }

    return null; // No redirect needed
  },
  routes: [
    // Commented out onboarding page - login is now the first screen
    // GoRoute(
    //   path: '/onboarding',
    //   pageBuilder: (context, state) => CustomTransitionPage(
    //     key: state.pageKey,
    //     child: const OnboardingPage(),
    //     transitionsBuilder: (context, animation, secondaryAnimation, child) {
    //       // Slide from left to right (reverse direction)
    //       return SlideTransition(
    //         position:
    //             Tween<Offset>(
    //               begin: const Offset(-1.0, 0.0), // Start from left
    //               end: Offset.zero, // End at center
    //             ).animate(
    //               CurvedAnimation(parent: animation, curve: Curves.easeInOut),
    //             ),
    //         child: child,
    //       );
    //     },
    //   ),
    // ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) =>
          CupertinoPage(key: state.pageKey, child: const LoginPage()),
    ),
    GoRoute(
      path: '/bookmarks',
      builder: (context, state) => const BookmarksPageWithDrawer(),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const StandaloneDrawerWrapper(child: SettingsPage()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide from right to left when entering
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0), // Start from right
                  end: Offset.zero, // End at center
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const StandaloneDrawerWrapper(child: NotificationsPage()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide from right to left when entering
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0), // Start from right
                  end: Offset.zero, // End at center
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const StandaloneDrawerWrapper(child: ProfilePage()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide from right to left when entering
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0), // Start from right
                  end: Offset.zero, // End at center
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/privacy-policy',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const StandaloneDrawerWrapper(child: PrivacyPolicyPage()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide from right to left when entering
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0), // Start from right
                  end: Offset.zero, // End at center
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
            child: child,
          );
        },
      ),
    ),
    StatefulShellRoute.indexedStack(
      pageBuilder: (context, state, navigationShell) {
        // Check navigation source
        final isComingFromDetail =
            state.extra is Map && (state.extra as Map)['fromDetail'] == true;
        final isComingFromLogin =
            state.extra is Map && (state.extra as Map)['fromLogin'] == true;

        return CustomTransitionPage(
          key: state.pageKey,
          child: HomeScreenWithDrawer(navigationShell: navigationShell),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // If coming from detail page, slide from left (reverse animation)
            if (isComingFromDetail) {
              return SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(-1.0, 0.0), // Start from left
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: child,
              );
            }

            // If coming from login, slide from right (forward animation)
            if (isComingFromLogin) {
              return SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(1.0, 0.0), // Start from right
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: child,
              );
            }

            // No animation for tab switching
            return child;
          },
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeTab(),
              routes: [
                GoRoute(
                  path: 'details',
                  builder: (context, state) => const HomeDetailsPage(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/company',
              builder: (context, state) => const CompanyTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/funds',
              builder: (context, state) => const FundsTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/people',
              builder: (context, state) => const PeopleTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/trials',
              builder: (context, state) => const TrialsTab(),
              routes: [
                // GoRoute(
                //   path: 'add',
                //   parentNavigatorKey: _rootNavigatorKey,
                //   builder: (context, state) => InvoiceFormSheet(),
                // ),
                GoRoute(
                  path: 'profile/:id',
                  builder: (context, state) => EmployeeProfilePage(
                    employeeId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

class BookmarksPageWithDrawer extends StatelessWidget {
  const BookmarksPageWithDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return StandaloneDrawerWrapper(
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showAlert(context),
            child: Icon(CupertinoIcons.alarm),
          ),
          middle: Text('Bookmarks'),
        ),
        child: SafeArea(
          child: _buildCenter(
            'Bookmarks',
            CupertinoIcons.bookmark_fill,
            CupertinoColors.systemOrange,
            context,
          ),
        ),
      ),
    );
  }
}

void _showAlert(BuildContext context) {
  showCupertinoDialog<void>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text('Alert'),
      content: Text('Proceed with destructive action?'),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: Text('No'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: Text('Yes'),
        ),
      ],
    ),
  );
}

class GlobalHomePage extends StatelessWidget {
  const GlobalHomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return StandaloneDrawerWrapper(
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showAlert(context),
            child: Icon(CupertinoIcons.alarm),
          ),
          middle: Text('Bookmarks'),
        ),
        child: SafeArea(
          child: _buildCenter(
            'Global Home',
            CupertinoIcons.globe,
            CupertinoColors.systemBlue,
            context,
          ),
        ),
      ),
    );
  }
}

Widget _buildCenter(
  String title,
  IconData icon,
  Color color,
  BuildContext context,
) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: color),
        SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 10),
        Text(
          title == 'Bookmarks'
              ? 'Your saved posts and content'
              : 'Global page without tabs',
          style: TextStyle(fontSize: 16, color: CupertinoColors.secondaryLabel),
        ),
        SizedBox(height: 30),
        Text(
          '← Swipe right to open drawer',
          style: TextStyle(fontSize: 14, color: CupertinoColors.systemBlue),
        ),
        SizedBox(height: 20),
        CupertinoButton(
          onPressed: () => context.go('/home'),
          child: Text('Go to Home'),
        ),
      ],
    ),
  );
}

// Sub-route pages
class HomeDetailsPage extends StatelessWidget {
  const HomeDetailsPage({super.key});
  @override
  Widget build(BuildContext context) => _buildSubPage('Home Details', context);
}

class EmployeeProfilePage extends StatelessWidget {
  final String employeeId;
  const EmployeeProfilePage({super.key, required this.employeeId});
  @override
  Widget build(BuildContext context) => _buildSubPage(
    'Employee Profile',
    context,
    subtitle: 'Employee Profile: $employeeId',
  );
}

Widget _buildSubPage(String title, BuildContext context, {String? subtitle}) {
  return CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(middle: Text(title)),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(subtitle ?? '$title Page'),
          Text(
            '(Drawer swipe disabled on sub-routes)',
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          SizedBox(height: 20),
          CupertinoButton(
            onPressed: () => context.pop(),
            child: Text('Go Back'),
          ),
        ],
      ),
    ),
  );
}
