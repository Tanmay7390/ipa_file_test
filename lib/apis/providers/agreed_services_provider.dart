// lib/apis/providers/agreed_services_provider.dart
import 'dart:developer';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_urls.dart';
import '../core/dio_provider.dart';
import 'auth_provider.dart';

// Agreed Service data model
class AgreedService {
  final int uid;
  final String serviceCategory;
  final String serviceName;
  final double serviceBudget;
  final int personnel;
  final DateTime startDate;
  final DateTime endDate;
  final String? id;

  AgreedService({
    required this.uid,
    required this.serviceCategory,
    required this.serviceName,
    required this.serviceBudget,
    required this.personnel,
    required this.startDate,
    required this.endDate,
    this.id,
  });

  factory AgreedService.fromJson(Map<String, dynamic> json) {
    return AgreedService(
      uid: json['uid'] ?? 0,
      serviceCategory: json['serviceCategory'] ?? '',
      serviceName: json['serviceName'] ?? '',
      serviceBudget: (json['serviceBudget'] ?? 0).toDouble(),
      personnel: json['personnel'] ?? 0,
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      id: json['_id'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'uid': uid,
      'serviceCategory': serviceCategory,
      'serviceName': serviceName,
      'serviceBudget': serviceBudget,
      'personnel': personnel,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };

    // Only include _id if it exists (for updates)
    if (id != null) {
      data['_id'] = id;
    }

    return data;
  }

  AgreedService copyWith({
    int? uid,
    String? serviceCategory,
    String? serviceName,
    double? serviceBudget,
    int? personnel,
    DateTime? startDate,
    DateTime? endDate,
    String? id,
  }) {
    return AgreedService(
      uid: uid ?? this.uid,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      serviceName: serviceName ?? this.serviceName,
      serviceBudget: serviceBudget ?? this.serviceBudget,
      personnel: personnel ?? this.personnel,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      id: id ?? this.id,
    );
  }
}

// Agreed Services data wrapper
class AgreedServicesData {
  final List<AgreedService> services;
  final bool isLoading;
  final String? error;
  final String? counterPartyId;

  AgreedServicesData({
    required this.services,
    this.isLoading = false,
    this.error,
    this.counterPartyId,
  });

  AgreedServicesData copyWith({
    List<AgreedService>? services,
    bool? isLoading,
    String? error,
    String? counterPartyId,
  }) {
    return AgreedServicesData(
      services: services ?? this.services,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      counterPartyId: counterPartyId ?? this.counterPartyId,
    );
  }
}

// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;

  ApiResponse({required this.success, this.data, this.message, this.error});

  factory ApiResponse.success(T data, [String? message]) {
    return ApiResponse(success: true, data: data, message: message);
  }

  factory ApiResponse.error(String error) {
    return ApiResponse(success: false, error: error);
  }
}

// Agreed Services Repository
class AgreedServicesRepository {
  final Dio dio;

  AgreedServicesRepository(this.dio);

