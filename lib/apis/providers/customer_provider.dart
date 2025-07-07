// lib/apis/providers/customer_provider.dart
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_urls.dart';
import '../core/dio_provider.dart';
import 'auth_provider.dart';

// Customer data model - flexible to handle any API response structure
class CustomerData {
  final List<Map<String, dynamic>> customers;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final int totalPages;
  final int totalCount;

  CustomerData({
    required this.customers,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
  });

  CustomerData copyWith({
    List<Map<String, dynamic>>? customers,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    int? totalPages,
    int? totalCount,
  }) {
    return CustomerData(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
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

// Customer repository
class CustomerRepository {
  final Dio dio;

  CustomerRepository(this.dio);

  // Get customer list with pagination and search
  Future<ApiResponse<CustomerData>> getCustomerList({
    required String accountId,
    int page = 1,
    int limit = 10,
    String? searchQuery,
  }) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.customerList, {
        'accountId': accountId,
      });

      // Build query parameters
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      log('Making request to: $url with params: $queryParams');

      final response = await dio.get(url, queryParameters: queryParams);

      log('Raw API Response: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Extract customers and total from API response
        List<Map<String, dynamic>> customers = [];
        int totalCount = 0;

        if (responseData is Map<String, dynamic>) {
          // Extract customers array - your API returns customers directly
          if (responseData.containsKey('customers')) {
            final customersData = responseData['customers'];
            if (customersData is List) {
              customers = List<Map<String, dynamic>>.from(customersData);
              log('Extracted ${customers.length} customers');
            }
          }

          // Extract total count
          if (responseData.containsKey('total')) {
            totalCount = responseData['total'] ?? 0;
          }
        }

        // Calculate pagination info
        final totalPages = totalCount > 0 ? (totalCount / limit).ceil() : 1;
        final hasMore = page < totalPages;

        log(
          'Total customers: $totalCount, Current page: $page, Has more: $hasMore',
        );

        final customerData = CustomerData(
          customers: customers,
          currentPage: page,
          totalPages: totalPages,
          totalCount: totalCount,
          hasMore: hasMore,
          isLoading: false,
          isLoadingMore: false,
        );

        return ApiResponse.success(
          customerData,
          responseData is Map ? responseData['message'] : null,
        );
      } else {
        return ApiResponse.error('Failed to fetch customers');
      }
    } on DioException catch (e) {
      log('Error fetching customers: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Get single customer
  Future<ApiResponse<Map<String, dynamic>>> getCustomer(
    String customerId,
  ) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.getCustomer, {
        'id': customerId,
      });

      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final responseData = response.data;
        Map<String, dynamic> customer = {};

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            customer = Map<String, dynamic>.from(responseData['data']);
          } else {
            customer = responseData;
          }
        }

