import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_urls.dart';
import '../core/dio_provider.dart';

class InventoryRepository {
  final Dio dio;

  InventoryRepository(this.dio);

  Future<ApiResponse<List<Map<String, dynamic>>>> getInventoryList(
    String accountId,
  ) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.inventoryList, {
        'accountId': accountId,
      });

      final response = await dio.get(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        List<Map<String, dynamic>> inventory = [];

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data') &&
              responseData['data'] is List) {
            inventory = List<Map<String, dynamic>>.from(responseData['data']);
          } else if (responseData.containsKey('inventories') &&
              responseData['inventories'] is List) {
            inventory = List<Map<String, dynamic>>.from(
              responseData['inventories'],
            );
          } else {
            inventory = [responseData];
          }
        } else if (responseData is List) {
          inventory = List<Map<String, dynamic>>.from(responseData);
        }

        return ApiResponse.success(
          inventory,
          responseData is Map
              ? (responseData['message'] ??
                    'Inventory list fetched successfully')
              : 'Inventory list fetched successfully',
        );
      } else {
        return ApiResponse.error('Failed to fetch inventory list');
      }
    } on DioException catch (e) {
      log('Error fetching inventory list: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getInventoryItem({
    required String accountId,
    required String itemId,
  }) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.inventoryList, {
        'accountId': accountId,
        'itemId': itemId,
      });

      final response = await dio.get(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        Map<String, dynamic> item = {};

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            item = Map<String, dynamic>.from(responseData['data']);
          } else {
            item = responseData;
          }
        }

        return ApiResponse.success(
          item,
          responseData is Map
              ? (responseData['message'] ??
                    'Inventory item fetched successfully')
              : 'Inventory item fetched successfully',
        );
      } else {
        return ApiResponse.error('Failed to fetch inventory item');
      }
    } on DioException catch (e) {
      log('Error fetching inventory item: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createInventoryItem({
    required String accountId,
    required Map<String, dynamic> itemData,
  }) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.inventoryList, {
        'accountId': accountId,
      });

      final response = await dio.post(url, data: itemData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;
        Map<String, dynamic> item = {};

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            item = Map<String, dynamic>.from(responseData['data']);
          } else {
            item = responseData;
          }
        }

        return ApiResponse.success(
          item,
          responseData is Map
              ? (responseData['message'] ??
                    'Inventory item created successfully')
              : 'Inventory item created successfully',
        );
      } else {
        return ApiResponse.error('Failed to create inventory item');
      }
    } on DioException catch (e) {
      log('Error creating inventory item: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateInventoryItem({
    required String accountId,
    required String itemId,
    required Map<String, dynamic> itemData,
  }) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.inventoryList, {
        'accountId': accountId,
        'itemId': itemId,
      });

      final response = await dio.put(url, data: itemData);

      if (response.statusCode == 200) {
        final responseData = response.data;
        Map<String, dynamic> item = {};

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            item = Map<String, dynamic>.from(responseData['data']);
          } else {
            item = responseData;
          }
        }

        return ApiResponse.success(
          item,
          responseData is Map
              ? (responseData['message'] ??
                    'Inventory item updated successfully')
              : 'Inventory item updated successfully',
        );
      } else {
        return ApiResponse.error('Failed to update inventory item');
      }
    } on DioException catch (e) {
      log('Error updating inventory item: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<bool>> deleteInventoryItem({
    required String accountId,
    required String itemId,
  }) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.inventoryList, {
        'accountId': accountId,
        'itemId': itemId,
      });

      final response = await dio.delete(url);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse.success(
          true,
          response.data is Map
              ? (response.data?['message'] ??
                    'Inventory item deleted successfully')
              : 'Inventory item deleted successfully',
        );
      } else {
        return ApiResponse.error('Failed to delete inventory item');
      }
    } on DioException catch (e) {
      log('Error deleting inventory item: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Search/Filter inventory items
  Future<ApiResponse<List<Map<String, dynamic>>>> searchInventoryItems({
    required String accountId,
    String? searchQuery,
    String? category,
    bool? inStock,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (inStock != null) {
        queryParams['inStock'] = inStock;
      }
      if (minPrice != null) {
        queryParams['minPrice'] = minPrice;
      }
      if (maxPrice != null) {
        queryParams['maxPrice'] = maxPrice;
      }

      final url = ApiUrls.replaceParams(ApiUrls.inventoryList, {
        'accountId': accountId,
      });

      final response = await dio.get(
        url,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        List<Map<String, dynamic>> inventory = [];

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data') &&
              responseData['data'] is List) {
            inventory = List<Map<String, dynamic>>.from(responseData['data']);
          } else if (responseData.containsKey('inventory') &&
              responseData['inventory'] is List) {
            inventory = List<Map<String, dynamic>>.from(
              responseData['inventory'],
            );
          } else if (responseData.containsKey('items') &&
              responseData['items'] is List) {
            inventory = List<Map<String, dynamic>>.from(responseData['items']);
          } else {
            inventory = [responseData];
          }
        } else if (responseData is List) {
          inventory = List<Map<String, dynamic>>.from(responseData);
        }

        return ApiResponse.success(
          inventory,
          responseData is Map
              ? (responseData['message'] ??
                    'Inventory search completed successfully')
              : 'Inventory search completed successfully',
        );
      } else {
        return ApiResponse.error('Failed to search inventory items');
      }
    } on DioException catch (e) {
      log('Error searching inventory items: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

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
            return 'Inventory item not found.';
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

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return InventoryRepository(dio);
});

// Inventory List Provider - Similar to bankAccountsProvider
final inventoryListProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      accountId,
    ) async {
      final repository = ref.watch(inventoryRepositoryProvider);
      final result = await repository.getInventoryList(accountId);

      if (result.success && result.data != null) {
        return result.data!;
      } else {
        return <Map<String, dynamic>>[];
      }
    });

