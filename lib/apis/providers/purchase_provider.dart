
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:Wareozo/apis/core/dio_provider.dart';
import 'package:Wareozo/apis/core/api_urls.dart';
import 'package:Wareozo/apis/providers/auth_provider.dart';

// Date range presets enum (reusing from sales)
enum PurchaseDateRangePreset {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  fyQ1,
  fyQ2,
  fyQ3,
  fyQ4,
  thisFYYear,
  lastFYYear,
  custom
}

// Purchase filter model with comprehensive filters
class PurchaseFilter {
  final String supplier;
  final String status;
  final String voucherType;
  final DateTime startDate;
  final DateTime endDate;
  final int limit;
  final String searchQuery;
  final PurchaseDateRangePreset dateRangePreset;

  const PurchaseFilter({
    this.supplier = 'all',
    this.status = 'all',
    this.voucherType = 'all',
    required this.startDate,
    required this.endDate,
    this.limit = 10,
    this.searchQuery = '',
    this.dateRangePreset = PurchaseDateRangePreset.thisFYYear,
  });

  PurchaseFilter copyWith({
    String? supplier,
    String? status,
    String? voucherType,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    String? searchQuery,
    PurchaseDateRangePreset? dateRangePreset,
  }) {
    return PurchaseFilter(
      supplier: supplier ?? this.supplier,
      status: status ?? this.status,
      voucherType: voucherType ?? this.voucherType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      limit: limit ?? this.limit,
      searchQuery: searchQuery ?? this.searchQuery,
      dateRangePreset: dateRangePreset ?? this.dateRangePreset,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'start': startDate.toIso8601String(),
      'end': endDate.toIso8601String(),
      'limit': limit.toString(),
    };

    if (voucherType != 'all') {
      params['voucherType'] = voucherType;
    }

    if (status != 'all') {
      params['status'] = status;
    }

    if (supplier != 'all') {
      params['filter'] = supplier;
    }

    return params;
  }
}

// Supplier/Vendor model for filters
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

// Purchase filter options model with predefined options
class PurchaseFilterOptions {
  final List<SupplierOption> suppliers;
  final List<String> statuses;
  final List<String> voucherTypes;
  final List<PurchaseDateRangeOption> dateRangeOptions;

  const PurchaseFilterOptions({
    this.suppliers = const [],
    this.statuses = const [
      'all',
      'DRAFT',
      'PENDING',
      'INVOICED',
      'PARTIALLY_PAID',
      'PAID',
      'OVER_PAID',
      'PENDING,PARTIALLY_PAID', // Outstanding
    ],
    this.voucherTypes = const [
      'all',
      'Purchase Invoice',
      'Purchase Order',
      'Debit Note',
      'Purchase Return',
    ],
    this.dateRangeOptions = const [
      PurchaseDateRangeOption(label: 'Today', value: PurchaseDateRangePreset.today),
      PurchaseDateRangeOption(label: 'Yesterday', value: PurchaseDateRangePreset.yesterday),
      PurchaseDateRangeOption(label: 'This Week', value: PurchaseDateRangePreset.thisWeek),
      PurchaseDateRangeOption(label: 'Last Week', value: PurchaseDateRangePreset.lastWeek),
      PurchaseDateRangeOption(label: 'This Month', value: PurchaseDateRangePreset.thisMonth),
      PurchaseDateRangeOption(label: 'Last Month', value: PurchaseDateRangePreset.lastMonth),
      PurchaseDateRangeOption(label: 'FY Q1 (Apr - Jun)', value: PurchaseDateRangePreset.fyQ1),
      PurchaseDateRangeOption(label: 'FY Q2 (Jul - Sept)', value: PurchaseDateRangePreset.fyQ2),
      PurchaseDateRangeOption(label: 'FY Q3 (Oct - Dec)', value: PurchaseDateRangePreset.fyQ3),
      PurchaseDateRangeOption(label: 'FY Q4 (Jan - Mar)', value: PurchaseDateRangePreset.fyQ4),
      PurchaseDateRangeOption(label: 'This FY Year (Apr - Mar)', value: PurchaseDateRangePreset.thisFYYear),
      PurchaseDateRangeOption(label: 'Last FY Year (Apr - Mar)', value: PurchaseDateRangePreset.lastFYYear),
      PurchaseDateRangeOption(label: 'Custom Date', value: PurchaseDateRangePreset.custom),
    ],
  });

