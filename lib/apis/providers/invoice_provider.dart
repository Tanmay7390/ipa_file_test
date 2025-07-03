import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/dio_provider.dart';
import '../core/api_urls.dart';
import '../../auth/components/auth_provider.dart'; 

// Invoice list provider - now depends on auth provider
final invoiceListProvider = StateNotifierProvider<InvoiceListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final dio = ref.watch(dioProvider);
  final authState = ref.watch(authProvider);
  return InvoiceListNotifier(dio, ref);
});

// Single invoice provider for details
final invoiceDetailProvider = StateNotifierProvider.family<InvoiceDetailNotifier, AsyncValue<Map<String, dynamic>?>, String>((ref, invoiceId) {
  final dio = ref.watch(dioProvider);
  return InvoiceDetailNotifier(dio, invoiceId);
});

// Invoice list notifier
class InvoiceListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final Dio _dio;
  final Ref _ref;
  List<Map<String, dynamic>> _allInvoices = [];
  String _currentSearchQuery = '';
  String? _currentAccountId;

  InvoiceListNotifier(this._dio, this._ref) : super(const AsyncValue.loading()) {
    // Listen to auth state changes
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && next.accountId != null) {
        // Reload invoices when account ID changes
        if (_currentAccountId != next.accountId) {
          loadInvoices();
        }
      }
    });
    
    // Load invoices if user is already authenticated
    final authState = _ref.read(authProvider);
    if (authState.isAuthenticated && authState.accountId != null) {
      loadInvoices();
    }
  }

  // Get account ID from auth provider
  String? _getAccountId() {
    final authState = _ref.read(authProvider);
    return authState.accountId ?? '6434642d86b9bb6018ef2528'; // Fallback to default
  }

  // Load invoices for the authenticated user's account
  Future<void> loadInvoices([String? accountId]) async {
    try {
      state = const AsyncValue.loading();
      
      // Use provided accountId or get from auth provider
      _currentAccountId = accountId ?? _getAccountId();
      
      if (_currentAccountId == null) {
        state = AsyncValue.error(
          'No account ID available. Please login again.', 
          StackTrace.current
        );
        return;
      }
      
      final String url = ApiUrls.replaceParams(
        ApiUrls.invoiceList,
        {'accountId': _currentAccountId!},
      );

      log('Loading invoices from: ${ApiUrls.baseUrl}$url');
      log('Using account ID: $_currentAccountId');

      final response = await _dio.get(url);
      
      if (response.statusCode == 200 && response.data != null) {
        // Handle different response structures
        List<dynamic> invoicesData = [];
        
        if (response.data is Map<String, dynamic>) {
          if (response.data.containsKey('invoices')) {
            invoicesData = response.data['invoices'] ?? [];
          } else if (response.data.containsKey('data')) {
            invoicesData = response.data['data'] ?? [];
          } else {
            // If response.data is a map but doesn't have expected keys, treat it as single invoice
            invoicesData = [response.data];
          }
        } else if (response.data is List) {
          invoicesData = response.data;
        }

        _allInvoices = invoicesData
            .map((invoice) => invoice as Map<String, dynamic>)
            .toList();
        
        log('Loaded ${_allInvoices.length} invoices for account: $_currentAccountId');
        
        // Apply current search if any
        _applySearch();
      } else {
        state = AsyncValue.error(
          'Failed to load invoices: ${response.statusCode}', 
          StackTrace.current
        );
      }
    } on DioException catch (e) {
      log('DioException loading invoices: ${e.message}');
      String errorMessage = 'Network error occurred';
      
      if (e.response != null) {
        errorMessage = 'Server error: ${e.response!.statusCode}';
        if (e.response!.data != null) {
          errorMessage += ' - ${e.response!.data}';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Response timeout';
      }
      
      state = AsyncValue.error(errorMessage, e.stackTrace);
    } catch (e, stackTrace) {
      log('Error loading invoices: $e');
      state = AsyncValue.error(e.toString(), stackTrace);
    }
  }

  // Search invoices
  void searchInvoices(String query) {
    _currentSearchQuery = query.toLowerCase().trim();
    _applySearch();
  }

  // Apply search filter
  void _applySearch() {
    if (_currentSearchQuery.isEmpty) {
      state = AsyncValue.data(_allInvoices);
    } else {
      final filteredInvoices = _allInvoices.where((invoice) {
        final invoiceNumber = invoice['invoiceNumber']?.toString().toLowerCase() ?? '';
        final buyerName = invoice['buyer']?['name']?.toString().toLowerCase() ?? '';
        final clientName = invoice['client']?['name']?.toString().toLowerCase() ?? '';
        final amount = invoice['amount']?.toString().toLowerCase() ?? '';
        final status = invoice['status']?.toString().toLowerCase() ?? '';
        
        return invoiceNumber.contains(_currentSearchQuery) ||
               buyerName.contains(_currentSearchQuery) ||
               clientName.contains(_currentSearchQuery) ||
               amount.contains(_currentSearchQuery) ||
               status.contains(_currentSearchQuery);
      }).toList();
      
      state = AsyncValue.data(filteredInvoices);
    }
  }

  // Delete invoice
  Future<void> deleteInvoice(String invoiceId) async {
    try {
      log('Deleting invoice: $invoiceId');
      
      // Make delete request
      await _dio.delete('invoice/$invoiceId');
      
      // Remove from local list
      _allInvoices.removeWhere((invoice) => 
        (invoice['_id'] == invoiceId || invoice['id'] == invoiceId));
      
      // Refresh the displayed list
      _applySearch();
      
      log('Invoice deleted successfully');
    } on DioException catch (e) {
      log('DioException deleting invoice: ${e.message}');
      // Re-throw so UI can handle the error
      throw Exception('Failed to delete invoice: ${e.message}');
    } catch (e) {
      log('Error deleting invoice: $e');
      throw Exception('Failed to delete invoice');
    }
  }

  // Refresh invoices
  Future<void> refreshInvoices() async {
    await loadInvoices();
  }

  // Force reload with current account ID
  Future<void> reloadInvoicesForCurrentAccount() async {
    final accountId = _getAccountId();
    if (accountId != null) {
      await loadInvoices(accountId);
    }
  }

  // Get current invoices
  List<Map<String, dynamic>> get currentInvoices {
    return state.maybeWhen(
      data: (invoices) => invoices,
      orElse: () => [],
    );
  }

  // Check if loading
  bool get isLoading {
    return state.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );
  }

  // Get current account ID
  String? get currentAccountId => _currentAccountId;
}

