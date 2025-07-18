// lib/providers/payment_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:Wareozo/apis/core/dio_provider.dart';
import 'package:Wareozo/apis/core/api_urls.dart';
import 'package:Wareozo/apis/providers/auth_provider.dart';

// Payment filter model (for Payment In)
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
    this.toAmountRange = 999999,
    required this.startDate,
    required this.endDate,
  });

  PaymentFilter copyWith({
    String? buyer,
    String? status,
    double? fromAmountRange,
    double? toAmountRange,
    int? startDate,
    int? endDate,
  }) {
    return PaymentFilter(
      buyer: buyer ?? this.buyer,
      status: status ?? this.status,
      fromAmountRange: fromAmountRange ?? this.fromAmountRange,
      toAmountRange: toAmountRange ?? this.toAmountRange,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return {
      'buyer': buyer,
      'status': status,
      'fromAmountRange': fromAmountRange.toString(),
      'toAmountRange': toAmountRange.toString(),
      'startDate': startDate.toString(),
      'endDate': endDate.toString(),
    };
  }
}

// Payment Out filter model (for Payment Out)
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
    this.toAmountRange = 999999,
    required this.startDate,
    required this.endDate,
  });

  PaymentOutFilter copyWith({
    String? supplier,
    String? status,
    double? fromAmountRange,
    double? toAmountRange,
    int? startDate,
    int? endDate,
  }) {
    return PaymentOutFilter(
      supplier: supplier ?? this.supplier,
      status: status ?? this.status,
      fromAmountRange: fromAmountRange ?? this.fromAmountRange,
      toAmountRange: toAmountRange ?? this.toAmountRange,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return {
      'supplier': supplier,
      'status': status,
      'fromAmountRange': fromAmountRange.toString(),
      'toAmountRange': toAmountRange.toString(),
      'startDate': startDate.toString(),
      'endDate': endDate.toString(),
    };
  }
}

// Buyer model for filters
class BuyerOption {
  final String id;
  final String name;

