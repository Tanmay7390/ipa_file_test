// lib/providers/sales_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:Wareozo/apis/core/dio_provider.dart';
import 'package:Wareozo/apis/core/api_urls.dart';
import 'package:Wareozo/apis/providers/auth_provider.dart';

// Date range presets enum
enum DateRangePreset {
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
  custom,
}

// Sales filter model with comprehensive filters
class SalesFilter {
  final String buyer;
  final String status;
  final String voucherType;
  final DateTime startDate;
  final DateTime endDate;
  final int limit;
  final String searchQuery;
  final DateRangePreset dateRangePreset;

  const SalesFilter({
    this.buyer = 'all',
    this.status = 'all',
    this.voucherType = 'all',
    required this.startDate,
    required this.endDate,
    this.limit = 10,
    this.searchQuery = '',
    this.dateRangePreset = DateRangePreset.thisFYYear,
  });

  SalesFilter copyWith({
    String? buyer,
    String? status,
    String? voucherType,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    String? searchQuery,
    DateRangePreset? dateRangePreset,
  }) {
    return SalesFilter(
      buyer: buyer ?? this.buyer,
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

    // Fix: Use correct parameter names based on API
    if (voucherType != 'all' && voucherType.isNotEmpty) {
      params['voucherType'] = voucherType;
    }

    if (status != 'all' && status.isNotEmpty) {
      // Map status values to what the API expects
      if (status == 'DRAFT') {
        params['status'] = 'DRAFT';
      } else if (status == 'PENDING') {
        params['status'] = 'PENDING';
      } else if (status == 'PAID') {
        params['status'] = 'PAID';
      } else if (status == 'PARTIALLY_PAID') {
        params['status'] = 'PARTIALLY_PAID';
      } else if (status == 'PENDING,PARTIALLY_PAID') {
        params['status'] = 'PENDING,PARTIALLY_PAID';
      } else {
        params['status'] = status;
      }
    }

    if (buyer != 'all' && buyer.isNotEmpty) {
      params['buyer'] = buyer; // Use 'buyer' instead of 'filter'
    }

    if (searchQuery.isNotEmpty) {
      params['search'] = searchQuery;
    }

    return params;
  }
}

// Buyer/Customer model for filters
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

// Filter options model with predefined options
class SalesFilterOptions {
  final List<BuyerOption> buyers;
  final List<String> statuses;
  final List<String> voucherTypes;
  final List<DateRangeOption> dateRangeOptions;

  const SalesFilterOptions({
    this.buyers = const [],
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
      'Invoice',
      'Quotation',
      'Credit Note',
      'Delivery Note',
      'Proforma Invoice',
    ],
    this.dateRangeOptions = const [
      DateRangeOption(label: 'Today', value: DateRangePreset.today),
      DateRangeOption(label: 'Yesterday', value: DateRangePreset.yesterday),
      DateRangeOption(label: 'This Week', value: DateRangePreset.thisWeek),
      DateRangeOption(label: 'Last Week', value: DateRangePreset.lastWeek),
      DateRangeOption(label: 'This Month', value: DateRangePreset.thisMonth),
      DateRangeOption(label: 'Last Month', value: DateRangePreset.lastMonth),
      DateRangeOption(label: 'FY Q1 (Apr - Jun)', value: DateRangePreset.fyQ1),
      DateRangeOption(label: 'FY Q2 (Jul - Sept)', value: DateRangePreset.fyQ2),
      DateRangeOption(label: 'FY Q3 (Oct - Dec)', value: DateRangePreset.fyQ3),
      DateRangeOption(label: 'FY Q4 (Jan - Mar)', value: DateRangePreset.fyQ4),
      DateRangeOption(
        label: 'This FY Year (Apr - Mar)',
        value: DateRangePreset.thisFYYear,
      ),
      DateRangeOption(
        label: 'Last FY Year (Apr - Mar)',
        value: DateRangePreset.lastFYYear,
      ),
      DateRangeOption(label: 'Custom Date', value: DateRangePreset.custom),
    ],
  });

  SalesFilterOptions copyWith({
    List<BuyerOption>? buyers,
    List<String>? statuses,
    List<String>? voucherTypes,
    List<DateRangeOption>? dateRangeOptions,
  }) {
    return SalesFilterOptions(
      buyers: buyers ?? this.buyers,
      statuses: statuses ?? this.statuses,
      voucherTypes: voucherTypes ?? this.voucherTypes,
      dateRangeOptions: dateRangeOptions ?? this.dateRangeOptions,
    );
  }
}

