import 'package:flutter/cupertino.dart';
import 'package:flutter_test_22/drawer.dart';
import 'package:flutter_test_22/tabs/home_tab.dart';
import 'package:flutter_test_22/tabs/agenda_tab.dart';
import 'package:flutter_test_22/tabs/speakers_tab.dart';
import 'package:flutter_test_22/tabs/attendees_tab.dart';
import 'package:flutter_test_22/tabs/exhibitors_tab.dart';
import 'package:flutter_test_22/pages/settings_page.dart';
import 'package:flutter_test_22/pages/notifications_page.dart';
import 'package:flutter_test_22/pages/profile_page.dart';
import 'package:flutter_test_22/pages/login_page.dart';
import 'package:flutter_test_22/pages/onboarding_page.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/bookmarks',
      builder: (context, state) => const BookmarksPageWithDrawer(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) =>
          const StandaloneDrawerWrapper(child: SettingsPage()),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) =>
          const StandaloneDrawerWrapper(child: NotificationsPage()),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) =>
          const StandaloneDrawerWrapper(child: ProfilePage()),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          HomeScreenWithDrawer(navigationShell: navigationShell),
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
              path: '/agenda',
              builder: (context, state) => const ScheduleTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/speakers',
              builder: (context, state) => const SpeakersTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/attendees',
              builder: (context, state) => const AttendeesTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/exhibitors',
              builder: (context, state) => const ExhibitorsTab(),
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
