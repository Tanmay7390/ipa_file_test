import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../apis/core/api_urls.dart';
import '../apis/core/dio_provider.dart';

class ShareService {
  final Dio _dio;

  ShareService(this._dio);

  // Helper method to log requests for debugging
  void _logRequest(
    String method,
    String url,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParams,
  ) {
    print('[${method.toUpperCase()}] $url');
    if (queryParams != null && queryParams.isNotEmpty) {
      print('Query Params: $queryParams');
    }
    if (data != null) {
      print('Payload: $data');
    }
  }

  // Helper method to handle API responses
  Map<String, dynamic> _handleResponse(Response response, String operation) {
    print('$operation - Response Status: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data ?? {};
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: '$operation failed with status ${response.statusCode}',
      );
    }
  }

  // Extract PDF URL from invoice data - no generation needed
  String? extractPdfUrl(Map<String, dynamic> invoiceData, String documentType) {
    try {
      String? pdfUrl;

      print('Extracting PDF URL for document type: $documentType');
      print('Invoice data keys: ${invoiceData.keys.toList()}');

      switch (documentType.toLowerCase()) {
        case 'paymentreceipt':
          // For payment receipts, try receipt PDF first, then fall back to invoice PDF
          pdfUrl = invoiceData['receiptPdfUrlLocation']?['Location'];
          if (pdfUrl == null || pdfUrl.toString().trim().isEmpty) {
            final receiptTemplates = invoiceData['receiptTemplates'] as List?;
            if (receiptTemplates != null && receiptTemplates.isNotEmpty) {
              pdfUrl = receiptTemplates.last['Location'];
            }
          }
          if (pdfUrl == null || pdfUrl.toString().trim().isEmpty) {
            pdfUrl = invoiceData['pdfUrlLocation']?['Location'];
          }
          break;
        case 'invoice':
        case 'quotation':
        default:
          // For invoices and quotations, use the main PDF URL
          pdfUrl = invoiceData['pdfUrlLocation']?['Location'];
          if (pdfUrl == null || pdfUrl.toString().trim().isEmpty) {
            final draftTemplates = invoiceData['draftTemplates'] as List?;
            if (draftTemplates != null && draftTemplates.isNotEmpty) {
              pdfUrl = draftTemplates.last['Location'];
            }
          }
          break;
      }

      if (pdfUrl != null && pdfUrl.toString().trim().isNotEmpty) {
        final cleanUrl = pdfUrl.toString().trim();
        print('Extracted PDF URL: $cleanUrl for document type: $documentType');

        // Validate URL format
        if (Uri.tryParse(cleanUrl) != null) {
          return cleanUrl;
        } else {
          print('Invalid URL format: $cleanUrl');
          return null;
        }
      }

      print(
        'No valid PDF URL found in invoice data for document type: $documentType',
      );
      return null;
    } catch (e) {
      print('PDF URL extraction error: $e');
      return null;
    }
  }

  // Share Invoice - Only uses dynamic template ID
  Future<Map<String, dynamic>> shareInvoice({
    required String invoiceId,
    required List<String> emailList,
    bool email = true,
    bool sms = false,
    bool whatsapp = false,
    String? templateId, // Must be provided from invoice data
  }) async {
    try {
      // Validate invoice ID
      if (invoiceId.trim().isEmpty) {
        throw Exception('Invoice ID cannot be empty');
      }

      // Validate template ID - must be provided
      if (templateId == null || templateId.trim().isEmpty) {
        throw Exception('Template ID is required and must be provided from invoice data');
      }

      // Clean and validate email list
      final cleanEmailList = emailList
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (email && cleanEmailList.isEmpty) {
        throw Exception('At least one valid email address is required');
      }

      final url = ApiUrls.replaceParams(ApiUrls.shareInvoice, {
        'invoiceId': invoiceId.trim(),
      });

      final queryParams = <String, dynamic>{};
      if (email) queryParams['email'] = 'true';
      if (sms) queryParams['sms'] = 'true';
      if (whatsapp) queryParams['whatsapp'] = 'true';

      // Include templateId in payload (must be from invoice data)
      final payload = <String, dynamic>{
        'templateId': templateId.trim(),
        'toEmailList': cleanEmailList,
        'dispatchType': 'Invoice',
      };

      _logRequest('POST', url, payload, queryParams);

      final response = await _dio.post(
        url,
        data: payload,
        queryParameters: queryParams,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      return _handleResponse(response, 'Share Invoice');
    } on DioException catch (e) {
      print('Share Invoice DioException: ${e.message}');
      print('Response data: ${e.response?.data}');
      print('Response status: ${e.response?.statusCode}');

      if (e.response?.statusCode == 500) {
        final errorData = e.response?.data;
        if (errorData != null && errorData.toString().contains('null')) {
          throw Exception(
            'Server error: Missing required data. Please ensure the invoice has all required fields.',
          );
        }
        throw Exception(
          'Server error: Unable to share invoice. Please try again.',
        );
      } else if (e.response?.statusCode == 404) {
        throw Exception(
          'Invoice not found. It may have been deleted or moved.',
        );
      } else if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      }

      throw Exception(
        'Failed to share invoice: ${e.message ?? 'Unknown error'}',
      );
    } catch (e) {
      print('Share Invoice Error: $e');
      throw Exception('Failed to share invoice: $e');
    }
  }

  // Share Quotation - Only uses dynamic template ID
  Future<Map<String, dynamic>> shareQuotation({
    required String invoiceId,
    required List<String> emailList,
    bool email = true,
    bool sms = false,
    bool whatsapp = false,
    String? templateId, // Must be provided from invoice data
  }) async {
    try {
      // Validate quotation ID
      if (invoiceId.trim().isEmpty) {
        throw Exception('Quotation ID cannot be empty');
      }

      // Validate template ID - must be provided
      if (templateId == null || templateId.trim().isEmpty) {
        throw Exception('Template ID is required and must be provided from quotation data');
      }

      // Clean and validate email list
      final cleanEmailList = emailList
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (email && cleanEmailList.isEmpty) {
        throw Exception('At least one valid email address is required');
      }

      final url = ApiUrls.replaceParams(ApiUrls.shareQuotation, {
        'invoiceId': invoiceId.trim(),
      });

      final queryParams = <String, dynamic>{};
      if (email) queryParams['email'] = 'true';
      if (sms) queryParams['sms'] = 'true';
      if (whatsapp) queryParams['whatsapp'] = 'true';

      // Include templateId in payload (must be from quotation data)
      final payload = <String, dynamic>{
        'templateId': templateId.trim(),
        'toEmailList': cleanEmailList,
        'dispatchType': 'Quotation',
      };

      _logRequest('POST', url, payload, queryParams);

      final response = await _dio.post(
        url,
        data: payload,
        queryParameters: queryParams,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      return _handleResponse(response, 'Share Quotation');
    } on DioException catch (e) {
      print('Share Quotation DioException: ${e.message}');
      print('Response data: ${e.response?.data}');

      if (e.response?.statusCode == 500) {
        final errorData = e.response?.data;
        if (errorData != null && errorData.toString().contains('null')) {
          throw Exception(
            'Server error: Missing required data. Please ensure the quotation has all required fields.',
          );
        }
        throw Exception(
          'Server error: Unable to share quotation. Please try again.',
        );
      } else if (e.response?.statusCode == 404) {
        throw Exception(
          'Quotation not found. It may have been deleted or moved.',
        );
      } else if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      }

      throw Exception(
        'Failed to share quotation: ${e.message ?? 'Unknown error'}',
      );
    } catch (e) {
      print('Share Quotation Error: $e');
      throw Exception('Failed to share quotation: $e');
    }
  }

  // Share Payment Receipt - Only uses dynamic template ID with additional payment data
  Future<Map<String, dynamic>> sharePaymentReceipt({
    required String invoiceId,
    required List<String> emailList,
    bool email = true,
    bool sms = false,
    bool whatsapp = false,
    String? templateId, // Must be provided from invoice data
    Map<String, dynamic>? additionalData, // Additional payment-related data
  }) async {
    try {
      // Validate receipt ID
      if (invoiceId.trim().isEmpty) {
        throw Exception('Payment receipt ID cannot be empty');
      }

      // Validate template ID - must be provided
      if (templateId == null || templateId.trim().isEmpty) {
        throw Exception('Template ID is required and must be provided from receipt data');
      }

      // Clean and validate email list
      final cleanEmailList = emailList
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (email && cleanEmailList.isEmpty) {
        throw Exception('At least one valid email address is required');
      }

      final url = ApiUrls.replaceParams(ApiUrls.sharePaymentReceipt, {
        'invoiceId': invoiceId.trim(),
      });

      final queryParams = <String, dynamic>{};
      if (email) queryParams['email'] = 'true';
      if (sms) queryParams['sms'] = 'true';
      if (whatsapp) queryParams['whatsapp'] = 'true';

      // Include templateId in payload (must be from receipt data)
      final payload = <String, dynamic>{
        'templateId': templateId.trim(),
        'toEmailList': cleanEmailList,
        'dispatchType': 'Payment Receipt',
      };

      // Add additional payment data if provided
      if (additionalData != null) {
        print('💰 Adding additional payment data: ${additionalData.keys.toList()}');
        // Include payment-related fields that server might expect
        if (additionalData.containsKey('payment')) {
          payload['payment'] = additionalData['payment'];
          print('  - payment: ${additionalData['payment']}');
        }
        if (additionalData.containsKey('paymentMode')) {
          payload['paymentMode'] = additionalData['paymentMode'];
          print('  - paymentMode: ${additionalData['paymentMode']}');
        }
        if (additionalData.containsKey('receivedAmount')) {
          payload['receivedAmount'] = additionalData['receivedAmount'];
          print('  - receivedAmount: ${additionalData['receivedAmount']}');
        }
        if (additionalData.containsKey('paymentDate')) {
          payload['paymentDate'] = additionalData['paymentDate'];
          print('  - paymentDate: ${additionalData['paymentDate']}');
        }
        // Include account info if available
        if (additionalData.containsKey('account')) {
          payload['account'] = additionalData['account'];
          print('  - account: ${additionalData['account']}');
        }
        // Include buyer info if available
        if (additionalData.containsKey('buyer')) {
          payload['buyer'] = additionalData['buyer'];
          print('  - buyer: ${additionalData['buyer']}');
        }
        if (additionalData.containsKey('client')) {
          payload['client'] = additionalData['client'];
          print('  - client: ${additionalData['client']}');
        }
      } else {
        print('⚠️ No additional payment data provided');
      }

      _logRequest('POST', url, payload, queryParams);

      final response = await _dio.post(
        url,
        data: payload,
        queryParameters: queryParams,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      return _handleResponse(response, 'Share Payment Receipt');
    } on DioException catch (e) {
      print('Share Payment Receipt DioException: ${e.message}');
      print('Response data: ${e.response?.data}');

      if (e.response?.statusCode == 500) {
        final errorData = e.response?.data;
        if (errorData != null && errorData.toString().contains('null')) {
          throw Exception(
            'Server error: Missing required payment data. Please ensure the payment receipt has all required fields including payment information.',
          );
        }
        throw Exception(
          'Server error: Unable to share payment receipt. Please try again.',
        );
      } else if (e.response?.statusCode == 404) {
        throw Exception(
          'Payment receipt not found. It may have been deleted or moved.',
        );
      } else if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      }

      throw Exception(
        'Failed to share payment receipt: ${e.message ?? 'Unknown error'}',
      );
    } catch (e) {
      print('Share Payment Receipt Error: $e');
      throw Exception('Failed to share payment receipt: $e');
    }
  }

  // Get Invoice Preview PDF URL - Enhanced to work with existing data
  Future<String?> getInvoicePreviewUrl(String invoiceId) async {
    try {
      if (invoiceId.trim().isEmpty) {
        throw Exception('Invoice ID cannot be empty');
      }

      print('Getting preview URL for invoice: $invoiceId');
      // Note: This method now requires the invoice data to be passed separately
      // since we can't fetch it without the invoice data
      return null; // Will be handled by the provider with invoice data
    } catch (e) {
      print('Get Preview URL Error: $e');
      return null;
    }
  }

  // New method to get PDF URL from invoice data directly
  String? getPdfUrlFromInvoiceData(
    Map<String, dynamic> invoiceData,
    String documentType,
  ) {
    return extractPdfUrl(invoiceData, documentType);
  }
}

// Provider for ShareService
final shareServiceProvider = Provider<ShareService>((ref) {
  final dio = ref.watch(dioProvider);
  return ShareService(dio);
});