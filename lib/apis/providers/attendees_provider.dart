// lib/apis/providers/attendees_provider.dart
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/dio_provider.dart';
import '../core/api_response.dart';

// Attendee model
class Attendee {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? title;
  final String? designation;
  final String? organization;
  final String? role;
  final String? location;
  final String? countryCode;
  final String? venue;
  final String? room;
  final String? photo;
  final String? about;
  final String? sortFirstName;
  final bool? canMessage;
  final String? messengerId;

  Attendee({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.title,
    this.designation,
    this.organization,
    this.role,
    this.location,
    this.countryCode,
    this.venue,
    this.room,
    this.photo,
    this.about,
    this.sortFirstName,
    this.canMessage,
    this.messengerId,
  });

  factory Attendee.fromJson(Map<String, dynamic> json) {
    return Attendee(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      title: json['title'] as String?,
      designation: json['designation'] as String?,
      organization: json['organization'] as String?,
      role: json['role'] as String?,
      location: json['location'] as String?,
      countryCode: json['countryCode'] as String?,
      venue: json['venue'] is String ? json['venue'] as String? : null,
      room: json['room'] as String?,
      photo: json['photo'] as String?,
      about: json['about'] as String?,
      sortFirstName: json['sortFirstName'] as String?,
      canMessage: json['canMessage'] as bool?,
      messengerId: json['messengerId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'title': title,
    'designation': designation,
    'organization': organization,
    'role': role,
    'location': location,
    'countryCode': countryCode,
    'venue': venue,
    'room': room,
    'photo': photo,
    'about': about,
    'sortFirstName': sortFirstName,
    'canMessage': canMessage,
    'messengerId': messengerId,
  };
}

// Attendees data model
class AttendeesData {
  final List<Attendee> attendees;
  final int totalPages;
  final int currentPage;
  final int count;

  AttendeesData({
    required this.attendees,
    required this.totalPages,
    required this.currentPage,
    required this.count,
  });

  factory AttendeesData.fromJson(Map<String, dynamic> json) {
    return AttendeesData(
      attendees: json['data'] != null
          ? (json['data'] as List)
                .map((a) => Attendee.fromJson(a as Map<String, dynamic>))
                .toList()
          : [],
      totalPages: json['totalPages'] ?? 1,
      currentPage: json['currentPage'] ?? 1,
      count: json['count'] ?? 0,
    );
  }
}

// Attendees repository
class AttendeesRepository {
  final Dio dio;

  AttendeesRepository(this.dio);

  // Get attendees list
  Future<ApiResponse<AttendeesData>> getAttendees({
    required String eventId,
    String search = '',
    int page = 1,
    int limit = 100,
  }) async {
    try {
      log(
        '🔍 Fetching attendees for event: $eventId, search: "$search", page: $page, limit: $limit',
      );

      final response = await dio.post(
        'common/getAllAttendees',
        data: {
          'eventId': eventId,
          'search': search,
          'page': page,
          'limit': limit,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      log('✅ Attendees Response Status: ${response.statusCode}');
      log('📦 Attendees Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          final attendeesData = AttendeesData.fromJson(responseData);
          log('🎉 Fetched ${attendeesData.attendees.length} attendees');

          return ApiResponse.success(
            attendeesData,
            responseData['message'] as String? ?? 'Attendees loaded',
          );
        } else {
          log('❌ Invalid response format');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Failed to fetch attendees: ${response.statusCode}');
        return ApiResponse.error('Failed to fetch attendees');
      }
    } on DioException catch (e) {
      log('❌ DioException fetching attendees: ${e.message}');
      log('❌ Response: ${e.response?.data}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('❌ Unexpected error fetching attendees: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Get attendee by ID
  Future<ApiResponse<Attendee>> getAttendeeById(String attendeeId) async {
    try {
      log('🔍 Fetching attendee details for ID: $attendeeId');

      final response = await dio.get(
        'common/getAttendeeById/$attendeeId',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      log('✅ Attendee Detail Response Status: ${response.statusCode}');
      log('📦 Attendee Detail Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic> &&
            responseData['data'] != null) {
          final attendee = Attendee.fromJson(
            responseData['data'] as Map<String, dynamic>,
          );
          log('🎉 Fetched attendee details: ${attendee.name}');

          return ApiResponse.success(
            attendee,
            responseData['message'] as String? ?? 'Attendee loaded',
          );
        } else {
          log('❌ Invalid response format');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Failed to fetch attendee: ${response.statusCode}');
        return ApiResponse.error('Failed to fetch attendee');
      }
    } on DioException catch (e) {
      log('❌ DioException fetching attendee: ${e.message}');
      log('❌ Response: ${e.response?.data}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('❌ Unexpected error fetching attendee: $e');
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
            return 'Attendee not found.';
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
final attendeesRepositoryProvider = Provider<AttendeesRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AttendeesRepository(dio);
});

// Attendees state notifier
class AttendeesNotifier extends StateNotifier<AsyncValue<AttendeesData>> {
  final AttendeesRepository _repository;
  String? _currentEventId;
  String _currentSearch = '';
  int _currentPage = 1;
  List<Attendee> _allAttendees = [];
  int _totalPages = 1;
  bool _isLoading = false;

  AttendeesNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadAttendees(
    String eventId, {
    String search = '',
    int page = 1,
    int limit = 100,
  }) async {
    // Prevent concurrent calls
    if (_isLoading) {
      log('⚠️ Already loading, skipping duplicate call');
      return;
    }

    _isLoading = true;
    log(
      '🔄 loadAttendees called: eventId=$eventId, search="$search", page=$page',
    );

    _currentEventId = eventId;
    _currentSearch = search;
    _currentPage = page;

    // If it's page 1, show loading and reset all attendees
    if (page == 1) {
      state = const AsyncValue.loading();
      _allAttendees = [];
    }

    final result = await _repository.getAttendees(
      eventId: eventId,
      search: search,
      page: page,
      limit: limit,
    );

    if (result.success && result.data != null) {
      _totalPages = result.data!.totalPages;

      // If it's page 1, replace all attendees, otherwise append
      if (page == 1) {
        _allAttendees = result.data!.attendees;
      } else {
        _allAttendees.addAll(result.data!.attendees);
      }

      // Create new AttendeesData with accumulated attendees
      final updatedData = AttendeesData(
        attendees: _allAttendees,
        totalPages: result.data!.totalPages,
        currentPage: result.data!.currentPage,
        count: _allAttendees.length,
      );

      state = AsyncValue.data(updatedData);
      log(
        '✅ loadAttendees completed: ${_allAttendees.length} attendees loaded',
      );
    } else {
      state = AsyncValue.error(
        result.error ?? 'Failed to load attendees',
        StackTrace.current,
      );
      log('❌ loadAttendees failed: ${result.error}');
    }

    _isLoading = false;
  }

  Future<void> search(String query) async {
    if (_currentEventId != null) {
      await loadAttendees(_currentEventId!, search: query, page: 1);
    }
  }

  Future<void> refresh() async {
    log('🔄 refresh() called');
    if (_currentEventId != null) {
      await loadAttendees(_currentEventId!, search: _currentSearch, page: 1);
    }
  }

  Future<void> loadMore() async {
    log(
      '📄 loadMore called: currentPage=$_currentPage, totalPages=$_totalPages, hasMore=${_currentPage < _totalPages}',
    );
    if (_currentEventId != null && _currentPage < _totalPages) {
      log('📄 Loading page ${_currentPage + 1}');
      await loadAttendees(
        _currentEventId!,
        search: _currentSearch,
        page: _currentPage + 1,
      );
    } else {
      log('📄 No more pages to load');
    }
  }

  bool get hasMore => _currentPage < _totalPages;
}

// Attendees provider
final attendeesProvider =
    StateNotifierProvider<AttendeesNotifier, AsyncValue<AttendeesData>>((ref) {
      final repository = ref.watch(attendeesRepositoryProvider);
      return AttendeesNotifier(repository);
    });

// Attendee detail provider - for individual attendee by ID
final attendeeDetailProvider = FutureProvider.family<Attendee, String>((
  ref,
  attendeeId,
) async {
  final repository = ref.watch(attendeesRepositoryProvider);
  final result = await repository.getAttendeeById(attendeeId);

  if (result.success && result.data != null) {
    return result.data!;
  } else {
    throw Exception(result.error ?? 'Failed to load attendee details');
  }
});