  PurchaseFilterOptions copyWith({
    List<SupplierOption>? suppliers,
    List<String>? statuses,
    List<String>? voucherTypes,
    List<PurchaseDateRangeOption>? dateRangeOptions,
  }) {
    return PurchaseFilterOptions(
      suppliers: suppliers ?? this.suppliers,
      statuses: statuses ?? this.statuses,
      voucherTypes: voucherTypes ?? this.voucherTypes,
      dateRangeOptions: dateRangeOptions ?? this.dateRangeOptions,
    );
  }
}

// Purchase date range option model
class PurchaseDateRangeOption {
  final String label;
  final PurchaseDateRangePreset value;

  const PurchaseDateRangeOption({required this.label, required this.value});
}

// Purchase status option model with labels
class PurchaseStatusOption {
  final String label;
  final String value;

  const PurchaseStatusOption({required this.label, required this.value});

  static const List<PurchaseStatusOption> statusOptions = [
    PurchaseStatusOption(label: 'All', value: 'all'),
    PurchaseStatusOption(label: 'Draft', value: 'DRAFT'),
    PurchaseStatusOption(label: 'Pending', value: 'PENDING'),
    PurchaseStatusOption(label: 'Invoiced', value: 'INVOICED'),
    PurchaseStatusOption(label: 'Partially Paid', value: 'PARTIALLY_PAID'),
    PurchaseStatusOption(label: 'Paid', value: 'PAID'),
    PurchaseStatusOption(label: 'Over Paid', value: 'OVER_PAID'),
    PurchaseStatusOption(label: 'Outstanding', value: 'PENDING,PARTIALLY_PAID'),
  ];
}

// Purchase voucher type option model
class PurchaseVoucherTypeOption {
  final String label;
  final String value;

  const PurchaseVoucherTypeOption({required this.label, required this.value});

  static const List<PurchaseVoucherTypeOption> purchaseVoucherTypes = [
    PurchaseVoucherTypeOption(label: 'Select Voucher', value: 'all'),
    PurchaseVoucherTypeOption(label: 'Purchase Invoice', value: 'Purchase Invoice'),
    PurchaseVoucherTypeOption(label: 'Purchase Order', value: 'Purchase Order'),
    PurchaseVoucherTypeOption(label: 'Debit Note', value: 'Debit Note'),
    PurchaseVoucherTypeOption(label: 'Purchase Return', value: 'Purchase Return'),
  ];
}

// Purchase dashboard numbers model
class PurchaseDashboardNumbers {
  final double totalInvoicesAmount;
  final double totalReceivedOrPaid;
  final double totalUnpaid;
  final double totalQuotationOrPOAmount;
  final double totalDeliveryNoteAmount;

  const PurchaseDashboardNumbers({
    this.totalInvoicesAmount = 0.0,
    this.totalReceivedOrPaid = 0.0,
    this.totalUnpaid = 0.0,
    this.totalQuotationOrPOAmount = 0.0,
    this.totalDeliveryNoteAmount = 0.0,
  });

  factory PurchaseDashboardNumbers.fromJson(Map<String, dynamic> json) {
    return PurchaseDashboardNumbers(
      totalInvoicesAmount: (json['totalInvoicesAmount'] ?? 0.0).toDouble(),
      totalReceivedOrPaid: (json['totalReceivedOrPaid'] ?? 0.0).toDouble(),
      totalUnpaid: (json['totalUnpaid'] ?? 0.0).toDouble(),
      totalQuotationOrPOAmount: (json['totalQuotationOrPOAmount'] ?? 0.0).toDouble(),
      totalDeliveryNoteAmount: (json['totalDeliveryNoteAmount'] ?? 0.0).toDouble(),
    );
  }
}

