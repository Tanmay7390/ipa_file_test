import 'package:flutter/cupertino.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Settings'),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.settings,
                size: 64,
                color: CupertinoColors.systemGrey,
              ),
              SizedBox(height: 20),
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Configure your app preferences',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
