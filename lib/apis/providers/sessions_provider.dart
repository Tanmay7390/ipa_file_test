// lib/apis/providers/sessions_provider.dart
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/dio_provider.dart';
import '../core/api_response.dart';

// Session Organizer model
class SessionOrganizer {
  final String id;
  final String? name;
  final String? designation;
  final String? photo;

  SessionOrganizer({required this.id, this.name, this.designation, this.photo});

  factory SessionOrganizer.fromJson(Map<String, dynamic> json) {
    return SessionOrganizer(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] as String?,
      designation: json['designation'] as String?,
      photo: json['photo'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'designation': designation,
    'photo': photo,
  };
}

// Session Speaker model
class SessionSpeaker {
  final String id;
  final String? name;
  final String? designation;
  final String? photo;

  SessionSpeaker({required this.id, this.name, this.designation, this.photo});

  factory SessionSpeaker.fromJson(Map<String, dynamic> json) {
    return SessionSpeaker(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] as String?,
      designation: json['designation'] as String?,
      photo: json['photo'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'designation': designation,
    'photo': photo,
  };
}

// Session model
class Session {
  final String id;
  final String? title;
  final String? startTime;
  final String? endTime;
  final int? duration;
  final String? timezone;
  final String? venue;
  final String? sessionType;
  final String? seatingType;
  final SessionOrganizer? organizer;
  final List<SessionSpeaker>? speakers;
  final String? status;
  final String? durationInHours;
  final bool? isLive;

