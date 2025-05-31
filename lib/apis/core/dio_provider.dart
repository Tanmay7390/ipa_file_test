// lib/core/providers/dio_provider.dart
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_urls.dart';

// Token provider - store auth token here
final authTokenProvider = StateProvider<String?>((ref) => null);

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
    headers: {'Content-Type': 'multipart/form-data'},
  );

  // Add token if available
  if (token != null) {
    dio.options.headers['Authorization'] = 'jwt $token';
  }

  // Request interceptor - automatically add token to all requests
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final currentToken = ref.read(authTokenProvider);
        if (currentToken != null) {
          options.headers['Authorization'] = 'Bearer $currentToken';
        }

        // Log request for debugging
        log('REQUEST: ${options.method} ${options.path}');
        log('HEADERS: ${options.headers}');

        handler.next(options);
      },
      onResponse: (response, handler) {
        // Log response for debugging
        log('RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
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

  // Set token
  void setToken(String token) {
    ref.read(authTokenProvider.notifier).state = token;
  }

  // Clear token
  void clearToken() {
    ref.read(authTokenProvider.notifier).state = null;
  }

  // Get current token
  String? get currentToken => ref.read(authTokenProvider);

  // Check if user is authenticated
  bool get isAuthenticated => currentToken != null;
}
