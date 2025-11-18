import 'package:flutter/cupertino.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Notifications'),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.bell,
                size: 64,
                color: CupertinoColors.systemYellow,
              ),
              SizedBox(height: 20),
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Stay updated with latest alerts',
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
