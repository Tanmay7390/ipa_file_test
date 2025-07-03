// lib/core/constants/api_urls.dart
class ApiUrls {
  // Base URL
  static const String baseUrl = 'https://www.wareozo.com/app-api/api/v1/';

  // My Business Profile endpoints
  static const String myBusinessProfile = 'account/{accountId}';
  static const String updateCompanyProfile = 'account/{accountId}';
  static const String updateLegal = 'account/{accountId}/legal';
  static const String updatePayment = 'account/{accountId}/accounting';

  // Bank endpoints
  static const String bankList = 'account/bankaccounts/{accountId}';
  static const String getBankById = 'account/bankaccount/{id}';
  static const String createBank = 'account/bankaccount';
  static const String updateBank = 'account/bankaccount/{id}';
  static const String deleteBank = 'account/bankaccounts/{id}';

  // Address endpoints
  static const String addressList = 'address/{accountId}';
  static const String getAddressById = 'address/address/{id}';
  static const String createAddress = 'address';
  static const String updateAddress = 'address/{id}';
  static const String deleteAddress = 'address/{id}';

  // DocumentSettings endpoints
  static const String documentSettingsList = 'document-settings/{accountId}';
  static const String getDocumentSettingsById = 'document-settings/single/{id}';
  static const String createDocumentSettings = 'document-settings';
  static const String updateDocumentSettings = 'document-settings/{id}';
  static const String deleteDocumentSettings = 'document-settings/{id}';

  // Invoice endpoints
  static const String invoiceList = 'invoice/account/{accountId}';
  static const String invoiceTemplates = 'invoice/templates';
  static const String bankAccounts = 'account/bankaccounts/{accountId}';
  static const String invoiceSeqNumber = 'invoice/seq-number';

  // Employee endpoints
  static const String employeeList = 'employee/account/{accountId}/emp-list';
  static const String getEmployee = 'employee/{id}';
  static const String createEmployee = 'employee';
  static const String updateEmployee = 'employee/{id}';
  static const String deleteEmployee = 'employee/{id}/deleteEmpAttachment';

  // Customer endpoints
  static const String customerList = 'customers/{accountId}';
  static const String customerSearch = 'customers/{accountId}/search';
  static const String getCustomer = 'customers/single/{id}';
  static const String createCustomer = 'account/buyer-seller';
  static const String updateCustomer = 'customers/one/{customerId}';

  static const String deleteCustomer = 'customer/{id}';

  // Customer Address endpoints
  static const String createCustomerAddress = 'customer/{customerId}/address';
  static const String updateCustomerAddress =
      'customer/{customerId}/address/{addressId}';
  static const String deleteCustomerAddress =
      'customer/{customerId}/address/{addressId}';
  static const String getCountries = 'countries';
  static const String getStates = 'states';

  // Supplier endpoints
  static const String supplierList = 'suppliers/{accountId}';
  static const String getSupplier = 'customers/single/{id}';

  // Inventory endpoints
  static const String inventoryList = 'sku/account/{accountId}';
  static const String createInventory = 'sku';
  static const String getInventorybyId = 'sku/{id}';
  static const String updateInventory = 'sku/{id}';
  static const String measuringUnit = 'sku/measuring-unit/get';
  static const String filterInventory = 'sku/account/{accountId}?{queryParam}';

  // Auth endpoints
  static const String register = 'register';
  static const String login = 'login';
  static const String sendOTP = 'user/otp';
  static const String refreshToken = 'auth/refresh';

  // Gst endpoints
  static const String gstList = 'gst';
  static const String getTaxRates = 'gst/tax-rates';

  // Countries & States & currency endpoints
  static const String countries = 'countries';
  static const String states = 'states';
  static const String currencies = 'curriences';

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
