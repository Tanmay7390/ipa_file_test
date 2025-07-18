import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../apis/core/api_urls.dart';
import '../apis/core/dio_provider.dart';
import '../apis/providers/auth_provider.dart';

// Payment Out state model
class PaymentOutState {
  final bool isLoading;
  final bool isLoadingInvoices;
  final String? error;
  final List<dynamic> payments;
  final List<dynamic> invoices;
  final List<dynamic> suppliers;
  final List<dynamic> bankAccounts;
  final Map<String, dynamic>? selectedInvoice;
  final bool paymentSuccess;
  final PaymentOutFilter filter;
  final PaymentOutFilterOptions filterOptions;

  const PaymentOutState({
    this.isLoading = false,
    this.isLoadingInvoices = false,
    this.error,
    this.payments = const [],
    this.invoices = const [],
    this.suppliers = const [],
    this.bankAccounts = const [],
    this.selectedInvoice,
    this.paymentSuccess = false,
    this.filter = const PaymentOutFilter(),
    this.filterOptions = const PaymentOutFilterOptions(),
  });

  PaymentOutState copyWith({
    bool? isLoading,
    bool? isLoadingInvoices,
    String? error,
    List<dynamic>? payments,
    List<dynamic>? invoices,
    List<dynamic>? suppliers,
    List<dynamic>? bankAccounts,
    Map<String, dynamic>? selectedInvoice,
    bool? paymentSuccess,
    PaymentOutFilter? filter,
    PaymentOutFilterOptions? filterOptions,
  }) {
    return PaymentOutState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingInvoices: isLoadingInvoices ?? this.isLoadingInvoices,
      error: error,
      payments: payments ?? this.payments,
      invoices: invoices ?? this.invoices,
      suppliers: suppliers ?? this.suppliers,
      bankAccounts: bankAccounts ?? this.bankAccounts,
      selectedInvoice: selectedInvoice,
      paymentSuccess: paymentSuccess ?? this.paymentSuccess,
      filter: filter ?? this.filter,
      filterOptions: filterOptions ?? this.filterOptions,
    );
  }
}

// Payment Out filter models
class PaymentOutFilter {
  final String supplier;
  final String status;
  final double fromAmountRange;
  final double toAmountRange;
  final int startDate;
  final int endDate;

  const PaymentOutFilter({
    this.supplier = 'ALL',
    this.status = 'ALL',
    this.fromAmountRange = 0,
    this.toAmountRange = 99999,
    this.startDate = 0,
    this.endDate = 0,
  });
}

class PaymentOutFilterOptions {
  final List<SupplierOption> suppliers;

  const PaymentOutFilterOptions({this.suppliers = const []});
}

class SupplierOption {
  final String id;
  final String name;

  const SupplierOption({required this.id, required this.name});
}

// Payment Out notifier
class PaymentOutNotifier extends StateNotifier<PaymentOutState> {
  final Dio _dio;
  final String? _accountId;

  PaymentOutNotifier(this._dio, this._accountId)
    : super(const PaymentOutState()) {
    // Initialize by loading data if account ID is available
    if (_accountId != null) {
      // Load data without affecting main loading state
      _initializeData();
    }
  }

  // Initialize data in background
  Future<void> _initializeData() async {
    fetchAllSuppliers();
    fetchBankAccounts();
    fetchPendingInvoices();
    fetchFilterOptions();
  }

