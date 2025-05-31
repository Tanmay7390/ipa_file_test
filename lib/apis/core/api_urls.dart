// lib/core/constants/api_urls.dart
class ApiUrls {
  // Base URL
  static const String baseUrl = 'https://www.wareozo.com/app-api/api/v1/';

  // Employee endpoints
  static const String employeeList = 'employee/account/{accountId}/emp-list';
  static const String createEmployee = 'employee/create';
  static const String updateEmployee = 'employee/{id}';
  static const String deleteEmployee = 'employee/{id}';
  static const String getEmployee = 'employee/{id}';

  // Auth endpoints
  static const String login = 'auth/login';
  static const String logout = 'auth/logout';
  static const String refreshToken = 'auth/refresh';

  // Other endpoints (add as needed)
  static const String departments = 'departments';
  static const String roles = 'roles';

  // Helper method to replace path parameters
  static String replaceParams(String url, Map<String, String> params) {
    String result = url;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
}
