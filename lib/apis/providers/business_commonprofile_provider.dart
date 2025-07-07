import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:Wareozo/apis/core/dio_provider.dart';
import 'package:Wareozo/apis/core/api_urls.dart';
import 'package:Wareozo/apis/providers/auth_provider.dart';

// Business Profile State
class BusinessProfileState {
  final bool isLoading;
  final Map<String, dynamic>? profile;
  final String? error;
  final bool isUpdating;

  const BusinessProfileState({
    this.isLoading = false,
    this.profile,
    this.error,
    this.isUpdating = false,
  });

  BusinessProfileState copyWith({
    bool? isLoading,
    Map<String, dynamic>? profile,
    String? error,
    bool? isUpdating,
  }) {
    return BusinessProfileState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      error: error,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }
}

// Business Profile Notifier
class BusinessProfileNotifier extends StateNotifier<BusinessProfileState> {
  final Dio _dio;
  final String? _accountId;

  BusinessProfileNotifier(this._dio, this._accountId)
    : super(const BusinessProfileState()) {
    if (_accountId != null) {
      fetchBusinessProfile();
    }
  }

  void setError(String error) {
    state = state.copyWith(error: error);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Fetch Business Profile
  Future<bool> fetchBusinessProfile() async {
    if (_accountId == null) {
      state = state.copyWith(
        error: 'Account ID not found. Please login again.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final url = ApiUrls.replaceParams(ApiUrls.myBusinessProfile, {
        'accountId': _accountId!,
      });

      print('Fetching business profile from: ${_dio.options.baseUrl}$url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Extract account data from response
        Map<String, dynamic>? profileData;
        if (data is Map<String, dynamic>) {
          if (data['accounts'] != null && data['accounts'] is List) {
            final accounts = data['accounts'] as List;
            if (accounts.isNotEmpty) {
              profileData = accounts[0] as Map<String, dynamic>;
            }
          } else {
            profileData = data;
          }
        }

        state = state.copyWith(isLoading: false, profile: profileData);
        return true;
      } else {
        String errorMessage = 'Failed to fetch business profile.';
        if (response.data != null && response.data is Map) {
          errorMessage =
              response.data['message'] ??
              response.data['error'] ??
              errorMessage;
        }

        state = state.copyWith(isLoading: false, error: errorMessage);
        return false;
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to fetch business profile.';

      if (e.response != null) {
        switch (e.response!.statusCode) {
          case 401:
            errorMessage = 'Unauthorized. Please login again.';
            break;
          case 404:
            errorMessage = 'Business profile not found.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          default:
            errorMessage = 'Failed to fetch business profile.';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please check your internet.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Request timeout. Please try again.';
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    } catch (e) {
      print('General Exception in fetchBusinessProfile: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  // Update Company Profile
  Future<bool> updateCompanyProfile(Map<String, dynamic> profileData) async {
    if (_accountId == null) {
      state = state.copyWith(
        error: 'Account ID not found. Please login again.',
      );
      return false;
    }

    state = state.copyWith(isUpdating: true, error: null);

    try {
      final url = ApiUrls.replaceParams(ApiUrls.updateCompanyProfile, {
        'accountId': _accountId!,
      });

      print('Updating company profile at: ${_dio.options.baseUrl}$url');
      print('Request data: $profileData');

      final response = await _dio.put(
        url,
        data: profileData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        // Update local state with new data
        final updatedProfile = Map<String, dynamic>.from(state.profile ?? {});
        updatedProfile.addAll(profileData);

        state = state.copyWith(isUpdating: false, profile: updatedProfile);

        // Refresh profile data
        await fetchBusinessProfile();
        return true;
      } else {
        String errorMessage = 'Failed to update company profile.';
        if (response.data != null && response.data is Map) {
          errorMessage =
              response.data['message'] ??
              response.data['error'] ??
              errorMessage;
        }

        state = state.copyWith(isUpdating: false, error: errorMessage);
        return false;
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to update company profile.';

      if (e.response != null) {
        switch (e.response!.statusCode) {
          case 400:
            if (e.response!.data is Map &&
                e.response!.data['message'] != null) {
              errorMessage = e.response!.data['message'];
            } else {
              errorMessage = 'Invalid profile data.';
            }
            break;
          case 401:
            errorMessage = 'Unauthorized. Please login again.';
            break;
          case 404:
            errorMessage = 'Business profile not found.';
            break;
          case 422:
            errorMessage = e.response!.data['message'] ?? 'Invalid input data.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          default:
            errorMessage = 'Failed to update company profile.';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please check your internet.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Request timeout. Please try again.';
      }

      state = state.copyWith(isUpdating: false, error: errorMessage);
      return false;
    } catch (e) {
      print('General Exception in updateCompanyProfile: $e');
      state = state.copyWith(
        isUpdating: false,
        error: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  // Update Legal Information
  Future<bool> updateLegalInfo(Map<String, dynamic> legalData) async {
    if (_accountId == null) {
      state = state.copyWith(
        error: 'Account ID not found. Please login again.',
      );
      return false;
    }

    state = state.copyWith(isUpdating: true, error: null);

    try {
      final url = ApiUrls.replaceParams(ApiUrls.updateLegal, {
        'accountId': _accountId!,
      });

      print('Updating legal info at: ${_dio.options.baseUrl}$url');
      print('Request data: $legalData');

      final response = await _dio.put(
        url,
        data: legalData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        // Update local state with new data
        final updatedProfile = Map<String, dynamic>.from(state.profile ?? {});
        updatedProfile.addAll(legalData);

        state = state.copyWith(isUpdating: false, profile: updatedProfile);

        // Refresh profile data
        await fetchBusinessProfile();
        return true;
      } else {
        String errorMessage = 'Failed to update legal information.';
        if (response.data != null && response.data is Map) {
          errorMessage =
              response.data['message'] ??
              response.data['error'] ??
              errorMessage;
        }

        state = state.copyWith(isUpdating: false, error: errorMessage);
        return false;
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to update legal information.';

      if (e.response != null) {
        switch (e.response!.statusCode) {
          case 400:
            if (e.response!.data is Map &&
                e.response!.data['message'] != null) {
              errorMessage = e.response!.data['message'];
            } else {
              errorMessage = 'Invalid legal data.';
            }
            break;
          case 401:
            errorMessage = 'Unauthorized. Please login again.';
            break;
          case 404:
            errorMessage = 'Business profile not found.';
            break;
          case 422:
            errorMessage = e.response!.data['message'] ?? 'Invalid input data.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          default:
            errorMessage = 'Failed to update legal information.';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please check your internet.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Request timeout. Please try again.';
      }

      state = state.copyWith(isUpdating: false, error: errorMessage);
      return false;
    } catch (e) {
      print('General Exception in updateLegalInfo: $e');
      state = state.copyWith(
        isUpdating: false,
        error: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  // Update Payment Information
  Future<bool> updatePaymentInfo(Map<String, dynamic> paymentData) async {
    if (_accountId == null) {
      state = state.copyWith(
        error: 'Account ID not found. Please login again.',
      );
      return false;
    }

    state = state.copyWith(isUpdating: true, error: null);

    try {
      final url = ApiUrls.replaceParams(ApiUrls.updatePayment, {
        'accountId': _accountId!,
      });

      print('Updating payment info at: ${_dio.options.baseUrl}$url');
      print('Request data: $paymentData');

      final response = await _dio.put(
        url,
        data: paymentData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        // Update local state with new data
        final updatedProfile = Map<String, dynamic>.from(state.profile ?? {});
        updatedProfile.addAll(paymentData);

        state = state.copyWith(isUpdating: false, profile: updatedProfile);

        // Refresh profile data
        await fetchBusinessProfile();
        return true;
      } else {
        String errorMessage = 'Failed to update payment information.';
        if (response.data != null && response.data is Map) {
          errorMessage =
              response.data['message'] ??
              response.data['error'] ??
              errorMessage;
        }

        state = state.copyWith(isUpdating: false, error: errorMessage);
        return false;
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to update payment information.';

      if (e.response != null) {
        switch (e.response!.statusCode) {
          case 400:
            if (e.response!.data is Map &&
                e.response!.data['message'] != null) {
              errorMessage = e.response!.data['message'];
            } else {
              errorMessage = 'Invalid payment data.';
            }
            break;
          case 401:
            errorMessage = 'Unauthorized. Please login again.';
            break;
          case 404:
            errorMessage = 'Business profile not found.';
            break;
          case 422:
            errorMessage = e.response!.data['message'] ?? 'Invalid input data.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          default:
            errorMessage = 'Failed to update payment information.';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please check your internet.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Request timeout. Please try again.';
      }

      state = state.copyWith(isUpdating: false, error: errorMessage);
      return false;
    } catch (e) {
      print('General Exception in updatePaymentInfo: $e');
      state = state.copyWith(
        isUpdating: false,
        error: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  // Helper methods to get specific data from profile
  Map<String, dynamic>? get companyInfo {
    if (state.profile == null) return null;

    return {
      'name': state.profile!['name'],
      'legalName': state.profile!['legalName'],
      'displayName': state.profile!['displayName'],
      'companyDesc': state.profile!['companyDesc'],
      'industryVertical': state.profile!['industryVertical'],
      'businessType': state.profile!['businessType'],
      'website': state.profile!['website'],
      'contactName': state.profile!['contactName'],
      'email': state.profile!['email'],
      'whatsAppNumber': state.profile!['whatsAppNumber'],
      'showSignatureOnInvoice': state.profile!['showSignatureOnInvoice'],
      'showLogoOnInvoice': state.profile!['showLogoOnInvoice'],
      'logo': state.profile!['logo'],
      'signature': state.profile!['signature'],
    };
  }

  Map<String, dynamic>? get legalInfo {
    if (state.profile == null) return null;

    return {
      'companyType': state.profile!['companyType'],
      'countryOfRegistration': state.profile!['countryOfRegistration'],
      'legalName': state.profile!['legalName'],
      'registrationNo': state.profile!['registrationNo'],
      'smeRegistrationFlag': state.profile!['smeRegistrationFlag'],
      'stateOfRegistration': state.profile!['stateOfRegistration'],
      'taxIdentificationNumber1': state.profile!['taxIdentificationNumber1'],
      'taxIdentificationNumber2': state.profile!['taxIdentificationNumber2'],
    };
  }

  Map<String, dynamic>? get paymentInfo {
    if (state.profile == null) return null;

    return {
      'bankAccounts': state.profile!['bankAccounts'],
      'gPayPhone': state.profile!['gPayPhone'],
      'gPayPhoneVerifiedFlag': state.profile!['gPayPhoneVerifiedFlag'],
      'qrCodeUrl': state.profile!['qrCodeUrl'],
      'upiId': state.profile!['upiId'],
    };
  }

  List<dynamic>? get addresses => state.profile?['addresses'];

  List<dynamic>? get bankAccounts => state.profile?['bankAccounts'];
}

// Business Profile Provider
final businessProfileProvider =
    StateNotifierProvider<BusinessProfileNotifier, BusinessProfileState>((ref) {
      final dio = ref.watch(dioProvider);
      final authState = ref.watch(authProvider);

      return BusinessProfileNotifier(dio, authState.accountId);
    });

// Helper providers for specific data
final companyInfoProvider = Provider<Map<String, dynamic>?>((ref) {
  final businessProfile = ref.watch(businessProfileProvider);
  return ref.read(businessProfileProvider.notifier).companyInfo;
});

final legalInfoProvider = Provider<Map<String, dynamic>?>((ref) {
  final businessProfile = ref.watch(businessProfileProvider);
  return ref.read(businessProfileProvider.notifier).legalInfo;
});

final paymentInfoProvider = Provider<Map<String, dynamic>?>((ref) {
  final businessProfile = ref.watch(businessProfileProvider);
  return ref.read(businessProfileProvider.notifier).paymentInfo;
});

final addressesProvider = Provider<List<dynamic>?>((ref) {
  final businessProfile = ref.watch(businessProfileProvider);
  return ref.read(businessProfileProvider.notifier).addresses;
});

final bankAccountsProvider = Provider<List<dynamic>?>((ref) {
  final businessProfile = ref.watch(businessProfileProvider);
  return ref.read(businessProfileProvider.notifier).bankAccounts;
});

// Business Profile Helper Provider
final businessProfileHelperProvider = Provider<BusinessProfileHelper>((ref) {
  return BusinessProfileHelper(ref);
});

class BusinessProfileHelper {
  final Ref ref;
  BusinessProfileHelper(this.ref);

  // Fetch business profile
  Future<bool> fetchProfile() async {
    return await ref
        .read(businessProfileProvider.notifier)
        .fetchBusinessProfile();
  }

  // Update company profile with validation
  Future<bool> updateCompanyProfile({
    String? name,
    String? legalName,
    String? displayName,
    String? companyDesc,
    String? industryVertical,
    List<String>? businessType,
    String? website,
    String? contactName,
    String? email,
    String? whatsAppNumber,
    bool? showSignatureOnInvoice,
    bool? showLogoOnInvoice,
    String? taxIdentificationNumber1,
    String? taxIdentificationNumber2,
  }) async {
    final Map<String, dynamic> data = {};

    if (name != null) data['name'] = name.trim();
    if (legalName != null) data['legalName'] = legalName.trim();
    if (displayName != null) data['displayName'] = displayName.trim();
    if (companyDesc != null) data['companyDesc'] = companyDesc.trim();
    if (industryVertical != null)
      data['industryVertical'] = industryVertical.trim();
    if (businessType != null) data['businessType'] = businessType;
    if (website != null) data['website'] = website.trim();
    if (contactName != null) data['contactName'] = contactName.trim();
    if (email != null) data['email'] = email.trim();
    if (whatsAppNumber != null) data['whatsAppNumber'] = whatsAppNumber.trim();
    if (showSignatureOnInvoice != null)
      data['showSignatureOnInvoice'] = showSignatureOnInvoice;
    if (showLogoOnInvoice != null)
      data['showLogoOnInvoice'] = showLogoOnInvoice;
    if (taxIdentificationNumber1 != null)
      data['taxIdentificationNumber1'] = taxIdentificationNumber1.trim();
    if (taxIdentificationNumber2 != null)
      data['taxIdentificationNumber2'] = taxIdentificationNumber2.trim();

    return await ref
        .read(businessProfileProvider.notifier)
        .updateCompanyProfile(data);
  }

  // Update legal info with validation
  Future<bool> updateLegalInfo({
    String? companyType,
    String? countryOfRegistration,
    String? legalName,
    String? registrationNo,
    bool? smeRegistrationFlag,
    String? stateOfRegistration,
    String? taxIdentificationNumber1,
    String? taxIdentificationNumber2,
  }) async {
    final Map<String, dynamic> data = {};

    if (companyType != null) data['companyType'] = companyType.trim();
    if (countryOfRegistration != null)
      data['countryOfRegistration'] = countryOfRegistration;
    if (legalName != null) data['legalName'] = legalName.trim();
    if (registrationNo != null) data['registrationNo'] = registrationNo.trim();
    if (smeRegistrationFlag != null)
      data['smeRegistrationFlag'] = smeRegistrationFlag;
    if (stateOfRegistration != null)
      data['stateOfRegistration'] = stateOfRegistration.trim();
    if (taxIdentificationNumber1 != null)
      data['taxIdentificationNumber1'] = taxIdentificationNumber1.trim();
    if (taxIdentificationNumber2 != null)
      data['taxIdentificationNumber2'] = taxIdentificationNumber2.trim();

    return await ref
        .read(businessProfileProvider.notifier)
        .updateLegalInfo(data);
  }

  // Update payment info
  Future<bool> updatePaymentInfo(Map<String, dynamic> paymentData) async {
    return await ref
        .read(businessProfileProvider.notifier)
        .updatePaymentInfo(paymentData);
  }

  // Get current profile data
  Map<String, dynamic>? get currentProfile =>
      ref.read(businessProfileProvider).profile;

  // Check if profile is loaded
  bool get isProfileLoaded => ref.read(businessProfileProvider).profile != null;

  // Check if loading
  bool get isLoading => ref.read(businessProfileProvider).isLoading;

  // Check if updating
  bool get isUpdating => ref.read(businessProfileProvider).isUpdating;

  // Get error
  String? get error => ref.read(businessProfileProvider).error;

  // Clear error
  void clearError() => ref.read(businessProfileProvider.notifier).clearError();
}
