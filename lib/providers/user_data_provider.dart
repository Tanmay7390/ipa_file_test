// lib/providers/user_data_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// User data model
class UserData {
  final String id;
  final String name;
  final String photo;
  final String email;
  final String role;

  UserData({
    required this.id,
    required this.name,
    required this.photo,
    required this.email,
    required this.role,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      photo: json['photo'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photo': photo,
      'email': email,
      'role': role,
    };
  }
}

// State notifier for user data (with in-memory cache)
class UserDataNotifier extends StateNotifier<AsyncValue<UserData?>> {
  static UserData? _cachedData; // In-memory cache
  static bool _isInitialized = false;

  UserDataNotifier() : super(_getCachedState()) {
    if (!_isInitialized) {
      _loadData();
    }
  }

  // Get cached state immediately (synchronous)
  static AsyncValue<UserData?> _getCachedState() {
    if (_cachedData != null) {
      return AsyncValue.data(_cachedData);
    }
    return const AsyncValue.data(
      null,
    ); // Return null immediately instead of loading
  }

  Future<void> _loadData() async {
    try {
      final userDataMap = await AuthService.getUserData();

      if (userDataMap != null) {
        _cachedData = UserData.fromJson(userDataMap);
        state = AsyncValue.data(_cachedData);
        _isInitialized = true;
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Method to refresh data
  Future<void> refresh() async {
    await _loadData();
  }

  // Clear cache (for logout)
  static void clearCache() {
    _cachedData = null;
    _isInitialized = false;
  }
}

// Provider to load user data from storage (cached and kept alive)
final userDataProvider =
    StateNotifierProvider<UserDataNotifier, AsyncValue<UserData?>>((ref) {
      return UserDataNotifier();
    });

// Keep alive provider - prevents disposal when not in use
final userDataKeepaliveProvider = Provider<void>((ref) {
  ref.watch(userDataProvider);
  ref.keepAlive();
});
