import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_urls.dart';
import '../core/dio_provider.dart';
import '../core/api_response.dart';
import '../../models/fund.dart';

// Funds API repository
class FundsRepository {
  final Dio dio;

  FundsRepository(this.dio);

  // Get list of funds with filters
  Future<ApiResponse<FundsListResponse>> getFunds({
    required int limit,
    required int offset,
    String? search,
    String? type,
    String? location,
    String? firm,
    String? title,
    String? isInvestment,
    String? isFilter,
  }) async {
    try {
      // Build query parameters
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
        'is_frontend': 'true',
        'is_view': 'false',
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }
      if (location != null && location.isNotEmpty) {
        queryParams['location'] = location;
      }
      if (firm != null && firm.isNotEmpty) {
        queryParams['firm'] = firm;
      }
      if (title != null && title.isNotEmpty) {
        queryParams['title'] = title;
      }
      if (isInvestment != null && isInvestment.isNotEmpty) {
        queryParams['is_investment'] = isInvestment;
      }
      if (isFilter != null && isFilter.isNotEmpty) {
        queryParams['is_filter'] = isFilter;
      }

      log('🔍 Fetching funds with params: $queryParams');

      final response = await dio.get(
        ApiUrls.getVcFunds,
        queryParameters: queryParams,
      );

      log('✅ Funds Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          try {
            final fundsResponse = FundsListResponse.fromJson(responseData);
            log('📊 Fetched ${fundsResponse.data.length} funds');
            return ApiResponse.success(
              fundsResponse,
              'Funds fetched successfully',
            );
          } catch (e) {
            log('❌ Error parsing funds response: $e');
            return ApiResponse.error('Failed to parse funds data: $e');
          }
        } else {
          log('❌ Invalid response format');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Failed with status: ${response.statusCode}');
        return ApiResponse.error('Failed to fetch funds');
      }
    } on DioException catch (e) {
      log('❌ DioException: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('❌ Unexpected error: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Get fund by ID - returns dynamic data
  Future<ApiResponse<Map<String, dynamic>?>> getFundById({
    required String fundId,
  }) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.getVcFundById, {
        'venture_capital_id': fundId,
      });

      log('🔍 Fetching fund details for Fund ID: $fundId');

      final response = await dio.get(
        url,
        queryParameters: {'is_admin': 'true'},
      );

      log('✅ Fund Details Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          log('📊 Fetched fund details successfully');
          return ApiResponse.success(
            responseData,
            'Fund details fetched successfully',
          );
        } else {
          log('❌ Invalid response format');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Failed to fetch fund: ${response.statusCode}');
        return ApiResponse.error(
          'Failed to fetch fund details: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('❌ Error fetching fund: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Helper method to handle Dio errors
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
            return message ?? 'Unauthorized. Please login again.';
          case 403:
            return 'Access denied.';
          case 404:
            return 'Fund not found.';
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

// Repository provider
final fundsRepositoryProvider = Provider<FundsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return FundsRepository(dio);
});

// State notifier for funds list
class FundsListNotifier extends StateNotifier<AsyncValue<List<Fund>>> {
  final FundsRepository _repository;

  List<Fund> _allFunds = [];
  int _currentOffset = 0;
  bool _hasMore = true;
  String? _currentSearch;
  Map<String, String> _currentFilters = {};

  FundsListNotifier(this._repository) : super(const AsyncValue.loading()) {
    Future.delayed(Duration(milliseconds: 100), () {
      loadFunds();
    });
  }

  Future<void> loadFunds({bool refresh = false}) async {
    if (refresh) {
      _currentOffset = 0;
      _allFunds = [];
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    if (!_hasMore && !refresh) return;

    try {
      final response = await _repository.getFunds(
        limit: 20,
        offset: _currentOffset,
        search: _currentSearch,
        type: _currentFilters['type'],
        location: _currentFilters['location'],
        firm: _currentFilters['firm'],
        title: _currentFilters['title'],
        isInvestment: _currentFilters['isInvestment'],
        isFilter: _currentFilters['isFilter'],
      );

      if (response.success && response.data != null) {
        final newFunds = response.data!.data;
        log('✅ LoadFunds: Got ${newFunds.length} funds from API');

        if (refresh) {
          _allFunds = newFunds;
        } else {
          _allFunds.addAll(newFunds);
        }

        _currentOffset += 20;
        _hasMore = newFunds.length >= 20;

        log('📊 Total funds in list: ${_allFunds.length}');
        state = AsyncValue.data(_allFunds);
      } else {
        log('❌ LoadFunds error: ${response.error}');
        state = AsyncValue.error(
          response.error ?? 'Failed to load funds',
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    await loadFunds();
  }

  Future<void> refresh() async {
    await loadFunds(refresh: true);
  }

  void search(String query) {
    _currentSearch = query;
    loadFunds(refresh: true);
  }

  void applyFilters(Map<String, String> filters) {
    _currentFilters = filters;
    loadFunds(refresh: true);
  }

  void clearFilters() {
    _currentFilters = {};
    loadFunds(refresh: true);
  }

  bool get hasMore => _hasMore;
  Map<String, String> get currentFilters => _currentFilters;
}

// Funds list provider
final fundsListProvider =
    StateNotifierProvider<FundsListNotifier, AsyncValue<List<Fund>>>((ref) {
      final repository = ref.watch(fundsRepositoryProvider);
      return FundsListNotifier(repository);
    });

// Fund details provider - returns dynamic data
final fundDetailsProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, fundId) async {
      final repository = ref.watch(fundsRepositoryProvider);
      final response = await repository.getFundById(fundId: fundId);

      if (response.success && response.data != null) {
        return response.data;
      }
      return null;
    });
