// lib/core/providers/dio_provider.dart
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_urls.dart';
import '../../services/auth_service.dart';

// Token provider - store auth token here
final authTokenProvider = StateProvider<String?>((ref) => null);

// Token initialization provider - loads token from storage on app startup
final tokenInitializerProvider = FutureProvider<void>((ref) async {
  final token = await AuthService.getToken();
  if (token != null) {
    ref.read(authTokenProvider.notifier).state = token;
  }
});

// Dio provider with automatic token and headers
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  final token = ref.watch(authTokenProvider);

  // Base configuration
  dio.options = BaseOptions(
    baseUrl: ApiUrls.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  );

  // Add token if available
  if (token != null) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }
  // Removed hardcoded token - will use the actual user token from login

  // Request interceptor - automatically add token to all requests
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final currentToken = ref.read(authTokenProvider);
        if (currentToken != null) {
          options.headers['Authorization'] = 'Bearer $currentToken';
          log('🔐 Token added to request: Bearer ${currentToken.substring(0, 20)}...');
        } else {
          log('⚠️ No token available for request');
        }

        // Log request for debugging
        log(
          'REQUEST: ${options.method} ${options.path} ${options.queryParameters}',
        );
        log('HEADERS: ${options.headers}');

        handler.next(options);
      },
      onResponse: (response, handler) {
        // Log response for debugging
        // log('RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        // Handle token expiry
        if (error.response?.statusCode == 401) {
          // Token expired - clear it
          ref.read(authTokenProvider.notifier).state = null;
          log('Token expired - cleared from storage');
        }

        // Log error for debugging
        log('ERROR: ${error.message}');
        handler.next(error);
      },
    ),
  );

  return dio;
});

// Helper provider for updating token
final authProvider = Provider<AuthHelper>((ref) {
  return AuthHelper(ref);
});

class AuthHelper {
  final Ref ref;
  AuthHelper(this.ref);

  // Set token - saves to both state and storage
  void setToken(String token) {
    ref.read(authTokenProvider.notifier).state = token;
    // Save to storage asynchronously (fire and forget)
    AuthService.updateToken(token);
  }

  // Clear token - clears from both state and storage
  void clearToken() {
    ref.read(authTokenProvider.notifier).state = null;
    // Clear storage asynchronously (fire and forget)
    AuthService.logout();
  }

  // Set token with async storage confirmation
  Future<void> setTokenAsync(String token) async {
    ref.read(authTokenProvider.notifier).state = token;
    await AuthService.updateToken(token);
  }

  // Clear token with async storage confirmation
  Future<void> clearTokenAsync() async {
    ref.read(authTokenProvider.notifier).state = null;
    await AuthService.logout();
  }

  // Get current token
  String? get currentToken => ref.read(authTokenProvider);

  // Check if user is authenticated
  bool get isAuthenticated => currentToken != null;
}
