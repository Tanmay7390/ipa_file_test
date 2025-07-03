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

  // Inventory endpoints
  static const String inventoryList = 'sku/account/{accountId}';

  // Customer endpoints
  static const String customerList = 'customers/{accountId}/search';
  static const String createCustomer = 'customer/create';
  static const String updateCustomer = 'customer/{id}';
  static const String deleteCustomer = 'customer/{id}';
  static const String getCustomer = 'customer/{id}';

  // Customer Address endpoints
  static const String createCustomerAddress = 'customer/{customerId}/address';
  static const String updateCustomerAddress =
      'customer/{customerId}/address/{addressId}';
  static const String deleteCustomerAddress =
      'customer/{customerId}/address/{addressId}';
  static const String getCountries = 'countries';
  static const String getStates = 'states';

  // Auth endpoints
  static const String login = 'auth/login';
  static const String logout = 'auth/logout';
  static const String refreshToken = 'auth/refresh';

  // Other endpoints (add as needed)
  static const String departments = 'departments';
  static const String roles = 'roles';

  // Invoice endpoints
  static const String invoiceTemplates = 'invoice/templates';
  static const String bankAccounts = 'account/bankaccounts/{accountId}';
  static const String invoiceSeqNumber = 'invoice/seq-number';

  // Helper method to replace path parameters
  static String replaceParams(String url, Map<String, String> params) {
    String result = url;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
}
