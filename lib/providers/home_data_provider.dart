// lib/providers/home_data_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../apis/providers/auth_provider.dart';

// Home page data model
class HomePageData {
  final EventData? event;
  final dynamic user;
  final Statistics? statistics;
  final List<FeaturedSession> featuredSessions;
  final CheckInData? checkIn;
  final RegistrationData? registration;

  HomePageData({
    this.event,
    this.user,
    this.statistics,
    this.featuredSessions = const [],
    this.checkIn,
    this.registration,
  });

  factory HomePageData.fromJson(Map<String, dynamic> json) {
    return HomePageData(
      event: json['event'] != null
          ? EventData.fromJson(json['event'] as Map<String, dynamic>)
          : null,
      statistics: json['statistics'] != null
          ? Statistics.fromJson(json['statistics'] as Map<String, dynamic>)
          : null,
      featuredSessions: json['featured_sessions'] != null
          ? (json['featured_sessions'] as List)
                .map((s) => FeaturedSession.fromJson(s as Map<String, dynamic>))
                .toList()
          : [],
      checkIn: json['check_in'] != null
          ? CheckInData.fromJson(json['check_in'] as Map<String, dynamic>)
          : null,
      registration: json['registration'] != null
          ? RegistrationData.fromJson(
              json['registration'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

// Event data model
class EventData {
  final String id;
  final String title;
  final String? subTitle;
  final String? logo;
  final String description;
  final String? startDate;
  final String? endDate;
  final FormattedDates? formattedDates;
  final VenueData? venue;
  final String? floorMap;

  EventData({
    required this.id,
    required this.title,
    this.subTitle,
    this.logo,
    required this.description,
    this.startDate,
    this.endDate,
    this.formattedDates,
    this.venue,
    this.floorMap,
  });

  factory EventData.fromJson(Map<String, dynamic> json) {
    return EventData(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subTitle: json['subTitle'] as String?,
      logo: json['logo'] as String?,
      description: json['description'] ?? '',
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      formattedDates: json['formatted_dates'] != null
          ? FormattedDates.fromJson(
              json['formatted_dates'] as Map<String, dynamic>,
            )
          : null,
      venue: json['venue'] != null
          ? VenueData.fromJson(json['venue'] as Map<String, dynamic>)
          : null,
      floorMap: json['floorMap'] as String?,
    );
  }
}

// Formatted dates model
class FormattedDates {
  final String range;
  final String month;
  final int year;
  final String display;

  FormattedDates({
    required this.range,
    required this.month,
    required this.year,
    required this.display,
  });

  factory FormattedDates.fromJson(Map<String, dynamic> json) {
    return FormattedDates(
      range: json['range'] ?? '',
      month: json['month'] ?? '',
      year: json['year'] ?? 2025,
      display: json['display'] ?? '',
    );
  }
}

// Venue data model
class VenueData {
  final String name;
  final int? capacity;
  final Address? address;

  VenueData({required this.name, this.capacity, this.address});

  factory VenueData.fromJson(Map<String, dynamic> json) {
    return VenueData(
      name: json['name'] ?? '',
      capacity: json['capacity'] as int?,
      address: json['address'] != null
          ? Address.fromJson(json['address'] as Map<String, dynamic>)
          : null,
    );
  }
}

// Address model
class Address {
  final String street;
  final String city;
  final String state;
  final String country;
  final String zipCode;

  Address({
    required this.street,
    required this.city,
    required this.state,
    required this.country,
    required this.zipCode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      zipCode: json['zipCode'] ?? '',
    );
  }
}

// Statistics model
class Statistics {
  final int totalAttendees;
  final int totalSpeakers;
  final int totalSessions;
  final StatisticsDisplay? display;

  Statistics({
    required this.totalAttendees,
    required this.totalSpeakers,
    required this.totalSessions,
    this.display,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      totalAttendees: json['total_attendees'] ?? 0,
      totalSpeakers: json['total_speakers'] ?? 0,
      totalSessions: json['total_sessions'] ?? 0,
      display: json['display'] != null
          ? StatisticsDisplay.fromJson(json['display'] as Map<String, dynamic>)
          : null,
    );
  }
}

// Statistics display model
class StatisticsDisplay {
  final String attendees;
  final String speakers;
  final String sessions;

  StatisticsDisplay({
    required this.attendees,
    required this.speakers,
    required this.sessions,
  });

  factory StatisticsDisplay.fromJson(Map<String, dynamic> json) {
    return StatisticsDisplay(
      attendees: json['attendees']?.toString() ?? '0',
      speakers: json['speakers']?.toString() ?? '0',
      sessions: json['sessions']?.toString() ?? '0',
    );
  }
}

// Featured session model
class FeaturedSession {
  final String id;
  final String title;
  final String formattedDatetime;
  final String? organizer;
  final String icon;
  final bool isFavorite;

  FeaturedSession({
    required this.id,
    required this.title,
    required this.formattedDatetime,
    this.organizer,
    required this.icon,
    required this.isFavorite,
  });

  factory FeaturedSession.fromJson(Map<String, dynamic> json) {
    return FeaturedSession(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      formattedDatetime: json['formatted_datetime'] ?? '',
      organizer: json['organizer'] as String?,
      icon: json['icon'] ?? 'calendar',
      isFavorite: json['is_favorite'] ?? false,
    );
  }
}

// Check-in data model
class CheckInData {
  final String qrCodeData;
  final String ticketNumber;
  final bool isCheckedIn;

  CheckInData({
    required this.qrCodeData,
    required this.ticketNumber,
    required this.isCheckedIn,
  });

  factory CheckInData.fromJson(Map<String, dynamic> json) {
    return CheckInData(
      qrCodeData: json['qr_code_data'] ?? '',
      ticketNumber: json['ticket_number'] ?? '',
      isCheckedIn: json['is_checked_in'] ?? false,
    );
  }
}

// Registration data model
class RegistrationData {
  final String id;
  final String ticketNumber;
  final String registrationType;
  final String status;

  RegistrationData({
    required this.id,
    required this.ticketNumber,
    required this.registrationType,
    required this.status,
  });

  factory RegistrationData.fromJson(Map<String, dynamic> json) {
    return RegistrationData(
      id: json['id'] ?? '',
      ticketNumber: json['ticket_number'] ?? '',
      registrationType: json['registration_type'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

// State notifier for home page data (with API fetch)
class HomePageDataNotifier extends StateNotifier<AsyncValue<HomePageData?>> {
  static HomePageData? _cachedData; // In-memory cache
  static bool _isInitialized = false;
  final Future<Map<String, dynamic>> Function(String eventId) _fetchHomePageApi;

  HomePageDataNotifier(this._fetchHomePageApi) : super(_getCachedState()) {
    if (!_isInitialized) {
      _loadData();
    }
  }

  // Get cached state immediately (synchronous)
  static AsyncValue<HomePageData?> _getCachedState() {
    if (_cachedData != null) {
      return AsyncValue.data(_cachedData);
    }
    return const AsyncValue.data(
      null,
    ); // Return null immediately instead of loading
  }

  Future<void> _loadData() async {
    try {
      // First, try to load from storage for immediate display
      final homePageMap = await AuthService.getHomePage();

      if (homePageMap != null) {
        _cachedData = HomePageData.fromJson(homePageMap);
        state = AsyncValue.data(_cachedData);
        _isInitialized = true;

        // Then fetch fresh data from API if we have an eventId
        final eventId = _cachedData?.event?.id;
        if (eventId != null && eventId.isNotEmpty) {
          await _fetchFromApi(eventId);
        }
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _fetchFromApi(String eventId) async {
    try {
      print('🌐 Calling _fetchHomePageApi with eventId: $eventId');
      final homePageMap = await _fetchHomePageApi(eventId);
      print('✅ Received response from API');
      print('📦 Response data keys: ${homePageMap.keys.toList()}');

      _cachedData = HomePageData.fromJson(homePageMap);
      state = AsyncValue.data(_cachedData);
      print('✅ State updated with fresh data');

      // Also save to storage for next time
      await AuthService.saveHomePageData(homePageMap);
      print('💾 Saved to storage');
    } catch (e) {
      // Don't update state with error if we have cached data
      // Just log the error
      print('❌ Error fetching home page from API: $e');
    }
  }

  // Method to refresh data from API
  Future<void> refresh() async {
    print('🔄 HomePageDataNotifier.refresh() called');
    print('📊 Cached data exists: ${_cachedData != null}');

    final eventId = _cachedData?.event?.id;
    print('🎯 EventId from cached data: $eventId');

    if (eventId != null && eventId.isNotEmpty) {
      print('✅ EventId is valid, fetching from API...');
      // Show loading state while refreshing
      state = const AsyncValue.loading();
      await _fetchFromApi(eventId);
    } else {
      print('⚠️ No eventId found, reloading from storage');
      // If no eventId, reload from storage
      await _loadData();
    }

    print('🔄 HomePageDataNotifier.refresh() completed');
  }

  // Clear cache (for logout)
  static void clearCache() {
    _cachedData = null;
    _isInitialized = false;
  }
}

// Provider to load home page data from storage (cached and kept alive)
final homePageDataProvider =
    StateNotifierProvider<HomePageDataNotifier, AsyncValue<HomePageData?>>((
      ref,
    ) {
      // Function to fetch home page data from API
      Future<Map<String, dynamic>> fetchHomePageApi(String eventId) async {
        final authActions = ref.read(authActionsProvider);
        final result = await authActions.fetchHomePage(eventId: eventId);
        if (result.success && result.data != null) {
          return result.data!;
        } else {
          throw Exception(result.error ?? 'Failed to fetch home page');
        }
      }

      return HomePageDataNotifier(fetchHomePageApi);
    });

// Keep alive provider - prevents disposal when not in use
final homePageDataKeepaliveProvider = Provider<void>((ref) {
  ref.watch(homePageDataProvider);
  ref.keepAlive();
});
