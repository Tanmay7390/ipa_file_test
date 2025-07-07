// lib/apis/providers/subscription_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:Wareozo/apis/core/dio_provider.dart';
import 'package:Wareozo/apis/core/api_urls.dart';
import 'package:Wareozo/apis/providers/auth_provider.dart';

// Subscription model
class Subscription {
  final String id;
  final String plan;
  final List<SubscriptionResource> resources;

  Subscription({
    required this.id,
    required this.plan,
    required this.resources,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['_id'] ?? '',
      plan: json['plan'] ?? '',
      resources: (json['resources'] as List<dynamic>?)
              ?.map((resource) => SubscriptionResource.fromJson(resource))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'plan': plan,
      'resources': resources.map((r) => r.toJson()).toList(),
    };
  }
}

class SubscriptionResource {
  final String id;
  final String resource;
  final String action;
  final String displayName;
  final String category;
  final String type;

  SubscriptionResource({
    required this.id,
    required this.resource,
    required this.action,
    required this.displayName,
    required this.category,
    required this.type,
  });

  factory SubscriptionResource.fromJson(Map<String, dynamic> json) {
    return SubscriptionResource(
      id: json['_id'] ?? '',
      resource: json['resource'] ?? '',
      action: json['action'] ?? '',
      displayName: json['displayName'] ?? '',
      category: json['category'] ?? '',
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'resource': resource,
      'action': action,
      'displayName': displayName,
      'category': category,
      'type': type,
    };
  }
}

// Subscription state
class SubscriptionState {
  final bool isLoading;
  final bool isUpdating;
  final List<Subscription> subscriptions;
  final String? selectedSubscriptionId;
  final String? currentSubscriptionId;
  final String? error;
  final String? successMessage;

  const SubscriptionState({
    this.isLoading = false,
    this.isUpdating = false,
    this.subscriptions = const [],
    this.selectedSubscriptionId,
    this.currentSubscriptionId,
    this.error,
    this.successMessage,
  });

  SubscriptionState copyWith({
    bool? isLoading,
    bool? isUpdating,
    List<Subscription>? subscriptions,
    String? selectedSubscriptionId,
    String? currentSubscriptionId,
    String? error,
    String? successMessage,
  }) {
    return SubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      subscriptions: subscriptions ?? this.subscriptions,
      selectedSubscriptionId: selectedSubscriptionId ?? this.selectedSubscriptionId,
      currentSubscriptionId: currentSubscriptionId ?? this.currentSubscriptionId,
      error: error,
      successMessage: successMessage,
    );
  }

  // Get subscription by ID
  Subscription? getSubscriptionById(String id) {
    try {
      return subscriptions.firstWhere((sub) => sub.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get current subscription
  Subscription? get currentSubscription {
    if (currentSubscriptionId == null) return null;
    return getSubscriptionById(currentSubscriptionId!);
  }

  // Get selected subscription
  Subscription? get selectedSubscription {
    if (selectedSubscriptionId == null) return null;
    return getSubscriptionById(selectedSubscriptionId!);
  }
}

// Subscription notifier
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final Dio _dio;
  final Ref _ref;

  SubscriptionNotifier(this._dio, this._ref) : super(const SubscriptionState());

  // Fetch available subscriptions
  Future<void> fetchSubscriptions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dio.get(ApiUrls.subscriptionList);

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data != null && data['subscriptions'] != null) {
          final subscriptions = (data['subscriptions'] as List)
              .map((subscription) => Subscription.fromJson(subscription))
              .toList();

          state = state.copyWith(
            isLoading: false,
            subscriptions: subscriptions,
          );

          // Also fetch current subscription from auth state
          await _fetchCurrentSubscription();
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'Invalid response format from server',
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch subscriptions: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to fetch subscriptions';
      
      if (e.response != null) {
        switch (e.response!.statusCode) {
          case 401:
            errorMessage = 'Unauthorized. Please login again.';
            break;
          case 403:
            errorMessage = 'Access denied.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          default:
            errorMessage = 'Failed to fetch subscriptions. Please try again.';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please check your internet.';
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  // Fetch current subscription from business profile
  Future<void> _fetchCurrentSubscription() async {
    try {
      final authState = _ref.read(authProvider);
      if (authState.accountId == null) return;

      final url = ApiUrls.replaceParams(
        ApiUrls.myBusinessProfile,
        {'accountId': authState.accountId!},
      );

      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data != null && data['account'] != null) {
          final account = data['account'];
          final subscription = account['subscription'];
          
          if (subscription != null && subscription['_id'] != null) {
            state = state.copyWith(
              currentSubscriptionId: subscription['_id'],
              selectedSubscriptionId: subscription['_id'],
            );
          }
        }
      }
    } catch (e) {
      // Don't update error state as this is a background operation
      print('Error fetching current subscription: $e');
    }
  }

  // Select a subscription
  void selectSubscription(String subscriptionId) {
    state = state.copyWith(
      selectedSubscriptionId: subscriptionId,
      error: null,
      successMessage: null,
    );
  }

  // Update account subscription
  Future<bool> updateSubscription() async {
    if (state.selectedSubscriptionId == null) {
      state = state.copyWith(error: 'Please select a subscription plan');
      return false;
    }

    final authState = _ref.read(authProvider);
    if (authState.accountId == null) {
      state = state.copyWith(error: 'Account ID not found. Please login again.');
      return false;
    }

    state = state.copyWith(isUpdating: true, error: null, successMessage: null);

    try {
      final url = ApiUrls.replaceParams(
        ApiUrls.updateSubscription,
        {'accountId': authState.accountId!},
      );

      final response = await _dio.put(
        url,
        data: {
          'subscription': state.selectedSubscriptionId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        String successMessage = 'Account updated! Refresh and Relogin is required to take the changes in effect';
        
        if (data != null && data['message'] != null) {
          successMessage = data['message'];
        }

        state = state.copyWith(
          isUpdating: false,
          currentSubscriptionId: state.selectedSubscriptionId,
          successMessage: successMessage,
        );
        
        return true;
      } else {
        String errorMessage = 'Failed to update subscription';
        
        if (response.data != null && response.data is Map) {
          errorMessage = response.data['message'] ?? 
                        response.data['error'] ?? 
                        errorMessage;
        }

        state = state.copyWith(isUpdating: false, error: errorMessage);
        return false;
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to update subscription';
      
      if (e.response != null) {
        switch (e.response!.statusCode) {
          case 400:
            errorMessage = 'Invalid subscription plan selected';
            break;
          case 401:
            errorMessage = 'Unauthorized. Please login again.';
            break;
          case 403:
            errorMessage = 'Access denied. Insufficient permissions.';
            break;
          case 404:
            errorMessage = 'Account or subscription not found.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          default:
            if (e.response!.data != null && e.response!.data is Map) {
              errorMessage = e.response!.data['message'] ?? 
                            e.response!.data['error'] ?? 
                            errorMessage;
            }
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please check your internet.';
      }

      state = state.copyWith(isUpdating: false, error: errorMessage);
      return false;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'An unexpected error occurred',
      );
      return false;
    }
  }

  // Clear messages
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }

  // Reset state
  void reset() {
    state = const SubscriptionState();
  }
}

// Subscription provider
final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  final dio = ref.watch(dioProvider);
  return SubscriptionNotifier(dio, ref);
});