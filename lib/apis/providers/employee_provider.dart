// lib/apis/providers/employee_provider.dart
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_urls.dart';
import '../core/dio_provider.dart';

// Employee data model - flexible to handle any API response structure
class EmployeeData {
  final List<Map<String, dynamic>> employees;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final int totalPages;
  final int totalCount;

  EmployeeData({
    required this.employees,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
  });

  EmployeeData copyWith({
    List<Map<String, dynamic>>? employees,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    int? totalPages,
    int? totalCount,
  }) {
    return EmployeeData(
      employees: employees ?? this.employees,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;

  ApiResponse({required this.success, this.data, this.message, this.error});

  factory ApiResponse.success(T data, [String? message]) {
    return ApiResponse(success: true, data: data, message: message);
  }

  factory ApiResponse.error(String error) {
    return ApiResponse(success: false, error: error);
  }
}

// Employee repository
class EmployeeRepository {
  final Dio dio;

  EmployeeRepository(this.dio);

  // Get employee list with pagination and search
  Future<ApiResponse<EmployeeData>> getEmployeeList({
    required String accountId,
    int page = 1,
    int limit = 20,
    String? searchQuery,
  }) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.employeeList, {
        'accountId': '6434642d86b9bb6018ef2528',
      });

      // Build query parameters
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['filter'] = searchQuery;
      }

      final response = await dio.get(url, queryParameters: queryParams);

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Handle different API response structures
        List<Map<String, dynamic>> employees = [];
        int totalPages = 1;
        int totalCount = 0;
        bool hasMore = false;

        if (responseData is Map<String, dynamic>) {
          // Structured response with pagination info
          if (responseData.containsKey('data')) {
            final data = responseData['data'];
            if (data is List) {
              employees = List<Map<String, dynamic>>.from(data);
            } else if (data is Map && data.containsKey('employees')) {
              employees = List<Map<String, dynamic>>.from(
                data['employees'] ?? [],
              );
              totalPages = data['totalPages'] ?? 1;
              totalCount = data['totalCount'] ?? employees.length;
              hasMore = page < totalPages;
            }
          } else if (responseData.containsKey('employees')) {
            employees = List<Map<String, dynamic>>.from(
              responseData['employees'] ?? [],
            );
            totalPages = responseData['totalPages'] ?? 1;
            totalCount = responseData['totalCount'] ?? employees.length;
            hasMore = page < totalPages;
          } else {
            // Direct list response
            employees = [responseData];
          }

          // Extract pagination info if available
          if (responseData.containsKey('pagination')) {
            final pagination = responseData['pagination'];
            totalPages = pagination['totalPages'] ?? 1;
            totalCount = pagination['totalCount'] ?? employees.length;
            hasMore = pagination['hasMore'] ?? (page < totalPages);
          }
        } else if (responseData is List) {
          // Direct array response
          employees = List<Map<String, dynamic>>.from(responseData);
          totalCount = employees.length;
          hasMore = false; // No pagination info available
        }

        final employeeData = EmployeeData(
          employees: employees,
          currentPage: page,
          totalPages: totalPages,
          totalCount: totalCount,
          hasMore: hasMore,
        );

        return ApiResponse.success(
          employeeData,
          responseData is Map ? responseData['message'] : null,
        );
      } else {
        return ApiResponse.error('Failed to fetch employees');
      }
    } on DioException catch (e) {
      log('Error fetching employees: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Get single employee
  Future<ApiResponse<Map<String, dynamic>>> getEmployee(
    String employeeId,
  ) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.getEmployee, {
        'id': employeeId,
      });

      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final responseData = response.data;
        Map<String, dynamic> employee = {};

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            employee = Map<String, dynamic>.from(responseData['data']);
          } else {
            employee = responseData;
          }
        }

        return ApiResponse.success(
          employee,
          responseData is Map ? responseData['message'] : null,
        );
      } else {
        return ApiResponse.error('Failed to fetch employee');
      }
    } on DioException catch (e) {
      log('Error fetching employee: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Create employee
  Future<ApiResponse<Map<String, dynamic>>> createEmployee(
    Map<String, dynamic> employeeData,
  ) async {
    try {
      final response = await dio.post(
        ApiUrls.createEmployee,
        data: FormData.fromMap(employeeData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;
        Map<String, dynamic> employee = {};

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            employee = Map<String, dynamic>.from(responseData['data']);
          } else {
            employee = responseData;
          }
        }

        return ApiResponse.success(
          employee,
          responseData is Map
              ? (responseData['message'] ?? 'Employee created successfully')
              : 'Employee created successfully',
        );
      } else {
        return ApiResponse.error('Failed to create employee');
      }
    } on DioException catch (e) {
      log('Error creating employee: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Update employee
  Future<ApiResponse<Map<String, dynamic>>> updateEmployee(
    String employeeId,
    Map<String, dynamic> employeeData,
  ) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.updateEmployee, {
        'id': employeeId,
      });

      final response = await dio.put(url, data: FormData.fromMap(employeeData));

      if (response.statusCode == 200) {
        final responseData = response.data;
        Map<String, dynamic> employee = {};

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            employee = Map<String, dynamic>.from(responseData['data']);
          } else {
            employee = responseData;
          }
        }

        return ApiResponse.success(
          employee,
          responseData is Map
              ? (responseData['message'] ?? 'Employee updated successfully')
              : 'Employee updated successfully',
        );
      } else {
        return ApiResponse.error('Failed to update employee');
      }
    } on DioException catch (e) {
      log('Error updating employee: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Delete employee
  Future<ApiResponse<bool>> deleteEmployee(String employeeId) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.deleteEmployee, {
        'id': employeeId,
      });

      final response = await dio.delete(url);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse.success(
          true,
          response.data is Map
              ? (response.data?['message'] ?? 'Employee deleted successfully')
              : 'Employee deleted successfully',
        );
      } else {
        return ApiResponse.error('Failed to delete employee');
      }
    } on DioException catch (e) {
      log('Error deleting employee: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('Unexpected error: $e');
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
            return 'Unauthorized. Please login again.';
          case 403:
            return 'Access denied. You don\'t have permission.';
          case 404:
            return 'Employee not found.';
          case 422:
            return message ?? 'Validation error. Please check your input.';
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
final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return EmployeeRepository(dio);
});

