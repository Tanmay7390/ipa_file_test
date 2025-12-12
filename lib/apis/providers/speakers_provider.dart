// lib/apis/providers/speakers_provider.dart
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/dio_provider.dart';
import '../core/api_response.dart';

// Social Media model
class SocialMedia {
  final String? facebook;
  final String? twitter;
  final String? instagram;
  final String? linkedin;
  final String? website;

  SocialMedia({
    this.facebook,
    this.twitter,
    this.instagram,
    this.linkedin,
    this.website,
  });

  factory SocialMedia.fromJson(Map<String, dynamic> json) {
    return SocialMedia(
      facebook: json['facebook'] as String?,
      twitter: json['twitter'] as String?,
      instagram: json['instagram'] as String?,
      linkedin: json['linkedin'] as String?,
      website: json['website'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'facebook': facebook,
    'twitter': twitter,
    'instagram': instagram,
    'linkedin': linkedin,
    'website': website,
  };
}

// Speaker model
class Speaker {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? title;
  final String? designation;
  final String? organization;
  final String? specialty;
  final String? city;
  final String? location;
  final String? countryCode;
  final String? venue;
  final String? room;
  final String? category;
  final String? role;
  final String? photo;
  final String? about;
  final String? sortFirstName;
  final SocialMedia? socialMedia;
  final List<Session>? sessions;
  final bool? canMessage;
  final String? messengerId;

  Speaker({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.title,
    this.designation,
    this.organization,
    this.specialty,
    this.city,
    this.location,
    this.countryCode,
    this.venue,
    this.room,
    this.category,
    this.role,
    this.photo,
    this.about,
    this.sortFirstName,
    this.socialMedia,
    this.sessions,
    this.canMessage,
    this.messengerId,
  });

  factory Speaker.fromJson(Map<String, dynamic> json) {
    return Speaker(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      title: json['title'] as String?,
      designation: json['designation'] as String?,
      organization: json['organization'] as String?,
      specialty: json['specialty'] as String?,
      city: json['city'] as String?,
      location: json['location'] as String?,
      countryCode: json['countryCode'] as String?,
      venue: json['venue'] is String ? json['venue'] as String? : null,
      room: json['room'] as String?,
      category: json['category'] as String?,
      role: json['role'] as String?,
      photo: json['photo'] as String?,
      about: json['about'] as String?,
      sortFirstName: json['sortFirstName'] as String?,
      socialMedia: json['socialMedia'] != null
          ? SocialMedia.fromJson(json['socialMedia'] as Map<String, dynamic>)
          : null,
      sessions: json['sessions'] != null
          ? (json['sessions'] as List)
                .map((s) => Session.fromJson(s as Map<String, dynamic>))
                .toList()
          : null,
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
    'specialty': specialty,
    'city': city,
    'location': location,
    'countryCode': countryCode,
    'venue': venue,
    'room': room,
    'category': category,
    'role': role,
    'photo': photo,
    'about': about,
    'sortFirstName': sortFirstName,
    'socialMedia': socialMedia?.toJson(),
    'sessions': sessions?.map((s) => s.toJson()).toList(),
    'canMessage': canMessage,
    'messengerId': messengerId,
  };
}

// Session model
class Session {
  final String? id;
  final String? date;
  final int? sessionCount;
  final String? title;
  final String? role;
  final String? time;
  final String? location;
  final bool? addToCalendar;
  final List<String>? tags;
  final String? startTime;
  final String? endTime;
  final String? venue;
  final String? sessionType;
  final String? status;

  Session({
    this.id,
    this.date,
    this.sessionCount,
    this.title,
    this.role,
    this.time,
    this.location,
    this.addToCalendar,
    this.tags,
    this.startTime,
    this.endTime,
    this.venue,
    this.sessionType,
    this.status,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['_id'] ?? json['id'],
      date: json['date'] as String?,
      sessionCount: json['sessionCount'] as int?,
      title: json['title'] as String?,
      role: json['role'] as String?,
      time: json['time'] as String?,
      location: json['location'] as String?,
      addToCalendar: json['addToCalendar'] as bool?,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : null,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      venue: json['venue'] as String?,
      sessionType: json['sessionType'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'sessionCount': sessionCount,
    'title': title,
    'role': role,
    'time': time,
    'location': location,
    'addToCalendar': addToCalendar,
    'tags': tags,
    'startTime': startTime,
    'endTime': endTime,
    'venue': venue,
    'sessionType': sessionType,
    'status': status,
  };
}

// Speakers data model
class SpeakersData {
  final List<Speaker> speakers;
  final int totalPages;
  final int currentPage;
  final int count;

  SpeakersData({
    required this.speakers,
    required this.totalPages,
    required this.currentPage,
    required this.count,
  });

  factory SpeakersData.fromJson(Map<String, dynamic> json) {
    return SpeakersData(
      speakers: json['data'] != null
          ? (json['data'] as List)
                .map((s) => Speaker.fromJson(s as Map<String, dynamic>))
                .toList()
          : [],
      totalPages: json['totalPages'] ?? 1,
      currentPage: json['currentPage'] ?? 1,
      count: json['count'] ?? 0,
    );
  }
}

// Speakers repository
class SpeakersRepository {
  final Dio dio;

  SpeakersRepository(this.dio);

  // Get speakers list
  Future<ApiResponse<SpeakersData>> getSpeakers({
    required String eventId,
    String search = '',
    int page = 1,
    int limit = 100,
  }) async {
    try {
      log(
        '🔍 Fetching speakers for event: $eventId, search: "$search", page: $page, limit: $limit',
      );

      final response = await dio.post(
        'common/getSpeakers',
        data: {
          'eventId': eventId,
          'search': search,
          'page': page,
          'limit': limit,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      log('✅ Speakers Response Status: ${response.statusCode}');
      log('📦 Speakers Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          final speakersData = SpeakersData.fromJson(responseData);
          log('🎉 Fetched ${speakersData.speakers.length} speakers');

          return ApiResponse.success(
            speakersData,
            responseData['message'] as String? ?? 'Speakers loaded',
          );
        } else {
          log('❌ Invalid response format');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Failed to fetch speakers: ${response.statusCode}');
        return ApiResponse.error('Failed to fetch speakers');
      }
    } on DioException catch (e) {
      log('❌ DioException fetching speakers: ${e.message}');
      log('❌ Response: ${e.response?.data}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('❌ Unexpected error fetching speakers: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Get speaker by ID
  Future<ApiResponse<Speaker>> getSpeakerById(String speakerId) async {
    try {
      log('🔍 Fetching speaker details for ID: $speakerId');

      final response = await dio.get(
        'common/getSpeakerById/$speakerId',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      log('✅ Speaker Detail Response Status: ${response.statusCode}');
      log('📦 Speaker Detail Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic> &&
            responseData['data'] != null) {
          final speaker = Speaker.fromJson(
            responseData['data'] as Map<String, dynamic>,
          );
          log('🎉 Fetched speaker details: ${speaker.name}');

          return ApiResponse.success(
            speaker,
            responseData['message'] as String? ?? 'Speaker loaded',
          );
        } else {
          log('❌ Invalid response format');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Failed to fetch speaker: ${response.statusCode}');
        return ApiResponse.error('Failed to fetch speaker');
      }
    } on DioException catch (e) {
      log('❌ DioException fetching speaker: ${e.message}');
      log('❌ Response: ${e.response?.data}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('❌ Unexpected error fetching speaker: $e');
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
            return 'Speaker not found.';
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
final speakersRepositoryProvider = Provider<SpeakersRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SpeakersRepository(dio);
});

// Speakers state notifier
class SpeakersNotifier extends StateNotifier<AsyncValue<SpeakersData>> {
  final SpeakersRepository _repository;
  String? _currentEventId;
  String _currentSearch = '';
  int _currentPage = 1;
  List<Speaker> _allSpeakers = [];
  int _totalPages = 1;
  bool _isLoading = false;

  SpeakersNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadSpeakers(
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
      '🔄 loadSpeakers called: eventId=$eventId, search="$search", page=$page',
    );

    _currentEventId = eventId;
    _currentSearch = search;
    _currentPage = page;

    // If it's page 1, show loading and reset all speakers
    if (page == 1) {
      state = const AsyncValue.loading();
      _allSpeakers = [];
    }

    final result = await _repository.getSpeakers(
      eventId: eventId,
      search: search,
      page: page,
      limit: limit,
    );

    if (result.success && result.data != null) {
      _totalPages = result.data!.totalPages;

      // If it's page 1, replace all speakers, otherwise append
      if (page == 1) {
        _allSpeakers = result.data!.speakers;
      } else {
        _allSpeakers.addAll(result.data!.speakers);
      }

      // Create new SpeakersData with accumulated speakers
      final updatedData = SpeakersData(
        speakers: _allSpeakers,
        totalPages: result.data!.totalPages,
        currentPage: result.data!.currentPage,
        count: _allSpeakers.length,
      );

      state = AsyncValue.data(updatedData);
      log('✅ loadSpeakers completed: ${_allSpeakers.length} speakers loaded');
    } else {
      state = AsyncValue.error(
        result.error ?? 'Failed to load speakers',
        StackTrace.current,
      );
      log('❌ loadSpeakers failed: ${result.error}');
    }

    _isLoading = false;
  }

  Future<void> search(String query) async {
    if (_currentEventId != null) {
      await loadSpeakers(_currentEventId!, search: query, page: 1);
    }
  }

  Future<void> refresh() async {
    log('🔄 refresh() called');
    if (_currentEventId != null) {
      await loadSpeakers(_currentEventId!, search: _currentSearch, page: 1);
    }
  }

  Future<void> loadMore() async {
    log(
      '📄 loadMore called: currentPage=$_currentPage, totalPages=$_totalPages, hasMore=${_currentPage < _totalPages}',
    );
    if (_currentEventId != null && _currentPage < _totalPages) {
      log('📄 Loading page ${_currentPage + 1}');
      await loadSpeakers(
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

// Speakers provider
final speakersProvider =
    StateNotifierProvider<SpeakersNotifier, AsyncValue<SpeakersData>>((ref) {
      final repository = ref.watch(speakersRepositoryProvider);
      return SpeakersNotifier(repository);
    });

// Speaker detail provider - for individual speaker by ID
final speakerDetailProvider = FutureProvider.family<Speaker, String>((
  ref,
  speakerId,
) async {
  final repository = ref.watch(speakersRepositoryProvider);
  final result = await repository.getSpeakerById(speakerId);

  if (result.success && result.data != null) {
    return result.data!;
  } else {
    throw Exception(result.error ?? 'Failed to load speaker details');
  }
});
