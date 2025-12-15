// OAuth Configuration
// This file contains OAuth configuration settings for Google and Microsoft authentication

class OAuthConfig {
  // Enable/disable OAuth providers
  static const bool enableGoogleSignIn = true;
  static const bool enableMicrosoftSignIn = true;

  // Google OAuth Configuration
  // Replace with your actual Google OAuth client ID from Firebase Console
  static const String googleClientId =
      'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com';

  // Microsoft OAuth Configuration
  // Replace with your actual Microsoft Azure AD application details
  static const String microsoftClientId = 'YOUR_AZURE_APP_CLIENT_ID';
  static const String microsoftTenantId = 'YOUR_AZURE_TENANT_ID';
  static const String microsoftRedirectUri =
      'msauth://com.yourcompany.axlmed/callback';

  // OAuth Scopes
  static const List<String> googleScopes = ['email', 'profile'];
  static const List<String> microsoftScopes = [
    'user.read',
    'openid',
    'profile',
    'email',
  ];

  // Web-based OAuth URLs (fallback when native OAuth is not configured)
  static const String googleOAuthWebUrl =
      'https://accounts.google.com/o/oauth2/v2/auth';
  static const String microsoftOAuthWebUrl =
      'https://login.microsoftonline.com/common/oauth2/v2.0/authorize';

  // Use web-based OAuth as fallback
  static const bool useWebOAuthFallback = true;

  // Development mode - bypass OAuth and use test tokens
  // Set to true until Google/Microsoft OAuth is properly configured
  static const bool isDevelopmentMode = true;
  static const String developmentGoogleToken = 'test_google_token';
  static const String developmentMicrosoftToken = 'test_microsoft_token';
}
