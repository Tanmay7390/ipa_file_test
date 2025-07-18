import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:Wareozo/apis/core/dio_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Auth state model
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;
  final String? userEmail;
  final String? userPhone;
  final String? token;
  final String? accountId;
  final bool isInitialized;
  final String? storedUsername;
  final String? storedPassword;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
    this.userEmail,
    this.userPhone,
    this.token,
    this.accountId,
    this.isInitialized = false,
    this.storedUsername,
    this.storedPassword,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
    String? userEmail,
    String? userPhone,
    String? token,
    String? accountId,
    bool? isInitialized,
    String? storedUsername,
    String? storedPassword,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      token: token ?? this.token,
      accountId: accountId ?? this.accountId,
      isInitialized: isInitialized ?? this.isInitialized,
      storedUsername: storedUsername ?? this.storedUsername,
      storedPassword: storedPassword ?? this.storedPassword,
    );
  }
}

class AuthHelper {
  final Ref ref;
  static const String _tokenKey = 'auth_token';
  static const String _userEmailKey = 'user_email';
  static const String _accountIdKey = 'account_id';
  static const String _usernameKey = 'username';
  static const String _passwordKey = 'password';

  AuthHelper(this.ref);

  //  methods for credential storage
  Future<void> setCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_passwordKey, password);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passwordKey);
  }

  // Set token and persist it
  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);

    // Update dio provider with the token
    final dio = ref.read(dioProvider);
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Set user email
  Future<void> setUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
  }

  // Get user email
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // Set account ID
  Future<void> setAccountId(String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountIdKey, accountId);
  }

  // Get account ID
  Future<String?> getAccountId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accountIdKey);
  }

  // Clear token and all stored data
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_accountIdKey);
    await prefs.remove(_usernameKey); 
    await prefs.remove(_passwordKey); 

    // Remove from dio headers
    final dio = ref.read(dioProvider);
    dio.options.headers.remove('Authorization');
  }

  // Add method to get stored credentials
  Future<Map<String, String?>> getStoredCredentials() async {
    final username = await getUsername();
    final password = await getPassword();
    return {'username': username, 'password': password};
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio;
  final AuthHelper _authHelper;

  AuthNotifier(this._dio, this._authHelper) : super(const AuthState()) {
    // Check stored auth state on initialization
    _initializeAuth();
  }

  // Initialize auth state from stored data
  Future<void> _initializeAuth() async {
    try {
      final token = await _authHelper.getToken();
      final userEmail = await _authHelper.getUserEmail();
      final accountId = await _authHelper.getAccountId();
      final credentials = await _authHelper.getStoredCredentials(); 

      if (token != null && token.isNotEmpty) {
        // Set token in dio headers
        _dio.options.headers['Authorization'] = 'Bearer $token';

        state = state.copyWith(
          isAuthenticated: true,
          token: token,
          userEmail: userEmail,
          accountId: accountId,
          isInitialized: true,
          storedUsername: credentials['username'], 
          storedPassword: credentials['password'], 
        );
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          isInitialized: true,
          storedUsername: credentials['username'], 
          storedPassword: credentials['password'], 
        );
      }
    } catch (e) {
      state = state.copyWith(isAuthenticated: false, isInitialized: true);
    }
  }

  void setError(String error) {
    state = state.copyWith(error: error);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Debug: Print request details
      print('Making login request to: ${_dio.options.baseUrl}login');
      print('Request data: ${{'email': email.trim(), 'password': password}}');

      final response = await _dio.post(
        'login',
        data: {'email': email.trim(), 'password': password},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['token'] ?? data['accessToken'] ?? data['jwt'];

        // Extract account ID from response
        String? accountId;
        if (data['user'] != null && data['user']['accounts'] != null) {
          final accounts = data['user']['accounts'] as List;
          if (accounts.isNotEmpty) {
            accountId = accounts[0]['_id']; // Get first account ID
          }
        }

        if (token != null) {
          // Store token and credentials persistently
          await _authHelper.setToken(token);
          await _authHelper.setUserEmail(email.trim());
          await _authHelper.setCredentials(email.trim(), password);
          if (accountId != null) {
            await _authHelper.setAccountId(accountId);
          }

          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            userEmail: email.trim(),
            token: token,
            accountId: accountId,
            storedUsername: email.trim(),
            storedPassword: password,
          );
          return true;
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'Login failed. Invalid response from server.',
          );
          return false;
        }
      } else {
        String errorMessage = 'Login failed. Please check your credentials.';

        if (response.data != null && response.data is Map) {
          errorMessage =
              response.data['message'] ??
              response.data['error'] ??
              errorMessage;
        }

        state = state.copyWith(isLoading: false, error: errorMessage);
        return false;
      }
    } on DioException catch (e) {
      String errorMessage = 'Login failed. Please try again.';

      if (e.response != null) {
        switch (e.response!.statusCode) {
          case 400:
            if (e.response!.data is Map &&
                e.response!.data['message'] != null) {
              errorMessage = e.response!.data['message'];
            } else {
              errorMessage = 'Invalid email or password format.';
            }
            break;
          case 401:
            errorMessage = 'Invalid credentials. Please try again.';
            break;
          case 422:
            errorMessage = e.response!.data['message'] ?? 'Invalid input data.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          default:
            errorMessage = 'Login failed. Please try again.';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please check your internet.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Request timeout. Please try again.';
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Debug: Print request details
      print('Making signup request to: ${_dio.options.baseUrl}register');
      print(
        'Request data: ${{'name': name.trim(), 'email': email.trim(), 'phone': phone.trim(), 'password': password}}',
      );

      final response = await _dio.post(
        'register', // Use relative path since baseUrl is set in dio_provider
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'password': password,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500; // Accept all status codes below 500
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        // Check if registration was successful
        state = state.copyWith(
          isLoading: false,
          userEmail: email.trim(),
          userPhone: phone.trim(),
        );
        return true;
      } else {
        // Handle different status codes
        String errorMessage = 'Registration failed. Please try again.';

        if (response.data != null && response.data is Map) {
          errorMessage =
              response.data['message'] ??
              response.data['error'] ??
              errorMessage;
        }

        state = state.copyWith(isLoading: false, error: errorMessage);
        return false;
      }
    } on DioException catch (e) {
      String errorMessage = 'Registration failed. Please try again.';

      if (e.response != null) {
        switch (e.response!.statusCode) {
          case 400:
            // Parse the actual error message from response
            if (e.response!.data is Map &&
                e.response!.data['message'] != null) {
              errorMessage = e.response!.data['message'];
            } else {
              errorMessage = 'Invalid registration data.';
            }
            break;
          case 409:
            errorMessage = 'Email or phone number already exists.';
            break;
          case 422:
            errorMessage = e.response!.data['message'] ?? 'Invalid input data.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          default:
            errorMessage = 'Registration failed. Please try again.';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please check your internet.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Request timeout. Please try again.';
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate Google sign in
      await Future.delayed(const Duration(seconds: 2));

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        userEmail: 'user@gmail.com',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Google sign in failed.');
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate Apple sign in
      await Future.delayed(const Duration(seconds: 2));

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        userEmail: 'user@icloud.com',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Apple sign in failed.');
      return false;
    }
  }

  Future<bool> sendOTP({
    required String contact,
    required String type, // Only 'email' is supported
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Only email is supported by the API
      if (type != 'email') {
        state = state.copyWith(
          isLoading: false,
          error: 'Only email OTP is supported.',
        );
        return false;
      }

      // Validate email format
      if (!RegExp(
        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      ).hasMatch(contact.trim())) {
        state = state.copyWith(
          isLoading: false,
          error: 'Please enter a valid email address.',
        );
        return false;
      }

      print('Making OTP request to: ${_dio.options.baseUrl}user/otp');
      print('Request data: ${{'email': contact.trim()}}');

      final response = await _dio.post(
        'user/otp',
        data: {'email': contact.trim()},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500; // Accept all status codes below 500
          },
        ),
      );

      print('OTP Response status: ${response.statusCode}');
      print('OTP Response data: ${response.data}');

      if (response.statusCode == 200) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        String errorMessage = 'Failed to send OTP. Please try again.';

        if (response.data != null && response.data is Map) {
          errorMessage =
              response.data['message'] ??
              response.data['error'] ??
              errorMessage;
        }

        state = state.copyWith(isLoading: false, error: errorMessage);
        return false;
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to send OTP. Please try again.';

      print('DioException: ${e.message}');
      print('Response: ${e.response?.data}');
      print('Status Code: ${e.response?.statusCode}');

      if (e.response != null) {
        switch (e.response!.statusCode) {
          case 400:
            if (e.response!.data is Map &&
                e.response!.data['message'] != null) {
              errorMessage = e.response!.data['message'];
            } else {
              errorMessage = 'Invalid email address.';
            }
            break;
          case 404:
            errorMessage = 'Email not found. Please check your email address.';
            break;
          case 429:
            errorMessage = 'Too many requests. Please try again later.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          default:
            errorMessage = 'Failed to send OTP. Please try again.';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please check your internet.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Request timeout. Please try again.';
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    } catch (e) {
      print('General Exception: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  Future<bool> verifyOTP({
    required String otp,
    required String contact,
    required String type,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // For email OTP verification - use login endpoint with OTP
      if (type == 'email') {
        print('Making OTP login request to: ${_dio.options.baseUrl}login');
        print('Request data: ${{'email': contact.trim(), 'otp': otp}}');

        final response = await _dio.post(
          'login', // Use login endpoint for OTP verification
          data: {
            'email': contact.trim(),
            'otp': otp,
          }, // Send email and OTP (no password)
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            validateStatus: (status) {
              return status! < 500; // Accept all status codes below 500
            },
          ),
        );

        if (response.statusCode == 200) {
          final data = response.data;
          final token = data['token'] ?? data['accessToken'] ?? data['jwt'];

          // Extract account ID from response
          String? accountId;
          if (data['user'] != null && data['user']['accounts'] != null) {
            final accounts = data['user']['accounts'] as List;
            if (accounts.isNotEmpty) {
              accountId = accounts[0]['_id'];
            }
          }

          if (token != null) {
            // Store token and credentials (for OTP, we don't store password)
            await _authHelper.setToken(token);
            await _authHelper.setUserEmail(contact.trim());
            await _authHelper.setCredentials(
              contact.trim(),
              '',
            ); // Store empty password for OTP login
            if (accountId != null) {
              await _authHelper.setAccountId(accountId);
            }

            state = state.copyWith(
              isLoading: false,
              isAuthenticated: true,
              userEmail: contact.trim(),
              token: token,
              accountId: accountId,
              storedUsername: contact.trim(),
              storedPassword: '',
            );
            return true;
          } else {
            state = state.copyWith(
              isLoading: false,
              error: 'OTP verification failed. Invalid response from server.',
            );
            return false;
          }
        } else {
          String errorMessage = 'OTP verification failed. Please try again.';

          if (response.data != null && response.data is Map) {
            errorMessage =
                response.data['message'] ??
                response.data['error'] ??
                errorMessage;
          }

          state = state.copyWith(isLoading: false, error: errorMessage);
          return false;
        }
      } else {
        // Phone number OTP - not implemented yet
        state = state.copyWith(
          isLoading: false,
          error:
              'Phone OTP verification is not available yet. Please use email.',
        );
        return false;
      }
    } on DioException catch (e) {
      String errorMessage = 'OTP verification failed. Please try again.';

      if (e.response != null) {
        switch (e.response!.statusCode) {
          case 400:
            if (e.response!.data is Map &&
                e.response!.data['message'] != null) {
              errorMessage = e.response!.data['message'];
            } else {
              errorMessage = 'Invalid OTP or email.';
            }
            break;
          case 401:
            errorMessage = 'Invalid or expired OTP.';
            break;
          case 404:
            errorMessage = 'Email not found.';
            break;
          case 422:
            errorMessage = e.response!.data['message'] ?? 'Invalid OTP format.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          default:
            errorMessage = 'OTP verification failed. Please try again.';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please check your internet.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Request timeout. Please try again.';
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  Future<bool> resetPassword({
    required String contact,
    required String type,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simulate password reset
      await Future.delayed(const Duration(seconds: 2));

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Password reset failed.');
      return false;
    }
  }

  // Sign out method
  Future<void> signOut() async {
    await _authHelper.clearToken();
    state = const AuthState(isInitialized: true);
  }
}

// Create a separate provider for AuthHelper
final authHelperProvider = Provider<AuthHelper>((ref) {
  return AuthHelper(ref);
});

// Updated auth provider with dependencies
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final dio = ref.watch(dioProvider);
  final authHelper = ref.watch(authHelperProvider);
  return AuthNotifier(dio, authHelper);
});
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authState = ref.watch(authProvider);

  if (!authState.isAuthenticated || authState.token == null) {
    return null;
  }

  try {
    final dio = ref.read(dioProvider);
    final response = await dio.get(
      '/user/profile',
    ); // Adjust endpoint as needed

    if (response.statusCode == 200) {
      return response.data;
    }
    return null;
  } catch (e) {
    print('Error fetching user profile: $e');
    return null;
  }
});