  Session({
    required this.id,
    this.title,
    this.startTime,
    this.endTime,
    this.duration,
    this.timezone,
    this.venue,
    this.sessionType,
    this.seatingType,
    this.organizer,
    this.speakers,
    this.status,
    this.durationInHours,
    this.isLive,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      duration: json['duration'] as int?,
      timezone: json['timezone'] as String?,
      venue: json['venue'] as String?,
      sessionType: json['sessionType'] as String?,
      seatingType: json['seatingType'] as String?,
      organizer: json['organizer'] != null
          ? SessionOrganizer.fromJson(json['organizer'] as Map<String, dynamic>)
          : null,
      speakers: json['speakers'] != null
          ? (json['speakers'] as List)
                .map((s) => SessionSpeaker.fromJson(s as Map<String, dynamic>))
                .toList()
          : null,
      status: json['status'] as String?,
      durationInHours: json['durationInHours'] as String?,
      isLive: json['isLive'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'startTime': startTime,
    'endTime': endTime,
    'duration': duration,
    'timezone': timezone,
    'venue': venue,
    'sessionType': sessionType,
    'seatingType': seatingType,
    'organizer': organizer?.toJson(),
    'speakers': speakers?.map((s) => s.toJson()).toList(),
    'status': status,
    'durationInHours': durationInHours,
    'isLive': isLive,
  };

  // Helper method to check if session is active/ongoing
  bool get isActive => status == 'ONGOING';
}

// Sessions data model
class SessionsData {
  final List<Session> sessions;
  final int count;

  SessionsData({required this.sessions, required this.count});

  factory SessionsData.fromJson(Map<String, dynamic> json) {
    return SessionsData(
      sessions: json['data'] != null
          ? (json['data'] as List)
                .map((s) => Session.fromJson(s as Map<String, dynamic>))
                .toList()
          : [],
      count: json['count'] ?? 0,
    );
  }
}

// Sessions repository
class SessionsRepository {
  final Dio dio;

  SessionsRepository(this.dio);

  // Get sessions list
  Future<ApiResponse<SessionsData>> getSessions({
    required String eventId,
  }) async {
    try {
      log('🔍 Fetching sessions for event: $eventId');

      final response = await dio.post(
        'session/getAllSessions',
        data: {'eventId': eventId},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      log('✅ Sessions Response Status: ${response.statusCode}');
      log('📦 Sessions Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          final sessionsData = SessionsData.fromJson(responseData);
          log('🎉 Fetched ${sessionsData.sessions.length} sessions');

          return ApiResponse.success(
            sessionsData,
            responseData['message'] as String? ?? 'Sessions loaded',
          );
        } else {
          log('❌ Invalid response format');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Failed to fetch sessions: ${response.statusCode}');
        return ApiResponse.error('Failed to fetch sessions');
      }
    } on DioException catch (e) {
      log('❌ DioException fetching sessions: ${e.message}');
      log('❌ Response: ${e.response?.data}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('❌ Unexpected error fetching sessions: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Get session by ID
  Future<ApiResponse<Map<String, dynamic>>> getSessionById(
    String sessionId,
    String userId,
  ) async {
    try {
      log('🔍 Fetching session details for ID: $sessionId, userId: $userId');

      final response = await dio.post(
        'session/getSessionById/$sessionId',
        data: {'userId': userId},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      log('✅ Session Detail Response Status: ${response.statusCode}');
      log('📦 Session Detail Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          // Return the entire response including allowAccess
          if (responseData['data'] != null) {
            final sessionData = responseData['data'] as Map<String, dynamic>;
            // Add allowAccess to the session data
            sessionData['allowAccess'] = responseData['allowAccess'] ?? false;

            log('🎉 Fetched session details: ${sessionData['title']}');
            log('🔐 AllowAccess: ${sessionData['allowAccess']}');

            return ApiResponse.success(
              sessionData,
              responseData['message'] as String? ?? 'Session loaded',
            );
          } else {
            log('❌ Invalid response format - missing data');
            return ApiResponse.error('Invalid response format');
          }
        } else {
          log('❌ Invalid response format');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Failed to fetch session: ${response.statusCode}');
        return ApiResponse.error('Failed to fetch session');
      }
    } on DioException catch (e) {
      log('❌ DioException fetching session: ${e.message}');
      log('❌ Response: ${e.response?.data}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('❌ Unexpected error fetching session: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Add or remove session from user schedule
  Future<ApiResponse<Map<String, dynamic>>> addRemoveSession({
    required String userId,
    required String eventId,
    required String sessionId,
  }) async {
    try {
      log(
        '🔍 Adding/Removing session: userId=$userId, eventId=$eventId, sessionId=$sessionId',
      );

      final response = await dio.post(
        'schedule/user-schedule/addRemove',
        data: {'userId': userId, 'eventId': eventId, 'sessionId': sessionId},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      log('✅ Add/Remove Session Response Status: ${response.statusCode}');
      log('📦 Add/Remove Session Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic> &&
            responseData['success'] == true) {
          log(
            '🎉 Session added/removed successfully: ${responseData['message']}',
          );

          return ApiResponse.success(
            responseData,
            responseData['message'] as String? ?? 'Session updated',
          );
        } else {
          log('❌ Invalid response format');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Failed to add/remove session: ${response.statusCode}');
        return ApiResponse.error('Failed to update session');
      }
    } on DioException catch (e) {
      log('❌ DioException adding/removing session: ${e.message}');
      log('❌ Response: ${e.response?.data}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('❌ Unexpected error adding/removing session: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Get user schedule
  Future<ApiResponse<List<Session>>> getUserSchedule({
    required String userId,
    required String eventId,
  }) async {
    try {
      log('🔍 Fetching user schedule: userId=$userId, eventId=$eventId');

      final response = await dio.post(
        'schedule/user-schedule/all',
        data: {'userId': userId, 'eventId': eventId},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      log('✅ User Schedule Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic> &&
            responseData['success'] == true &&
            responseData['data'] != null) {
          final dataList = responseData['data'] as List;
          final sessions = dataList
              .map((item) {
                // The session details are inside 'sessionId' object
                if (item['sessionId'] != null) {
                  return Session.fromJson(
                    item['sessionId'] as Map<String, dynamic>,
                  );
                }
                return null;
              })
              .whereType<Session>()
              .toList();

          log('🎉 Fetched ${sessions.length} sessions in user schedule');

          return ApiResponse.success(
            sessions,
            responseData['message'] as String? ?? 'User schedule loaded',
          );
        } else {
          log('❌ Invalid response format');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Failed to fetch user schedule: ${response.statusCode}');
        return ApiResponse.error('Failed to fetch user schedule');
      }
    } on DioException catch (e) {
      log('❌ DioException fetching user schedule: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('❌ Unexpected error fetching user schedule: $e');
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
            return 'Session not found.';
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
final sessionsRepositoryProvider = Provider<SessionsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SessionsRepository(dio);
});

// Sessions state notifier
class SessionsNotifier extends StateNotifier<AsyncValue<SessionsData>> {
  final SessionsRepository _repository;
  String? _currentEventId;
  bool _isLoading = false;

  SessionsNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadSessions(String eventId) async {
    // Prevent concurrent calls
    if (_isLoading) {
      log('⚠️ Already loading, skipping duplicate call');
      return;
    }

    _isLoading = true;
    log('🔄 loadSessions called: eventId=$eventId');

    _currentEventId = eventId;
    state = const AsyncValue.loading();

    final result = await _repository.getSessions(eventId: eventId);

    if (result.success && result.data != null) {
      state = AsyncValue.data(result.data!);
      log(
        '✅ loadSessions completed: ${result.data!.sessions.length} sessions loaded',
      );
    } else {
      state = AsyncValue.error(
        result.error ?? 'Failed to load sessions',
        StackTrace.current,
      );
      log('❌ loadSessions failed: ${result.error}');
    }

    _isLoading = false;
  }

  Future<void> refresh() async {
    log('🔄 refresh() called');
    if (_currentEventId != null) {
      await loadSessions(_currentEventId!);
    }
  }

  // Toggle session in user schedule (add or remove)
  Future<ApiResponse<Map<String, dynamic>>> toggleSession({
    required String userId,
    required String eventId,
    required String sessionId,
  }) async {
    log(
      '🔄 toggleSession called: userId=$userId, eventId=$eventId, sessionId=$sessionId',
    );

    final result = await _repository.addRemoveSession(
      userId: userId,
      eventId: eventId,
      sessionId: sessionId,
    );

    if (result.success) {
      log('✅ toggleSession successful: ${result.message}');
    } else {
      log('❌ toggleSession failed: ${result.error}');
    }

    return result;
  }
}

// Sessions provider
final sessionsProvider =
    StateNotifierProvider<SessionsNotifier, AsyncValue<SessionsData>>((ref) {
      final repository = ref.watch(sessionsRepositoryProvider);
      return SessionsNotifier(repository);
    });

// Parameter class for session detail provider
class SessionDetailParams {
  final String sessionId;
  final String userId;

  SessionDetailParams({required this.sessionId, required this.userId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionDetailParams &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          userId == other.userId;

  @override
  int get hashCode => sessionId.hashCode ^ userId.hashCode;
}

// Session detail provider - for individual session by ID
final sessionDetailProvider =
    FutureProvider.family<Map<String, dynamic>, SessionDetailParams>((
      ref,
      params,
    ) async {
      final repository = ref.watch(sessionsRepositoryProvider);
      final result = await repository.getSessionById(
        params.sessionId,
        params.userId,
      );

      if (result.success && result.data != null) {
        return result.data!;
      } else {
        throw Exception(result.error ?? 'Failed to load session details');
      }
    });

// User Schedule state notifier
class UserScheduleNotifier extends StateNotifier<AsyncValue<List<Session>>> {
  final SessionsRepository _repository;
  String? _currentUserId;
  String? _currentEventId;

  UserScheduleNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadUserSchedule({
    required String userId,
    required String eventId,
  }) async {
    _currentUserId = userId;
    _currentEventId = eventId;
    state = const AsyncValue.loading();

    final result = await _repository.getUserSchedule(
      userId: userId,
      eventId: eventId,
    );

    if (result.success && result.data != null) {
      state = AsyncValue.data(result.data!);
    } else {
      state = AsyncValue.error(
        result.error ?? 'Failed to load user schedule',
        StackTrace.current,
      );
    }
  }

  Future<void> refresh() async {
    if (_currentUserId != null && _currentEventId != null) {
      await loadUserSchedule(
        userId: _currentUserId!,
        eventId: _currentEventId!,
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> toggleSession({
    required String userId,
    required String eventId,
    required String sessionId,
  }) async {
    final result = await _repository.addRemoveSession(
      userId: userId,
      eventId: eventId,
      sessionId: sessionId,
    );

    if (result.success) {
      await loadUserSchedule(userId: userId, eventId: eventId);
    }

    return result;
  }
}

// User Schedule provider
final userScheduleProvider =
    StateNotifierProvider<UserScheduleNotifier, AsyncValue<List<Session>>>((
      ref,
    ) {
      final repository = ref.watch(sessionsRepositoryProvider);
      return UserScheduleNotifier(repository);
    });
