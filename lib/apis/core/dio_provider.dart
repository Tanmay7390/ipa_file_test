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
  dio.options.headers['Authorization'] =
      'jwt eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiI2NDM0NjNmMDg2YjliYjYwMThlZjI1MjAiLCJhY2NvdW50SWQiOiI2NDM0NjQyZDg2YjliYjYwMThlZjI1MjgiLCJhdXRob3JpemVkUmVzb3VyY2VzIjpbeyJfaWQiOiI2MjNkODdlYjlmMzY5OTY4MzM5NTRmOTUiLCJyZXNvdXJjZSI6IlVzZXJzIiwiYWN0aW9uIjoiVmlldyIsImRpc3BsYXlOYW1lIjoiVXNlcnMiLCJjYXRlZ29yeSI6IkFkbWluaXN0cmF0aXZlIiwidHlwZSI6IkFjdGlvbiJ9LHsiX2lkIjoiNjIzZDg3ZjI5ZjM2OTk2ODMzOTU0Zjk3IiwicmVzb3VyY2UiOiJVc2VycyIsImFjdGlvbiI6IkRlbGV0ZSIsImRpc3BsYXlOYW1lIjoiVXNlcnMiLCJjYXRlZ29yeSI6IkFkbWluaXN0cmF0aXZlIiwidHlwZSI6IkFjdGlvbiJ9LHsiX2lkIjoiNjIzZDg3ZGI5ZjM2OTk2ODMzOTU0ZjkxIiwicmVzb3VyY2UiOiJVc2VycyIsImFjdGlvbiI6IkNyZWF0ZSIsImRpc3BsYXlOYW1lIjoiVXNlcnMiLCJjYXRlZ29yeSI6IkFkbWluaXN0cmF0aXZlIiwidHlwZSI6IkFjdGlvbiJ9LHsiX2lkIjoiNjJhMzQ4YTZmNWQyYzVkODMyNWVmNzIxIiwicmVzb3VyY2UiOiJVc2VycyIsImFjdGlvbiI6IlVwZGF0ZSIsImRpc3BsYXlOYW1lIjoiVXNlcnMiLCJjYXRlZ29yeSI6IkFkbWluaXN0cmF0aXZlIiwidHlwZSI6IkFjdGlvbiJ9LHsiX2lkIjoiNjIzZDg3OTU5ZjM2OTk2ODMzOTU0Zjg5IiwicmVzb3VyY2UiOiJBY2NvdW50IiwiYWN0aW9uIjoiQ3JlYXRlIiwiZGlzcGxheU5hbWUiOiJBY2NvdW50cyIsImNhdGVnb3J5IjoiQWRtaW5pc3RyYXRpdmUiLCJ0eXBlIjoiQWN0aW9uIn0seyJfaWQiOiI2MjNkODdhMzlmMzY5OTY4MzM5NTRmOGIiLCJyZXNvdXJjZSI6IkFjY291bnQiLCJhY3Rpb24iOiJVcGRhdGUiLCJkaXNwbGF5TmFtZSI6IkFjY291bnRzIiwiY2F0ZWdvcnkiOiJBZG1pbmlzdHJhdGl2ZSIsInR5cGUiOiJBY3Rpb24ifSx7Il9pZCI6IjYyM2Q4N2QyOWYzNjk5NjgzMzk1NGY4ZiIsInJlc291cmNlIjoiQWNjb3VudCIsImFjdGlvbiI6IkRlbGV0ZSIsImRpc3BsYXlOYW1lIjoiQWNjb3VudHMiLCJjYXRlZ29yeSI6IkFkbWluaXN0cmF0aXZlIiwidHlwZSI6IkFjdGlvbiJ9LHsiX2lkIjoiNjIzZDg3Yzg5ZjM2OTk2ODMzOTU0ZjhkIiwicmVzb3VyY2UiOiJBY2NvdW50IiwiYWN0aW9uIjoiVmlldyIsImRpc3BsYXlOYW1lIjoiQWNjb3VudHMiLCJjYXRlZ29yeSI6IkFkbWluaXN0cmF0aXZlIiwiQWN0aW9uIjoiQWN0aW9uIn1dLCJpYXQiOjE3NDEzMzMwNjQsImV4cCI6MTc0MTMzNjY2NH0.PcFRDhs75ummsg9nF0INPZX_ZEnIUEXDR-ZOD509dOc';

  // Request interceptor - automatically add token to all requests
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final currentToken = ref.read(authTokenProvider);
        if (currentToken != null) {
          options.headers['Authorization'] = 'Bearer $currentToken';
        }

        // Log request for debugging
        log(
          'REQUEST: ${options.method} ${options.path} ${options.queryParameters}',
        );
        // log('HEADERS: ${options.headers}');

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
