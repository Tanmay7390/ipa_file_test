import 'package:flutter/cupertino.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Profile'),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.person_circle,
                size: 64,
                color: CupertinoColors.systemIndigo,
              ),
              SizedBox(height: 20),
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Manage your account information',
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
