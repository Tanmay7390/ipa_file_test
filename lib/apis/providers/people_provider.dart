import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_urls.dart';
import '../core/dio_provider.dart';
import '../core/api_response.dart';
import '../../models/person.dart';

// People API repository
class PeopleRepository {
  final Dio dio;

  PeopleRepository(this.dio);

  // Get list of people with filters
  Future<ApiResponse<PeopleListResponse>> getPeople({
    required int limit,
    required int offset,
    String? search,
    String isCEO = 'true',
    String? axlCompany,
    String? axlCountry,
    String? location,
    String? ignoreDates,
    String? isFilter,
    String? titleCategory,
  }) async {
    try {
      // Build query parameters
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
        'is_CEO': isCEO,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (axlCompany != null && axlCompany.isNotEmpty) {
        queryParams['axl_company'] = axlCompany;
      }
      if (axlCountry != null && axlCountry.isNotEmpty) {
        queryParams['axl_country'] = axlCountry;
      }
      if (location != null && location.isNotEmpty) {
        queryParams['location'] = location;
      }
      if (ignoreDates != null && ignoreDates.isNotEmpty) {
        queryParams['ignore_DATES'] = ignoreDates;
      }
      if (isFilter != null && isFilter.isNotEmpty) {
        queryParams['is_filter'] = isFilter;
      }
      if (titleCategory != null && titleCategory.isNotEmpty) {
        queryParams['title_category'] = titleCategory;
      }

      log('🔍 Fetching people with params: $queryParams');

      final response = await dio.get(
        ApiUrls.getPeople,
        queryParameters: queryParams,
      );

      log('✅ People Response Status: ${response.statusCode}');
      log('📦 People Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          // Log the type of data field for debugging
          final dataType = responseData['data']?.runtimeType;
          log('📋 Data field type: $dataType');

          if (responseData['data'] is List) {
            log('✅ Data is a List with ${(responseData['data'] as List).length} items');
          }

          try {
            final peopleResponse = PeopleListResponse.fromJson(responseData);
            log('📊 Fetched ${peopleResponse.data.length} people');
            log('✅ People data successfully parsed');

            return ApiResponse.success(
              peopleResponse,
              'People fetched successfully',
            );
          } catch (e) {
            log('❌ Error parsing people response: $e');
            return ApiResponse.error('Failed to parse people data: $e');
          }
        } else {
          log('❌ Invalid response format - expected Map but got ${responseData.runtimeType}');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Failed with status: ${response.statusCode}');
        return ApiResponse.error('Failed to fetch people');
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

  // Get person by ID - returns dynamic data
  Future<ApiResponse<Map<String, dynamic>>> getPersonByIdDynamic({
    required int id,
    bool isAdmin = true,
    bool isCEO = true,
  }) async {
    try {
      final url = ApiUrls.replaceParams(
        ApiUrls.getPersonById,
        {'people_id': id.toString()},
      );

      final queryParams = {
        'is_admin': isAdmin.toString(),
        'is_CEO': isCEO.toString(),
      };

      log('🔍 Fetching person details for ID: $id');

      final response = await dio.get(
        url,
        queryParameters: queryParams,
      );

      log('✅ Person Details Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          // Return the full response data without parsing to a model
          log('📊 Fetched person details successfully');

          return ApiResponse.success(
            responseData,
            'Person details fetched successfully',
          );
        } else {
          log('❌ Invalid response format');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Failed to fetch person: ${response.statusCode}');
        return ApiResponse.error(
          'Failed to fetch person details: ${response.statusCode}',
        );
      }
    } catch (e) {
      log('❌ Error fetching person: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Get person by ID - legacy method with model parsing
  Future<ApiResponse<Person>> getPersonById({
    required int id,
    bool isAdmin = true,
    bool isCEO = true,
  }) async {
    try {
      final url = ApiUrls.replaceParams(
        ApiUrls.getPersonById,
        {'people_id': id.toString()},
      );

      final queryParams = {
        'is_admin': isAdmin.toString(),
        'is_CEO': isCEO.toString(),
      };

      log('🔍 Fetching person details for ID: $id');

      final response = await dio.get(
        url,
        queryParameters: queryParams,
      );

      log('✅ Person Details Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          final data = responseData['data'];
          if (data != null) {
            // Merge the nested arrays into the main data object
            final mergedData = Map<String, dynamic>.from(data);

            // Add notable_positions if they exist at the top level
            if (responseData['notable_positions'] != null) {
              mergedData['notable_positions'] = responseData['notable_positions'];
            }

            // Add education if it exists at the top level
            if (responseData['education'] != null) {
              mergedData['education'] = responseData['education'];
            }

            // Add notable_affiliation if it exists
            if (responseData['notable_affiliation'] != null) {
              mergedData['notable_affiliation'] = responseData['notable_affiliation'];
            }

            final person = Person.fromJson(mergedData);
            log('📊 Fetched person: ${person.name}');

            return ApiResponse.success(
              person,
              'Person details fetched successfully',
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
        return ApiResponse.error('Failed to fetch person details');
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
        final message = e.response?.data?['message'] ?? e.response?.data?['error'];

        switch (statusCode) {
          case 400:
            return message ?? 'Bad request. Please check your input.';
          case 401:
            return message ?? 'Unauthorized. Please login again.';
          case 403:
            return 'Access denied.';
          case 404:
            return 'Person not found.';
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
final peopleRepositoryProvider = Provider<PeopleRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return PeopleRepository(dio);
});

// State notifier for people list
class PeopleListNotifier extends StateNotifier<AsyncValue<List<Person>>> {
  final PeopleRepository _repository;

  List<Person> _allPeople = [];
  int _currentOffset = 0;
  bool _hasMore = true;
  String? _currentSearch;
  Map<String, String> _currentFilters = {};

  PeopleListNotifier(this._repository) : super(const AsyncValue.loading()) {
    // Delay initial load to ensure token is initialized
    Future.delayed(Duration(milliseconds: 100), () {
      loadPeople();
    });
  }

  Future<void> loadPeople({bool refresh = false}) async {
    if (refresh) {
      _currentOffset = 0;
      _allPeople = [];
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    if (!_hasMore && !refresh) return;

    try {
      final response = await _repository.getPeople(
        limit: 20,
        offset: _currentOffset,
        search: _currentSearch,
        isCEO: _currentFilters['isCEO'] ?? 'true',
        axlCompany: _currentFilters['company'],
        axlCountry: _currentFilters['country'],
        location: _currentFilters['location'],
        titleCategory: _currentFilters['titleCategory'],
        ignoreDates: _currentFilters['ignoreDates'],
        isFilter: _currentFilters['isFilter'],
      );

      if (response.success && response.data != null) {
        final newPeople = response.data!.data;
        log('✅ LoadPeople: Got ${newPeople.length} people from API');

        if (refresh) {
          _allPeople = newPeople;
        } else {
          _allPeople.addAll(newPeople);
        }

        _currentOffset += 20;
        _hasMore = newPeople.length >= 20;

        log('📊 Total people in list: ${_allPeople.length}');
        state = AsyncValue.data(_allPeople);
      } else {
        log('❌ LoadPeople error: ${response.error}');
        state = AsyncValue.error(response.error ?? 'Failed to load people', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    await loadPeople();
  }

  Future<void> refresh() async {
    await loadPeople(refresh: true);
  }

  void search(String query) {
    _currentSearch = query;
    loadPeople(refresh: true);
  }

  void applyFilters(Map<String, String> filters) {
    _currentFilters = filters;
    loadPeople(refresh: true);
  }

  void clearFilters() {
    _currentFilters = {};
    loadPeople(refresh: true);
  }

  bool get hasMore => _hasMore;
  Map<String, String> get currentFilters => _currentFilters;
}

// People list provider
final peopleListProvider = StateNotifierProvider<PeopleListNotifier, AsyncValue<List<Person>>>((ref) {
  final repository = ref.watch(peopleRepositoryProvider);
  return PeopleListNotifier(repository);
});

// Person details provider - returns dynamic data
final personDetailsProvider = FutureProvider.family<Map<String, dynamic>?, int>((ref, id) async {
  final repository = ref.watch(peopleRepositoryProvider);
  final response = await repository.getPersonByIdDynamic(id: id);

  if (response.success && response.data != null) {
    return response.data;
  }
  return null;
});