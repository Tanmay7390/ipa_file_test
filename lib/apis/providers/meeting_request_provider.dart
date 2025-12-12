// lib/apis/providers/meeting_request_provider.dart
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/dio_provider.dart';
import '../core/api_response.dart';

// Meeting Request Repository
class MeetingRequestRepository {
  final Dio dio;

  MeetingRequestRepository(this.dio);

  // Create meeting request
  Future<ApiResponse<Map<String, dynamic>>> createMeetingRequest({
    required String eventId,
    required String requesterId,
    required String requesterName,
    required String recipientId,
    required String recipientName,
    required String title,
    required String meetingDate,
    required String startTime,
    required String endTime,
    String? note,
    String? location,
    bool isVideoMeeting = false,
  }) async {
    try {
      log('🔍 Creating meeting request: $title');

      final response = await dio.post(
        'meeting-request/create',
        data: {
          'event_id': eventId,
          'requester_id': requesterId,
          'requester_name': requesterName,
          'recipient_id': recipientId,
          'recipient_name': recipientName,
          'title': title,
          'meeting_date': meetingDate,
          'start_time': startTime,
          'end_time': endTime,
          'note': note ?? '',
          'location': location ?? '',
          'is_video_meeting': isVideoMeeting,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      log('✅ Meeting Request Response Status: ${response.statusCode}');
      log('📦 Meeting Request Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          // Check if the API response has a success field
          final bool apiSuccess = responseData['success'] ?? false;

          if (apiSuccess) {
            // Extract the actual data from the 'data' field
            final actualData = responseData['data'] as Map<String, dynamic>?;
            return ApiResponse.success(
              actualData ?? responseData,
              responseData['message'] as String? ?? 'Meeting request sent successfully',
            );
          } else {
            // API returned success: false
            log('❌ API returned success: false');
            return ApiResponse.error(
              responseData['message'] as String? ?? 'Failed to create meeting request'
            );
          }
        } else {
          log('❌ Invalid response format');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Failed to create meeting request: ${response.statusCode}');
        return ApiResponse.error('Failed to create meeting request');
      }
    } on DioException catch (e) {
      log('❌ DioException creating meeting request: ${e.message}');
      log('❌ Response: ${e.response?.data}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('❌ Unexpected error creating meeting request: $e');
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
            return 'Access denied.';
          case 404:
            return 'Resource not found.';
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
final meetingRequestRepositoryProvider = Provider<MeetingRequestRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return MeetingRequestRepository(dio);
});

// Actions provider for use in widgets
final meetingRequestActionsProvider = Provider((ref) {
  final repository = ref.watch(meetingRequestRepositoryProvider);
  return repository;
});
