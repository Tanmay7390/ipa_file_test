import 'package:flutter/cupertino.dart';
import '../components/tab_naviagtor.dart'; // Import for CustomCupertinoPageRoute

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabView(
      builder: (BuildContext context) {
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: const Text('Standard Navigation - Home'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.add),
              onPressed: () {},
            ),
          ),
          child: Center(
            child: CupertinoButton(
              child: const Text('Next page with custom transition'),
              onPressed: () {
                Navigator.of(context).push(
                  // Use our custom route with CupertinoPageTransition
                  CustomCupertinoPageRoute<void>(
                    builder: (BuildContext context) {
                      return CupertinoPageScaffold(
                        navigationBar: CupertinoNavigationBar(
                          middle: const Text('Page 2 of Home tab'),
                        ),
                        child: Center(
                          child: CupertinoButton(
                            child: const Text('Back'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
