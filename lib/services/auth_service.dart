import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Helper function to parse JSON in isolate (for large data)
Map<String, dynamic> _parseJson(String jsonString) {
  return jsonDecode(jsonString) as Map<String, dynamic>;
}

class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyEmail = 'user_email';
  static const String _keyLoginTime = 'login_time';
  static const String _keyToken = 'auth_token';
  static const String _keyHomePage = 'home_page_data';
  static const String _keyUserData = 'user_data';

  // Save login info with token and additional data
  static Future<void> saveLoginInfo({
    required String email,
    required String token,
    Map<String, dynamic>? homePage,
    Map<String, dynamic>? userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyLoginTime, DateTime.now().toIso8601String());

    // Store home page data if available
    if (homePage != null) {
      await prefs.setString(_keyHomePage, jsonEncode(homePage));
    }

    // Store user data if available
    if (userData != null) {
      await prefs.setString(_keyUserData, jsonEncode(userData));
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Get email
  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  // Get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  // Get login time
  static Future<String?> getLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLoginTime);
  }

  // Get home page data (optimized with compute for large JSON)
  static Future<Map<String, dynamic>?> getHomePage() async {
    final prefs = await SharedPreferences.getInstance();
    final homePageString = prefs.getString(_keyHomePage);
    if (homePageString != null) {
      // Parse JSON in background isolate to prevent UI blocking
      return await compute(_parseJson, homePageString);
    }
    return null;
  }

  // Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_keyUserData);
    if (userDataString != null) {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  // Update token
  static Future<void> updateToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  // Save home page data only
  static Future<void> saveHomePageData(
    Map<String, dynamic> homePageData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHomePage, jsonEncode(homePageData));
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
