import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_urls.dart';
import '../core/dio_provider.dart';

class InvoiceRepository {
  final Dio dio;

  InvoiceRepository(this.dio);

  Future<ApiResponse<List<Map<String, dynamic>>>> getInvoiceTemplates() async {
    try {
      final response = await dio.get(ApiUrls.invoiceTemplates);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        List<Map<String, dynamic>> templates = [];

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data') &&
              responseData['data'] is List) {
            templates = List<Map<String, dynamic>>.from(responseData['data']);
          }
        } else if (responseData is List) {
          templates = List<Map<String, dynamic>>.from(responseData);
        }

        return ApiResponse.success(
          templates,
          responseData is Map
              ? (responseData['message'] ?? 'Templates fetched successfully')
              : 'Templates fetched successfully',
        );
      } else {
        return ApiResponse.error('Failed to fetch templates');
      }
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getBankAccounts(
    String accountId,
  ) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.bankAccounts, {
        'accountId': accountId,
      });

      final response = await dio.get(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        List<Map<String, dynamic>> banks = [];

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data') &&
              responseData['data'] is List) {
            banks = List<Map<String, dynamic>>.from(responseData['data']);
          } else if (responseData.containsKey('banks') &&
              responseData['banks'] is List) {
            banks = List<Map<String, dynamic>>.from(responseData['banks']);
          } else {
            banks = [responseData];
          }
        } else if (responseData is List) {
          banks = List<Map<String, dynamic>>.from(responseData);
        }

        return ApiResponse.success(
          banks,
          responseData is Map
              ? (responseData['message'] ??
                    'Bank accounts fetched successfully')
              : 'Bank accounts fetched successfully',
        );
      } else {
        return ApiResponse.error('Failed to fetch bank accounts');
      }
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getInvoiceSequenceNumber({
    String voucherType = 'Invoice',
  }) async {
    try {
      final response = await dio.get(
        ApiUrls.invoiceSeqNumber,
        queryParameters: {'voucherType': voucherType},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        Map<String, dynamic> sequenceData = {};

        if (responseData is Map<String, dynamic>) {
          sequenceData = responseData;
        } else {
          return ApiResponse.error('Unexpected response format');
        }

        return ApiResponse.success(
          sequenceData,
          'Invoice sequence fetched successfully',
        );
      } else {
        return ApiResponse.error('Failed to fetch invoice sequence');
      }
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('An unexpected error occurred');
    }
  }

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
            return 'Resource not found.';
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

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return InvoiceRepository(dio);
});

final invoiceTemplatesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repository = ref.watch(invoiceRepositoryProvider);
  final result = await repository.getInvoiceTemplates();

  if (result.success && result.data != null) {
    return result.data!;
  } else {
    throw Exception(result.error ?? 'Failed to fetch templates');
  }
});

final bankAccountsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      accountId,
    ) async {
      final repository = ref.watch(invoiceRepositoryProvider);
      final result = await repository.getBankAccounts(accountId);

      if (result.success && result.data != null) {
        return result.data!;
      } else {
        throw Exception(result.error ?? 'Failed to fetch bank accounts');
      }
    });

final invoiceSequenceProvider =
    FutureProvider.family<Map<String, dynamic>, String>((
      ref,
      voucherType,
    ) async {
      final repository = ref.watch(invoiceRepositoryProvider);
      final result = await repository.getInvoiceSequenceNumber(
        voucherType: voucherType,
      );

      if (result.success && result.data != null) {
        return result.data!;
      } else {
        throw Exception(result.error ?? 'Failed to fetch invoice sequence');
      }
    });

final invoiceActionsProvider = Provider<InvoiceActions>((ref) {
  final repository = ref.watch(invoiceRepositoryProvider);
  return InvoiceActions(repository);
});

class InvoiceActions {
  final InvoiceRepository _repository;

  InvoiceActions(this._repository);

  Future<ApiResponse<List<Map<String, dynamic>>>> getInvoiceTemplates() async {
    return await _repository.getInvoiceTemplates();
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getBankAccounts(
    String accountId,
  ) async {
    return await _repository.getBankAccounts(accountId);
  }

  Future<ApiResponse<Map<String, dynamic>>> getInvoiceSequenceNumber({
    String voucherType = 'Invoice',
  }) async {
    return await _repository.getInvoiceSequenceNumber(voucherType: voucherType);
  }
}