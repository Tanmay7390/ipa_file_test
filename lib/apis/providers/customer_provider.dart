// lib/apis/providers/customer_provider.dart
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_urls.dart';
import '../core/dio_provider.dart';

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
    int page = 0,
    int limit = 10,
    String? searchQuery,
  }) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.customerList, {
        'accountId': '6434642d86b9bb6018ef2528',
      });

      // Build query parameters
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['name'] = searchQuery;
      }

      final response = await dio.get(url, queryParameters: queryParams);

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Handle different API response structures
        List<Map<String, dynamic>> customers = [];
        int totalPages = 1;
        int totalCount = 0;
        bool hasMore = false;

        if (responseData is Map<String, dynamic>) {
          // Structured response with pagination info
          if (responseData.containsKey('data')) {
            final data = responseData['data'];
            if (data is List) {
              customers = List<Map<String, dynamic>>.from(data);
            } else if (data is Map && data.containsKey('customers')) {
              customers = List<Map<String, dynamic>>.from(
                data['customers'] ?? [],
              );
              totalPages = data['totalPages'] ?? 1;
              totalCount = data['totalCount'] ?? customers.length;
              hasMore = page < totalPages;
            }
          } else if (responseData.containsKey('customers')) {
            customers = List<Map<String, dynamic>>.from(
              responseData['customers'] ?? [],
            );
            totalPages = responseData['totalPages'] ?? 1;
            totalCount = responseData['totalCount'] ?? customers.length;
            hasMore = page < totalPages;
          } else {
            // Direct list response
            customers = [responseData];
          }

          // Extract pagination info if available
          if (responseData.containsKey('pagination')) {
            final pagination = responseData['pagination'];
            totalPages = pagination['totalPages'] ?? 1;
            totalCount = pagination['totalCount'] ?? customers.length;
            hasMore = pagination['hasMore'] ?? (page < totalPages);
          }
        } else if (responseData is List) {
          // Direct array response
          customers = List<Map<String, dynamic>>.from(responseData);
          totalCount = customers.length;
          hasMore = false; // No pagination info available
        }

        final customerData = CustomerData(
          customers: customers,
          currentPage: page,
          totalPages: totalPages,
          totalCount: totalCount,
          hasMore: hasMore,
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

  // Create customer
  Future<ApiResponse<Map<String, dynamic>>> createCustomer(
    Map<String, dynamic> customerData,
  ) async {
    try {
      final response = await dio.post(
        ApiUrls.createCustomer,
        data: FormData.fromMap(customerData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
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
          responseData is Map
              ? (responseData['message'] ?? 'Customer created successfully')
              : 'Customer created successfully',
        );
      } else {
        return ApiResponse.error('Failed to create customer');
      }
    } on DioException catch (e) {
      log('Error creating customer: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Update customer
  Future<ApiResponse<Map<String, dynamic>>> updateCustomer(
    String customerId,
    Map<String, dynamic> customerData,
  ) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.updateCustomer, {
        'id': customerId,
      });

      final response = await dio.put(url, data: FormData.fromMap(customerData));

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
          responseData is Map
              ? (responseData['message'] ?? 'Customer updated successfully')
              : 'Customer updated successfully',
        );
      } else {
        return ApiResponse.error('Failed to update customer');
      }
    } on DioException catch (e) {
      log('Error updating customer: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error: $e');
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
      return CustomerListNotifier(repository);
    });

// Customer actions provider for CRUD operations
final customerActionsProvider = Provider<CustomerActions>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return CustomerActions(repository);
});

// Customer list state notifier
class CustomerListNotifier extends StateNotifier<AsyncValue<CustomerData>> {
  final CustomerRepository _repository;
  String _currentAccountId = '';

  CustomerListNotifier(this._repository) : super(const AsyncValue.loading());

  // Load customers with pagination and search
  Future<void> loadCustomers({
    required int page,
    bool refresh = false,
    String? searchQuery,
    String? accountId,
  }) async {
    try {
      // Use provided accountId or keep current one
      if (accountId != null) {
        _currentAccountId = accountId;
      }

      if (_currentAccountId.isEmpty) {
        // Set default account ID if needed
        _currentAccountId = 'default_account'; // Replace with actual logic
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
        accountId: _currentAccountId,
        page: page,
        searchQuery: searchQuery,
      );

      if (result.success && result.data != null) {
        final newData = result.data!;

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
  void updateCustomer(String customerId, Map<String, dynamic> updatedCustomer) {
    state.whenData((currentData) {
      final updatedCustomers = currentData.customers.map((emp) {
        return emp['_id'] == customerId ? updatedCustomer : emp;
      }).toList();
      state = AsyncValue.data(
        currentData.copyWith(customers: updatedCustomers),
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