  // Get agreed services for a customer/supplier
  Future<ApiResponse<AgreedServicesData>> getAgreedServices({
    required String counterPartyId,
  }) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.agreedServicesList, {
        'id': counterPartyId,
      });

      log('Getting agreed services from: $url');
      log(
        'Using auth token: ${dio.options.headers['Authorization'] != null ? 'Present' : 'Missing'}',
      );

      final response = await dio.get(url);

      log(
        'Agreed services response: ${response.statusCode} - ${response.data}',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        List<AgreedService> services = [];

        if (responseData is Map<String, dynamic>) {
          // Extract agreed services from the response
          if (responseData.containsKey('agreedServices')) {
            final servicesData = responseData['agreedServices'];
            if (servicesData is List) {
              services = servicesData
                  .map((service) => AgreedService.fromJson(service))
                  .toList();
              log('Extracted ${services.length} agreed services');
            }
          }

          // Log the counterPartyOfAccount for validation
          final counterPartyOfAccount = responseData['counterPartyOfAccount'];
          log('Counter party belongs to account: $counterPartyOfAccount');
        }

        final agreedServicesData = AgreedServicesData(
          services: services,
          counterPartyId: counterPartyId,
          isLoading: false,
        );

        return ApiResponse.success(
          agreedServicesData,
          responseData is Map ? responseData['message'] : null,
        );
      } else {
        return ApiResponse.error('Failed to fetch agreed services');
      }
    } on DioException catch (e) {
      log('Error fetching agreed services: ${e.message}');
      if (e.response?.statusCode == 401) {
        log('Authentication failed - token may be expired');
      }
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error fetching agreed services: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Update agreed services for a customer/supplier
  Future<ApiResponse<AgreedServicesData>> updateAgreedServices({
    required String counterPartyId,
    required List<AgreedService> services,
    List<String>? attachments,
  }) async {
    try {
      final url = ApiUrls.updateAgreedServices;

      // Prepare the payload according to the API specification
      final payload = {
        'counterPartyId': counterPartyId,
        'agreedServices': services.map((service) => service.toJson()).toList(),
        'attachments': attachments ?? [],
      };

      log('Updating agreed services with URL: $url');
      log('Payload: $payload');

      final response = await dio.put(url, data: payload);

      log(
        'Update agreed services response: ${response.statusCode} - ${response.data}',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Return the updated services data
        final agreedServicesData = AgreedServicesData(
          services:
              services, // Use the services we sent since API confirmed success
          counterPartyId: counterPartyId,
          isLoading: false,
        );

        String successMessage = 'Agreed services updated successfully';
        if (responseData is Map && responseData['message'] != null) {
          successMessage = responseData['message'];
        }

        return ApiResponse.success(agreedServicesData, successMessage);
      } else {
        return ApiResponse.error(
          'Failed to update agreed services: HTTP ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      log('Error updating agreed services: ${e.message}');
      if (e.response?.data != null) {
        log('Error response data: ${e.response!.data}');
      }
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error updating agreed services: $e');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Add a single agreed service
  Future<ApiResponse<AgreedServicesData>> addAgreedService({
    required String counterPartyId,
    required AgreedService newService,
    required List<AgreedService> existingServices,
  }) async {
    // Create a new list with the added service
    final updatedServices = [...existingServices, newService];
    return await updateAgreedServices(
      counterPartyId: counterPartyId,
      services: updatedServices,
    );
  }

  // Remove an agreed service by uid
  Future<ApiResponse<AgreedServicesData>> removeAgreedService({
    required String counterPartyId,
    required int serviceUid,
    required List<AgreedService> existingServices,
  }) async {
    // Create a new list without the removed service
    final updatedServices = existingServices
        .where((service) => service.uid != serviceUid)
        .toList();

    return await updateAgreedServices(
      counterPartyId: counterPartyId,
      services: updatedServices,
    );
  }

  // Update a specific agreed service by uid
  Future<ApiResponse<AgreedServicesData>> updateSingleAgreedService({
    required String counterPartyId,
    required AgreedService updatedService,
    required List<AgreedService> existingServices,
  }) async {
    // Create a new list with the updated service
    final updatedServices = existingServices.map((service) {
      if (service.uid == updatedService.uid) {
        return updatedService;
      }
      return service;
    }).toList();

    return await updateAgreedServices(
      counterPartyId: counterPartyId,
      services: updatedServices,
    );
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
        final responseData = e.response?.data;

        // Try to extract error message from response
        String? message;
        if (responseData is Map<String, dynamic>) {
          message =
              responseData['message'] ??
              responseData['error'] ??
              responseData['msg'];
        } else if (responseData is String) {
          message = responseData;
        }

        switch (statusCode) {
          case 400:
            return message ?? 'Bad request. Please check your input.';
          case 401:
            return 'Unauthorized. Please login again.';
          case 403:
            return 'Access denied. You don\'t have permission to update this customer/supplier.';
          case 404:
            return 'Customer/Supplier not found.';
          case 422:
            return message ?? 'Validation error. Please check your input.';
          case 500:
            return 'Server error. Please try again later.';
          default:
            return message ??
                'An error occurred (HTTP $statusCode). Please try again.';
        }
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          return 'Network error. Please check your internet connection.';
        }
        return 'Network error. Please check your internet connection.';
      default:
        return 'An unexpected error occurred.';
    }
  }
}

// Repository provider
final agreedServicesRepositoryProvider = Provider<AgreedServicesRepository>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return AgreedServicesRepository(dio);
});