// Date range option model
class DateRangeOption {
  final String label;
  final DateRangePreset value;

  const DateRangeOption({required this.label, required this.value});
}

// Status option model with labels
class StatusOption {
  final String label;
  final String value;

  const StatusOption({required this.label, required this.value});

  static const List<StatusOption> statusOptions = [
    StatusOption(label: 'All', value: 'all'),
    StatusOption(label: 'Draft', value: 'DRAFT'),
    StatusOption(label: 'Pending', value: 'PENDING'),
    StatusOption(label: 'Invoiced', value: 'INVOICED'),
    StatusOption(label: 'Partially Paid', value: 'PARTIALLY_PAID'),
    StatusOption(label: 'Paid', value: 'PAID'),
    StatusOption(label: 'Over Paid', value: 'OVER_PAID'),
    StatusOption(label: 'Outstanding', value: 'PENDING,PARTIALLY_PAID'),
  ];

  static const List<StatusOption> estimateStatusOptions = [
    StatusOption(label: 'All', value: 'all'),
    StatusOption(label: 'Draft', value: 'DRAFT'),
    StatusOption(label: 'Pending', value: 'PENDING'),
    StatusOption(label: 'Accepted', value: 'ACCEPTED'),
    StatusOption(label: 'Rejected', value: 'REJECTED'),
  ];
}

// Voucher type option model
class VoucherTypeOption {
  final String label;
  final String value;

  const VoucherTypeOption({required this.label, required this.value});

  static const List<VoucherTypeOption> saleVoucherTypes = [
    VoucherTypeOption(label: 'Select Voucher', value: 'all'),
    VoucherTypeOption(label: 'Invoice', value: 'Invoice'),
    VoucherTypeOption(label: 'Quotation', value: 'Quotation'),
    VoucherTypeOption(label: 'Credit Note', value: 'Credit Note'),
    VoucherTypeOption(label: 'Delivery Note', value: 'Delivery Note'),
    VoucherTypeOption(label: 'Proforma Invoice', value: 'Proforma Invoice'),
  ];

  static const List<VoucherTypeOption> purchaseVoucherTypes = [
    VoucherTypeOption(label: 'All', value: 'all'),
    VoucherTypeOption(label: 'Purchase Invoice', value: 'Purchase Invoice'),
    VoucherTypeOption(label: 'Purchase Order', value: 'Purchase Order'),
  ];
}

// Sales dashboard numbers model
class SalesDashboardNumbers {
  final double totalInvoicesAmount;
  final double totalReceivedOrPaid;
  final double totalUnpaid;
  final double totalQuotationOrPOAmount;
  final double totalDeliveryNoteAmount;

  const SalesDashboardNumbers({
    this.totalInvoicesAmount = 0.0,
    this.totalReceivedOrPaid = 0.0,
    this.totalUnpaid = 0.0,
    this.totalQuotationOrPOAmount = 0.0,
    this.totalDeliveryNoteAmount = 0.0,
  });

  factory SalesDashboardNumbers.fromJson(Map<String, dynamic> json) {
    return SalesDashboardNumbers(
      totalInvoicesAmount: (json['totalInvoicesAmount'] ?? 0.0).toDouble(),
      totalReceivedOrPaid: (json['totalReceivedOrPaid'] ?? 0.0).toDouble(),
      totalUnpaid: (json['totalUnpaid'] ?? 0.0).toDouble(),
      totalQuotationOrPOAmount: (json['totalQuotationOrPOAmount'] ?? 0.0)
          .toDouble(),
      totalDeliveryNoteAmount: (json['totalDeliveryNoteAmount'] ?? 0.0)
          .toDouble(),
    );
  }
}

// Sales state
class SalesState {
  final bool isLoading;
  final List<Map<String, dynamic>> invoices;
  final int total;
  final SalesDashboardNumbers dashboardNumbers;
  final String? error;
  final SalesFilter filter;
  final SalesFilterOptions filterOptions;
  final bool isLoadingFilters;

