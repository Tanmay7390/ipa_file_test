import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyEventCode = 'event_code';
  static const String _keyLoginTime = 'login_time';

  // Save login info
  static Future<void> saveLoginInfo(String eventCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyEventCode, eventCode);
    await prefs.setString(_keyLoginTime, DateTime.now().toIso8601String());
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Get event code
  static Future<String?> getEventCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEventCode);
  }

  // Get login time
  static Future<String?> getLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLoginTime);
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
