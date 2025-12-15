// lib/apis/providers/auth_provider.dart
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_urls.dart';
import '../core/dio_provider.dart'; // AuthHelper with async methods
import '../core/api_response.dart';

// Login request model
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

// Login response model
class LoginResponse {
  final String token;
  final Map<String, dynamic>? homePage;
  final Map<String, dynamic>? user;
  final String? message;
  final String? detail;

  LoginResponse({required this.token, this.homePage, this.user, this.message, this.detail});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Handle API response structure
    return LoginResponse(
      token: json['token'] ?? '',
      homePage: json['home_page'] as Map<String, dynamic>?,
      user: json['user'] as Map<String, dynamic>?,
      message: json['message'] as String?,
      detail: json['detail'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'home_page': homePage,
    'user': user,
    'message': message,
  };
}

// Auth repository
class AuthRepository {
  final Dio dio;

  AuthRepository(this.dio);

  // Login
  Future<ApiResponse<LoginResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      log('🔐 Login Request - Email/Login: $email');

      final response = await dio.post(
        ApiUrls.login,
        data: {'login': email, 'password': password},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      log('✅ Login Response Status: ${response.statusCode}');
      log('📦 Login Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          final loginResponse = LoginResponse.fromJson(responseData);

          // Safely log token (truncate if long enough)
          final tokenPreview = loginResponse.token.length > 20
              ? '${loginResponse.token.substring(0, 20)}...'
              : loginResponse.token;
          log('🎉 Login successful - Token: $tokenPreview');
          log('👤 User Data: ${loginResponse.user}');
          log('🏠 Home Page Data: ${loginResponse.homePage}');

          return ApiResponse.success(
            loginResponse,
            loginResponse.detail ?? loginResponse.message ?? 'Login successful',
          );
        } else {
          log('❌ Invalid response format');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Login failed with status: ${response.statusCode}');
        return ApiResponse.error('Login failed');
      }
    } on DioException catch (e) {
      log('❌ DioException during login: ${e.message}');
      log('❌ Response: ${e.response?.data}');
      log('❌ Status Code: ${e.response?.statusCode}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('❌ Unexpected error during login: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Google OAuth login
  Future<ApiResponse<LoginResponse>> googleLogin({required String idToken}) async {
    try {
      log('🔐 Google OAuth Login Request with token');

      final response = await dio.post(
        ApiUrls.googleAuth,
        data: {'token': idToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      log('✅ Google OAuth Response Status: ${response.statusCode}');
      log('📦 Google OAuth Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          final loginResponse = LoginResponse.fromJson(responseData);

          // Safely log token (truncate if long enough)
          final tokenPreview = loginResponse.token.length > 20
              ? '${loginResponse.token.substring(0, 20)}...'
              : loginResponse.token;
          log('🎉 Google login successful - Token: $tokenPreview');
          log('👤 User Data: ${loginResponse.user}');

          return ApiResponse.success(
            loginResponse,
            loginResponse.detail ?? loginResponse.message ?? 'Google login successful',
          );
        } else {
          log('❌ Invalid response format');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Google login failed with status: ${response.statusCode}');
        return ApiResponse.error('Google login failed');
      }
    } on DioException catch (e) {
      log('❌ DioException during Google login: ${e.message}');
      log('❌ Response: ${e.response?.data}');
      log('❌ Status Code: ${e.response?.statusCode}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('❌ Unexpected error during Google login: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Microsoft OAuth login
  Future<ApiResponse<LoginResponse>> microsoftLogin({required String accessToken}) async {
    try {
      log('🔐 Microsoft OAuth Login Request with token');

      final response = await dio.post(
        ApiUrls.microsoftAuth,
        data: {'token': accessToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      log('✅ Microsoft OAuth Response Status: ${response.statusCode}');
      log('📦 Microsoft OAuth Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          final loginResponse = LoginResponse.fromJson(responseData);

          // Safely log token (truncate if long enough)
          final tokenPreview = loginResponse.token.length > 20
              ? '${loginResponse.token.substring(0, 20)}...'
              : loginResponse.token;
          log('🎉 Microsoft login successful - Token: $tokenPreview');
          log('👤 User Data: ${loginResponse.user}');

          return ApiResponse.success(
            loginResponse,
            loginResponse.detail ?? loginResponse.message ?? 'Microsoft login successful',
          );
        } else {
          log('❌ Invalid response format');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Microsoft login failed with status: ${response.statusCode}');
        return ApiResponse.error('Microsoft login failed');
      }
    } on DioException catch (e) {
      log('❌ DioException during Microsoft login: ${e.message}');
      log('❌ Response: ${e.response?.data}');
      log('❌ Status Code: ${e.response?.statusCode}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('❌ Unexpected error during Microsoft login: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Logout
  Future<ApiResponse<bool>> logout() async {
    try {
      log('🚪 Logout Request');

      final response = await dio.post(ApiUrls.logout);

      log('✅ Logout Response Status: ${response.statusCode}');
      log('📦 Logout Response Data: ${response.data}');

      if (response.statusCode == 200) {
        log('🎉 Logout successful');
        return ApiResponse.success(
          true,
          response.data is Map
              ? (response.data?['message'] ?? 'Logout successful')
              : 'Logout successful',
        );
      } else {
        log('❌ Logout failed with status: ${response.statusCode}');
        return ApiResponse.error('Logout failed');
      }
    } on DioException catch (e) {
      log('❌ DioException during logout: ${e.message}');
      log('❌ Response: ${e.response?.data}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('❌ Unexpected error during logout: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Refresh token
  Future<ApiResponse<String>> refreshToken() async {
    try {
      log('🔄 Refresh Token Request');

      final response = await dio.post(ApiUrls.refreshToken);

      log('✅ Refresh Token Response Status: ${response.statusCode}');
      log('📦 Refresh Token Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        String? newToken;

        if (responseData is Map<String, dynamic>) {
          newToken = responseData['token'] ?? responseData['access_token'];
        }

        if (newToken != null) {
          // Safely log token (truncate if long enough)
          final tokenPreview = newToken.length > 20
              ? '${newToken.substring(0, 20)}...'
              : newToken;
          log('🎉 Token refreshed - New Token: $tokenPreview');
          return ApiResponse.success(
            newToken,
            responseData is Map
                ? (responseData['message'] ?? 'Token refreshed')
                : 'Token refreshed',
          );
        } else {
          log('❌ No token found in response');
          return ApiResponse.error('No token in response');
        }
      } else {
        log('❌ Token refresh failed with status: ${response.statusCode}');
        return ApiResponse.error('Token refresh failed');
      }
    } on DioException catch (e) {
      log('❌ DioException during token refresh: ${e.message}');
      log('❌ Response: ${e.response?.data}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('❌ Unexpected error during token refresh: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Fetch home page data
  Future<ApiResponse<Map<String, dynamic>>> fetchHomePage({
    required String eventId,
  }) async {
    try {
      log('🏠 Fetch Home Page Request - EventId: $eventId');

      final response = await dio.post(
        ApiUrls.homePage,
        data: {'eventId': eventId},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      log('✅ Home Page Response Status: ${response.statusCode}');
      log('📦 Home Page Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          final data = responseData['data'] as Map<String, dynamic>?;

          if (data != null) {
            log('🎉 Home Page data fetched successfully');
            return ApiResponse.success(
              data,
              responseData['message'] ?? 'Home page data fetched',
            );
          } else {
            log('❌ No data found in response');
            return ApiResponse.error('No data found');
          }
        } else {
          log('❌ Invalid response format');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Home Page fetch failed with status: ${response.statusCode}');
        return ApiResponse.error('Failed to fetch home page data');
      }
    } on DioException catch (e) {
      log('❌ DioException during home page fetch: ${e.message}');
      log('❌ Response: ${e.response?.data}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('❌ Unexpected error during home page fetch: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Helper method to handle Dio errors
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Server response timeout. Please try again.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message =
            e.response?.data?['message'] ?? e.response?.data?['error'];

        switch (statusCode) {
          case 400:
            return message ?? 'Bad request. Please check your input.';
          case 401:
            return message ?? 'Invalid email or password.';
          case 403:
            return 'Access denied.';
          case 404:
            return 'Service not found.';
          case 422:
            return message ?? 'Validation error. Please check your input.';
          case 500:
            return 'Server error. Please try again later.';
          default:
            return message ?? 'An error occurred. Please try again.';
        }
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.unknown:
        return 'Network error. Please check your internet connection.';
      default:
        return 'An unexpected error occurred.';
    }
  }
}

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});

// Auth actions provider
final authActionsProvider = Provider<AuthActions>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final authHelper = ref.watch(authProvider);
  return AuthActions(repository, authHelper);
});

// Auth actions class
class AuthActions {
  final AuthRepository _repository;
  final AuthHelper _authHelper;

  AuthActions(this._repository, this._authHelper);

  Future<ApiResponse<LoginResponse>> login({
    required String email,
    required String password,
  }) async {
    final result = await _repository.login(email: email, password: password);

    // If login successful, save token
    if (result.success && result.data != null) {
      log('💾 Saving authentication data to storage...');
      await _authHelper.setTokenAsync(result.data!.token);
      log('✅ Authentication data saved successfully');
      log('📊 Login Result: ${result.message}');
    } else {
      log('❌ Login failed in AuthActions: ${result.error}');
    }

    return result;
  }

  Future<ApiResponse<LoginResponse>> googleLogin({required String idToken}) async {
    final result = await _repository.googleLogin(idToken: idToken);

    // If login successful, save token
    if (result.success && result.data != null) {
      log('💾 Saving Google authentication data to storage...');
      await _authHelper.setTokenAsync(result.data!.token);
      log('✅ Google authentication data saved successfully');
      log('📊 Google Login Result: ${result.message}');
    } else {
      log('❌ Google login failed in AuthActions: ${result.error}');
    }

    return result;
  }

  Future<ApiResponse<LoginResponse>> microsoftLogin({required String accessToken}) async {
    final result = await _repository.microsoftLogin(accessToken: accessToken);

    // If login successful, save token
    if (result.success && result.data != null) {
      log('💾 Saving Microsoft authentication data to storage...');
      await _authHelper.setTokenAsync(result.data!.token);
      log('✅ Microsoft authentication data saved successfully');
      log('📊 Microsoft Login Result: ${result.message}');
    } else {
      log('❌ Microsoft login failed in AuthActions: ${result.error}');
    }

    return result;
  }

  Future<ApiResponse<bool>> logout() async {
    log('🗑️ Clearing authentication data...');
    final result = await _repository.logout();

    // Clear token regardless of result
    await _authHelper.clearTokenAsync();
    log('✅ Authentication data cleared');

    return result;
  }

  Future<ApiResponse<String>> refreshToken() async {
    final result = await _repository.refreshToken();

    // If refresh successful, update token
    if (result.success && result.data != null) {
      log('💾 Updating token in storage...');
      await _authHelper.setTokenAsync(result.data!);
      log('✅ Token updated successfully');
    } else {
      log('❌ Token refresh failed in AuthActions: ${result.error}');
    }

    return result;
  }

  Future<ApiResponse<Map<String, dynamic>>> fetchHomePage({
    required String eventId,
  }) async {
    return await _repository.fetchHomePage(eventId: eventId);
  }
}
