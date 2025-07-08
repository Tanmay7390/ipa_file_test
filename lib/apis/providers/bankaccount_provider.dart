import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:Wareozo/apis/core/dio_provider.dart';
import 'package:Wareozo/apis/core/api_urls.dart';
import 'package:Wareozo/apis/providers/auth_provider.dart';

// Bank Account State
class BankAccountState {
  final List<Map<String, dynamic>> bankAccounts;
  final Map<String, dynamic>? selectedBankAccount;
  final bool isLoading;
  final bool isFetchingById;
  final String? error;

  const BankAccountState({
    this.bankAccounts = const [],
    this.selectedBankAccount,
    this.isLoading = false,
    this.isFetchingById = false,
    this.error,
  });

  BankAccountState copyWith({
    List<Map<String, dynamic>>? bankAccounts,
    Map<String, dynamic>? selectedBankAccount,
    bool? isLoading,
    bool? isFetchingById,
    String? error,
  }) {
    return BankAccountState(
      bankAccounts: bankAccounts ?? this.bankAccounts,
      selectedBankAccount: selectedBankAccount ?? this.selectedBankAccount,
      isLoading: isLoading ?? this.isLoading,
      isFetchingById: isFetchingById ?? this.isFetchingById,
      error: error,
    );
  }
}

// Bank Account Notifier
class BankAccountNotifier extends StateNotifier<BankAccountState> {
  final Dio _dio;
  final Ref _ref;

  BankAccountNotifier(this._dio, this._ref) : super(const BankAccountState());

  String? get _accountId => _ref.read(authProvider).accountId;

  // Fetch all bank accounts
  Future<void> fetchBankAccounts() async {
    if (_accountId == null) {
      state = state.copyWith(
        error: 'Account ID not found. Please login again.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final url = ApiUrls.replaceParams(ApiUrls.bankList, {
        'accountId': _accountId!,
      });

      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        // Debug: Print the response structure
        print('API Response: ${response.data}');
        print('Response type: ${response.data.runtimeType}');
        if (response.data is Map) {
          print('Response keys: ${response.data.keys}');
        }

        // Handle different response structures
        List<dynamic> data = [];

        if (response.data is Map) {
          // Try different possible keys where bank accounts might be stored
          data =
              response.data['banks'] ??
              response.data['data'] ??
              response.data['bankAccounts'] ??
              response.data['result'] ??
              [];
        } else if (response.data is List) {
          data = response.data;
        }

        print('Extracted data: $data');
        print('Data length: ${data.length}');

        // Validate and filter the data
        final validBankAccounts = data
            .where(
              (item) => item is Map<String, dynamic> && item['_id'] != null,
            )
            .cast<Map<String, dynamic>>()
            .toList();

        print('Valid bank accounts: ${validBankAccounts.length}');

        state = state.copyWith(
          bankAccounts: validBankAccounts,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error:
              'Failed to fetch bank accounts. Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('DioException: ${e.message}');
      print('Response data: ${e.response?.data}');
      state = state.copyWith(isLoading: false, error: _handleDioError(e));
    } catch (e) {
      print('General Exception: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred: $e',
      );
    }
  }

  // Get bank account by ID
  Future<Map<String, dynamic>?> getBankById(String bankId) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.getBankById, {'id': bankId});
      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        Map<String, dynamic>? bankData;

        if (response.data is Map<String, dynamic>) {
          bankData =
              response.data['bank'] ??
              response.data['data'] ??
              response.data['bankAccount'] ??
              response.data['result'] ??
              response.data;
        }

        if (bankData != null && bankData['_id'] != null) {
          return bankData;
        }
        return null;
      }
      return null;
    } catch (e) {
      print('Error in getBankById: $e');
      return null;
    }
  }

  // Create new bank account
  // In the createBankAccount method
  Future<bool> createBankAccount(Map<String, dynamic> bankAccountData) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Change 'accountId' to 'account' as per API expectation
      final dataWithAccountId = {...bankAccountData, 'account': _accountId};

      final response = await _dio.post(
        ApiUrls.createBank,
        data: dataWithAccountId,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchBankAccounts();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to create bank account',
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

  // Similarly in the updateBankAccount method
  Future<bool> updateBankAccount(
    String bankId,
    Map<String, dynamic> bankAccountData,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final url = ApiUrls.replaceParams(ApiUrls.updateBank, {'id': bankId});

      // Add account parameter for update as well
      final dataWithAccount = {...bankAccountData, 'account': _accountId};

      final response = await _dio.put(url, data: dataWithAccount);

      if (response.statusCode == 200) {
        await fetchBankAccounts();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update bank account',
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

  // Delete bank account
  Future<bool> deleteBankAccount(String bankId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final url = ApiUrls.replaceParams(ApiUrls.deleteBank, {'id': bankId});

      final response = await _dio.delete(url);

      if (response.statusCode == 200) {
        // Refresh the list after successful deletion
        await fetchBankAccounts();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to delete bank account',
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

  // Clear selected bank account
  void clearSelectedBankAccount() {
    state = state.copyWith(selectedBankAccount: null);
  }

  // Debug method to manually set bank accounts (for testing)
  void setBankAccountsManually(List<Map<String, dynamic>> bankAccounts) {
    state = state.copyWith(
      bankAccounts: bankAccounts,
      isLoading: false,
      error: null,
    );
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

// Bank Account Provider
final bankAccountProvider =
    StateNotifierProvider<BankAccountNotifier, BankAccountState>((ref) {
      final dio = ref.watch(dioProvider);
      return BankAccountNotifier(dio, ref);
    });

// Auto-fetch provider that watches auth state changes
final bankAccountAutoFetchProvider = Provider<void>((ref) {
  final authState = ref.watch(authProvider);
  final bankAccountNotifier = ref.read(bankAccountProvider.notifier);

  // Auto-fetch when user becomes authenticated and has accountId
  if (authState.isAuthenticated && authState.accountId != null) {
    Future.microtask(() => bankAccountNotifier.fetchBankAccounts());
  }
});

// Provider for getting a specific bank account by ID
final getBankByIdProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, bankId) async {
      final bankAccountNotifier = ref.read(bankAccountProvider.notifier);
      return await bankAccountNotifier.getBankById(bankId);
    });