// Purchase state
class PurchaseState {
  final bool isLoading;
  final List<Map<String, dynamic>> invoices;
  final int total;
  final PurchaseDashboardNumbers dashboardNumbers;
  final String? error;
  final PurchaseFilter filter;
  final PurchaseFilterOptions filterOptions;
  final bool isLoadingFilters;

  const PurchaseState({
    this.isLoading = false,
    this.invoices = const [],
    this.total = 0,
    this.dashboardNumbers = const PurchaseDashboardNumbers(),
    this.error,
    required this.filter,
    this.filterOptions = const PurchaseFilterOptions(),
    this.isLoadingFilters = false,
  });

  PurchaseState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? invoices,
    int? total,
    PurchaseDashboardNumbers? dashboardNumbers,
    String? error,
    PurchaseFilter? filter,
    PurchaseFilterOptions? filterOptions,
    bool? isLoadingFilters,
  }) {
    return PurchaseState(
      isLoading: isLoading ?? this.isLoading,
      invoices: invoices ?? this.invoices,
      total: total ?? this.total,
      dashboardNumbers: dashboardNumbers ?? this.dashboardNumbers,
      error: error,
      filter: filter ?? this.filter,
      filterOptions: filterOptions ?? this.filterOptions,
      isLoadingFilters: isLoadingFilters ?? this.isLoadingFilters,
    );
  }
}

// Utility class for financial year calculations (reusing from sales)
class PurchaseFinancialYearUtils {
  static Map<String, DateTime> getFinancialYearDates() {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // Financial year starts from April
    final fyStartYear = currentMonth >= 4 ? currentYear : currentYear - 1;
    final fyEndYear = fyStartYear + 1;

    return {
      'startDateFY': DateTime(fyStartYear, 4, 1),
      'endDateFY': DateTime(fyEndYear, 3, 31),
    };
  }

  static Map<String, DateTime> getLastFinancialYearDates() {
    final fyDates = getFinancialYearDates();
    final startDateFY = fyDates['startDateFY']!;
    final endDateFY = fyDates['endDateFY']!;

    return {
      'startDateLastFY': DateTime(startDateFY.year - 1, 4, 1),
      'endDateLastFY': DateTime(endDateFY.year - 1, 3, 31),
    };
  }

  static Map<String, DateTime> getDateRangeForPreset(PurchaseDateRangePreset preset) {
    final now = DateTime.now();
    final fyDates = getFinancialYearDates();
    final startDateFY = fyDates['startDateFY']!;
    final endDateFY = fyDates['endDateFY']!;

    switch (preset) {
      case PurchaseDateRangePreset.today:
        return {'startDate': now, 'endDate': now};
      
      case PurchaseDateRangePreset.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        return {'startDate': yesterday, 'endDate': yesterday};
      
      case PurchaseDateRangePreset.thisWeek:
        final startOfWeek = now.subtract(Duration(days: 7));
        return {'startDate': startOfWeek, 'endDate': now};
      
      case PurchaseDateRangePreset.lastWeek:
        final endOfLastWeek = now.subtract(const Duration(days: 7));
        final startOfLastWeek = now.subtract(const Duration(days: 14));
        return {'startDate': startOfLastWeek, 'endDate': endOfLastWeek};
      
      case PurchaseDateRangePreset.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        return {'startDate': startOfMonth, 'endDate': endOfMonth};
      
      case PurchaseDateRangePreset.lastMonth:
        final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
        final endOfLastMonth = DateTime(now.year, now.month, 0);
        return {'startDate': startOfLastMonth, 'endDate': endOfLastMonth};
      
      case PurchaseDateRangePreset.fyQ1:
        final qStartDate = DateTime(startDateFY.year, 4, 1); // Apr
        final qEndDate = DateTime(startDateFY.year, 6, 30); // Jun
        return {'startDate': qStartDate, 'endDate': qEndDate};
      
      case PurchaseDateRangePreset.fyQ2:
        final qStartDate = DateTime(startDateFY.year, 7, 1); // Jul
        final qEndDate = DateTime(startDateFY.year, 9, 30); // Sep
        return {'startDate': qStartDate, 'endDate': qEndDate};
      
      case PurchaseDateRangePreset.fyQ3:
        final qStartDate = DateTime(startDateFY.year, 10, 1); // Oct
        final qEndDate = DateTime(startDateFY.year, 12, 31); // Dec
        return {'startDate': qStartDate, 'endDate': qEndDate};
      
      case PurchaseDateRangePreset.fyQ4:
        final qStartDate = DateTime(endDateFY.year, 1, 1); // Jan
        final qEndDate = DateTime(endDateFY.year, 3, 31); // Mar
        return {'startDate': qStartDate, 'endDate': qEndDate};
      
      case PurchaseDateRangePreset.thisFYYear:
        return {'startDate': startDateFY, 'endDate': endDateFY};
      
      case PurchaseDateRangePreset.lastFYYear:
        final lastFYDates = getLastFinancialYearDates();
        return {
          'startDate': lastFYDates['startDateLastFY']!,
          'endDate': lastFYDates['endDateLastFY']!
        };
      
      case PurchaseDateRangePreset.custom:
        return {'startDate': now, 'endDate': now};
    }
  }
}