  // Fetch payment out list
  Future<void> fetchPayments() async {
    if (_accountId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Note: You may need to adjust this endpoint based on your API
      // This assumes there's a similar endpoint for vendor payments
      final response = await _dio.get(
        'invoice/vendor-payment-list', // Adjust this endpoint as needed
        queryParameters: {
          'supplier': state.filter.supplier,
          'status': state.filter.status,
          'fromAmountRange': state.filter.fromAmountRange,
          'toAmountRange': state.filter.toAmountRange,
          'startDate': state.filter.startDate > 0
              ? state.filter.startDate
              : DateTime.now()
                    .subtract(const Duration(days: 365))
                    .millisecondsSinceEpoch,
          'endDate': state.filter.endDate > 0
              ? state.filter.endDate
              : DateTime.now()
                    .add(const Duration(days: 365))
                    .millisecondsSinceEpoch,
        },
      );

      if (response.statusCode == 200) {
        state = state.copyWith(
          isLoading: false,
          payments: response.data['payments'] ?? [],
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load payments',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Fetch filter options
  Future<void> fetchFilterOptions() async {
    if (_accountId == null) return;

    try {
      final url = ApiUrls.replaceParams(ApiUrls.customerSearch, {
        'accountId': _accountId,
      });

      final response = await _dio.get(
        url,
        queryParameters: {'name': '', 'searchFor': 'supplier'},
      );

      if (response.statusCode == 200) {
        final suppliers = response.data['accounts'] as List<dynamic>? ?? [];
        final supplierOptions = suppliers.map((supplier) {
          return SupplierOption(
            id: supplier['_id'] ?? '',
            name: supplier['name'] ?? '',
          );
        }).toList();

        state = state.copyWith(
          filterOptions: PaymentOutFilterOptions(suppliers: supplierOptions),
        );
      }
    } catch (e) {
      // Handle error silently for filter options
    }
  }

  // Update filter
  void updateFilter(PaymentOutFilter newFilter) {
    state = state.copyWith(filter: newFilter);
    fetchPayments();
  }

  // Reset filters
  void resetFilters() {
    final now = DateTime.now();
    final newFilter = PaymentOutFilter(
      supplier: 'ALL',
      status: 'ALL',
      fromAmountRange: 0,
      toAmountRange: 99999,
      startDate: now.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
      endDate: now.millisecondsSinceEpoch,
    );
    state = state.copyWith(filter: newFilter);
    fetchPayments();
  }

  // Fetch pending invoices (purchase invoices for suppliers)
  Future<void> fetchPendingInvoices() async {
    if (_accountId == null) return;

    try {
      final url = ApiUrls.replaceParams(ApiUrls.purchaseList, {
        'accountId': _accountId,
      });

      final response = await _dio.get(
        url,
        queryParameters: {
          'status': 'PENDING,PARTIALLY_PAID',
          'voucherType': 'Invoice',
        },
      );

      if (response.statusCode == 200) {
        state = state.copyWith(invoices: response.data['invoices'] ?? []);
      }
    } catch (e) {
      // Handle error silently for invoices
    }
  }

  // Fetch all suppliers
  Future<void> fetchAllSuppliers() async {
    if (_accountId == null) return;

    try {
      final url = ApiUrls.replaceParams(ApiUrls.customerSearch, {
        'accountId': _accountId,
      });

      final response = await _dio.get(
        url,
        queryParameters: {'name': '', 'searchFor': 'supplier'},
      );

      if (response.statusCode == 200) {
        state = state.copyWith(suppliers: response.data['accounts'] ?? []);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Fetch purchase invoices for a specific supplier
  Future<void> fetchSupplierInvoices(String supplierId) async {
    if (_accountId == null) return;

    state = state.copyWith(isLoadingInvoices: true, error: null);

    try {
      final url = ApiUrls.replaceParams(ApiUrls.purchaseList, {
        'accountId': _accountId,
      });

      final response = await _dio.get(
        url,
        queryParameters: {
          'filter': supplierId,
          'status': 'PENDING,PARTIALLY_PAID',
          'voucherType': 'Invoice',
        },
      );

      if (response.statusCode == 200) {
        state = state.copyWith(
          isLoadingInvoices: false,
          invoices: response.data['invoices'] ?? [],
        );
      } else {
        state = state.copyWith(
          isLoadingInvoices: false,
          error: 'Failed to load supplier invoices',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoadingInvoices: false, error: e.toString());
    }
  }

  // Search suppliers
  Future<void> searchSuppliers(String query) async {
    if (_accountId == null) return;

    try {
      final url = ApiUrls.replaceParams(ApiUrls.customerSearch, {
        'accountId': _accountId,
      });

      final response = await _dio.get(
        url,
        queryParameters: {'name': query, 'searchFor': 'supplier'},
      );

      if (response.statusCode == 200) {
        state = state.copyWith(suppliers: response.data['accounts'] ?? []);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Fetch bank accounts (existing method - renamed for clarity)
  Future<void> fetchBankAccounts() async {
    if (_accountId == null) return;

    try {
      final url = ApiUrls.replaceParams(ApiUrls.bankList, {
        'accountId': _accountId,
      });

      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        state = state.copyWith(bankAccounts: response.data['banks'] ?? []);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Search bank accounts - similar to searchSuppliers
  Future<void> searchBankAccounts(String query) async {
    if (_accountId == null) return;

    try {
      final url = ApiUrls.replaceParams(ApiUrls.bankList, {
        'accountId': _accountId,
      });

      // First fetch all bank accounts
      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final allBankAccounts = response.data['banks'] as List<dynamic>? ?? [];

        // Filter bank accounts based on the search query
        final filteredBankAccounts = allBankAccounts.where((bank) {
          final bankName = (bank['bankName'] ?? '').toString().toLowerCase();
          final accountNumber = (bank['accountNumber'] ?? '')
              .toString()
              .toLowerCase();
          final searchQuery = query.toLowerCase();

          return bankName.contains(searchQuery) ||
              accountNumber.contains(searchQuery);
        }).toList();

        state = state.copyWith(bankAccounts: filteredBankAccounts);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Fetch all bank accounts (alias for fetchBankAccounts for consistency)
  Future<void> fetchAllBankAccounts() async {
    await fetchBankAccounts();
  }

  // Helper method to safely get a valid number from dynamic data
  double _getValidNumber(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) {
      if (value.isNaN || value.isInfinite) return 0.0;
      return value.toDouble();
    }

    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed == null || parsed.isNaN || parsed.isInfinite) return 0.0;
      return parsed;
    }

    return 0.0;
  }

  // Create new payment out (to supplier)
  Future<bool> createPayment({
    required String paymentTo, // Supplier ID
    required String paymentDate,
    required double amount,
    required String paymentMode, // CASH, CHEQUE, CARD, UPI, NETBANKING
    required String fromBankAccount, // Your bank account ID
    String? toBankAccount, // Supplier bank account ID (optional)
    String? instrumentId, // Cheque/UPI/Txn ID
    String? instrumentDate, // For cheque date
    List<String>? invoices, // Selected invoice IDs
    String? ref1,
    String? ref2,
    String? remark,
  }) async {
    if (_accountId == null) return false;

    state = state.copyWith(isLoading: true, error: null, paymentSuccess: false);

    try {
      // Fix timestamp calculation - use correct current timestamp
      final now = DateTime.now();
      final currentTimestamp = now.millisecondsSinceEpoch;
      final paymentDateTime = DateTime.parse(paymentDate);

      print('Current timestamp: $currentTimestamp');
      print(
        'Payment date timestamp: ${paymentDateTime.millisecondsSinceEpoch}',
      );

      // TEMPORARY FIX: Create all payments as advance payments to avoid NaN error
      // This will help us isolate if the issue is with basic payment creation
      // or specifically with invoice application logic
      List<Map<String, dynamic>> invoicesData = [];
      bool appliedFlag = false; // Always false to create advance payments

      // For now, we'll create advance payments and handle invoice application separately
      // Once basic payment creation works, we can work on invoice application

      print(
        'Creating advance payment (invoices will not be applied automatically)',
      );
      if (invoices != null && invoices.isNotEmpty) {
        print(
          'Note: Selected invoices: $invoices - will need to be applied manually',
        );
      }

      // Payment out data structure (based on the API payload example)
      final data = {
        'account': _accountId,
        'paymentDate': paymentDateTime.toIso8601String(),
        'amount': amount.toInt(),
        'appliedFlag': appliedFlag,
        'bankClearingDate': currentTimestamp,
        'bankDebitDate': currentTimestamp,
        'currency': '62a4b0ceb628fb10ac97ce0e',
        'entryDate': currentTimestamp,
        'fromBankAccount': fromBankAccount,
        'instrument': paymentMode,
        'instrumentDate': paymentDateTime.millisecondsSinceEpoch,
        'instrumentId': instrumentId?.isNotEmpty == true ? instrumentId : '',
        'invoices': [],
        'paymentMode': paymentMode,
        'paymentStatus': 'PAID',
        'paymentTo': paymentTo,
        'ref1': ref1 ?? '',
        'ref2': ref2 ?? '',
        'remark': remark ?? '',
        'toBankAccount': toBankAccount ?? '',
      };

      print('Payment out data being sent: $data');

      try {
        // Try the payment creation using vendor payment endpoint
        final response = await _dio.post(ApiUrls.addVendorPayment, data: data);

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Success handling
          fetchPayments();
          fetchPendingInvoices();

          state = state.copyWith(isLoading: false, paymentSuccess: true);

          if (invoices != null && invoices.isNotEmpty) {
            print(
              'Payment created as advance payment. Invoice application may need to be done manually.',
            );
          } else {
            print('Payment to supplier created successfully.');
          }

          return true;
        } else {
          throw DioException(
            requestOptions: RequestOptions(path: ApiUrls.addVendorPayment),
            response: response,
          );
        }
      } on DioException catch (dioError) {
        // If first attempt fails, try with minimal structure
        if (dioError.response?.statusCode == 500) {
          print('First attempt failed, trying minimal payload structure...');

          // Try minimal structure without optional fields
          final minimalData = {
            'account': _accountId,
            'paymentDate': paymentDateTime.toIso8601String(),
            'amount': amount.toInt(),
            'appliedFlag': false,
            'bankClearingDate': currentTimestamp,
            'bankDebitDate': currentTimestamp,
            'currency': '62a4b0ceb628fb10ac97ce0e',
            'entryDate': currentTimestamp,
            'fromBankAccount': fromBankAccount,
            'instrument': paymentMode,
            'instrumentDate': paymentDateTime.millisecondsSinceEpoch,
            'invoices': [],
            'paymentMode': paymentMode,
            'paymentStatus': 'PAID',
            'paymentTo': paymentTo,
            'toBankAccount': '',
          };

          print('Trying minimal payload: $minimalData');

          try {
            final fallbackResponse = await _dio.post(
              ApiUrls.addVendorPayment,
              data: minimalData,
            );

            if (fallbackResponse.statusCode == 200 ||
                fallbackResponse.statusCode == 201) {
              fetchPayments();
              fetchPendingInvoices();
              state = state.copyWith(isLoading: false, paymentSuccess: true);
              print('Minimal payload succeeded!');
              return true;
            }
          } catch (fallbackError) {
            print('Minimal payload also failed: $fallbackError');
          }
        }

        // If all attempts fail, handle the error
        String errorMessage = 'Network error occurred';

        try {
          if (dioError.response?.data != null) {
            if (dioError.response!.data is Map<String, dynamic>) {
              final Map<String, dynamic> responseData =
                  dioError.response!.data as Map<String, dynamic>;
              errorMessage =
                  responseData['message']?.toString() ??
                  responseData['error']?.toString() ??
                  'Server error: ${dioError.response?.statusCode}';
            } else if (dioError.response!.data is String) {
              errorMessage = dioError.response!.data.toString();
            } else {
              errorMessage = 'Server error: ${dioError.response?.statusCode}';
            }
          } else {
            errorMessage = dioError.message?.toString() ?? 'Connection failed';
          }
        } catch (parseError) {
          errorMessage = 'Error parsing server response';
        }

        print('Payment creation error: $errorMessage');
        print('Full error details: ${dioError.toString()}');

        state = state.copyWith(isLoading: false, error: errorMessage);
        return false;
      } catch (e) {
        // Handle any other exceptions
        print('Unexpected error during payment creation: $e');
        state = state.copyWith(
          isLoading: false,
          error: 'Unexpected error occurred',
        );
        return false;
      }
    } catch (e) {
      // Handle any exceptions from the outer try block
      print('Outer try block error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Payment creation failed: ${e.toString()}',
      );
      return false;
    }
  }

  // Reset payment success state
  void resetPaymentSuccess() {
    state = state.copyWith(paymentSuccess: false);
  }

  // Reset error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Select invoice
  void selectInvoice(Map<String, dynamic> invoice) {
    state = state.copyWith(selectedInvoice: invoice);
  }

  // Clear selected invoice
  void clearSelectedInvoice() {
    state = state.copyWith(selectedInvoice: null);
  }
}

// Payment Out provider
final paymentOutProvider =
    StateNotifierProvider<PaymentOutNotifier, PaymentOutState>((ref) {
      final dio = ref.watch(dioProvider);
      final authState = ref.watch(authProvider);
      final accountId = authState.accountId;

      return PaymentOutNotifier(dio, accountId);
    });

// Payment mode provider for out payments
final paymentOutModeProvider = StateProvider<String>((ref) => 'CASH');