        return ApiResponse.success(
          customer,
          responseData is Map ? responseData['message'] : null,
        );
      } else {
        return ApiResponse.error('Failed to fetch customer');
      }
    } on DioException catch (e) {
      log('Error fetching customer: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Create customer/supplier
  Future<ApiResponse<Map<String, dynamic>>> createCustomer(
    Map<String, dynamic> customerData,
  ) async {
    try {
      final url = ApiUrls.createCustomer; // 'account/buyer-seller'

      log('Creating customer with data: $customerData');

      // Check if there are any files in the data
      bool hasFiles = false;
      for (var value in customerData.values) {
        if (value is MultipartFile) {
          hasFiles = true;
          break;
        }
      }

      dynamic requestData;
      if (hasFiles) {
        // Use FormData for file uploads
        requestData = FormData.fromMap(customerData);
        log('Using FormData for file upload');
      } else {
        // Use regular JSON for non-file data
        requestData = customerData;
        log('Using JSON data (no files)');
      }

      final response = await dio.post(url, data: requestData);

      log(
        'Create customer response: ${response.statusCode} - ${response.data}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        Map<String, dynamic> createdCustomer = {};

        if (responseData is Map<String, dynamic>) {
          // Handle different response structures
          if (responseData.containsKey('data')) {
            createdCustomer = Map<String, dynamic>.from(responseData['data']);
          } else if (responseData.containsKey('customer')) {
            createdCustomer = Map<String, dynamic>.from(
              responseData['customer'],
            );
          } else {
            createdCustomer = responseData;
          }
        }

        return ApiResponse.success(
          createdCustomer,
          responseData is Map
              ? responseData['message']
              : 'Customer created successfully',
        );
      } else {
        return ApiResponse.error('Failed to create customer');
      }
    } on DioException catch (e) {
      log('Error creating customer: ${e.message}');
      if (e.response?.data != null) {
        log('Error response data: ${e.response!.data}');
      }
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error creating customer: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  //Update customer
  Future<ApiResponse<Map<String, dynamic>>> updateCustomer(
    String customerId,
    Map<String, dynamic> customerData,
  ) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.updateCustomer, {
        'customerId': customerId,
      });

      log('Updating customer $customerId with URL: $url');
      log('Full URL will be: ${ApiUrls.baseUrl}$url');
      log('Update data: $customerData');

      // Check if there are any files in the data
      bool hasFiles = false;
      for (var value in customerData.values) {
        if (value is MultipartFile) {
          hasFiles = true;
          break;
        }
      }

      dynamic requestData;
      if (hasFiles) {
        // Use FormData for file uploads
        requestData = FormData.fromMap(customerData);
        log('Using FormData for file upload');
      } else {
        // Use regular JSON for non-file data
        requestData = customerData;
        log('Using JSON data (no files)');
      }

      final response = await dio.post(url, data: requestData);

      log(
        'Update customer response: ${response.statusCode} - ${response.data}',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        Map<String, dynamic> updatedCustomer = {};

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            updatedCustomer = Map<String, dynamic>.from(responseData['data']);
          } else if (responseData.containsKey('customer')) {
            updatedCustomer = Map<String, dynamic>.from(
              responseData['customer'],
            );
          } else {
            updatedCustomer = responseData;
          }
        }

        return ApiResponse.success(
          updatedCustomer,
          responseData is Map
              ? responseData['message']
              : 'Customer updated successfully',
        );
      } else {
        return ApiResponse.error('Failed to update customer');
      }
    } on DioException catch (e) {
      log('Error updating customer: ${e.message}');
      if (e.response?.data != null) {
        log('Error response data: ${e.response!.data}');
      }
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error updating customer: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Delete customer
  Future<ApiResponse<bool>> deleteCustomer(String customerId) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.deleteCustomer, {
        'id': customerId,
      });

      final response = await dio.delete(url);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse.success(
          true,
          response.data is Map
              ? (response.data?['message'] ?? 'Customer deleted successfully')
              : 'Customer deleted successfully',
        );
      } else {
        return ApiResponse.error('Failed to delete customer');
      }
    } on DioException catch (e) {
      log('Error deleting customer: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error: $e');
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
            return 'Unauthorized. Please login again.';
          case 403:
            return 'Access denied. You don\'t have permission.';
          case 404:
            return 'Customer not found.';
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
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CustomerRepository(dio);
});

// Search provider
final customerSearchProvider = StateProvider<String>((ref) => '');

// Customer list provider
final customerListProvider =
    StateNotifierProvider<CustomerListNotifier, AsyncValue<CustomerData>>((
      ref,
    ) {
      final repository = ref.watch(customerRepositoryProvider);
      return CustomerListNotifier(repository, ref); // Pass ref here
    });

// Customer actions provider for CRUD operations
final customerActionsProvider = Provider<CustomerActions>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return CustomerActions(repository);
});

// Customer list state notifier
class CustomerListNotifier extends StateNotifier<AsyncValue<CustomerData>> {
  final CustomerRepository _repository;
  final Ref _ref; // Add this line
  String _currentAccountId = '';

  CustomerListNotifier(this._repository, this._ref)
    : super(const AsyncValue.loading());

