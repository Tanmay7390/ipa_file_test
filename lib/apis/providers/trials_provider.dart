import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_urls.dart';
import '../core/dio_provider.dart';
import '../core/api_response.dart';
import '../../models/trial.dart';

// Trials API repository
class TrialsRepository {
  final Dio dio;

  TrialsRepository(this.dio);

  // Get list of trials with filters
  Future<ApiResponse<TrialsListResponse>> getTrials({
    required int limit,
    required int offset,
    String? search,
    String? trialsPhase,
    String? trialsStatus,
    String? interventionTreeIds,
    String? trialsClass,
    String? primaryIntervention,
    String? therapeuticArea,
    String? typeIds,
    String? companySize,
    String? axlCountry,
    String? axlCountryIds,
    String? studyFirstPostedDateFrom,
    String? studyFirstPostedDateTo,
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
      if (trialsPhase != null && trialsPhase.isNotEmpty) {
        queryParams['trials_phase'] = trialsPhase;
      }
      if (trialsStatus != null && trialsStatus.isNotEmpty) {
        queryParams['trials_status'] = trialsStatus;
      }
      if (interventionTreeIds != null && interventionTreeIds.isNotEmpty) {
        queryParams['intervention_tree_ids'] = interventionTreeIds;
      }
      if (trialsClass != null && trialsClass.isNotEmpty) {
        queryParams['trials_class'] = trialsClass;
      }
      if (primaryIntervention != null && primaryIntervention.isNotEmpty) {
        queryParams['primary_intervention'] = primaryIntervention;
      }
      if (therapeuticArea != null && therapeuticArea.isNotEmpty) {
        queryParams['therapeutic_area'] = therapeuticArea;
      }
      if (typeIds != null && typeIds.isNotEmpty) {
        queryParams['type_ids'] = typeIds;
      }
      if (companySize != null && companySize.isNotEmpty) {
        queryParams['company_size'] = companySize;
      }
      if (axlCountry != null && axlCountry.isNotEmpty) {
        queryParams['axl_country'] = axlCountry;
      }
      if (axlCountryIds != null && axlCountryIds.isNotEmpty) {
        queryParams['axl_country_ids'] = axlCountryIds;
      }
      if (studyFirstPostedDateFrom != null &&
          studyFirstPostedDateFrom.isNotEmpty) {
        queryParams['study_first_posted_date_from'] = studyFirstPostedDateFrom;
      }
      if (studyFirstPostedDateTo != null && studyFirstPostedDateTo.isNotEmpty) {
        queryParams['study_first_posted_date_to'] = studyFirstPostedDateTo;
      }

      log('🔍 Fetching trials with params: $queryParams');

      final response = await dio.get(
        ApiUrls.getTrials,
        queryParameters: queryParams,
      );

      log('✅ Trials Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          try {
            final trialsResponse = TrialsListResponse.fromJson(responseData);
            log('📊 Fetched ${trialsResponse.data.length} trials');
            return ApiResponse.success(
              trialsResponse,
              'Trials fetched successfully',
            );
          } catch (e) {
            log('❌ Error parsing trials response: $e');
            return ApiResponse.error('Failed to parse trials data: $e');
          }
        } else {
          log('❌ Invalid response format');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Failed with status: ${response.statusCode}');
        return ApiResponse.error('Failed to fetch trials');
      }
    } on DioException catch (e) {
      log('❌ DioException: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('❌ Unexpected error: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Get trial by NCT number - returns dynamic data
  Future<ApiResponse<Map<String, dynamic>?>> getTrialByNct({
    required String nctNumber,
  }) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.getTrialByNct, {
        'nct_number': nctNumber,
      });

      log('🔍 Fetching trial details for NCT: $nctNumber');

      final response = await dio.get(url);

      log('✅ Trial Details Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          log('📊 Fetched trial details successfully');
          return ApiResponse.success(
            responseData,
            'Trial details fetched successfully',
          );
        } else {
          log('❌ Invalid response format');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Failed to fetch trial: ${response.statusCode}');
        return ApiResponse.error(
          'Failed to fetch trial details: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('❌ Error fetching trial: $e');
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
            return 'Trial not found.';
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
final trialsRepositoryProvider = Provider<TrialsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TrialsRepository(dio);
});

// State notifier for trials list
class TrialsListNotifier extends StateNotifier<AsyncValue<List<Trial>>> {
  final TrialsRepository _repository;

  List<Trial> _allTrials = [];
  int _currentOffset = 0;
  bool _hasMore = true;
  String? _currentSearch;
  Map<String, String> _currentFilters = {};

  TrialsListNotifier(this._repository) : super(const AsyncValue.loading()) {
    Future.delayed(Duration(milliseconds: 100), () {
      loadTrials();
    });
  }

  Future<void> loadTrials({bool refresh = false}) async {
    if (refresh) {
      _currentOffset = 0;
      _allTrials = [];
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    if (!_hasMore && !refresh) return;

    try {
      final response = await _repository.getTrials(
        limit: 20,
        offset: _currentOffset,
        search: _currentSearch,
        trialsPhase: _currentFilters['trialsPhase'],
        trialsStatus: _currentFilters['trialsStatus'],
        interventionTreeIds: _currentFilters['interventionTreeIds'],
        trialsClass: _currentFilters['trialsClass'],
        primaryIntervention: _currentFilters['primaryIntervention'],
        therapeuticArea: _currentFilters['therapeuticArea'],
        typeIds: _currentFilters['typeIds'],
        companySize: _currentFilters['companySize'],
        axlCountry: _currentFilters['axlCountry'],
        axlCountryIds: _currentFilters['axlCountryIds'],
        studyFirstPostedDateFrom: _currentFilters['studyFirstPostedDateFrom'],
        studyFirstPostedDateTo: _currentFilters['studyFirstPostedDateTo'],
      );

      if (response.success && response.data != null) {
        final newTrials = response.data!.data;
        log('✅ LoadTrials: Got ${newTrials.length} trials from API');

        if (refresh) {
          _allTrials = newTrials;
        } else {
          _allTrials.addAll(newTrials);
        }

        _currentOffset += 20;
        _hasMore = newTrials.length >= 20;

        log('📊 Total trials in list: ${_allTrials.length}');
        state = AsyncValue.data(_allTrials);
      } else {
        log('❌ LoadTrials error: ${response.error}');
        state = AsyncValue.error(
          response.error ?? 'Failed to load trials',
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    await loadTrials();
  }

  Future<void> refresh() async {
    await loadTrials(refresh: true);
  }

  void search(String query) {
    _currentSearch = query;
    loadTrials(refresh: true);
  }

  void applyFilters(Map<String, String> filters) {
    _currentFilters = filters;
    loadTrials(refresh: true);
  }

  void clearFilters() {
    _currentFilters = {};
    loadTrials(refresh: true);
  }

  bool get hasMore => _hasMore;
  Map<String, String> get currentFilters => _currentFilters;
}

// Trials list provider
final trialsListProvider =
    StateNotifierProvider<TrialsListNotifier, AsyncValue<List<Trial>>>((ref) {
      final repository = ref.watch(trialsRepositoryProvider);
      return TrialsListNotifier(repository);
    });

// Trial details provider - returns dynamic data
final trialDetailsProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((
      ref,
      nctNumber,
    ) async {
      final repository = ref.watch(trialsRepositoryProvider);
      final response = await repository.getTrialByNct(nctNumber: nctNumber);

      if (response.success && response.data != null) {
        return response.data;
      }
      return null;
    });
