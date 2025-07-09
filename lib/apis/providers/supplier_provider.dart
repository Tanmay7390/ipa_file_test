// lib/apis/providers/Supplier_provider.dart
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_urls.dart';
import '../core/dio_provider.dart';
import 'package:Wareozo/apis/providers/auth_provider.dart';

// Supplier data model - flexible to handle any API response structure
class SupplierData {
  final List<Map<String, dynamic>> suppliers;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final int totalPages;
  final int totalCount;

  SupplierData({
    required this.suppliers,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
  });

  SupplierData copyWith({
    List<Map<String, dynamic>>? suppliers,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    int? totalPages,
    int? totalCount,
  }) {
    return SupplierData(
      suppliers: suppliers ?? this.suppliers,
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

// Supplier repository
class SupplierRepository {
  final Dio dio;

  SupplierRepository(this.dio);

  // Create supplier
  Future<ApiResponse<Map<String, dynamic>>> createSupplier(
    Map<String, dynamic> supplierData,
  ) async {
    try {
      final url = ApiUrls.createCustomer; // Same endpoint as customer

      log('Creating supplier with data: $supplierData');

      // Check if there are any files in the data
      bool hasFiles = false;
      for (var value in supplierData.values) {
        if (value is MultipartFile) {
          hasFiles = true;
          break;
        }
      }

      dynamic requestData;
      if (hasFiles) {
        requestData = FormData.fromMap(supplierData);
        log('Using FormData for file upload');
      } else {
        requestData = supplierData;
        log('Using JSON data (no files)');
      }

      final response = await dio.post(url, data: requestData);

      log(
        'Create supplier response: ${response.statusCode} - ${response.data}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        Map<String, dynamic> createdSupplier = {};

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('fullAccountDetails')) {
            createdSupplier = Map<String, dynamic>.from(
              responseData['fullAccountDetails'],
            );
          } else if (responseData.containsKey('data')) {
            createdSupplier = Map<String, dynamic>.from(responseData['data']);
          } else if (responseData.containsKey('supplier')) {
            createdSupplier = Map<String, dynamic>.from(
              responseData['supplier'],
            );
          } else {
            createdSupplier = responseData;
          }
        }

        return ApiResponse.success(
          createdSupplier,
          'Supplier created successfully',
        );
      } else {
        return ApiResponse.error('Failed to create supplier');
      }
    } on DioException catch (e) {
      log('Error creating supplier: ${e.message}');
      if (e.response?.data != null) {
        log('Error response data: ${e.response!.data}');
      }
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error creating supplier: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Get Supplier list with pagination and search
  Future<ApiResponse<SupplierData>> getsupplierList({
    required String accountId,
    int page = 1,
    int limit = 10,
    String? searchQuery,
  }) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.supplierList, {
        'accountId': accountId,
      });

      // Try 0-based pagination (page - 1) and add potential filters
      final queryParams = <String, dynamic>{
        'page': page - 1, // Try 0-based pagination
        'limit': limit,
        'isVendor':
            true, // Add this filter since your sample data shows isVendor: true
      };

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      log('Making request to: $url with params: $queryParams');

      final response = await dio.get(url, queryParameters: queryParams);

      // Rest of your existing code remains the same...
      log('Raw API Response: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        List<Map<String, dynamic>> suppliers = [];
        int totalCount = 0;

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('suppliers')) {
            final suppliersData = responseData['suppliers'];
            if (suppliersData is List) {
              suppliers = List<Map<String, dynamic>>.from(suppliersData);
              log('Extracted ${suppliers.length} suppliers');
            }
          }

          if (responseData.containsKey('total')) {
            totalCount = responseData['total'] ?? 0;
          }
        }

        final totalPages = totalCount > 0 ? (totalCount / limit).ceil() : 1;
        final hasMore = page < totalPages;

        final supplierData = SupplierData(
          suppliers: suppliers,
          currentPage: page,
          totalPages: totalPages,
          totalCount: totalCount,
          hasMore: hasMore,
          isLoading: false,
          isLoadingMore: false,
        );

        return ApiResponse.success(
          supplierData,
          responseData is Map ? responseData['message'] : null,
        );
      } else {
        return ApiResponse.error('Failed to fetch suppliers');
      }
    } on DioException catch (e) {
      log('Error fetching suppliers: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Update supplier method
  Future<ApiResponse<Map<String, dynamic>>> updateSupplier(
    String supplierId,
    Map<String, dynamic> supplierData,
  ) async {
    try {
      // Use the same endpoint as customer update since suppliers use customer API
      final url = ApiUrls.replaceParams(ApiUrls.updateCustomer, {
        'customerId': supplierId,
      });

      log('Updating supplier $supplierId with URL: $url');
      log('Full URL will be: ${ApiUrls.baseUrl}$url');
      log('Update data: $supplierData');

      final response = await dio.post(url, data: supplierData);

      log(
        'Update supplier response: ${response.statusCode} - ${response.data}',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        Map<String, dynamic> updatedSupplier = {};

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            updatedSupplier = Map<String, dynamic>.from(responseData['data']);
          } else if (responseData.containsKey('supplier')) {
            updatedSupplier = Map<String, dynamic>.from(
              responseData['supplier'],
            );
          } else {
            updatedSupplier = responseData;
          }
        }

        return ApiResponse.success(
          updatedSupplier,
          responseData is Map
              ? responseData['message']
              : 'Supplier updated successfully',
        );
      } else {
        return ApiResponse.error('Failed to update supplier');
      }
    } on DioException catch (e) {
      log('Error updating supplier: ${e.message}');
      if (e.response?.data != null) {
        log('Error response data: ${e.response!.data}');
      }
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error updating supplier: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Add this debug method to your SupplierRepository class
  Future<void> debugSupplierAPI({required String accountId}) async {
    try {
      // Test different variations of the API call
      print('=== DEBUGGING SUPPLIER API ===');
      print('Account ID: $accountId');

      // 1. Test the exact URL being used
      final url = ApiUrls.replaceParams(ApiUrls.supplierList, {
        'accountId': accountId,
      });
      print('Full URL: $url');

      // 2. Test without pagination parameters
      print('\n--- Test 1: No pagination params ---');
      try {
        final response1 = await dio.get(url);
        print('Response 1: ${response1.data}');
      } catch (e) {
        print('Error 1: $e');
      }

      // 3. Test with only limit parameter
      print('\n--- Test 2: Only limit param ---');
      try {
        final response2 = await dio.get(url, queryParameters: {'limit': 50});
        print('Response 2: ${response2.data}');
      } catch (e) {
        print('Error 2: $e');
      }

      // 4. Test with different page values
      print('\n--- Test 3: Different page values ---');
      for (int i = 0; i <= 2; i++) {
        try {
          final response3 = await dio.get(
            url,
            queryParameters: {'page': i, 'limit': 10},
          );
          print('Page $i Response: ${response3.data}');
        } catch (e) {
          print('Page $i Error: $e');
        }
      }

      // 5. Test the base URL without accountId (if applicable)
      print('\n--- Test 4: Check base suppliers endpoint ---');
      try {
        final baseResponse = await dio.get('suppliers');
        print('Base Response: ${baseResponse.data}');
      } catch (e) {
        print('Base Error: $e');
      }

      // 6. Test with different query parameters
      print('\n--- Test 5: With isVendor filter ---');
      try {
        final response5 = await dio.get(
          url,
          queryParameters: {'page': 1, 'limit': 10, 'isVendor': true},
        );
        print('Vendor Response: ${response5.data}');
      } catch (e) {
        print('Vendor Error: $e');
      }
    } catch (e) {
      print('Debug error: $e');
    }
  }

  // Also add this method to check the ApiUrls.supplierList value
  void debugApiUrls() {
    print('=== API URLS DEBUG ===');
    print('ApiUrls.supplierList: ${ApiUrls.supplierList}');
    // Add other relevant URLs for comparison
  }

  // Get supplier profile
  Future<ApiResponse<Map<String, dynamic>>> getSupplierProfile(
    String supplierId,
  ) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.getSupplier, {
        'id': supplierId,
      });

      log('Getting supplier profile from: $url');

      final response = await dio.get(url);

      log('Supplier profile response: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Since your API returns the supplier data directly (not nested)
        Map<String, dynamic> supplierData = {};

        if (responseData is Map<String, dynamic>) {
          supplierData = responseData;
        }

        return ApiResponse.success(supplierData);
      } else {
        return ApiResponse.error('Failed to fetch supplier profile');
      }
    } on DioException catch (e) {
      log('Error fetching supplier profile: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error fetching supplier profile: $e');
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
            return 'Supplier not found.';
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
final SupplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SupplierRepository(dio);
});

