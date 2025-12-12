// lib/apis/providers/exhibitors_provider.dart
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/dio_provider.dart';
import '../core/api_response.dart';
import '../core/api_urls.dart';

// Exhibitor Social Media model
class ExhibitorSocialMedia {
  final String? facebook;
  final String? twitter;
  final String? instagram;
  final String? linkedin;
  final String? website;

  ExhibitorSocialMedia({
    this.facebook,
    this.twitter,
    this.instagram,
    this.linkedin,
    this.website,
  });

  factory ExhibitorSocialMedia.fromJson(Map<String, dynamic> json) {
    return ExhibitorSocialMedia(
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

// Exhibitor Media model
class ExhibitorMedia {
  final String? type;
  final String? url;
  final String? thumbnailUrl;
  final num? duration;

  ExhibitorMedia({this.type, this.url, this.thumbnailUrl, this.duration});

  factory ExhibitorMedia.fromJson(Map<String, dynamic> json) {
    return ExhibitorMedia(
      type: json['type'] as String?,
      url: json['url'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      duration: json['duration'] as num?,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'url': url,
    'thumbnailUrl': thumbnailUrl,
    'duration': duration,
  };
}

// Exhibitor model
class Exhibitor {
  final String id;
  final String? companyName;
  final String? category;
  final String? booth;
  final String? badge;
  final String? about;
  final String? photo;
  final ExhibitorSocialMedia? socialMedia;
  final ExhibitorMedia? media;
  final Map<String, dynamic>? userId; // Keeping as Map for flexibility
  final Map<String, dynamic>? eventId; // Keeping as Map for flexibility

  // Computed/Compatibility fields
  String? get website => socialMedia?.website;
  String? get email => userId?['email'];
  String? get phone => null; // Not in new schema
  String? get address => eventId?['venue']?['address']?['street'];
  String? get city => eventId?['venue']?['address']?['city'];
  String? get state => eventId?['venue']?['address']?['state'];
  String? get country => eventId?['venue']?['address']?['country'];
  String? get zipCode => eventId?['venue']?['address']?['zipCode'];

  Exhibitor({
    required this.id,
    this.companyName,
    this.category,
    this.booth,
    this.badge,
    this.about,
    this.photo,
    this.socialMedia,
    this.media,
    this.userId,
    this.eventId,
  });

  factory Exhibitor.fromJson(Map<String, dynamic> json) {
    return Exhibitor(
      id: json['_id'] ?? json['id'] ?? '',
      companyName: json['companyName'] as String?,
      category: json['category'] as String?,
      booth: json['booth'] as String?,
      badge: json['badge'] as String?,
      about: json['about'] as String?,
      photo: json['photo'] as String?,
      socialMedia: json['socialMedia'] != null
          ? ExhibitorSocialMedia.fromJson(
              json['socialMedia'] as Map<String, dynamic>,
            )
          : null,
      media: json['media'] != null
          ? ExhibitorMedia.fromJson(json['media'] as Map<String, dynamic>)
          : null,
      userId: json['userId'] is Map
          ? json['userId'] as Map<String, dynamic>
          : (json['userId'] is String ? {'_id': json['userId']} : null),
      eventId: json['eventId'] is Map
          ? json['eventId'] as Map<String, dynamic>
          : (json['eventId'] is String ? {'id': json['eventId']} : null),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'companyName': companyName,
    'category': category,
    'booth': booth,
    'badge': badge,
    'about': about,
    'photo': photo,
    'socialMedia': socialMedia?.toJson(),
    'media': media?.toJson(),
    'userId': userId,
    'eventId': eventId,

    // Compatibility fields for Detail Page
    'sponsorType': badge,
    'location': booth,
    'name': companyName,
    'website': website,
    'email': email,
    'address': address,
    'city': city,
    'state': state,
    'country': country,
    'zipCode': zipCode,
  };
}

// Exhibitors repository
class ExhibitorsRepository {
  final Dio dio;

  ExhibitorsRepository(this.dio);

  // Get exhibitors list
  Future<ApiResponse<List<Exhibitor>>> getExhibitors({
    required String userId,
    required String eventId,
  }) async {
    try {
      log('🔍 Fetching exhibitors for event: $eventId, user: $userId');

      final response = await dio.post(
        ApiUrls.getExhibitors,
        data: {'userId': userId, 'eventId': eventId},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      log('✅ Exhibitors Response Status: ${response.statusCode}');
      // log('📦 Exhibitors Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic> &&
            responseData['data'] is List) {
          final List<dynamic> dataList = responseData['data'];
          final exhibitors = dataList
              .map((e) => Exhibitor.fromJson(e as Map<String, dynamic>))
              .toList();

          log('🎉 Fetched ${exhibitors.length} exhibitors');

          return ApiResponse.success(
            exhibitors,
            responseData['message'] as String? ?? 'Exhibitors loaded',
          );
        } else {
          log('❌ Invalid response format');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Failed to fetch exhibitors: ${response.statusCode}');
        return ApiResponse.error('Failed to fetch exhibitors');
      }
    } on DioException catch (e) {
      log('❌ DioException fetching exhibitors: ${e.message}');
      log('❌ Response: ${e.response?.data}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('❌ Unexpected error fetching exhibitors: $e');
      return ApiResponse.error('An unexpected error occurred');
    }
  }

  // Get exhibitor by ID
  Future<ApiResponse<Exhibitor>> getExhibitorById(String exhibitorId) async {
    try {
      log('🔍 Fetching exhibitor details for ID: $exhibitorId');

      final url = ApiUrls.replaceParams(ApiUrls.getExhibitorById, {
        'id': exhibitorId,
      });

      final response = await dio.get(
        url,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      log('✅ Exhibitor Detail Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        log('📦 Exhibitor Detail Data: $responseData');

        if (responseData is Map<String, dynamic>) {
          Map<String, dynamic> exhibitorData;

          // Handle both wrapped and unwrapped responses
          if (responseData.containsKey('data') && responseData['data'] is Map) {
            exhibitorData = responseData['data'] as Map<String, dynamic>;
          } else {
            exhibitorData = responseData;
          }

          try {
            final exhibitor = Exhibitor.fromJson(exhibitorData);
            log('🎉 Fetched exhibitor details: ${exhibitor.companyName}');

            return ApiResponse.success(
              exhibitor,
              responseData['message'] as String? ?? 'Exhibitor loaded',
            );
          } catch (e) {
            log('❌ Error parsing exhibitor data: $e');
            return ApiResponse.error('Error parsing data');
          }
        } else {
          log('❌ Invalid response format');
          return ApiResponse.error('Invalid response format');
        }
      } else {
        log('❌ Failed to fetch exhibitor: ${response.statusCode}');
        return ApiResponse.error('Failed to fetch exhibitor');
      }
    } on DioException catch (e) {
      log('❌ DioException fetching exhibitor: ${e.message}');
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      log('❌ Unexpected error fetching exhibitor: $e');
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
            return 'Exhibitor not found.';
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
final exhibitorsRepositoryProvider = Provider<ExhibitorsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ExhibitorsRepository(dio);
});

// Exhibitors state notifier
class ExhibitorsNotifier extends StateNotifier<AsyncValue<List<Exhibitor>>> {
  final ExhibitorsRepository _repository;
  String? _currentEventId;
  String? _currentUserId;
  List<Exhibitor> _allExhibitors = [];
  bool _isLoading = false;

  ExhibitorsNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> loadExhibitors({
    required String userId,
    required String eventId,
  }) async {
    // Prevent concurrent calls if already loading same request
    if (_isLoading && _currentEventId == eventId && _currentUserId == userId) {
      return;
    }

    _isLoading = true;
    _currentEventId = eventId;
    _currentUserId = userId;

    state = const AsyncValue.loading();

    final result = await _repository.getExhibitors(
      userId: userId,
      eventId: eventId,
    );

    if (result.success && result.data != null) {
      _allExhibitors = result.data!;
      state = AsyncValue.data(_allExhibitors);
    } else {
      state = AsyncValue.error(
        result.error ?? 'Failed to load exhibitors',
        StackTrace.current,
      );
    }

    _isLoading = false;
  }

  Future<void> refresh() async {
    if (_currentEventId != null && _currentUserId != null) {
      await loadExhibitors(userId: _currentUserId!, eventId: _currentEventId!);
    }
  }

  // Simple local search since API might not support search
  void search(String query) {
    if (query.isEmpty) {
      state = AsyncValue.data(_allExhibitors);
      return;
    }

    final lowerQuery = query.toLowerCase();
    final filtered = _allExhibitors.where((e) {
      return (e.companyName?.toLowerCase().contains(lowerQuery) ?? false) ||
          (e.category?.toLowerCase().contains(lowerQuery) ?? false) ||
          (e.booth?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();

    state = AsyncValue.data(filtered);
  }
}

// Exhibitors provider
final exhibitorsProvider =
    StateNotifierProvider<ExhibitorsNotifier, AsyncValue<List<Exhibitor>>>((
      ref,
    ) {
      final repository = ref.watch(exhibitorsRepositoryProvider);
      return ExhibitorsNotifier(repository);
    });

// Exhibitor detail provider - for individual exhibitor by ID
final exhibitorDetailProvider = FutureProvider.family<Exhibitor, String>((
  ref,
  exhibitorId,
) async {
  final repository = ref.watch(exhibitorsRepositoryProvider);
  final result = await repository.getExhibitorById(exhibitorId);

  if (result.success && result.data != null) {
    return result.data!;
  } else {
    throw Exception(result.error ?? 'Failed to load exhibitor details');
  }
});