  const BuyerOption({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuyerOption &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

// Supplier model for filters
class SupplierOption {
  final String id;
  final String name;

  const SupplierOption({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplierOption &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

// Filter options model (for Payment In)
class FilterOptions {
  final List<BuyerOption> buyers;
  final List<String> statuses;
  final List<String> paymentModes;

  const FilterOptions({
    this.buyers = const [],
    this.statuses = const ['FULLY_APPLIED', 'PARTIALLY_APPLIED', 'UNAPPLIED'],
    this.paymentModes = const [],
  });

  FilterOptions copyWith({
    List<BuyerOption>? buyers,
    List<String>? statuses,
    List<String>? paymentModes,
  }) {
    return FilterOptions(
      buyers: buyers ?? this.buyers,
      statuses: statuses ?? this.statuses,
      paymentModes: paymentModes ?? this.paymentModes,
    );
  }
}

// Filter options model (for Payment Out)
class FilterOutOptions {
  final List<SupplierOption> suppliers;
  final List<String> statuses;
  final List<String> paymentModes;

  const FilterOutOptions({
    this.suppliers = const [],
    this.statuses = const ['FULLY_APPLIED', 'PARTIALLY_APPLIED', 'UNAPPLIED'],
    this.paymentModes = const [],
  });

  FilterOutOptions copyWith({
    List<SupplierOption>? suppliers,
    List<String>? statuses,
    List<String>? paymentModes,
  }) {
    return FilterOutOptions(
      suppliers: suppliers ?? this.suppliers,
      statuses: statuses ?? this.statuses,
      paymentModes: paymentModes ?? this.paymentModes,
    );
  }
}

// Payment state (for Payment In)
class PaymentState {
  final bool isLoading;
  final List<Map<String, dynamic>> payments;
  final String? error;
  final PaymentFilter filter;
  final FilterOptions filterOptions;
  final bool isLoadingFilters;

  const PaymentState({
    this.isLoading = false,
    this.payments = const [],
    this.error,
    required this.filter,
    this.filterOptions = const FilterOptions(),
    this.isLoadingFilters = false,
  });

  PaymentState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? payments,
    String? error,
    PaymentFilter? filter,
    FilterOptions? filterOptions,
    bool? isLoadingFilters,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      payments: payments ?? this.payments,
      error: error,
      filter: filter ?? this.filter,
      filterOptions: filterOptions ?? this.filterOptions,
      isLoadingFilters: isLoadingFilters ?? this.isLoadingFilters,
    );
  }
}

// Payment Out state
class PaymentOutState {
  final bool isLoading;
  final List<Map<String, dynamic>> payments;
  final String? error;
  final PaymentOutFilter filter;
  final FilterOutOptions filterOptions;
  final bool isLoadingFilters;

  const PaymentOutState({
    this.isLoading = false,
    this.payments = const [],
    this.error,
    required this.filter,
    this.filterOptions = const FilterOutOptions(),
    this.isLoadingFilters = false,
  });

  PaymentOutState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? payments,
    String? error,
    PaymentOutFilter? filter,
    FilterOutOptions? filterOptions,
    bool? isLoadingFilters,
  }) {
    return PaymentOutState(
      isLoading: isLoading ?? this.isLoading,
      payments: payments ?? this.payments,
      error: error,
      filter: filter ?? this.filter,
      filterOptions: filterOptions ?? this.filterOptions,
      isLoadingFilters: isLoadingFilters ?? this.isLoadingFilters,
    );
  }
}

// Payment notifier (for Payment In)
class PaymentNotifier extends StateNotifier<PaymentState> {
  final Dio _dio;
  final Ref _ref;

  PaymentNotifier(this._dio, this._ref)
    : super(
        PaymentState(
          filter: PaymentFilter(
            startDate: DateTime.now()
                .subtract(const Duration(days: 365))
                .millisecondsSinceEpoch,
            endDate: DateTime.now().millisecondsSinceEpoch,
          ),
        ),
      );

  // Fetch filter options from API
  Future<void> fetchFilterOptions() async {
    final authState = _ref.read(authProvider);

    if (!authState.isAuthenticated || authState.token == null) {
      return;
    }

    state = state.copyWith(isLoadingFilters: true);

    try {
      // First, fetch a basic payment list to extract unique buyers and payment modes
      final response = await _dio.get(
        ApiUrls.paymenInList,
        queryParameters: {
          'buyer': 'ALL',
          'status': 'ALL',
          'fromAmountRange': '0',
          'toAmountRange': '99999999',
          'startDate': DateTime.now()
              .subtract(const Duration(days: 365))
              .millisecondsSinceEpoch
              .toString(),
          'endDate': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final payments = data['payments'] as List<dynamic>? ?? [];

        // Extract unique buyers with their IDs and names
        final Map<String, String> buyersMap = {};
        final Set<String> paymentModesSet = {};

        for (var payment in payments) {
          final paymentFrom = payment['paymentFrom'];
          if (paymentFrom != null) {
            final buyerId = paymentFrom['_id'];
            final buyerName = paymentFrom['name'];
            if (buyerId != null &&
                buyerName != null &&
                buyerId.toString().isNotEmpty &&
                buyerName.toString().isNotEmpty) {
              buyersMap[buyerId.toString()] = buyerName.toString();
            }
          }

          final paymentMode = payment['paymentMode'];
          if (paymentMode != null && paymentMode.toString().isNotEmpty) {
            paymentModesSet.add(paymentMode.toString());
          }
        }

        // Convert buyers map to list of BuyerOption
        final List<BuyerOption> buyerOptions = buyersMap.entries
            .map((entry) => BuyerOption(id: entry.key, name: entry.value))
            .toList();

        // Sort buyers by name
        buyerOptions.sort((a, b) => a.name.compareTo(b.name));

        final filterOptions = FilterOptions(
          buyers: buyerOptions,
          paymentModes: paymentModesSet.toList()..sort(),
        );

        state = state.copyWith(
          isLoadingFilters: false,
          filterOptions: filterOptions,
        );
      } else {
        state = state.copyWith(isLoadingFilters: false);
      }
    } on DioException catch (e) {
      print('Error fetching filter options: $e');
      state = state.copyWith(isLoadingFilters: false);
    } catch (e) {
      print('Unexpected error fetching filter options: $e');
      state = state.copyWith(isLoadingFilters: false);
    }
  }

  // Fetch payments with current filter
  Future<void> fetchPayments() async {
    final authState = _ref.read(authProvider);

    if (!authState.isAuthenticated || authState.token == null) {
      state = state.copyWith(error: 'Not authenticated');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final queryParams = state.filter.toQueryParameters();

      final response = await _dio.get(
        ApiUrls.paymenInList,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final payments = data['payments'] as List<dynamic>? ?? [];

        state = state.copyWith(
          isLoading: false,
          payments: payments.cast<Map<String, dynamic>>(),
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch payments: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to fetch payments';

      if (e.response != null) {
        switch (e.response!.statusCode) {
          case 401:
            errorMessage = 'Unauthorized access';
            break;
          case 403:
            errorMessage = 'Access forbidden';
            break;
          case 404:
            errorMessage = 'Payments not found';
            break;
          case 500:
            errorMessage = 'Server error';
            break;
          default:
            errorMessage = 'Failed to fetch payments';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Request timeout';
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  // Update filter and fetch payments
  Future<void> updateFilter(PaymentFilter newFilter) async {
    state = state.copyWith(filter: newFilter);
    await fetchPayments();
  }

  // Quick filter methods
  Future<void> filterByStatus(String status) async {
    final newFilter = state.filter.copyWith(status: status);
    await updateFilter(newFilter);
  }

  Future<void> filterByBuyer(String buyerId) async {
    final newFilter = state.filter.copyWith(buyer: buyerId);
    await updateFilter(newFilter);
  }

  Future<void> filterByAmountRange(double fromAmount, double toAmount) async {
    final newFilter = state.filter.copyWith(
      fromAmountRange: fromAmount,
      toAmountRange: toAmount,
    );
    await updateFilter(newFilter);
  }

  Future<void> filterByDateRange(DateTime startDate, DateTime endDate) async {
    final newFilter = state.filter.copyWith(
      startDate: startDate.millisecondsSinceEpoch,
      endDate: endDate.millisecondsSinceEpoch,
    );
    await updateFilter(newFilter);
  }

  // Reset filters to default
  Future<void> resetFilters() async {
    final defaultFilter = PaymentFilter(
      startDate: DateTime.now()
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch,
      endDate: DateTime.now().millisecondsSinceEpoch,
    );
    await updateFilter(defaultFilter);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Payment Out notifier
class PaymentOutNotifier extends StateNotifier<PaymentOutState> {
  final Dio _dio;
  final Ref _ref;

  PaymentOutNotifier(this._dio, this._ref)
    : super(
        PaymentOutState(
          filter: PaymentOutFilter(
            startDate: DateTime.now()
                .subtract(const Duration(days: 365))
                .millisecondsSinceEpoch,
            endDate: DateTime.now().millisecondsSinceEpoch,
          ),
        ),
      );

  // Fetch filter options from API
  Future<void> fetchFilterOptions() async {
    final authState = _ref.read(authProvider);

    if (!authState.isAuthenticated || authState.token == null) {
      return;
    }

    state = state.copyWith(isLoadingFilters: true);

    try {
      // First, fetch a basic payment out list to extract unique suppliers and payment modes
      final response = await _dio.get(
        ApiUrls.paymenOutList,
        queryParameters: {
          'supplier': 'ALL',
          'status': 'ALL',
          'fromAmountRange': '0',
          'toAmountRange': '99999999',
          'startDate': DateTime.now()
              .subtract(const Duration(days: 365))
              .millisecondsSinceEpoch
              .toString(),
          'endDate': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final payments = data['payments'] as List<dynamic>? ?? [];

        // Extract unique suppliers with their IDs and names
        final Map<String, String> suppliersMap = {};
        final Set<String> paymentModesSet = {};

        for (var payment in payments) {
          final paymentTo = payment['paymentTo'];
          if (paymentTo != null) {
            final supplierId = paymentTo['_id'];
            final supplierName = paymentTo['name'];
            if (supplierId != null &&
                supplierName != null &&
                supplierId.toString().isNotEmpty &&
                supplierName.toString().isNotEmpty) {
              suppliersMap[supplierId.toString()] = supplierName.toString();
            }
          }

          final paymentMode = payment['paymentMode'];
          if (paymentMode != null && paymentMode.toString().isNotEmpty) {
            paymentModesSet.add(paymentMode.toString());
          }
        }

        // Convert suppliers map to list of SupplierOption
        final List<SupplierOption> supplierOptions = suppliersMap.entries
            .map((entry) => SupplierOption(id: entry.key, name: entry.value))
            .toList();

        // Sort suppliers by name
        supplierOptions.sort((a, b) => a.name.compareTo(b.name));

        final filterOptions = FilterOutOptions(
          suppliers: supplierOptions,
          paymentModes: paymentModesSet.toList()..sort(),
        );

        state = state.copyWith(
          isLoadingFilters: false,
          filterOptions: filterOptions,
        );
      } else {
        state = state.copyWith(isLoadingFilters: false);
      }
    } on DioException catch (e) {
      print('Error fetching filter options: $e');
      state = state.copyWith(isLoadingFilters: false);
    } catch (e) {
      print('Unexpected error fetching filter options: $e');
      state = state.copyWith(isLoadingFilters: false);
    }
  }

  // Fetch payments with current filter
  Future<void> fetchPayments() async {
    final authState = _ref.read(authProvider);

    if (!authState.isAuthenticated || authState.token == null) {
      state = state.copyWith(error: 'Not authenticated');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final queryParams = state.filter.toQueryParameters();

      final response = await _dio.get(
        ApiUrls.paymenOutList,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final payments = data['payments'] as List<dynamic>? ?? [];

        state = state.copyWith(
          isLoading: false,
          payments: payments.cast<Map<String, dynamic>>(),
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch payment out: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to fetch payment out';

      if (e.response != null) {
        switch (e.response!.statusCode) {
          case 401:
            errorMessage = 'Unauthorized access';
            break;
          case 403:
            errorMessage = 'Access forbidden';
            break;
          case 404:
            errorMessage = 'Payment out not found';
            break;
          case 500:
            errorMessage = 'Server error';
            break;
          default:
            errorMessage = 'Failed to fetch payment out';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Request timeout';
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  // Update filter and fetch payments
  Future<void> updateFilter(PaymentOutFilter newFilter) async {
    state = state.copyWith(filter: newFilter);
    await fetchPayments();
  }

  // Quick filter methods
  Future<void> filterByStatus(String status) async {
    final newFilter = state.filter.copyWith(status: status);
    await updateFilter(newFilter);
  }

  Future<void> filterBySupplier(String supplierId) async {
    final newFilter = state.filter.copyWith(supplier: supplierId);
    await updateFilter(newFilter);
  }

  Future<void> filterByAmountRange(double fromAmount, double toAmount) async {
    final newFilter = state.filter.copyWith(
      fromAmountRange: fromAmount,
      toAmountRange: toAmount,
    );
    await updateFilter(newFilter);
  }

  Future<void> filterByDateRange(DateTime startDate, DateTime endDate) async {
    final newFilter = state.filter.copyWith(
      startDate: startDate.millisecondsSinceEpoch,
      endDate: endDate.millisecondsSinceEpoch,
    );
    await updateFilter(newFilter);
  }

  // Reset filters to default
  Future<void> resetFilters() async {
    final defaultFilter = PaymentOutFilter(
      startDate: DateTime.now()
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch,
      endDate: DateTime.now().millisecondsSinceEpoch,
    );
    await updateFilter(defaultFilter);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Payment provider (for Payment In)
final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return PaymentNotifier(dio, ref);
});

// Payment Out provider
final paymentOutProvider =
    StateNotifierProvider<PaymentOutNotifier, PaymentOutState>((ref) {
      final dio = ref.watch(dioProvider);
      return PaymentOutNotifier(dio, ref);
    });

// Helper provider to get filtered payments (Payment In)
final filteredPaymentsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final paymentState = ref.watch(paymentProvider);
  return paymentState.payments;
});

// Helper provider to get filtered payment out
final filteredPaymentOutProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final paymentOutState = ref.watch(paymentOutProvider);
  return paymentOutState.payments;
});

// Helper provider to check if payments are loading (Payment In)
final paymentsLoadingProvider = Provider<bool>((ref) {
  final paymentState = ref.watch(paymentProvider);
  return paymentState.isLoading;
});

// Helper provider to check if payment out are loading
final paymentOutLoadingProvider = Provider<bool>((ref) {
  final paymentOutState = ref.watch(paymentOutProvider);
  return paymentOutState.isLoading;
});

// Helper provider to get payment error (Payment In)
final paymentsErrorProvider = Provider<String?>((ref) {
  final paymentState = ref.watch(paymentProvider);
  return paymentState.error;
});

// Helper provider to get payment out error
final paymentOutErrorProvider = Provider<String?>((ref) {
  final paymentOutState = ref.watch(paymentOutProvider);
  return paymentOutState.error;
});

// Helper provider to get filter options (Payment In)
final filterOptionsProvider = Provider<FilterOptions>((ref) {
  final paymentState = ref.watch(paymentProvider);
  return paymentState.filterOptions;
});

// Helper provider to get filter out options
final filterOutOptionsProvider = Provider<FilterOutOptions>((ref) {
  final paymentOutState = ref.watch(paymentOutProvider);
  return paymentOutState.filterOptions;
});

// Helper provider to get buyer options with ALL option (Payment In)
final buyerOptionsProvider = Provider<List<Map<String, String>>>((ref) {
  final filterOptions = ref.watch(filterOptionsProvider);
  final List<Map<String, String>> options = [
    {'id': 'ALL', 'name': 'ALL'},
  ];

  for (final buyer in filterOptions.buyers) {
    options.add({'id': buyer.id, 'name': buyer.name});
  }

  return options;
});

// Helper provider to get supplier options with ALL option (Payment Out)
final supplierOptionsProvider = Provider<List<Map<String, String>>>((ref) {
  final filterOutOptions = ref.watch(filterOutOptionsProvider);
  final List<Map<String, String>> options = [
    {'id': 'ALL', 'name': 'ALL'},
  ];

  for (final supplier in filterOutOptions.suppliers) {
    options.add({'id': supplier.id, 'name': supplier.name});
  }

  return options;
});