// Purchase notifier
class PurchaseNotifier extends StateNotifier<PurchaseState> {
  final Dio _dio;
  final Ref _ref;

  PurchaseNotifier(this._dio, this._ref) : super(_getInitialState());

  static PurchaseState _getInitialState() {
    final fyDates = PurchaseFinancialYearUtils.getFinancialYearDates();
    return PurchaseState(
      filter: PurchaseFilter(
        startDate: fyDates['startDateFY']!,
        endDate: fyDates['endDateFY']!,
      ),
    );
  }

  // Fetch filter options from API
  Future<void> fetchFilterOptions() async {
    final authState = _ref.read(authProvider);

    if (!authState.isAuthenticated || 
        authState.token == null || 
        authState.accountId == null) {
      return;
    }

    state = state.copyWith(isLoadingFilters: true);

    try {
      // Build the URL with account ID
      final purchaseUrl = ApiUrls.replaceParams(
        ApiUrls.purchaseList,
        {'accountId': authState.accountId!},
      );

      // First, fetch a basic purchase list to extract unique suppliers
      final response = await _dio.get(
        purchaseUrl,
        queryParameters: {
          'start': PurchaseFinancialYearUtils.getFinancialYearDates()['startDateFY']!.toIso8601String(),
          'end': PurchaseFinancialYearUtils.getFinancialYearDates()['endDateFY']!.toIso8601String(),
          'voucherType': 'all',
          'limit': '1000', // Get more records for better filter options
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final invoices = data['invoices'] as List<dynamic>? ?? [];

        // Extract unique suppliers with their IDs and names
        final Map<String, String> suppliersMap = {};

        for (var invoice in invoices) {
          // Extract supplier information
          final supplier = invoice['supplier'] ?? invoice['client'];
          if (supplier != null) {
            final supplierId = supplier['_id'];
            final supplierName = supplier['name'] ?? supplier['displayName'];
            if (supplierId != null &&
                supplierName != null &&
                supplierId.toString().isNotEmpty &&
                supplierName.toString().isNotEmpty) {
              suppliersMap[supplierId.toString()] = supplierName.toString();
            }
          }
        }

        // Convert suppliers map to list of SupplierOption
        final List<SupplierOption> supplierOptions = suppliersMap.entries
            .map((entry) => SupplierOption(id: entry.key, name: entry.value))
            .toList();

        // Sort suppliers by name
        supplierOptions.sort((a, b) => a.name.compareTo(b.name));

        final filterOptions = PurchaseFilterOptions(
          suppliers: supplierOptions,
        );

        state = state.copyWith(
          isLoadingFilters: false,
          filterOptions: filterOptions,
        );
      } else {
        state = state.copyWith(isLoadingFilters: false);
      }
    } on DioException catch (e) {
      print('Error fetching purchase filter options: $e');
      state = state.copyWith(isLoadingFilters: false);
    } catch (e) {
      print('Unexpected error fetching purchase filter options: $e');
      state = state.copyWith(isLoadingFilters: false);
    }
  }

  // Fetch purchases with current filter
  Future<void> fetchPurchases() async {
    final authState = _ref.read(authProvider);

    if (!authState.isAuthenticated || 
        authState.token == null || 
        authState.accountId == null) {
      state = state.copyWith(error: 'Not authenticated');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Build the URL with account ID
      final purchaseUrl = ApiUrls.replaceParams(
        ApiUrls.purchaseList,
        {'accountId': authState.accountId!},
      );

      final queryParams = state.filter.toQueryParameters();

      final response = await _dio.get(
        purchaseUrl,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final invoices = data['invoices'] as List<dynamic>? ?? [];
        final total = data['total'] as int? ?? 0;
        final dashboardNumbers = data['dashboardNumbers'] != null
            ? PurchaseDashboardNumbers.fromJson(data['dashboardNumbers'])
            : const PurchaseDashboardNumbers();

        state = state.copyWith(
          isLoading: false,
          invoices: invoices.cast<Map<String, dynamic>>(),
          total: total,
          dashboardNumbers: dashboardNumbers,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch purchases: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to fetch purchases';

      if (e.response != null) {
        switch (e.response!.statusCode) {
          case 401:
            errorMessage = 'Unauthorized access';
            break;
          case 403:
            errorMessage = 'Access forbidden';
            break;
          case 404:
            errorMessage = 'Purchases not found';
            break;
          case 500:
            errorMessage = 'Server error';
            break;
          default:
            errorMessage = 'Failed to fetch purchases';
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

  // Update filter and fetch purchases
  Future<void> updateFilter(PurchaseFilter newFilter) async {
    state = state.copyWith(filter: newFilter);
    await fetchPurchases();
  }

  // Quick filter methods
  Future<void> filterByVoucherType(String voucherType) async {
    final newFilter = state.filter.copyWith(voucherType: voucherType);
    await updateFilter(newFilter);
  }

  Future<void> filterByStatus(String status) async {
    final newFilter = state.filter.copyWith(status: status);
    await updateFilter(newFilter);
  }

  Future<void> filterBySupplier(String supplierId) async {
    final newFilter = state.filter.copyWith(supplier: supplierId);
    await updateFilter(newFilter);
  }

  Future<void> filterBySearchQuery(String query) async {
    final newFilter = state.filter.copyWith(searchQuery: query);
    await updateFilter(newFilter);
  }

  Future<void> filterByDateRange(DateTime startDate, DateTime endDate) async {
    final newFilter = state.filter.copyWith(
      startDate: startDate,
      endDate: endDate,
      dateRangePreset: PurchaseDateRangePreset.custom,
    );
    await updateFilter(newFilter);
  }

  Future<void> filterByDateRangePreset(PurchaseDateRangePreset preset) async {
    final dateRange = PurchaseFinancialYearUtils.getDateRangeForPreset(preset);
    final newFilter = state.filter.copyWith(
      startDate: dateRange['startDate']!,
      endDate: dateRange['endDate']!,
      dateRangePreset: preset,
    );
    await updateFilter(newFilter);
  }

  Future<void> setLimit(int limit) async {
    final newFilter = state.filter.copyWith(limit: limit);
    await updateFilter(newFilter);
  }

  // Preset date range filter methods
  Future<void> filterByToday() async {
    await filterByDateRangePreset(PurchaseDateRangePreset.today);
  }

  Future<void> filterByYesterday() async {
    await filterByDateRangePreset(PurchaseDateRangePreset.yesterday);
  }

  Future<void> filterByThisWeek() async {
    await filterByDateRangePreset(PurchaseDateRangePreset.thisWeek);
  }

  Future<void> filterByLastWeek() async {
    await filterByDateRangePreset(PurchaseDateRangePreset.lastWeek);
  }

  Future<void> filterByThisMonth() async {
    await filterByDateRangePreset(PurchaseDateRangePreset.thisMonth);
  }

  Future<void> filterByLastMonth() async {
    await filterByDateRangePreset(PurchaseDateRangePreset.lastMonth);
  }

  Future<void> filterByFYQ1() async {
    await filterByDateRangePreset(PurchaseDateRangePreset.fyQ1);
  }

  Future<void> filterByFYQ2() async {
    await filterByDateRangePreset(PurchaseDateRangePreset.fyQ2);
  }

  Future<void> filterByFYQ3() async {
    await filterByDateRangePreset(PurchaseDateRangePreset.fyQ3);
  }

  Future<void> filterByFYQ4() async {
    await filterByDateRangePreset(PurchaseDateRangePreset.fyQ4);
  }

  Future<void> filterByThisFYYear() async {
    await filterByDateRangePreset(PurchaseDateRangePreset.thisFYYear);
  }

  Future<void> filterByLastFYYear() async {
    await filterByDateRangePreset(PurchaseDateRangePreset.lastFYYear);
  }

  // Reset filters to default (This FY Year)
  Future<void> resetFilters() async {
    final fyDates = PurchaseFinancialYearUtils.getFinancialYearDates();
    final defaultFilter = PurchaseFilter(
      startDate: fyDates['startDateFY']!,
      endDate: fyDates['endDateFY']!,
      dateRangePreset: PurchaseDateRangePreset.thisFYYear,
    );
    await updateFilter(defaultFilter);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Get specific invoice by ID
  Future<Map<String, dynamic>?> getInvoiceById(String invoiceId) async {
    try {
      final invoice = state.invoices.firstWhere(
        (invoice) => invoice['_id'] == invoiceId,
      );
      return invoice;
    } catch (e) {
      // If not found in current list, you might want to fetch from API
      return null;
    }
  }

  // Get invoices by status
  List<Map<String, dynamic>> getInvoicesByStatus(String status) {
    return state.invoices
        .where((invoice) => 
            invoice['status'] == status || 
            invoice['displayStatus'] == status)
        .toList();
  }

  // Get invoices by voucher type
  List<Map<String, dynamic>> getInvoicesByVoucherType(String voucherType) {
    if (voucherType == 'all') return state.invoices;
    return state.invoices
        .where((invoice) => invoice['voucherType'] == voucherType)
        .toList();
  }

  // Search invoices by query
  List<Map<String, dynamic>> searchInvoices(String query) {
    if (query.isEmpty) return state.invoices;
    
    return state.invoices.where((invoice) {
      final invoiceNumber = invoice['invoiceNumber']?.toString().toLowerCase() ?? '';
      final supplierName = invoice['supplier']?['name']?.toString().toLowerCase() ?? '';
      final queryLower = query.toLowerCase();
      
      return invoiceNumber.contains(queryLower) || supplierName.contains(queryLower);
    }).toList();
  }
}

// Purchase provider
final purchaseProvider = StateNotifierProvider<PurchaseNotifier, PurchaseState>((ref) {
  final dio = ref.watch(dioProvider);
  return PurchaseNotifier(dio, ref);
});

// Helper provider to get filtered purchases
final filteredPurchasesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final purchaseState = ref.watch(purchaseProvider);
  return purchaseState.invoices;
});

// Helper provider to check if purchases are loading
final purchaseLoadingProvider = Provider<bool>((ref) {
  final purchaseState = ref.watch(purchaseProvider);
  return purchaseState.isLoading;
});

// Helper provider to get purchase error
final purchaseErrorProvider = Provider<String?>((ref) {
  final purchaseState = ref.watch(purchaseProvider);
  return purchaseState.error;
});

// Helper provider to get purchase filter options
final purchaseFilterOptionsProvider = Provider<PurchaseFilterOptions>((ref) {
  final purchaseState = ref.watch(purchaseProvider);
  return purchaseState.filterOptions;
});

// Helper provider to get supplier options with ALL option
final purchaseSupplierOptionsProvider = Provider<List<Map<String, String>>>((ref) {
  final filterOptions = ref.watch(purchaseFilterOptionsProvider);
  final List<Map<String, String>> options = [
    {'id': 'all', 'name': 'All'},
  ];

  for (final supplier in filterOptions.suppliers) {
    options.add({'id': supplier.id, 'name': supplier.name});
  }

  return options;
});

// Helper provider to get status options
final purchaseStatusOptionsProvider = Provider<List<PurchaseStatusOption>>((ref) {
  return PurchaseStatusOption.statusOptions;
});

// Helper provider to get voucher type options
final purchaseVoucherTypeOptionsProvider = Provider<List<PurchaseVoucherTypeOption>>((ref) {
  return PurchaseVoucherTypeOption.purchaseVoucherTypes;
});

// Helper provider to get date range options
final purchaseDateRangeOptionsProvider = Provider<List<PurchaseDateRangeOption>>((ref) {
  final filterOptions = ref.watch(purchaseFilterOptionsProvider);
  return filterOptions.dateRangeOptions;
});

// Helper provider to get dashboard numbers
final purchaseDashboardProvider = Provider<PurchaseDashboardNumbers>((ref) {
  final purchaseState = ref.watch(purchaseProvider);
  return purchaseState.dashboardNumbers;
});

// Helper provider to get total count
final purchaseTotalProvider = Provider<int>((ref) {
  final purchaseState = ref.watch(purchaseProvider);
  return purchaseState.total;
});

// Helper provider to get current filter
final purchaseCurrentFilterProvider = Provider<PurchaseFilter>((ref) {
  final purchaseState = ref.watch(purchaseProvider);
  return purchaseState.filter;
});

// Helper provider to get invoices by status
final pendingPurchasesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final purchaseState = ref.watch(purchaseProvider);
  return purchaseState.invoices
      .where((invoice) => 
          invoice['status'] == 'PENDING' || 
          invoice['displayStatus'] == 'PENDING')
      .toList();
});

final paidPurchasesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final purchaseState = ref.watch(purchaseProvider);
  return purchaseState.invoices
      .where((invoice) => 
          invoice['status'] == 'PAID' || 
          invoice['displayStatus'] == 'PAID')
      .toList();
});

final partiallyPaidPurchasesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final purchaseState = ref.watch(purchaseProvider);
  return purchaseState.invoices
      .where((invoice) => 
          invoice['status'] == 'PARTIALLY_PAID' || 
          invoice['displayStatus'] == 'PARTIALLY_PAID')
      .toList();
});

final draftPurchasesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final purchaseState = ref.watch(purchaseProvider);
  return purchaseState.invoices
      .where((invoice) => 
          invoice['status'] == 'DRAFT' || 
          invoice['displayStatus'] == 'DRAFT')
      .toList();
});

final outstandingPurchasesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final purchaseState = ref.watch(purchaseProvider);
  return purchaseState.invoices
      .where((invoice) => 
          invoice['status'] == 'PENDING' || 
          invoice['status'] == 'PARTIALLY_PAID' ||
          invoice['displayStatus'] == 'PENDING' ||
          invoice['displayStatus'] == 'PARTIALLY_PAID')
      .toList();
});

// Helper provider to get voucher type counts
final purchaseVoucherTypeCountsProvider = Provider<Map<String, int>>((ref) {
  final purchaseState = ref.watch(purchaseProvider);
  final Map<String, int> counts = {};
  
  for (final invoice in purchaseState.invoices) {
    final voucherType = invoice['voucherType'] ?? 'Unknown';
    counts[voucherType] = (counts[voucherType] ?? 0) + 1;
  }
  
  return counts;
});

// Helper provider to get status counts
final purchaseStatusCountsProvider = Provider<Map<String, int>>((ref) {
  final purchaseState = ref.watch(purchaseProvider);
  final Map<String, int> counts = {};
  
  for (final invoice in purchaseState.invoices) {
    final status = invoice['status'] ?? invoice['displayStatus'] ?? 'Unknown';
    counts[status] = (counts[status] ?? 0) + 1;
  }
  
  return counts;
});

// Helper provider to search invoices
final searchPurchasesProvider = Provider.family<List<Map<String, dynamic>>, String>((ref, query) {
  final purchaseState = ref.watch(purchaseProvider);
  
  if (query.isEmpty) return purchaseState.invoices;
  
  return purchaseState.invoices.where((invoice) {
    final invoiceNumber = invoice['invoiceNumber']?.toString().toLowerCase() ?? '';
    final supplierName = invoice['supplier']?['name']?.toString().toLowerCase() ?? '';
    final queryLower = query.toLowerCase();
    
    return invoiceNumber.contains(queryLower) || supplierName.contains(queryLower);
  }).toList();
});