// Search provider
final employeeSearchProvider = StateProvider<String>((ref) => '');

// Employee list provider
final employeeListProvider =
    StateNotifierProvider<EmployeeListNotifier, AsyncValue<EmployeeData>>((
      ref,
    ) {
      final repository = ref.watch(employeeRepositoryProvider);
      return EmployeeListNotifier(repository);
    });

// Employee actions provider for CRUD operations
final employeeActionsProvider = Provider<EmployeeActions>((ref) {
  final repository = ref.watch(employeeRepositoryProvider);
  return EmployeeActions(repository);
});

// Employee list state notifier
class EmployeeListNotifier extends StateNotifier<AsyncValue<EmployeeData>> {
  final EmployeeRepository _repository;
  String _currentAccountId = '';

  EmployeeListNotifier(this._repository) : super(const AsyncValue.loading());

  // Load employees with pagination and search
  Future<void> loadEmployees({
    required int page,
    bool refresh = false,
    String? searchQuery,
    String? accountId,
  }) async {
    try {
      // Use provided accountId or keep current one
      if (accountId != null) {
        _currentAccountId = accountId;
      }

      if (_currentAccountId.isEmpty) {
        // Set default account ID if needed
        _currentAccountId = 'default_account'; // Replace with actual logic
      }

      if (refresh || page == 1) {
        state = const AsyncValue.loading();
      } else {
        // Show loading more indicator
        state.whenData((currentData) {
          state = AsyncValue.data(currentData.copyWith(isLoadingMore: true));
        });
      }

      final result = await _repository.getEmployeeList(
        accountId: _currentAccountId,
        page: page,
        searchQuery: searchQuery,
      );

      if (result.success && result.data != null) {
        final newData = result.data!;

        if (page == 1 || refresh) {
          // First page or refresh - replace all data
          state = AsyncValue.data(newData);
        } else {
          // Append to existing data
          state.whenData((currentData) {
            final combinedEmployees = [
              ...currentData.employees,
              ...newData.employees,
            ];

            state = AsyncValue.data(
              newData.copyWith(
                employees: combinedEmployees,
                isLoadingMore: false,
              ),
            );
          });
        }
      } else {
        state = AsyncValue.error(
          result.error ?? 'Failed to load employees',
          StackTrace.current,
        );
      }
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  // Remove employee from local state (optimistic update)
  void removeEmployee(String employeeId) {
    state.whenData((currentData) {
      final updatedEmployees = currentData.employees
          .where((emp) => emp['_id'] != employeeId)
          .toList();
      state = AsyncValue.data(
        currentData.copyWith(
          employees: updatedEmployees,
          totalCount: currentData.totalCount - 1,
        ),
      );
    });
  }

  // Add employee to local state (optimistic update)
  void addEmployee(Map<String, dynamic> employee) {
    state.whenData((currentData) {
      final updatedEmployees = [employee, ...currentData.employees];
      state = AsyncValue.data(
        currentData.copyWith(
          employees: updatedEmployees,
          totalCount: currentData.totalCount + 1,
        ),
      );
    });
  }

  // Update employee in local state (optimistic update)
  void updateEmployee(String employeeId, Map<String, dynamic> updatedEmployee) {
    state.whenData((currentData) {
      final updatedEmployees = currentData.employees.map((emp) {
        return emp['_id'] == employeeId ? updatedEmployee : emp;
      }).toList();
      state = AsyncValue.data(
        currentData.copyWith(employees: updatedEmployees),
      );
    });
  }
}

// Employee actions class for CRUD operations
class EmployeeActions {
  final EmployeeRepository _repository;

  EmployeeActions(this._repository);

  Future<ApiResponse<Map<String, dynamic>>> getEmployee(
    String employeeId,
  ) async {
    return await _repository.getEmployee(employeeId);
  }

  Future<ApiResponse<Map<String, dynamic>>> createEmployee(
    Map<String, dynamic> employeeData,
  ) async {
    return await _repository.createEmployee(employeeData);
  }

  Future<ApiResponse<Map<String, dynamic>>> updateEmployee(
    String employeeId,
    Map<String, dynamic> employeeData,
  ) async {
    return await _repository.updateEmployee(employeeId, employeeData);
  }

  Future<ApiResponse<bool>> deleteEmployee(String employeeId) async {
    return await _repository.deleteEmployee(employeeId);
  }
}
