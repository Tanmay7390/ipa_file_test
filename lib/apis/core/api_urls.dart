// lib/core/constants/api_urls.dart
class ApiUrls {
  // Base URL
  // static const String baseUrl = 'http://localhost:5002/api/';
  static const String baseUrl = 'https://purvishinfotech.com/event-api/api/';
  // static const String socketUrl = 'http://139.59.20.227:5002';

  // Auth endpoints
  static const String login = 'auth/login';
  static const String logout = 'auth/logout';
  static const String refreshToken = 'auth/refresh';
  static const String homePage = 'auth/homePage';

  // Common endpoints
  static const String getExhibitors = 'common/getExhibitors';
  static const String getExhibitorById = 'common/getExhibitorById/{id}';

  // Helper method to replace path parameters
  static String replaceParams(String url, Map<String, String> params) {
    String result = url;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
}