// Search provider
final suppliersearchProvider = StateProvider<String>((ref) => '');

// Supplier list provider
final supplierListProvider =
    StateNotifierProvider<supplierListNotifier, AsyncValue<SupplierData>>((
      ref,
    ) {
      final repository = ref.watch(SupplierRepositoryProvider);
      return supplierListNotifier(repository, ref); // Pass ref here
    });

// Suppliers actions provider for CRUD operations
final supplierActionsProvider = Provider<SupplierActions>((ref) {
  final repository = ref.watch(SupplierRepositoryProvider);
  return SupplierActions(repository);
});

// Supplier list state notifier
class supplierListNotifier extends StateNotifier<AsyncValue<SupplierData>> {
  final SupplierRepository _repository;
  final Ref _ref; // Add this line
  String _currentAccountId = '';

  supplierListNotifier(this._repository, this._ref)
    : super(const AsyncValue.loading());

  // Load suppliers with pagination and search
  Future<void> loadsuppliers({
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

      final result = await _repository.getsupplierList(
        accountId: targetAccountId,
        page: page,
        searchQuery: searchQuery,
      );

      if (result.success && result.data != null) {
        final newData = result.data!;
        log('Loaded suppliers: ${newData.suppliers.length}');
        log(
          'First Supplier: ${newData.suppliers.isNotEmpty ? newData.suppliers.first : 'none'}',
        );

        if (page == 1 || refresh) {
          // First page or refresh - replace all data
          state = AsyncValue.data(newData);
        } else {
          // Append to existing data
          state.whenData((currentData) {
            final combinedsuppliers = [
              ...currentData.suppliers,
              ...newData.suppliers,
            ];

            state = AsyncValue.data(
              newData.copyWith(
                suppliers: combinedsuppliers,
                isLoadingMore: false,
              ),
            );
          });
        }
      } else {
        state = AsyncValue.error(
          result.error ?? 'Failed to load suppliers',
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

  void updateSupplier(Map<String, dynamic> updatedSupplier) {
    state.whenData((currentData) {
      final updatedList = currentData.suppliers.map((supplier) {
        if (supplier['_id'] == updatedSupplier['_id']) {
          return updatedSupplier;
        }
        return supplier;
      }).toList();

      state = AsyncValue.data(
        currentData.copyWith(
          suppliers: updatedList,
          currentPage: currentData.currentPage,
          hasMore: currentData.hasMore,
          isLoadingMore: currentData.isLoadingMore,
        ),
      );
    });
  }

  // Remove Suppliers from local state (optimistic update)
  void removeSupplier(String supplierId) {
    state.whenData((currentData) {
      final updatedSuppliers = currentData.suppliers
          .where((emp) => emp['_id'] != supplierId)
          .toList();
      state = AsyncValue.data(
        currentData.copyWith(
          suppliers: updatedSuppliers,
          totalCount: currentData.totalCount - 1,
        ),
      );
    });
  }
}

class SupplierActions {
  final SupplierRepository _repository;

  SupplierActions(this._repository);

  Future<ApiResponse<Map<String, dynamic>>> createSupplier(
    Map<String, dynamic> supplierData,
  ) async {
    return await _repository.createSupplier(supplierData);
  }

  Future<ApiResponse<Map<String, dynamic>>> updateSupplier(
    String supplierId,
    Map<String, dynamic> supplierData,
  ) async {
    return await _repository.updateSupplier(supplierId, supplierData);
  }

  // Delete supplier method
  Future<ApiResponse<bool>> deleteSupplier(String supplierId) async {
    try {
      // Since there's no specific delete endpoint in api_urls.dart for suppliers,
      // you'll need to add it or use a generic endpoint
      final response = await _repository.dio.delete('suppliers/$supplierId');

      if (response.statusCode == 200) {
        return ApiResponse.success(true, 'Supplier deleted successfully');
      } else {
        return ApiResponse.error('Failed to delete supplier');
      }
    } catch (e) {
      return ApiResponse.error('Error deleting supplier: $e');
    }
  }

  // Add other CRUD operations as needed
}

final supplierProfileProvider =
    StateNotifierProvider<
      SupplierProfileNotifier,
      AsyncValue<Map<String, dynamic>?>
    >((ref) {
      final repository = ref.watch(SupplierRepositoryProvider);
      return SupplierProfileNotifier(repository);
    });

// Supplier profile state notifier
class SupplierProfileNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final SupplierRepository _repository;

  SupplierProfileNotifier(this._repository) : super(const AsyncValue.loading());

  Future<ApiResponse<Map<String, dynamic>>> getSupplierProfile(
    String supplierId,
  ) async {
    state = const AsyncValue.loading();

    try {
      final result = await _repository.getSupplierProfile(supplierId);

      if (result.success && result.data != null) {
        state = AsyncValue.data(result.data);
        return result;
      } else {
        state = AsyncValue.error(
          result.error ?? 'Failed to load supplier profile',
          StackTrace.current,
        );
        return result;
      }
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return ApiResponse.error(e.toString());
    }
  }
}
