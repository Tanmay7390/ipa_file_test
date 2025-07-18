import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../apis/core/api_urls.dart';
import '../apis/core/dio_provider.dart';
import '../apis/providers/auth_provider.dart';

// TDS Tax Rate model
class TDSRate {
  final String id;
  final String taxName;
  final String taxSection;
  final double taxRate;
  final String taxType;

  const TDSRate({
    required this.id,
    required this.taxName,
    required this.taxSection,
    required this.taxRate,
    required this.taxType,
  });

  factory TDSRate.fromJson(Map<String, dynamic> json) {
    return TDSRate(
      id: json['_id'] ?? '',
      taxName: json['taxName'] ?? '',
      taxSection: json['taxSection'] ?? '',
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
      taxType: json['taxType'] ?? '',
    );
  }
}

// Payment state model
class PaymentState {
  final bool isLoading;
  final bool isLoadingInvoices;
  final bool isLoadingTDS;
  final String? error;
  final List<dynamic> payments;
  final List<dynamic> invoices;
  final List<dynamic> customers;
  final List<dynamic> bankAccounts;
  final List<TDSRate> tdsRates;
  final Map<String, dynamic>? selectedInvoice;
  final bool paymentSuccess;
  final PaymentFilter filter;
  final PaymentFilterOptions filterOptions;

  const PaymentState({
    this.isLoading = false,
    this.isLoadingInvoices = false,
    this.isLoadingTDS = false,
    this.error,
    this.payments = const [],
    this.invoices = const [],
    this.customers = const [],
    this.bankAccounts = const [],
    this.tdsRates = const [],
    this.selectedInvoice,
    this.paymentSuccess = false,
    this.filter = const PaymentFilter(),
    this.filterOptions = const PaymentFilterOptions(),
  });

  PaymentState copyWith({
    bool? isLoading,
    bool? isLoadingInvoices,
    bool? isLoadingTDS,
    String? error,
    List<dynamic>? payments,
    List<dynamic>? invoices,
    List<dynamic>? customers,
    List<dynamic>? bankAccounts,
    List<TDSRate>? tdsRates,
    Map<String, dynamic>? selectedInvoice,
    bool? paymentSuccess,
    PaymentFilter? filter,
    PaymentFilterOptions? filterOptions,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingInvoices: isLoadingInvoices ?? this.isLoadingInvoices,
      isLoadingTDS: isLoadingTDS ?? this.isLoadingTDS,
      error: error,
      payments: payments ?? this.payments,
      invoices: invoices ?? this.invoices,
      customers: customers ?? this.customers,
      bankAccounts: bankAccounts ?? this.bankAccounts,
      tdsRates: tdsRates ?? this.tdsRates,
      selectedInvoice: selectedInvoice,
      paymentSuccess: paymentSuccess ?? this.paymentSuccess,
      filter: filter ?? this.filter,
      filterOptions: filterOptions ?? this.filterOptions,
    );
  }
}

// Payment filter models (existing)
class PaymentFilter {
  final String buyer;
  final String status;
  final double fromAmountRange;
  final double toAmountRange;
  final int startDate;
  final int endDate;

  const PaymentFilter({
    this.buyer = 'ALL',
    this.status = 'ALL',
    this.fromAmountRange = 0,
    this.toAmountRange = 99999,
    this.startDate = 0,
    this.endDate = 0,
  });
}

class PaymentFilterOptions {
  final List<BuyerOption> buyers;

  const PaymentFilterOptions({this.buyers = const []});
}

class BuyerOption {
  final String id;
  final String name;

  const BuyerOption({required this.id, required this.name});
}

// Payment notifier
class PaymentNotifier extends StateNotifier<PaymentState> {
  final Dio _dio;
  final String? _accountId;

  PaymentNotifier(this._dio, this._accountId) : super(const PaymentState()) {
    // Initialize by loading data if account ID is available
    if (_accountId != null) {
      _initializeData();
    }
  }

  // Initialize data in background
  Future<void> _initializeData() async {
    fetchAllCustomers();
    fetchBankAccounts();
    fetchPendingInvoices();
    fetchFilterOptions();
    fetchTDSRates();
  }

