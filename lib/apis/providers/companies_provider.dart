import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_urls.dart';
import '../core/dio_provider.dart';

// Company repository provider
final companiesRepositoryProvider = Provider<CompaniesRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CompaniesRepository(dio);
});

class CompaniesRepository {
  final Dio dio;

  CompaniesRepository(this.dio);

  // Get companies list
  Future<ApiResponse<Map<String, dynamic>>> getCompanies({
    required int limit,
    required int offset,
    String? search,
    String? typeIds,
    String? subtypeIds,
    String? investorTypeIds,
    String? country,
    bool? hasParent,
    int? conditionId,
    String? interventionTreeIds,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (typeIds != null && typeIds.isNotEmpty) {
        queryParams['type_ids'] = typeIds;
      }
      if (subtypeIds != null && subtypeIds.isNotEmpty) {
        queryParams['subtype_ids'] = subtypeIds;
      }
      if (investorTypeIds != null && investorTypeIds.isNotEmpty) {
        queryParams['investor_type_ids'] = investorTypeIds;
      }
      if (country != null && country.isNotEmpty) {
        queryParams['axl_country'] = country;
      }
      if (hasParent != null) {
        queryParams['has_parent'] = hasParent.toString();
      }
      if (conditionId != null) {
        queryParams['condition_id'] = conditionId.toString();
      }
      if (interventionTreeIds != null && interventionTreeIds.isNotEmpty) {
        queryParams['intervention_tree_ids'] = interventionTreeIds;
      }

      log('🔍 Fetching companies with params: $queryParams');

      final response = await dio.get(
        ApiUrls.getCompanies,
        queryParameters: queryParams,
      );

      log('✅ Companies Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          log('📊 Fetched companies successfully');

          return ApiResponse.success(
            responseData,
            'Companies fetched successfully',
          );
        } else {
          log('❌ Invalid response format - expected Map but got ${responseData.runtimeType}');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Failed with status: ${response.statusCode}');
        return ApiResponse.error('Failed to fetch companies');
      }
    } on DioException catch (e) {
      log('❌ DioException: ${e.message}');
      log('❌ Response: ${e.response?.data}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('❌ Unexpected error: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Get company by ID
  Future<ApiResponse<Map<String, dynamic>>> getCompanyById({
    required int id,
    bool isAdmin = true,
  }) async {
    try {
      final url = ApiUrls.replaceParams(
        ApiUrls.getCompanyById,
        {'company_id': id.toString()},
      );

      final queryParams = {
        'is_admin': isAdmin.toString(),
      };

      log('🔍 Fetching company details for ID: $id');

      final response = await dio.get(
        url,
        queryParameters: queryParams,
      );

      log('✅ Company Details Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          log('📊 Fetched company details successfully');

          return ApiResponse.success(
            responseData,
            'Company details fetched successfully',
          );
        } else {
          log('❌ Invalid response format');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Failed to fetch company: ${response.statusCode}');
        return ApiResponse.error(
          'Failed to fetch company details: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('❌ Error fetching company: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  String _handleDioError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        return data['message'] ?? 'Server error: $statusCode';
      }
      return 'Server error: $statusCode';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout. Please try again.';
      case DioExceptionType.connectionError:
        return 'Connection error. Please check your internet connection.';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      default:
        return 'Network error. Please try again.';
    }
  }
}

// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory ApiResponse.success(T data, [String? message]) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
    );
  }

  factory ApiResponse.error(String error) {
    return ApiResponse(
      success: false,
      error: error,
    );
  }
}

// Companies state notifier
class CompaniesListNotifier extends StateNotifier<CompaniesListState> {
  final CompaniesRepository repository;

  CompaniesListNotifier(this.repository) : super(CompaniesListState());

  // Current filters
  Map<String, String> currentFilters = {};

  Future<void> loadCompanies({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        companies: [],
        offset: 0,
        hasMore: true,
        isLoading: false,
      );
    }

    if (state.isLoading || (!state.hasMore && !refresh)) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await repository.getCompanies(
        limit: 20,
        offset: state.offset,
        search: currentFilters['search'],
        typeIds: currentFilters['type_ids'],
        subtypeIds: currentFilters['subtype_ids'],
        country: currentFilters['axl_country'],
      );

      if (response.success && response.data != null) {
        final data = response.data!['data'] as List<dynamic>;
        final companies = data.cast<Map<String, dynamic>>();

        state = state.copyWith(
          companies: [...state.companies, ...companies],
          offset: state.offset + companies.length,
          hasMore: companies.length >= 20,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: response.error,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  void searchCompanies(String query) {
    currentFilters['search'] = query;
    loadCompanies(refresh: true);
  }

  void applyFilters(Map<String, String> filters) {
    currentFilters = filters;
    loadCompanies(refresh: true);
  }

  void clearFilters() {
    currentFilters = {};
    loadCompanies(refresh: true);
  }
}

// Companies list state
class CompaniesListState {
  final List<Map<String, dynamic>> companies;
  final bool isLoading;
  final String? error;
  final int offset;
  final bool hasMore;

  CompaniesListState({
    this.companies = const [],
    this.isLoading = false,
    this.error,
    this.offset = 0,
    this.hasMore = true,
  });

  CompaniesListState copyWith({
    List<Map<String, dynamic>>? companies,
    bool? isLoading,
    String? error,
    int? offset,
    bool? hasMore,
  }) {
    return CompaniesListState(
      companies: companies ?? this.companies,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      offset: offset ?? this.offset,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// Provider for companies list
final companiesListProvider = StateNotifierProvider<CompaniesListNotifier, CompaniesListState>((ref) {
  final repository = ref.watch(companiesRepositoryProvider);
  return CompaniesListNotifier(repository);
});

// Company details provider
final companyDetailsProvider = FutureProvider.family<Map<String, dynamic>?, int>((ref, id) async {
  final repository = ref.watch(companiesRepositoryProvider);
  final response = await repository.getCompanyById(id: id);

  if (response.success && response.data != null) {
    return response.data;
  }
  return null;
});