  const SalesState({
    this.isLoading = false,
    this.invoices = const [],
    this.total = 0,
    this.dashboardNumbers = const SalesDashboardNumbers(),
    this.error,
    required this.filter,
    this.filterOptions = const SalesFilterOptions(),
    this.isLoadingFilters = false,
  });

  SalesState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? invoices,
    int? total,
    SalesDashboardNumbers? dashboardNumbers,
    String? error,
    SalesFilter? filter,
    SalesFilterOptions? filterOptions,
    bool? isLoadingFilters,
  }) {
    return SalesState(
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

// Utility class for financial year calculations
class FinancialYearUtils {
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

  static Map<String, DateTime> getDateRangeForPreset(DateRangePreset preset) {
    final now = DateTime.now();
    final fyDates = getFinancialYearDates();
    final startDateFY = fyDates['startDateFY']!;
    final endDateFY = fyDates['endDateFY']!;

    switch (preset) {
      case DateRangePreset.today:
        return {'startDate': now, 'endDate': now};

      case DateRangePreset.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        return {'startDate': yesterday, 'endDate': yesterday};

      case DateRangePreset.thisWeek:
        final startOfWeek = now.subtract(Duration(days: 7));
        return {'startDate': startOfWeek, 'endDate': now};

      case DateRangePreset.lastWeek:
        final endOfLastWeek = now.subtract(const Duration(days: 7));
        final startOfLastWeek = now.subtract(const Duration(days: 14));
        return {'startDate': startOfLastWeek, 'endDate': endOfLastWeek};

      case DateRangePreset.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        return {'startDate': startOfMonth, 'endDate': endOfMonth};

      case DateRangePreset.lastMonth:
        final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
        final endOfLastMonth = DateTime(now.year, now.month, 0);
        return {'startDate': startOfLastMonth, 'endDate': endOfLastMonth};

      case DateRangePreset.fyQ1:
        final qStartDate = DateTime(startDateFY.year, 4, 1); // Apr
        final qEndDate = DateTime(startDateFY.year, 6, 30); // Jun
        return {'startDate': qStartDate, 'endDate': qEndDate};

      case DateRangePreset.fyQ2:
        final qStartDate = DateTime(startDateFY.year, 7, 1); // Jul
        final qEndDate = DateTime(startDateFY.year, 9, 30); // Sep
        return {'startDate': qStartDate, 'endDate': qEndDate};

      case DateRangePreset.fyQ3:
        final qStartDate = DateTime(startDateFY.year, 10, 1); // Oct
        final qEndDate = DateTime(startDateFY.year, 12, 31); // Dec
        return {'startDate': qStartDate, 'endDate': qEndDate};

      case DateRangePreset.fyQ4:
        final qStartDate = DateTime(endDateFY.year, 1, 1); // Jan
        final qEndDate = DateTime(endDateFY.year, 3, 31); // Mar
        return {'startDate': qStartDate, 'endDate': qEndDate};

      case DateRangePreset.thisFYYear:
        return {'startDate': startDateFY, 'endDate': endDateFY};

      case DateRangePreset.lastFYYear:
        final lastFYDates = getLastFinancialYearDates();
        return {
          'startDate': lastFYDates['startDateLastFY']!,
          'endDate': lastFYDates['endDateLastFY']!,
        };

      case DateRangePreset.custom:
        return {'startDate': now, 'endDate': now};
    }
  }
}

// Sales notifier
class SalesNotifier extends StateNotifier<SalesState> {
  final Dio _dio;
  final Ref _ref;

  SalesNotifier(this._dio, this._ref) : super(_getInitialState());

  static SalesState _getInitialState() {
    final fyDates = FinancialYearUtils.getFinancialYearDates();
    return SalesState(
      filter: SalesFilter(
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
      final salesUrl = ApiUrls.replaceParams(ApiUrls.salesList, {
        'accountId': authState.accountId!,
      });

      // First, fetch a basic sales list to extract unique buyers
      final response = await _dio.get(
        salesUrl,
        queryParameters: {
          'start': FinancialYearUtils.getFinancialYearDates()['startDateFY']!
              .toIso8601String(),
          'end': FinancialYearUtils.getFinancialYearDates()['endDateFY']!
              .toIso8601String(),
          'voucherType': 'all',
          'limit': '1000', // Get more records for better filter options
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final invoices = data['invoices'] as List<dynamic>? ?? [];

        // Extract unique buyers with their IDs and names
        final Map<String, String> buyersMap = {};

        for (var invoice in invoices) {
          // Extract buyer information
          final buyer = invoice['buyer'] ?? invoice['client'];
          if (buyer != null) {
            final buyerId = buyer['_id'];
            final buyerName = buyer['name'] ?? buyer['displayName'];
            if (buyerId != null &&
                buyerName != null &&
                buyerId.toString().isNotEmpty &&
                buyerName.toString().isNotEmpty) {
              buyersMap[buyerId.toString()] = buyerName.toString();
            }
          }
        }

        // Convert buyers map to list of BuyerOption
        final List<BuyerOption> buyerOptions = buyersMap.entries
            .map((entry) => BuyerOption(id: entry.key, name: entry.value))
            .toList();

        // Sort buyers by name
        buyerOptions.sort((a, b) => a.name.compareTo(b.name));

        final filterOptions = SalesFilterOptions(buyers: buyerOptions);

        state = state.copyWith(
          isLoadingFilters: false,
          filterOptions: filterOptions,
        );
      } else {
        state = state.copyWith(isLoadingFilters: false);
      }
    } on DioException catch (e) {
      print('Error fetching sales filter options: $e');
      state = state.copyWith(isLoadingFilters: false);
    } catch (e) {
      print('Unexpected error fetching sales filter options: $e');
      state = state.copyWith(isLoadingFilters: false);
    }
  }

  // Fetch sales with current filter
  Future<void> fetchSales() async {
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
      final salesUrl = ApiUrls.replaceParams(ApiUrls.salesList, {
        'accountId': authState.accountId!,
      });

      final queryParams = state.filter.toQueryParameters();
      print('Sales API Query Params: $queryParams'); // Debug log

      final response = await _dio.get(salesUrl, queryParameters: queryParams);

      print('Sales API Response Status: ${response.statusCode}'); // Debug log

      if (response.statusCode == 200) {
        final data = response.data;
        print('Sales API Response Data Keys: ${data.keys}'); // Debug log

        final invoices = data['invoices'] as List<dynamic>? ?? [];
        final total = data['total'] as int? ?? 0;
        final dashboardNumbers = data['dashboardNumbers'] != null
            ? SalesDashboardNumbers.fromJson(data['dashboardNumbers'])
            : const SalesDashboardNumbers();

        // Apply client-side filtering as a fallback
        List<Map<String, dynamic>> filteredInvoices = invoices
            .cast<Map<String, dynamic>>();

        // Apply status filter on client side if needed
        if (state.filter.status != 'all') {
          filteredInvoices = filteredInvoices.where((invoice) {
            final invoiceStatus =
                invoice['status']?.toString() ??
                invoice['displayStatus']?.toString() ??
                '';

            if (state.filter.status == 'PENDING,PARTIALLY_PAID') {
              return invoiceStatus == 'PENDING' ||
                  invoiceStatus == 'PARTIALLY_PAID';
            }

            return invoiceStatus.toUpperCase() ==
                state.filter.status.toUpperCase();
          }).toList();
        }

        // Apply voucher type filter on client side if needed
        if (state.filter.voucherType != 'all') {
          filteredInvoices = filteredInvoices.where((invoice) {
            final voucherType = invoice['voucherType']?.toString() ?? '';
            return voucherType.toUpperCase() ==
                state.filter.voucherType.toUpperCase();
          }).toList();
        }

        // Apply buyer filter on client side if needed
        if (state.filter.buyer != 'all') {
          filteredInvoices = filteredInvoices.where((invoice) {
            final buyerId =
                invoice['buyer']?['_id']?.toString() ??
                invoice['client']?['_id']?.toString() ??
                '';
            return buyerId == state.filter.buyer;
          }).toList();
        }

        print(
          'Filtered Invoices Count: ${filteredInvoices.length}',
        ); // Debug log

        state = state.copyWith(
          isLoading: false,
          invoices: filteredInvoices,
          total: filteredInvoices.length, // Use filtered count
          dashboardNumbers: dashboardNumbers,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch sales: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to fetch sales';
      print('DioException: $e'); // Debug log

      if (e.response != null) {
        switch (e.response!.statusCode) {
          case 401:
            errorMessage = 'Unauthorized access';
            break;
          case 403:
            errorMessage = 'Access forbidden';
            break;
          case 404:
            errorMessage = 'Sales not found';
            break;
          case 500:
            errorMessage = 'Server error';
            break;
          default:
            errorMessage = 'Failed to fetch sales';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Request timeout';
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
    } catch (e) {
      print('Unexpected error: $e'); // Debug log
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  // Update filter and fetch sales
  Future<void> updateFilter(SalesFilter newFilter) async {
    state = state.copyWith(filter: newFilter);
    await fetchSales();
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

  Future<void> filterByBuyer(String buyerId) async {
    final newFilter = state.filter.copyWith(buyer: buyerId);
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
      dateRangePreset: DateRangePreset.custom,
    );
    await updateFilter(newFilter);
  }

  Future<void> filterByDateRangePreset(DateRangePreset preset) async {
    final dateRange = FinancialYearUtils.getDateRangeForPreset(preset);
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
    await filterByDateRangePreset(DateRangePreset.today);
  }

  Future<void> filterByYesterday() async {
    await filterByDateRangePreset(DateRangePreset.yesterday);
  }

  Future<void> filterByThisWeek() async {
    await filterByDateRangePreset(DateRangePreset.thisWeek);
  }

  Future<void> filterByLastWeek() async {
    await filterByDateRangePreset(DateRangePreset.lastWeek);
  }

  Future<void> filterByThisMonth() async {
    await filterByDateRangePreset(DateRangePreset.thisMonth);
  }

  Future<void> filterByLastMonth() async {
    await filterByDateRangePreset(DateRangePreset.lastMonth);
  }

  Future<void> filterByFYQ1() async {
    await filterByDateRangePreset(DateRangePreset.fyQ1);
  }

  Future<void> filterByFYQ2() async {
    await filterByDateRangePreset(DateRangePreset.fyQ2);
  }

  Future<void> filterByFYQ3() async {
    await filterByDateRangePreset(DateRangePreset.fyQ3);
  }

  Future<void> filterByFYQ4() async {
    await filterByDateRangePreset(DateRangePreset.fyQ4);
  }

  Future<void> filterByThisFYYear() async {
    await filterByDateRangePreset(DateRangePreset.thisFYYear);
  }

  Future<void> filterByLastFYYear() async {
    await filterByDateRangePreset(DateRangePreset.lastFYYear);
  }

  // Reset filters to default (This FY Year)
  Future<void> resetFilters() async {
    final fyDates = FinancialYearUtils.getFinancialYearDates();
    final defaultFilter = SalesFilter(
      startDate: fyDates['startDateFY']!,
      endDate: fyDates['endDateFY']!,
      dateRangePreset: DateRangePreset.thisFYYear,
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
        .where(
          (invoice) =>
              invoice['status'] == status || invoice['displayStatus'] == status,
        )
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
      final invoiceNumber =
          invoice['invoiceNumber']?.toString().toLowerCase() ?? '';
      final buyerName =
          invoice['buyer']?['name']?.toString().toLowerCase() ?? '';
      final queryLower = query.toLowerCase();

      return invoiceNumber.contains(queryLower) ||
          buyerName.contains(queryLower);
    }).toList();
  }
}

// Sales provider
final salesProvider = StateNotifierProvider<SalesNotifier, SalesState>((ref) {
  final dio = ref.watch(dioProvider);
  return SalesNotifier(dio, ref);
});

// Helper provider to get filtered sales
final filteredSalesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final salesState = ref.watch(salesProvider);
  return salesState.invoices;
});

// Helper provider to check if sales are loading
final salesLoadingProvider = Provider<bool>((ref) {
  final salesState = ref.watch(salesProvider);
  return salesState.isLoading;
});

// Helper provider to get sales error
final salesErrorProvider = Provider<String?>((ref) {
  final salesState = ref.watch(salesProvider);
  return salesState.error;
});

// Helper provider to get sales filter options
final salesFilterOptionsProvider = Provider<SalesFilterOptions>((ref) {
  final salesState = ref.watch(salesProvider);
  return salesState.filterOptions;
});

// Helper provider to get buyer options with ALL option
final salesBuyerOptionsProvider = Provider<List<Map<String, String>>>((ref) {
  final filterOptions = ref.watch(salesFilterOptionsProvider);
  final List<Map<String, String>> options = [
    {'id': 'all', 'name': 'All'},
  ];

  for (final buyer in filterOptions.buyers) {
    options.add({'id': buyer.id, 'name': buyer.name});
  }

  return options;
});

// Helper provider to get status options
final salesStatusOptionsProvider = Provider<List<StatusOption>>((ref) {
  return StatusOption.statusOptions;
});

// Helper provider to get voucher type options
final salesVoucherTypeOptionsProvider = Provider<List<VoucherTypeOption>>((
  ref,
) {
  return VoucherTypeOption.saleVoucherTypes;
});

// Helper provider to get date range options
final salesDateRangeOptionsProvider = Provider<List<DateRangeOption>>((ref) {
  final filterOptions = ref.watch(salesFilterOptionsProvider);
  return filterOptions.dateRangeOptions;
});

// Helper provider to get dashboard numbers
final salesDashboardProvider = Provider<SalesDashboardNumbers>((ref) {
  final salesState = ref.watch(salesProvider);
  return salesState.dashboardNumbers;
});

// Helper provider to get total count
final salesTotalProvider = Provider<int>((ref) {
  final salesState = ref.watch(salesProvider);
  return salesState.total;
});

// Helper provider to get current filter
final salesCurrentFilterProvider = Provider<SalesFilter>((ref) {
  final salesState = ref.watch(salesProvider);
  return salesState.filter;
});

// Helper provider to get invoices by status
final pendingInvoicesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final salesState = ref.watch(salesProvider);
  return salesState.invoices
      .where(
        (invoice) =>
            invoice['status'] == 'PENDING' ||
            invoice['displayStatus'] == 'PENDING',
      )
      .toList();
});

final paidInvoicesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final salesState = ref.watch(salesProvider);
  return salesState.invoices
      .where(
        (invoice) =>
            invoice['status'] == 'PAID' || invoice['displayStatus'] == 'PAID',
      )
      .toList();
});

final partiallyPaidInvoicesProvider = Provider<List<Map<String, dynamic>>>((
  ref,
) {
  final salesState = ref.watch(salesProvider);
  return salesState.invoices
      .where(
        (invoice) =>
            invoice['status'] == 'PARTIALLY_PAID' ||
            invoice['displayStatus'] == 'PARTIALLY_PAID',
      )
      .toList();
});

final draftInvoicesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final salesState = ref.watch(salesProvider);
  return salesState.invoices
      .where(
        (invoice) =>
            invoice['status'] == 'DRAFT' || invoice['displayStatus'] == 'DRAFT',
      )
      .toList();
});

final outstandingInvoicesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final salesState = ref.watch(salesProvider);
  return salesState.invoices
      .where(
        (invoice) =>
            invoice['status'] == 'PENDING' ||
            invoice['status'] == 'PARTIALLY_PAID' ||
            invoice['displayStatus'] == 'PENDING' ||
            invoice['displayStatus'] == 'PARTIALLY_PAID',
      )
      .toList();
});

// Helper provider to get voucher type counts
final voucherTypeCountsProvider = Provider<Map<String, int>>((ref) {
  final salesState = ref.watch(salesProvider);
  final Map<String, int> counts = {};

  for (final invoice in salesState.invoices) {
    final voucherType = invoice['voucherType'] ?? 'Unknown';
    counts[voucherType] = (counts[voucherType] ?? 0) + 1;
  }

  return counts;
});

// Helper provider to get status counts
final statusCountsProvider = Provider<Map<String, int>>((ref) {
  final salesState = ref.watch(salesProvider);
  final Map<String, int> counts = {};

  for (final invoice in salesState.invoices) {
    final status = invoice['status'] ?? invoice['displayStatus'] ?? 'Unknown';
    counts[status] = (counts[status] ?? 0) + 1;
  }

  return counts;
});

// Helper provider to search invoices
final searchInvoicesProvider =
    Provider.family<List<Map<String, dynamic>>, String>((ref, query) {
      final salesState = ref.watch(salesProvider);

      if (query.isEmpty) return salesState.invoices;

      return salesState.invoices.where((invoice) {
        final invoiceNumber =
            invoice['invoiceNumber']?.toString().toLowerCase() ?? '';
        final buyerName =
            invoice['buyer']?['name']?.toString().toLowerCase() ?? '';
        final queryLower = query.toLowerCase();

        return invoiceNumber.contains(queryLower) ||
            buyerName.contains(queryLower);
      }).toList();
    });