  // Fetch TDS tax rates
  Future<void> fetchTDSRates() async {
    state = state.copyWith(isLoadingTDS: true);

    try {
      final response = await _dio.get(ApiUrls.getTaxRates);

      if (response.statusCode == 200) {
        final taxRates = response.data['taxRates'] as List<dynamic>? ?? [];

        // Filter only TDS rates
        final tdsRates = taxRates
            .where((rate) => rate['taxType'] == 'tds')
            .map((rate) => TDSRate.fromJson(rate))
            .toList();

        state = state.copyWith(isLoadingTDS: false, tdsRates: tdsRates);
      } else {
        state = state.copyWith(
          isLoadingTDS: false,
          error: 'Failed to load TDS rates',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingTDS: false,
        error: 'Error loading TDS rates: ${e.toString()}',
      );
    }
  }

  // Validate payment amount against selected invoices
  String? validatePaymentAmount(
    double amount,
    List<Map<String, dynamic>> selectedInvoices,
  ) {
    if (selectedInvoices.isEmpty) {
      return null; // No validation needed if no invoices selected
    }

    double totalInvoiceAmount = 0.0;
    for (var invoice in selectedInvoices) {
      totalInvoiceAmount += _getValidNumber(invoice['balanceAmount']);
    }

    if (amount < totalInvoiceAmount) {
      return 'Payment amount cannot be less than total invoice amount (₹${totalInvoiceAmount.toStringAsFixed(2)})';
    }

    return null;
  }

  // Existing methods (fetchPayments, fetchFilterOptions, etc.) remain the same...

  // Fetch payment list
  Future<void> fetchPayments() async {
    if (_accountId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dio.get(
        ApiUrls.paymenInList,
        queryParameters: {
          'buyer': state.filter.buyer,
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
        queryParameters: {'name': '', 'searchFor': 'buyer'},
      );

      if (response.statusCode == 200) {
        final customers = response.data['customers'] as List<dynamic>? ?? [];
        final buyers = customers.map((customer) {
          return BuyerOption(
            id: customer['_id'] ?? '',
            name: customer['name'] ?? '',
          );
        }).toList();

        state = state.copyWith(
          filterOptions: PaymentFilterOptions(buyers: buyers),
        );
      }
    } catch (e) {
      // Handle error silently for filter options
    }
  }

  // Update filter
  void updateFilter(PaymentFilter newFilter) {
    state = state.copyWith(filter: newFilter);
    fetchPayments();
  }

  // Reset filters
  void resetFilters() {
    final now = DateTime.now();
    final newFilter = PaymentFilter(
      buyer: 'ALL',
      status: 'ALL',
      fromAmountRange: 0,
      toAmountRange: 99999,
      startDate: now.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
      endDate: now.millisecondsSinceEpoch,
    );
    state = state.copyWith(filter: newFilter);
    fetchPayments();
  }

  // Fetch pending invoices
  Future<void> fetchPendingInvoices() async {
    if (_accountId == null) return;

    try {
      final url = ApiUrls.replaceParams(ApiUrls.invoiceList, {
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

  // Fetch all customers
  Future<void> fetchAllCustomers() async {
    if (_accountId == null) return;

    try {
      final url = ApiUrls.replaceParams(ApiUrls.customerSearch, {
        'accountId': _accountId,
      });

      final response = await _dio.get(
        url,
        queryParameters: {'name': '', 'searchFor': 'buyer'},
      );

      if (response.statusCode == 200) {
        state = state.copyWith(customers: response.data['customers'] ?? []);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Fetch sales invoices for a specific customer
  Future<void> fetchCustomerInvoices(String customerId) async {
    if (_accountId == null) return;

    state = state.copyWith(isLoadingInvoices: true, error: null);

    try {
      final url = ApiUrls.replaceParams(ApiUrls.salesList, {
        'accountId': _accountId,
      });

      final response = await _dio.get(
        url,
        queryParameters: {
          'filter': customerId,
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
          error: 'Failed to load customer invoices',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoadingInvoices: false, error: e.toString());
    }
  }

  // Search customers
  Future<void> searchCustomers(String query) async {
    if (_accountId == null) return;

    try {
      final url = ApiUrls.replaceParams(ApiUrls.customerSearch, {
        'accountId': _accountId,
      });

      final response = await _dio.get(
        url,
        queryParameters: {'name': query, 'searchFor': 'buyer'},
      );

      if (response.statusCode == 200) {
        state = state.copyWith(customers: response.data['customers'] ?? []);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Fetch bank accounts
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

  // Search bank accounts
  Future<void> searchBankAccounts(String query) async {
    if (_accountId == null) return;

    try {
      final url = ApiUrls.replaceParams(ApiUrls.bankList, {
        'accountId': _accountId,
      });

      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final allBankAccounts = response.data['banks'] as List<dynamic>? ?? [];

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

  // Create new payment with per-invoice TDS support
  Future<bool> createPayment({
    required String paymentFrom,
    required String paymentDate,
    required double amount,
    required String paymentMode,
    required String toBankAccount,
    String? fromBankAccount,
    String? instrumentId,
    String? instrumentDate,
    List<String>? invoices,
    String? ref1,
    String? ref2,
    String? remark,
    TDSRate? tdsRate, // Kept for backward compatibility but not used
    double? tdsAmount,
    bool isAdvancePayment = false,
  }) async {
    if (_accountId == null) return false;

    state = state.copyWith(isLoading: true, error: null, paymentSuccess: false);

    try {
      final now = DateTime.now();
      final currentTimestamp = now.millisecondsSinceEpoch;
      final paymentDateTime = DateTime.parse(paymentDate);

      // Create payment data with TDS information
      final data = {
        'account': _accountId,
        'paymentDate': paymentDateTime.millisecondsSinceEpoch,
        'amount': amount.toInt(),
        'appliedFlag': !isAdvancePayment,
        'bankClearingDate': currentTimestamp,
        'bankDepositDate': currentTimestamp,
        'currency': '62a4b0ceb628fb10ac97ce0e',
        'entryDate': currentTimestamp,
        'fromBankAccount': fromBankAccount ?? '',
        'instrument': paymentMode,
        'instrumentDate': paymentDateTime.millisecondsSinceEpoch,
        'instrumentId': instrumentId?.isNotEmpty == true
            ? instrumentId
            : currentTimestamp.toString(),
        'invoices': invoices ?? [],
        'paymentFrom': paymentFrom,
        'paymentMode': paymentMode,
        'paymentStatus': 'RECEIVED',
        'ref1': ref1 ?? '',
        'ref2': ref2 ?? '',
        'remark': remark ?? '',
        'toBankAccount': toBankAccount,
        // Add TDS information if available
        'tds': {
          'apply': (tdsAmount ?? 0.0) > 0.0,
          'totalAmount': (tdsAmount ?? 0.0).toStringAsFixed(2),
          'taxableAmount': amount,
        },
      };

      final response = await _dio.post(ApiUrls.addPaymentReceipt, data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchPayments();
        fetchPendingInvoices();
        state = state.copyWith(isLoading: false, paymentSuccess: true);
        return true;
      } else {
        throw DioException(
          requestOptions: RequestOptions(path: ApiUrls.addPaymentReceipt),
          response: response,
        );
      }
    } catch (e) {
      String errorMessage = 'Payment creation failed';

      if (e is DioException && e.response?.data != null) {
        try {
          if (e.response!.data is Map<String, dynamic>) {
            final responseData = e.response!.data as Map<String, dynamic>;
            errorMessage =
                responseData['message']?.toString() ??
                responseData['error']?.toString() ??
                'Server error: ${e.response?.statusCode}';
          }
        } catch (parseError) {
          errorMessage = 'Error parsing server response';
        }
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
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

// Payment provider
final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  final authState = ref.watch(authProvider);
  final accountId = authState.accountId;

  return PaymentNotifier(dio, accountId);
});

// Payment mode provider
final paymentModeProvider = StateProvider<String>((ref) => 'CASH');
