// lib/core/constants/api_urls.dart
class ApiUrls {
  // Base URL
  // static const String baseUrl = 'http://localhost:5002/api/';
  // static const String baseUrl = 'https://purvishinfotech.com/event-api/api/';
  static const String baseUrl = 'https://api.diseaseportal.com/api/';
  // static const String socketUrl = 'http://139.59.20.227:5002';

  // Auth endpoints
  static const String login = 'account/login/';
  static const String logout = 'auth/logout';
  static const String refreshToken = 'auth/refresh';
  static const String homePage = 'auth/homePage';

  // OAuth endpoints
  static const String googleAuth = 'auth/google/';
  static const String microsoftAuth = 'auth/microsoft/';

  // Common endpoints
  static const String getExhibitors = 'common/getExhibitors';
  static const String getExhibitorById = 'common/getExhibitorById/{id}';

  // People endpoints
  static const String getPeople = 'people';
  static const String getPersonById = 'people/{people_id}';

  // Company endpoints
  static const String getCompanies = 'companies';
  static const String getCompanyById = 'companies/{company_id}';

  // Trials endpoints
  static const String getTrials = 'trials/category/all';
  static const String getTrialByNct = 'trials/nct/{nct_number}';
  static const String getTherapeuticAreas = 'trials/therapeutic-areas';

  // VC Funds endpoints
  static const String getVcFunds = 'venture_capital';
  static const String getVcFundById = 'venture_capital/{venture_capital_id}';
  static const String getVcDeals = 'venture_capitals/deals';

  // Helper method to replace path parameters
  static String replaceParams(String url, Map<String, String> params) {
    String result = url;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }
}