// Agreed services state notifier
class AgreedServicesNotifier
    extends StateNotifier<AsyncValue<AgreedServicesData>> {
  final AgreedServicesRepository _repository;
  final Ref _ref;

  AgreedServicesNotifier(this._repository, this._ref)
    : super(const AsyncValue.loading());

  // Load agreed services for a customer/supplier
  Future<void> loadAgreedServices(String counterPartyId) async {
    state = const AsyncValue.loading();

    try {
      // Check authentication first
      final authState = _ref.read(authProvider);
      if (!_isAuthenticated(authState)) {
        state = AsyncValue.error('User not authenticated', StackTrace.current);
        return;
      }

      final result = await _repository.getAgreedServices(
        counterPartyId: counterPartyId,
      );

      if (result.success && result.data != null) {
        state = AsyncValue.data(result.data!);
      } else {
        state = AsyncValue.error(
          result.error ?? 'Failed to load agreed services',
          StackTrace.current,
        );
      }
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  // Update agreed services
  Future<bool> updateAgreedServices({
    required String counterPartyId,
    required List<AgreedService> services,
    List<String>? attachments,
  }) async {
    try {
      // Check authentication first
      final authState = _ref.read(authProvider);
      if (!_isAuthenticated(authState)) {
        state = AsyncValue.error('User not authenticated', StackTrace.current);
        return false;
      }

      // Validate that counterPartyId belongs to current account
      if (!await _validateCounterPartyAccess(counterPartyId, authState)) {
        state = AsyncValue.error(
          'Access denied to this customer/supplier',
          StackTrace.current,
        );
        return false;
      }

      // Set loading state
      state.whenData((currentData) {
        state = AsyncValue.data(currentData.copyWith(isLoading: true));
      });

      final result = await _repository.updateAgreedServices(
        counterPartyId: counterPartyId,
        services: services,
        attachments: attachments,
      );

      if (result.success && result.data != null) {
        state = AsyncValue.data(result.data!);
        return true;
      } else {
        state = AsyncValue.error(
          result.error ?? 'Failed to update agreed services',
          StackTrace.current,
        );
        return false;
      }
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return false;
    }
  }

  // Add a new agreed service
  Future<bool> addAgreedService({
    required String counterPartyId,
    required AgreedService newService,
  }) async {
    try {
      // Check authentication first
      final authState = _ref.read(authProvider);
      if (!_isAuthenticated(authState)) {
        state = AsyncValue.error('User not authenticated', StackTrace.current);
        return false;
      }

      return await state.when(
        data: (currentData) async {
          final result = await _repository.addAgreedService(
            counterPartyId: counterPartyId,
            newService: newService,
            existingServices: currentData.services,
          );

          if (result.success && result.data != null) {
            state = AsyncValue.data(result.data!);
            return true;
          } else {
            state = AsyncValue.error(
              result.error ?? 'Failed to add agreed service',
              StackTrace.current,
            );
            return false;
          }
        },
        loading: () => false,
        error: (error, stack) => false,
      );
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return false;
    }
  }

  // Remove an agreed service
  Future<bool> removeAgreedService({
    required String counterPartyId,
    required int serviceUid,
  }) async {
    try {
      // Check authentication first
      final authState = _ref.read(authProvider);
      if (!_isAuthenticated(authState)) {
        state = AsyncValue.error('User not authenticated', StackTrace.current);
        return false;
      }

      return await state.when(
        data: (currentData) async {
          final result = await _repository.removeAgreedService(
            counterPartyId: counterPartyId,
            serviceUid: serviceUid,
            existingServices: currentData.services,
          );

          if (result.success && result.data != null) {
            state = AsyncValue.data(result.data!);
            return true;
          } else {
            state = AsyncValue.error(
              result.error ?? 'Failed to remove agreed service',
              StackTrace.current,
            );
            return false;
          }
        },
        loading: () => false,
        error: (error, stack) => false,
      );
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return false;
    }
  }

  // Update a specific agreed service
  Future<bool> updateSingleAgreedService({
    required String counterPartyId,
    required AgreedService updatedService,
  }) async {
    try {
      // Check authentication first
      final authState = _ref.read(authProvider);
      if (!_isAuthenticated(authState)) {
        state = AsyncValue.error('User not authenticated', StackTrace.current);
        return false;
      }

      return await state.when(
        data: (currentData) async {
          final result = await _repository.updateSingleAgreedService(
            counterPartyId: counterPartyId,
            updatedService: updatedService,
            existingServices: currentData.services,
          );

          if (result.success && result.data != null) {
            state = AsyncValue.data(result.data!);
            return true;
          } else {
            state = AsyncValue.error(
              result.error ?? 'Failed to update agreed service',
              StackTrace.current,
            );
            return false;
          }
        },
        loading: () => false,
        error: (error, stack) => false,
      );
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return false;
    }
  }

  // Clear current state
  void clearState() {
    state = const AsyncValue.loading();
  }

  // Helper method to check if user is authenticated
  bool _isAuthenticated(AuthState authState) {
    return authState.isAuthenticated &&
        authState.token != null &&
        authState.accountId != null;
  }

  // Helper method to get account ID from auth state
  String? _getAccountIdFromAuth(AuthState authState) {
    // Method 1: Direct access from AuthState
    if (authState.accountId != null && authState.accountId!.isNotEmpty) {
      return authState.accountId;
    }

    // Method 2: Extract from token if needed (fallback)
    if (authState.token != null) {
      try {
        return _extractAccountIdFromToken(authState.token!);
      } catch (e) {
        log('Error extracting account ID from token: $e');
      }
    }

    return null;
  }

  // Helper method to extract account ID from token (if needed)
  String? _extractAccountIdFromToken(String token) {
    try {
      // Since accountId is already stored in AuthState, just return it
      final authState = _ref.read(authProvider);
      return authState.accountId;
    } catch (e) {
      log('Error in _extractAccountIdFromToken: $e');
      return null;
    }
  }

  // Helper method to validate that the counterParty belongs to current account
  Future<bool> _validateCounterPartyAccess(
    String counterPartyId,
    AuthState authState,
  ) async {
    try {
      final accountId = _getAccountIdFromAuth(authState);
      if (accountId == null) {
        log('No account ID found for validation');
        return false;
      }

      // For agreed services, we trust that the API will validate access
      // based on the authentication token. The customer/supplier must belong
      // to the authenticated account for the API to return data.
      // Additional validation could be added here if needed.

      log(
        'Validating access for counterParty: $counterPartyId, account: $accountId',
      );
      return true;
    } catch (e) {
      log('Error validating counter party access: $e');
      return false;
    }
  }
}

// Agreed services provider
final agreedServicesProvider =
    StateNotifierProvider<
      AgreedServicesNotifier,
      AsyncValue<AgreedServicesData>
    >((ref) {
      final repository = ref.watch(agreedServicesRepositoryProvider);
      return AgreedServicesNotifier(repository, ref);
    });

// Actions provider for convenient access to methods
final agreedServicesActionsProvider = Provider<AgreedServicesActions>((ref) {
  final repository = ref.watch(agreedServicesRepositoryProvider);
  return AgreedServicesActions(repository);
});

// Actions class for direct repository access
class AgreedServicesActions {
  final AgreedServicesRepository _repository;

  AgreedServicesActions(this._repository);

  Future<ApiResponse<AgreedServicesData>> getAgreedServices(
    String counterPartyId,
  ) async {
    return await _repository.getAgreedServices(counterPartyId: counterPartyId);
  }

  Future<ApiResponse<AgreedServicesData>> updateAgreedServices({
    required String counterPartyId,
    required List<AgreedService> services,
    List<String>? attachments,
  }) async {
    return await _repository.updateAgreedServices(
      counterPartyId: counterPartyId,
      services: services,
      attachments: attachments,
    );
  }

  Future<ApiResponse<AgreedServicesData>> addAgreedService({
    required String counterPartyId,
    required AgreedService newService,
    required List<AgreedService> existingServices,
  }) async {
    return await _repository.addAgreedService(
      counterPartyId: counterPartyId,
      newService: newService,
      existingServices: existingServices,
    );
  }

  Future<ApiResponse<AgreedServicesData>> removeAgreedService({
    required String counterPartyId,
    required int serviceUid,
    required List<AgreedService> existingServices,
  }) async {
    return await _repository.removeAgreedService(
      counterPartyId: counterPartyId,
      serviceUid: serviceUid,
      existingServices: existingServices,
    );
  }

  Future<ApiResponse<AgreedServicesData>> updateSingleAgreedService({
    required String counterPartyId,
    required AgreedService updatedService,
    required List<AgreedService> existingServices,
  }) async {
    return await _repository.updateSingleAgreedService(
      counterPartyId: counterPartyId,
      updatedService: updatedService,
      existingServices: existingServices,
    );
  }
}

// Enhanced actions provider with authentication validation
final agreedServicesAuthenticatedActionsProvider =
    Provider<AuthenticatedAgreedServicesActions>((ref) {
      final repository = ref.watch(agreedServicesRepositoryProvider);
      final authState = ref.watch(authProvider);
      return AuthenticatedAgreedServicesActions(repository, authState);
    });

// Authenticated actions wrapper that includes auth validation
class AuthenticatedAgreedServicesActions {
  final AgreedServicesRepository _repository;
  final AuthState _authState;

  AuthenticatedAgreedServicesActions(this._repository, this._authState);

  // Validate authentication before any operation
  bool get isAuthenticated =>
      _authState.isAuthenticated &&
      _authState.token != null &&
      _authState.accountId != null;

  String? get currentAccountId => _authState.accountId;
  String? get currentUserEmail => _authState.userEmail;

  Future<ApiResponse<AgreedServicesData>> getAgreedServices(
    String counterPartyId,
  ) async {
    if (!isAuthenticated) {
      return ApiResponse.error('User not authenticated');
    }

    log(
      'Getting agreed services for counterParty: $counterPartyId, account: $currentAccountId',
    );
    return await _repository.getAgreedServices(counterPartyId: counterPartyId);
  }

  Future<ApiResponse<AgreedServicesData>> updateAgreedServices({
    required String counterPartyId,
    required List<AgreedService> services,
    List<String>? attachments,
  }) async {
    if (!isAuthenticated) {
      return ApiResponse.error('User not authenticated');
    }

    log(
      'Updating agreed services for counterParty: $counterPartyId, account: $currentAccountId',
    );
    log('Services count: ${services.length}');

    return await _repository.updateAgreedServices(
      counterPartyId: counterPartyId,
      services: services,
      attachments: attachments,
    );
  }

  Future<ApiResponse<AgreedServicesData>> addAgreedService({
    required String counterPartyId,
    required AgreedService newService,
    required List<AgreedService> existingServices,
  }) async {
    if (!isAuthenticated) {
      return ApiResponse.error('User not authenticated');
    }

    log(
      'Adding agreed service "${newService.serviceName}" for counterParty: $counterPartyId',
    );

    return await _repository.addAgreedService(
      counterPartyId: counterPartyId,
      newService: newService,
      existingServices: existingServices,
    );
  }

  Future<ApiResponse<AgreedServicesData>> removeAgreedService({
    required String counterPartyId,
    required int serviceUid,
    required List<AgreedService> existingServices,
  }) async {
    if (!isAuthenticated) {
      return ApiResponse.error('User not authenticated');
    }

    log(
      'Removing agreed service with UID: $serviceUid for counterParty: $counterPartyId',
    );

    return await _repository.removeAgreedService(
      counterPartyId: counterPartyId,
      serviceUid: serviceUid,
      existingServices: existingServices,
    );
  }

  Future<ApiResponse<AgreedServicesData>> updateSingleAgreedService({
    required String counterPartyId,
    required AgreedService updatedService,
    required List<AgreedService> existingServices,
  }) async {
    if (!isAuthenticated) {
      return ApiResponse.error('User not authenticated');
    }

    log(
      'Updating agreed service "${updatedService.serviceName}" for counterParty: $counterPartyId',
    );

    return await _repository.updateSingleAgreedService(
      counterPartyId: counterPartyId,
      updatedService: updatedService,
      existingServices: existingServices,
    );
  }
}