// Individual Inventory Item Provider
final inventoryItemProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, String>>((
      ref,
      params,
    ) async {
      final repository = ref.watch(inventoryRepositoryProvider);
      final result = await repository.getInventoryItem(
        accountId: params['accountId']!,
        itemId: params['itemId']!,
      );

      if (result.success && result.data != null) {
        return result.data!;
      } else {
        return <String, dynamic>{};
      }
    });

// Search Inventory Provider
final searchInventoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((
      ref,
      searchParams,
    ) async {
      final repository = ref.watch(inventoryRepositoryProvider);
      final result = await repository.searchInventoryItems(
        accountId: searchParams['accountId'] as String,
        searchQuery: searchParams['searchQuery'] as String?,
        category: searchParams['category'] as String?,
        inStock: searchParams['inStock'] as bool?,
        minPrice: searchParams['minPrice'] as double?,
        maxPrice: searchParams['maxPrice'] as double?,
      );

      if (result.success && result.data != null) {
        return result.data!;
      } else {
        return <Map<String, dynamic>>[];
      }
    });

final inventoryActionsProvider = Provider<InventoryActions>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return InventoryActions(repository);
});

class InventoryActions {
  final InventoryRepository _repository;

  InventoryActions(this._repository);

  Future<ApiResponse<List<Map<String, dynamic>>>> getInventoryList(
    String accountId,
  ) async {
    return await _repository.getInventoryList(accountId);
  }

  Future<ApiResponse<Map<String, dynamic>>> getInventoryItem({
    required String accountId,
    required String itemId,
  }) async {
    return await _repository.getInventoryItem(
      accountId: accountId,
      itemId: itemId,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> createInventoryItem({
    required String accountId,
    required Map<String, dynamic> itemData,
  }) async {
    return await _repository.createInventoryItem(
      accountId: accountId,
      itemData: itemData,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> updateInventoryItem({
    required String accountId,
    required String itemId,
    required Map<String, dynamic> itemData,
  }) async {
    return await _repository.updateInventoryItem(
      accountId: accountId,
      itemId: itemId,
      itemData: itemData,
    );
  }

  Future<ApiResponse<bool>> deleteInventoryItem({
    required String accountId,
    required String itemId,
  }) async {
    return await _repository.deleteInventoryItem(
      accountId: accountId,
      itemId: itemId,
    );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> searchInventoryItems({
    required String accountId,
    String? searchQuery,
    String? category,
    bool? inStock,
    double? minPrice,
    double? maxPrice,
  }) async {
    return await _repository.searchInventoryItems(
      accountId: accountId,
      searchQuery: searchQuery,
      category: category,
      inStock: inStock,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }
}
