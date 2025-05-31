import 'package:flutter/cupertino.dart';
import 'package:flutter_test_22/drawer.dart';
// import 'package:flutter_test_22/forms/employee_form.dart';
import 'package:flutter_test_22/tabs/employee_tab.dart';
import 'package:flutter_test_22/tabs/home_tab.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/global-home',
      builder: (context, state) => const GlobalHomePage(),
    ),
    GoRoute(
      path: '/bookmarks',
      builder: (context, state) => const BookmarksPageWithDrawer(),
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
              path: '/employee',
              builder: (context, state) => const EmployeeTab(),
              routes: [
                // GoRoute(
                //   path: 'add',
                //   parentNavigatorKey: _rootNavigatorKey,
                //   builder: (context, state) => EmployeeAddPage(),
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
