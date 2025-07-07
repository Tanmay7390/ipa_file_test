import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:Wareozo/apis/core/dio_provider.dart';
import 'package:Wareozo/apis/core/api_urls.dart';
import 'package:Wareozo/apis/providers/auth_provider.dart';

// Address State
class AddressState {
  final List<Map<String, dynamic>> addresses;
  final Map<String, dynamic>? selectedAddress;
  final bool isLoading;
  final bool isFetchingById;
  final String? error;

  const AddressState({
    this.addresses = const [],
    this.selectedAddress,
    this.isLoading = false,
    this.isFetchingById = false,
    this.error,
  });

  AddressState copyWith({
    List<Map<String, dynamic>>? addresses,
    Map<String, dynamic>? selectedAddress,
    bool? isLoading,
    bool? isFetchingById,
    String? error,
  }) {
    return AddressState(
      addresses: addresses ?? this.addresses,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      isLoading: isLoading ?? this.isLoading,
      isFetchingById: isFetchingById ?? this.isFetchingById,
      error: error,
    );
  }
}

// Address Notifier
class AddressNotifier extends StateNotifier<AddressState> {
  final Dio _dio;
  final Ref _ref;

  AddressNotifier(this._dio, this._ref) : super(const AddressState());

  String? get _accountId => _ref.read(authProvider).accountId;

  // Fetch all addresses
  Future<void> fetchAddresses() async {
    if (_accountId == null) {
      state = state.copyWith(
        error: 'Account ID not found. Please login again.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final url = ApiUrls.replaceParams(ApiUrls.addressList, {
        'accountId': _accountId!,
      });

      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        // Debug: Print the response structure
        print('Address API Response: ${response.data}');
        print('Address Response type: ${response.data.runtimeType}');
        if (response.data is Map) {
          print('Address Response keys: ${response.data.keys}');
        }

        // Handle different response structures
        List<dynamic> data = [];

        if (response.data is Map) {
          // Try different possible keys where addresses might be stored
          data =
              response.data['addresses'] ??
              response.data['data'] ??
              response.data['addressList'] ??
              response.data['result'] ??
              [];
        } else if (response.data is List) {
          data = response.data;
        }

        print('Extracted address data: $data');
        print('Address data length: ${data.length}');

        // Validate and filter the data
        final validAddresses = data
            .where(
              (item) => item is Map<String, dynamic> && item['_id'] != null,
            )
            .cast<Map<String, dynamic>>()
            .toList();

        print('Valid addresses: ${validAddresses.length}');

        state = state.copyWith(addresses: validAddresses, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch addresses. Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('Address DioException: ${e.message}');
      print('Address Response data: ${e.response?.data}');
      state = state.copyWith(isLoading: false, error: _handleDioError(e));
    } catch (e) {
      print('Address General Exception: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred: $e',
      );
    }
  }

  // Get address by ID
  Future<Map<String, dynamic>?> getAddressById(String addressId) async {
    state = state.copyWith(isFetchingById: true, error: null);

    try {
      final url = ApiUrls.replaceParams(ApiUrls.getAddressById, {
        'id': addressId,
      });

      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        // Debug: Print the response structure
        print('Get Address By ID Response: ${response.data}');
        print('Response type: ${response.data.runtimeType}');

        Map<String, dynamic>? addressData;

        if (response.data is Map<String, dynamic>) {
          // Try different possible keys where address data might be stored
          addressData =
              response.data['address'] ??
              response.data['data'] ??
              response.data['addressData'] ??
              response.data['result'] ??
              response.data;
        }

        print('Extracted address data: $addressData');

        // Validate the address data
        if (addressData != null && addressData['_id'] != null) {
          state = state.copyWith(
            selectedAddress: addressData,
            isFetchingById: false,
          );
          return addressData;
        } else {
          state = state.copyWith(
            isFetchingById: false,
            error: 'Invalid address data received',
          );
          return null;
        }
      } else {
        state = state.copyWith(
          isFetchingById: false,
          error: 'Failed to fetch address. Status: ${response.statusCode}',
        );
        return null;
      }
    } on DioException catch (e) {
      print('DioException in getAddressById: ${e.message}');
      print('Response data: ${e.response?.data}');
      state = state.copyWith(isFetchingById: false, error: _handleDioError(e));
      return null;
    } catch (e) {
      print('General Exception in getAddressById: $e');
      state = state.copyWith(
        isFetchingById: false,
        error: 'An unexpected error occurred: $e',
      );
      return null;
    }
  }

  // Create new address
  Future<bool> createAddress(Map<String, dynamic> addressData) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Add accountId to the data
      final dataWithAccountId = {...addressData, 'accountId': _accountId};

      final response = await _dio.post(
        ApiUrls.createAddress,
        data: dataWithAccountId,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh the list after successful creation
        await fetchAddresses();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to create address',
        );
        return false;
      }
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _handleDioError(e));
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      return false;
    }
  }

  // Update address
  Future<bool> updateAddress(
    String addressId,
    Map<String, dynamic> addressData,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final url = ApiUrls.replaceParams(ApiUrls.updateAddress, {
        'id': addressId,
      });

      final response = await _dio.put(url, data: addressData);

      if (response.statusCode == 200) {
        // Refresh the list after successful update
        await fetchAddresses();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update address',
        );
        return false;
      }
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _handleDioError(e));
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      return false;
    }
  }

  // Delete address
  Future<bool> deleteAddress(String addressId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final url = ApiUrls.replaceParams(ApiUrls.deleteAddress, {
        'id': addressId,
      });

      final response = await _dio.delete(url);

      if (response.statusCode == 200) {
        // Refresh the list after successful deletion
        await fetchAddresses();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to delete address',
        );
        return false;
      }
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _handleDioError(e));
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      return false;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Clear selected address
  void clearSelectedAddress() {
    state = state.copyWith(selectedAddress: null);
  }

  // Debug method to manually set addresses (for testing)
  void setAddressesManually(List<Map<String, dynamic>> addresses) {
    state = state.copyWith(addresses: addresses, isLoading: false, error: null);
  }

  // Handle Dio errors
  String _handleDioError(DioException e) {
    if (e.response != null) {
      switch (e.response!.statusCode) {
        case 400:
          return e.response!.data['message'] ?? 'Invalid request data';
        case 401:
          return 'Unauthorized. Please login again.';
        case 403:
          return 'Access forbidden';
        case 404:
          return 'Resource not found';
        case 500:
          return 'Server error. Please try again later.';
        default:
          return 'Request failed. Please try again. Status: ${e.response!.statusCode}';
      }
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your internet.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Request timeout. Please try again.';
    } else {
      return 'Network error. Please check your connection.';
    }
  }
}

// Address Provider
final addressProvider = StateNotifierProvider<AddressNotifier, AddressState>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return AddressNotifier(dio, ref);
});

// Auto-fetch provider that watches auth state changes
final addressAutoFetchProvider = Provider<void>((ref) {
  final authState = ref.watch(authProvider);
  final addressNotifier = ref.read(addressProvider.notifier);

  // Auto-fetch when user becomes authenticated and has accountId
  if (authState.isAuthenticated && authState.accountId != null) {
    Future.microtask(() => addressNotifier.fetchAddresses());
  }
});

// Provider for getting a specific address by ID
final getAddressByIdProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((
      ref,
      addressId,
    ) async {
      final addressNotifier = ref.read(addressProvider.notifier);
      return await addressNotifier.getAddressById(addressId);
    });
