import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'share_service.dart';
import 'package:dio/dio.dart';

// State for share loading
final shareLoadingProvider = StateProvider<bool>((ref) => false);

// State for share error
final shareErrorProvider = StateProvider<String?>((ref) => null);

// State for share success message
final shareSuccessProvider = StateProvider<String?>((ref) => null);

// Share Provider
class ShareNotifier extends StateNotifier<Map<String, dynamic>> {
  final ShareService _shareService;
  final Ref _ref;

  ShareNotifier(this._shareService, this._ref) : super({});

  // Helper method to handle errors
  String _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please check your internet connection.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final errorData = error.response?.data;

          if (statusCode == 500) {
            if (errorData != null && errorData.toString().contains('null')) {
              return 'Document data is incomplete. Please ensure all required fields are filled.';
            }
            return 'Server error occurred. Please try again later.';
          } else if (statusCode == 401) {
            return 'Authentication failed. Please login again.';
          } else if (statusCode == 403) {
            return 'Permission denied. You do not have access to this resource.';
          } else if (statusCode == 404) {
            return 'Resource not found. The document may have been deleted.';
          }
          return 'Server error (${statusCode}). Please try again.';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network.';
        default:
          return 'Network error occurred. Please try again.';
      }
    }

    // Handle other types of errors
    String errorMessage = error.toString();
    if (errorMessage.contains('Cannot read properties of null')) {
      return 'Document data is incomplete. Please ensure all required fields are filled.';
    } else if (errorMessage.contains('Failed to share')) {
      return 'Failed to share document. Please check your internet connection and try again.';
    } else if (errorMessage.contains('PDF generation')) {
      return 'Failed to generate PDF. Please try again.';
    } else if (errorMessage.contains('templateId')) {
      return 'Template configuration error. Please contact support.';
    } else if (errorMessage.contains('Template ID is required')) {
      return 'No template configured for this document. Please contact support.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  // Clear error and success messages
  void clearMessages() {
    _ref.read(shareErrorProvider.notifier).state = null;
    _ref.read(shareSuccessProvider.notifier).state = null;
  }

  // Extract PDF URL from invoice data - no generation needed
  String? extractPdfUrl({
    required Map<String, dynamic> invoiceData,
    required String documentType,
  }) {
    try {
      return _shareService.getPdfUrlFromInvoiceData(invoiceData, documentType);
    } catch (e) {
      final errorMessage = _handleError(e);
      _ref.read(shareErrorProvider.notifier).state = errorMessage;
      print('PDF URL Extraction Error: $e');
      return null;
    }
  }

  // Share Invoice - templateId must be provided from invoice data
  Future<bool> shareInvoice({
    required String invoiceId,
    required List<String> emailList,
    bool email = true,
    bool sms = false,
    bool whatsapp = false,
    required String? templateId, // Made required to enforce dynamic usage
  }) async {
    try {
      _ref.read(shareLoadingProvider.notifier).state = true;
      clearMessages();

      // Validate inputs
      if (invoiceId.isEmpty) {
        throw Exception('Invoice ID is required');
      }

      // Validate template ID - must be provided from invoice data
      if (templateId == null || templateId.trim().isEmpty) {
        throw Exception(
          'Template ID is required and must be provided from invoice data',
        );
      }

      if (emailList.isEmpty && email) {
        throw Exception('At least one email address is required');
      }

      // Validate email format
      if (email && emailList.isNotEmpty) {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        for (String emailAddr in emailList) {
          if (!emailRegex.hasMatch(emailAddr.trim())) {
            throw Exception('Invalid email format: $emailAddr');
          }
        }
      }

      final result = await _shareService.shareInvoice(
        invoiceId: invoiceId,
        emailList: emailList,
        email: email,
        sms: sms,
        whatsapp: whatsapp,
        templateId: templateId,
      );

      state = result;
      // Extract success message from server response
      final successMessage =
          result['message'] ?? 'Invoice shared successfully!';
      _ref.read(shareSuccessProvider.notifier).state = successMessage;
      return true;
    } catch (e) {
      final errorMessage = _handleError(e);
      _ref.read(shareErrorProvider.notifier).state = errorMessage;
      print('Share Invoice Error: $e');
      return false;
    } finally {
      _ref.read(shareLoadingProvider.notifier).state = false;
    }
  }

  // Share Quotation - templateId must be provided from quotation data
  Future<bool> shareQuotation({
    required String invoiceId,
    required List<String> emailList,
    bool email = true,
    bool sms = false,
    bool whatsapp = false,
    required String? templateId, // Made required to enforce dynamic usage
  }) async {
    try {
      _ref.read(shareLoadingProvider.notifier).state = true;
      clearMessages();

      // Validate inputs
      if (invoiceId.isEmpty) {
        throw Exception('Quotation ID is required');
      }

      // Validate template ID - must be provided from quotation data
      if (templateId == null || templateId.trim().isEmpty) {
        throw Exception(
          'Template ID is required and must be provided from quotation data',
        );
      }

      if (emailList.isEmpty && email) {
        throw Exception('At least one email address is required');
      }

      // Validate email format
      if (email && emailList.isNotEmpty) {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        for (String emailAddr in emailList) {
          if (!emailRegex.hasMatch(emailAddr.trim())) {
            throw Exception('Invalid email format: $emailAddr');
          }
        }
      }

      final result = await _shareService.shareQuotation(
        invoiceId: invoiceId,
        emailList: emailList,
        email: email,
        sms: sms,
        whatsapp: whatsapp,
        templateId: templateId,
      );

      state = result;
      final successMessage =
          result['message'] ?? 'Quotation shared successfully!';
      _ref.read(shareSuccessProvider.notifier).state = successMessage;
      return true;
    } catch (e) {
      final errorMessage = _handleError(e);
      _ref.read(shareErrorProvider.notifier).state = errorMessage;
      print('Share Quotation Error: $e');
      return false;
    } finally {
      _ref.read(shareLoadingProvider.notifier).state = false;
    }
  }

  // Share Payment Receipt - templateId must be provided from receipt data
  Future<bool> sharePaymentReceipt({
    required String invoiceId,
    required List<String> emailList,
    bool email = true,
    bool sms = false,
    bool whatsapp = false,
    required String? templateId, // Made required to enforce dynamic usage
  }) async {
    try {
      _ref.read(shareLoadingProvider.notifier).state = true;
      clearMessages();

      // Validate inputs
      if (invoiceId.isEmpty) {
        throw Exception('Payment receipt ID is required');
      }

      // Validate template ID - must be provided from receipt data
      if (templateId == null || templateId.trim().isEmpty) {
        throw Exception(
          'Template ID is required and must be provided from receipt data',
        );
      }

      if (emailList.isEmpty && email) {
        throw Exception('At least one email address is required');
      }

      // Validate email format
      if (email && emailList.isNotEmpty) {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        for (String emailAddr in emailList) {
          if (!emailRegex.hasMatch(emailAddr.trim())) {
            throw Exception('Invalid email format: $emailAddr');
          }
        }
      }

      final result = await _shareService.sharePaymentReceipt(
        invoiceId: invoiceId,
        emailList: emailList,
        email: email,
        sms: sms,
        whatsapp: whatsapp,
        templateId: templateId,
      );

      state = result;
      final successMessage =
          result['message'] ?? 'Payment receipt shared successfully!';
      _ref.read(shareSuccessProvider.notifier).state = successMessage;
      return true;
    } catch (e) {
      final errorMessage = _handleError(e);
      _ref.read(shareErrorProvider.notifier).state = errorMessage;
      print('Share Payment Receipt Error: $e');
      return false;
    } finally {
      _ref.read(shareLoadingProvider.notifier).state = false;
    }
  }

  // Get Preview URL for invoice
  Future<String?> getPreviewUrl(String invoiceId) async {
    try {
      if (invoiceId.isEmpty) {
        throw Exception('Invoice ID is required');
      }

      return await _shareService.getInvoicePreviewUrl(invoiceId);
    } catch (e) {
      final errorMessage = _handleError(e);
      _ref.read(shareErrorProvider.notifier).state = errorMessage;
      print('Get Preview URL Error: $e');
      return null;
    }
  }

  // Get PDF URL from existing invoice data
  String? getPdfUrl({
    required String invoiceId,
    required Map<String, dynamic> invoiceData,
    required String documentType,
  }) {
    try {
      clearMessages();

      // Extract PDF URL directly from invoice data
      String? pdfUrl = _shareService.getPdfUrlFromInvoiceData(
        invoiceData,
        documentType,
      );

      if (pdfUrl != null && pdfUrl.toString().isNotEmpty) {
        print('Found PDF URL in invoice data: $pdfUrl');
        return pdfUrl.toString();
      }

      print(
        'No PDF URL found in invoice data for document type: $documentType',
      );
      final errorMessage =
          'PDF not available for this ${documentType.toLowerCase()}';
      _ref.read(shareErrorProvider.notifier).state = errorMessage;
      return null;
    } catch (e) {
      final errorMessage = _handleError(e);
      _ref.read(shareErrorProvider.notifier).state = errorMessage;
      print('Get PDF URL Error: $e');
      return null;
    }
  }
}

final shareProvider =
    StateNotifierProvider<ShareNotifier, Map<String, dynamic>>((ref) {
      final shareService = ref.watch(shareServiceProvider);
      return ShareNotifier(shareService, ref);
    });
