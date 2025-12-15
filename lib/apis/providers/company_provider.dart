import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_urls.dart';
import '../core/dio_provider.dart';
import '../core/api_response.dart';
import '../../models/company.dart';

// Company API repository
class CompanyRepository {
  final Dio dio;

  CompanyRepository(this.dio);

  // Get list of companies with filters
  Future<ApiResponse<CompaniesListResponse>> getCompanies({
    required int limit,
    required int offset,
    String? search,
    String? typeIds,
    String? subtypeIds,
    String? investorTypeIds,
    String? axlCountry,
    String? hasParent,
    int? conditionId,
    String? interventionTreeIds,
  }) async {
    try {
      // Build query parameters
      final queryParams = {
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
      if (axlCountry != null && axlCountry.isNotEmpty) {
        queryParams['axl_country'] = axlCountry;
      }
      if (hasParent != null && hasParent.isNotEmpty) {
        queryParams['has_parent'] = hasParent;
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
      log('📦 Companies Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          final dataType = responseData['data']?.runtimeType;
          log('📋 Data field type: $dataType');

          if (responseData['data'] is List) {
            log(
              '✅ Data is a List with ${(responseData['data'] as List).length} items',
            );
          }

          try {
            final companiesResponse = CompaniesListResponse.fromJson(
              responseData,
            );
            log('📊 Fetched ${companiesResponse.data.length} companies');
            log('✅ Companies data successfully parsed');

            return ApiResponse.success(
              companiesResponse,
              'Companies fetched successfully',
            );
          } catch (e) {
            log('❌ Error parsing companies response: $e');
            return ApiResponse.error('Failed to parse companies data: $e');
          }
        } else {
          log(
            '❌ Invalid response format - expected Map but got ${responseData.runtimeType}',
          );
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

  // Get company by ID - returns dynamic data
  Future<ApiResponse<Map<String, dynamic>?>> getCompanyByIdDynamic({
    required int id,
    bool isAdmin = true,
  }) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.getCompanyById, {
        'company_id': id.toString(),
      });

      final queryParams = {'is_admin': isAdmin.toString()};

      log('🔍 Fetching company details for ID: $id');

      final response = await dio.get(url, queryParameters: queryParams);

      log('✅ Company Details Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          // Return the full response data without parsing to a model
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

  // Get company by ID - legacy method with model parsing
  Future<ApiResponse<Company>> getCompanyById({
    required int id,
    bool isAdmin = true,
  }) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.getCompanyById, {
        'company_id': id.toString(),
      });

      final queryParams = {'is_admin': isAdmin.toString()};

      log('🔍 Fetching company details for ID: $id');

      final response = await dio.get(url, queryParameters: queryParams);

      log('✅ Company Details Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          final data = responseData['data'];
          if (data != null) {
            // Merge the nested arrays into the main data object
            final mergedData = Map<String, dynamic>.from(data);

            // Add notable_positions if they exist at the top level
            if (responseData['notable_positions'] != null) {
              mergedData['notable_positions'] =
                  responseData['notable_positions'];
            }

            final company = Company.fromJson(mergedData);
            log('📊 Fetched company: ${company.axlCompanyName}');

            return ApiResponse.success(
              company,
              'Company details fetched successfully',
            );
          } else {
            log('❌ No data found in response');
            return ApiResponse.error('No data found');
          }
        } else {
          log('❌ Invalid response format');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Failed with status: ${response.statusCode}');
        return ApiResponse.error('Failed to fetch company details');
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
            return 'Company not found.';
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
final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CompanyRepository(dio);
});

// State notifier for companies list
class CompanyListNotifier extends StateNotifier<AsyncValue<List<Company>>> {
  final CompanyRepository _repository;

  List<Company> _allCompanies = [];
  int _currentOffset = 0;
  bool _hasMore = true;
  String? _currentSearch;
  Map<String, String> _currentFilters = {};

  CompanyListNotifier(this._repository) : super(const AsyncValue.loading()) {
    // Delay initial load to ensure token is initialized
    Future.delayed(Duration(milliseconds: 100), () {
      loadCompanies();
    });
  }

  Future<void> loadCompanies({bool refresh = false}) async {
    if (refresh) {
      _currentOffset = 0;
      _allCompanies = [];
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    if (!_hasMore && !refresh) return;

    try {
      final response = await _repository.getCompanies(
        limit: 20,
        offset: _currentOffset,
        search: _currentSearch,
        typeIds: _currentFilters['typeIds'],
        subtypeIds: _currentFilters['subtypeIds'],
        investorTypeIds: _currentFilters['investorTypeIds'],
        axlCountry: _currentFilters['country'],
        hasParent: _currentFilters['hasParent'],
        conditionId: _currentFilters['conditionId'] != null
            ? int.tryParse(_currentFilters['conditionId']!)
            : null,
        interventionTreeIds: _currentFilters['interventionTreeIds'],
      );

      if (response.success && response.data != null) {
        final newCompanies = response.data!.data;
        log('✅ LoadCompanies: Got ${newCompanies.length} companies from API');

        if (refresh) {
          _allCompanies = newCompanies;
        } else {
          _allCompanies.addAll(newCompanies);
        }

        _currentOffset += 20;
        _hasMore = newCompanies.length >= 20;

        log('📊 Total companies in list: ${_allCompanies.length}');
        state = AsyncValue.data(_allCompanies);
      } else {
        log('❌ LoadCompanies error: ${response.error}');
        state = AsyncValue.error(
          response.error ?? 'Failed to load companies',
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    await loadCompanies();
  }

  Future<void> refresh() async {
    await loadCompanies(refresh: true);
  }

  void search(String query) {
    _currentSearch = query;
    loadCompanies(refresh: true);
  }

  void applyFilters(Map<String, String> filters) {
    _currentFilters = filters;
    loadCompanies(refresh: true);
  }

  void clearFilters() {
    _currentFilters = {};
    loadCompanies(refresh: true);
  }

  bool get hasMore => _hasMore;
  Map<String, String> get currentFilters => _currentFilters;
}

// Companies list provider
final companyListProvider =
    StateNotifierProvider<CompanyListNotifier, AsyncValue<List<Company>>>((
      ref,
    ) {
      final repository = ref.watch(companyRepositoryProvider);
      return CompanyListNotifier(repository);
    });

// Company details provider - returns dynamic data
final companyDetailsProvider =
    FutureProvider.family<Map<String, dynamic>?, int>((ref, id) async {
      final repository = ref.watch(companyRepositoryProvider);
      final response = await repository.getCompanyByIdDynamic(id: id);

      if (response.success && response.data != null) {
        return response.data;
      }
      return null;
    });
