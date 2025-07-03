import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_urls.dart';
import '../core/dio_provider.dart';

class AddressRepository {
  final Dio dio;

  AddressRepository(this.dio);

  Future<ApiResponse<List<Map<String, dynamic>>>> getCountries() async {
    try {
      final response = await dio.get(ApiUrls.getCountries);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        List<Map<String, dynamic>> countries = [];

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data') &&
              responseData['data'] is List) {
            countries = List<Map<String, dynamic>>.from(responseData['data']);
          } else if (responseData.containsKey('countries') &&
              responseData['countries'] is List) {
            countries = List<Map<String, dynamic>>.from(
              responseData['countries'],
            );
          } else {
            countries = [responseData];
          }
        } else if (responseData is List) {
          countries = List<Map<String, dynamic>>.from(responseData);
        }

        return ApiResponse.success(
          countries,
          responseData is Map
              ? (responseData['message'] ?? 'Countries fetched successfully')
              : 'Countries fetched successfully',
        );
      } else {
        return ApiResponse.error('Failed to fetch countries');
      }
    } on DioException catch (e) {
      log('Error fetching countries: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getStates({
    String? countryId,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (countryId != null) {
        queryParams['countryId'] = countryId;
      }

      final response = await dio.get(
        ApiUrls.getStates,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        List<Map<String, dynamic>> states = [];

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data') &&
              responseData['data'] is List) {
            states = List<Map<String, dynamic>>.from(responseData['data']);
          } else if (responseData.containsKey('states') &&
              responseData['states'] is List) {
            states = List<Map<String, dynamic>>.from(responseData['states']);
          } else {
            states = [responseData];
          }
        } else if (responseData is List) {
          states = List<Map<String, dynamic>>.from(responseData);
        }

        return ApiResponse.success(
          states,
          responseData is Map
              ? (responseData['message'] ?? 'States fetched successfully')
              : 'States fetched successfully',
        );
      } else {
        return ApiResponse.error('Failed to fetch states');
      }
    } on DioException catch (e) {
      log('Error fetching states: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createAddress({
    required String customerId,
    required Map<String, dynamic> addressData,
  }) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.createCustomerAddress, {
        'customerId': customerId,
      });

      final response = await dio.post(url, data: addressData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;
        Map<String, dynamic> address = {};

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            address = Map<String, dynamic>.from(responseData['data']);
          } else {
            address = responseData;
          }
        }

        return ApiResponse.success(
          address,
          responseData is Map
              ? (responseData['message'] ?? 'Address created successfully')
              : 'Address created successfully',
        );
      } else {
        return ApiResponse.error('Failed to create address');
      }
    } on DioException catch (e) {
      log('Error creating address: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateAddress({
    required String customerId,
    required String addressId,
    required Map<String, dynamic> addressData,
  }) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.updateCustomerAddress, {
        'customerId': customerId,
        'addressId': addressId,
      });

      final response = await dio.put(url, data: addressData);

      if (response.statusCode == 200) {
        final responseData = response.data;
        Map<String, dynamic> address = {};

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            address = Map<String, dynamic>.from(responseData['data']);
          } else {
            address = responseData;
          }
        }

        return ApiResponse.success(
          address,
          responseData is Map
              ? (responseData['message'] ?? 'Address updated successfully')
              : 'Address updated successfully',
        );
      } else {
        return ApiResponse.error('Failed to update address');
      }
    } on DioException catch (e) {
      log('Error updating address: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<bool>> deleteAddress({
    required String customerId,
    required String addressId,
  }) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.deleteCustomerAddress, {
        'customerId': customerId,
        'addressId': addressId,
      });

      final response = await dio.delete(url);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse.success(
          true,
          response.data is Map
              ? (response.data?['message'] ?? 'Address deleted successfully')
              : 'Address deleted successfully',
        );
      } else {
        return ApiResponse.error('Failed to delete address');
      }
    } on DioException catch (e) {
      log('Error deleting address: ${e.message}');
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
            return 'Resource not found.';
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

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AddressRepository(dio);
});

// Countries Provider - Similar to invoice templates provider
final countriesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repository = ref.watch(addressRepositoryProvider);
  final result = await repository.getCountries();

  if (result.success && result.data != null) {
    return result.data!;
  } else {
    return <Map<String, dynamic>>[];
  }
});

// States Provider - Similar to bank accounts provider but independent
final statesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(addressRepositoryProvider);
  final result = await repository.getStates();

  if (result.success && result.data != null) {
    return result.data!;
  } else {
    return <Map<String, dynamic>>[];
  }
});

// States by Country Provider - Similar to bank accounts provider with parameter
final statesByCountryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      countryId,
    ) async {
      final repository = ref.watch(addressRepositoryProvider);
      final result = await repository.getStates(countryId: countryId);

      if (result.success && result.data != null) {
        return result.data!;
      } else {
        return <Map<String, dynamic>>[];
      }
    });

final addressActionsProvider = Provider<AddressActions>((ref) {
  final repository = ref.watch(addressRepositoryProvider);
  return AddressActions(repository);
});

class AddressActions {
  final AddressRepository _repository;

  AddressActions(this._repository);

  Future<ApiResponse<List<Map<String, dynamic>>>> getCountries() async {
    return await _repository.getCountries();
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getStates({
    String? countryId,
  }) async {
    return await _repository.getStates(countryId: countryId);
  }

  Future<ApiResponse<Map<String, dynamic>>> createAddress({
    required String customerId,
    required Map<String, dynamic> addressData,
  }) async {
    return await _repository.createAddress(
      customerId: customerId,
      addressData: addressData,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> updateAddress({
    required String customerId,
    required String addressId,
    required Map<String, dynamic> addressData,
  }) async {
    return await _repository.updateAddress(
      customerId: customerId,
      addressId: addressId,
      addressData: addressData,
    );
  }

  Future<ApiResponse<bool>> deleteAddress({
    required String customerId,
    required String addressId,
  }) async {
    return await _repository.deleteAddress(
      customerId: customerId,
      addressId: addressId,
    );
  }
}