  // Load customers with pagination and search
  Future<void> loadCustomers({
    required int page,
    bool refresh = false,
    String? searchQuery,
    String? accountId,
  }) async {
    try {
      // Use provided accountId or get from auth token
      String? targetAccountId = accountId;
      if (targetAccountId == null) {
        final authState = _ref.read(authProvider);
        targetAccountId = _getAccountIdFromAuth(authState);
      }

      if (targetAccountId == null || targetAccountId.isEmpty) {
        state = AsyncValue.error('No account ID found', StackTrace.current);
        return;
      }

      if (refresh || page == 1) {
        state = const AsyncValue.loading();
      } else {
        // Show loading more indicator
        state.whenData((currentData) {
          state = AsyncValue.data(currentData.copyWith(isLoadingMore: true));
        });
      }

      final result = await _repository.getCustomerList(
        accountId: targetAccountId,
        page: page,
        searchQuery: searchQuery,
      );

      if (result.success && result.data != null) {
        final newData = result.data!;
        log('Loaded customers: ${newData.customers.length}');
        log(
          'First customer: ${newData.customers.isNotEmpty ? newData.customers.first : 'none'}',
        );

        if (page == 1 || refresh) {
          // First page or refresh - replace all data
          state = AsyncValue.data(newData);
        } else {
          // Append to existing data
          state.whenData((currentData) {
            final combinedCustomers = [
              ...currentData.customers,
              ...newData.customers,
            ];

            state = AsyncValue.data(
              newData.copyWith(
                customers: combinedCustomers,
                isLoadingMore: false,
              ),
            );
          });
        }
      } else {
        state = AsyncValue.error(
          result.error ?? 'Failed to load customers',
          StackTrace.current,
        );
      }
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  // Helper method to extract account ID from auth state
  String? _getAccountIdFromAuth(AuthState authState) {
    // Method 1: If you store account ID in your auth token, decode it
    if (authState.token != null) {
      try {
        return _extractAccountIdFromToken(authState.token!);
      } catch (e) {
        print('Error extracting account ID from token: $e');
      }
    }

    // Method 2: If you have a separate field in AuthState for account ID
    // Add accountId field to your AuthState class and return it here
    // return authState.accountId;

    return null;
  }

  String? _extractAccountIdFromToken(String token) {
    try {
      // For now, get it from the auth state if available
      final authState = _ref.read(authProvider);
      return authState.accountId;
    } catch (e) {
      return null;
    }
  }

  // Remove customer from local state (optimistic update)
  void removeCustomer(String customerId) {
    state.whenData((currentData) {
      final updatedCustomers = currentData.customers
          .where((emp) => emp['_id'] != customerId)
          .toList();
      state = AsyncValue.data(
        currentData.copyWith(
          customers: updatedCustomers,
          totalCount: currentData.totalCount - 1,
        ),
      );
    });
  }

  // Add customer to local state (optimistic update)
  void addCustomer(Map<String, dynamic> customer) {
    state.whenData((currentData) {
      final updatedCustomers = [customer, ...currentData.customers];
      state = AsyncValue.data(
        currentData.copyWith(
          customers: updatedCustomers,
          totalCount: currentData.totalCount + 1,
        ),
      );
    });
  }

  // Update customer in local state (optimistic update)
  void updateCustomer(Map<String, dynamic> updatedCustomer) {
    state.whenData((currentData) {
      final updatedList = currentData.customers.map((customer) {
        if (customer['_id'] == updatedCustomer['_id']) {
          return updatedCustomer;
        }
        return customer;
      }).toList();

      state = AsyncValue.data(
        currentData.copyWith(
          customers: updatedList,
          currentPage: currentData.currentPage,
          hasMore: currentData.hasMore,
          isLoadingMore: currentData.isLoadingMore,
        ),
      );
    });
  }
}

// Customer actions class for CRUD operations
class CustomerActions {
  final CustomerRepository _repository;

  CustomerActions(this._repository);

  Future<ApiResponse<Map<String, dynamic>>> getCustomer(
    String customerId,
  ) async {
    return await _repository.getCustomer(customerId);
  }

  Future<ApiResponse<Map<String, dynamic>>> createCustomer(
    Map<String, dynamic> customerData,
  ) async {
    return await _repository.createCustomer(customerData);
  }

  Future<ApiResponse<Map<String, dynamic>>> updateCustomer(
    String customerId,
    Map<String, dynamic> customerData,
  ) async {
    return await _repository.updateCustomer(customerId, customerData);
  }

  Future<ApiResponse<bool>> deleteCustomer(String customerId) async {
    return await _repository.deleteCustomer(customerId);
  }
}