// Invoice detail notifier
class InvoiceDetailNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final Dio _dio;
  final String _invoiceId;

  InvoiceDetailNotifier(this._dio, this._invoiceId) : super(const AsyncValue.loading()) {
    loadInvoiceDetail();
  }

  // Load single invoice details
  Future<void> loadInvoiceDetail() async {
    try {
      state = const AsyncValue.loading();
      
      log('Loading invoice detail: $_invoiceId');

      final response = await _dio.get('invoice/$_invoiceId');
      
      if (response.statusCode == 200 && response.data != null) {
        Map<String, dynamic> invoiceData;
        
        if (response.data is Map<String, dynamic>) {
          if (response.data.containsKey('invoice')) {
            invoiceData = response.data['invoice'];
          } else if (response.data.containsKey('data')) {
            invoiceData = response.data['data'];
          } else {
            invoiceData = response.data;
          }
        } else {
          throw Exception('Invalid response format');
        }

        state = AsyncValue.data(invoiceData);
        log('Invoice detail loaded successfully');
      } else {
        state = AsyncValue.error(
          'Failed to load invoice detail: ${response.statusCode}', 
          StackTrace.current
        );
      }
    } on DioException catch (e) {
      log('DioException loading invoice detail: ${e.message}');
      String errorMessage = 'Network error occurred';
      
      if (e.response != null) {
        errorMessage = 'Server error: ${e.response!.statusCode}';
      }
      
      state = AsyncValue.error(errorMessage, e.stackTrace);
    } catch (e, stackTrace) {
      log('Error loading invoice detail: $e');
      state = AsyncValue.error(e.toString(), stackTrace);
    }
  }

  // Update invoice
  Future<void> updateInvoice(Map<String, dynamic> invoiceData) async {
    try {
      log('Updating invoice: $_invoiceId');

      final response = await _dio.put(
        'invoice/$_invoiceId',
        data: invoiceData,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        // Update local state
        await loadInvoiceDetail();
        log('Invoice updated successfully');
      } else {
        throw Exception('Failed to update invoice: ${response.statusCode}');
      }
    } on DioException catch (e) {
      log('DioException updating invoice: ${e.message}');
      throw Exception('Failed to update invoice: ${e.message}');
    } catch (e) {
      log('Error updating invoice: $e');
      throw Exception('Failed to update invoice');
    }
  }

  // Refresh invoice detail
  Future<void> refreshInvoiceDetail() async {
    await loadInvoiceDetail();
  }
}

// Helper providers for invoice statistics
final invoiceStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final invoicesAsync = ref.watch(invoiceListProvider);
  
  return invoicesAsync.when(
    data: (invoices) {
      double totalAmount = 0.0;
      double todayAmount = 0.0;
      double paidAmount = 0.0;
      double pendingAmount = 0.0;
      int totalCount = invoices.length;
      
      final DateTime today = DateTime.now();
      
      for (final invoice in invoices) {
        final double amount = double.tryParse(invoice['amount']?.toString() ?? '0') ?? 0.0;
        final String status = invoice['status']?.toString().toUpperCase() ?? '';
        
        totalAmount += amount;
        
        // Check if invoice is from today
        final String? dateString = invoice['date']?.toString();
        if (dateString != null) {
          try {
            final DateTime invoiceDate = DateTime.parse(dateString);
            if (invoiceDate.year == today.year && 
                invoiceDate.month == today.month && 
                invoiceDate.day == today.day) {
              todayAmount += amount;
            }
          } catch (e) {
            // Ignore date parsing errors
          }
        }
        
        // Calculate paid vs pending amounts
        if (status == 'PAID' || status == 'COMPLETED') {
          paidAmount += amount;
        } else {
          pendingAmount += amount;
        }
      }
      
      return {
        'totalAmount': totalAmount,
        'todayAmount': todayAmount,
        'paidAmount': paidAmount,
        'pendingAmount': pendingAmount,
        'totalCount': totalCount,
      };
    },
    loading: () => {
      'totalAmount': 0.0,
      'todayAmount': 0.0,
      'paidAmount': 0.0,
      'pendingAmount': 0.0,
      'totalCount': 0,
    },
    error: (_, __) => {
      'totalAmount': 0.0,
      'todayAmount': 0.0,
      'paidAmount': 0.0,
      'pendingAmount': 0.0,
      'totalCount': 0,
    },
  );
});

// Provider to get current account ID from auth
final currentAccountIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.accountId;
});