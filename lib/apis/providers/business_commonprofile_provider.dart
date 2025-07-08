import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:Wareozo/apis/core/dio_provider.dart';
import 'package:Wareozo/apis/core/api_urls.dart';
import 'package:Wareozo/apis/providers/auth_provider.dart';
import 'dart:io';
import 'dart:convert';

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

  // Helper method to create properly formatted data for API
  Map<String, dynamic> _prepareApiData(Map<String, dynamic> profileData) {
    print('_prepareApiData input: $profileData');

    final Map<String, dynamic> cleanedData = {};

    profileData.forEach((key, value) {
      print('Processing key: $key, value: $value, type: ${value.runtimeType}');

      if (value != null) {
        // Handle different value types appropriately
        if (value is String) {
          final trimmed = value.trim();
          if (trimmed.isNotEmpty &&
              trimmed != 'undefined' &&
              trimmed != 'null') {
            cleanedData[key] = trimmed;
            print('Added string: $key = $trimmed');
          }
        } else if (value is List) {
          if (value.isNotEmpty) {
            // Ensure all list items are strings
            final stringList = value.map((item) => item.toString()).toList();
            cleanedData[key] = stringList;
            print('Added list: $key = $stringList');
          }
        } else if (value is bool) {
          cleanedData[key] = value;
          print('Added bool: $key = $value');
        } else if (value is num) {
          cleanedData[key] = value;
          print('Added number: $key = $value');
        } else {
          // For other types, convert to string
          cleanedData[key] = value.toString();
          print('Added converted: $key = ${value.toString()}');
        }
      }
    });

    print('_prepareApiData output: $cleanedData');
    return cleanedData;
  }

  //  the updateCompanyProfileWithFiles method:

  Future<bool> updateCompanyProfileWithFiles({
    required Map<String, dynamic> profileData,
    File? logoFile,
    File? signatureFile,
  }) async {
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
      print('Raw profileData received: $profileData');

      // Clean and prepare the data
      final cleanedData = _prepareApiData(profileData);
      print('Cleaned profile data to send: $cleanedData');

      if (cleanedData.isEmpty && logoFile == null && signatureFile == null) {
        state = state.copyWith(
          isUpdating: false,
          error: 'No valid data to update. Please check your input.',
        );
        return false;
      }

      // Check if we have files to upload
      bool hasFiles = logoFile != null || signatureFile != null;

      Response response;

      if (hasFiles) {
        // Use FormData for file uploads
        FormData formData = FormData();

        // Add profile data fields
        cleanedData.forEach((key, value) {
          if (value != null) {
            if (value is List) {
              for (int i = 0; i < value.length; i++) {
                formData.fields.add(MapEntry('$key[$i]', value[i].toString()));
              }
            } else {
              formData.fields.add(MapEntry(key, value.toString()));
            }
          }
        });

        // Add files if present
        if (logoFile != null) {
          String fileName = logoFile.path.split('/').last;
          formData.files.add(
            MapEntry(
              'logo',
              await MultipartFile.fromFile(logoFile.path, filename: fileName),
            ),
          );
          print('Adding logo file: $fileName');
        }

        if (signatureFile != null) {
          String fileName = signatureFile.path.split('/').last;
          formData.files.add(
            MapEntry(
              'signature',
              await MultipartFile.fromFile(
                signatureFile.path,
                filename: fileName,
              ),
            ),
          );
          print('Adding signature file: $fileName');
        }

        response = await _dio.put(
          url,
          data: formData,
          options: Options(
            headers: {'Accept': 'application/json'},
            validateStatus: (status) => true, // Accept all status codes
          ),
        );
      } else {
        // Send JSON data without files - SEND ALL EXPECTED FIELDS

        // Create a complete data object with all expected fields
        final completeData = {
          'name': cleanedData['name'] ?? '',
          'legalName': cleanedData['legalName'] ?? '',
          'displayName': cleanedData['displayName'] ?? '',
          'companyDesc': cleanedData['companyDesc'] ?? '',
          'industryVertical': cleanedData['industryVertical'] ?? '',
          'contactName': cleanedData['contactName'] ?? '',
          'email': cleanedData['email'] ?? '',
          'whatsAppNumber': cleanedData['whatsAppNumber'] ?? '',
          'website': cleanedData['website'] ?? '',
          'taxIdentificationNumber1':
              cleanedData['taxIdentificationNumber1'] ?? '',
          'taxIdentificationNumber2':
              cleanedData['taxIdentificationNumber2'] ?? '',
          'businessType': cleanedData['businessType'] ?? ['Service'],
          'showSignatureOnInvoice':
              cleanedData['showSignatureOnInvoice'] ?? false,
          'showLogoOnInvoice': cleanedData['showLogoOnInvoice'] ?? false,
        };

        print('Complete data being sent: $completeData');

        response = await _dio.put(
          url,
          data: completeData, // Send as Map, not JSON string
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            validateStatus: (status) => status! < 600,
          ),
        );
      }

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // Update local state with new data
        final updatedProfile = Map<String, dynamic>.from(state.profile ?? {});
        updatedProfile.addAll(cleanedData);

        // If files were uploaded, the response should contain new URLs
        if (response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          Map<String, dynamic>? accountData;
          if (responseData['account'] != null) {
            accountData = responseData['account'] as Map<String, dynamic>;
          } else if (responseData['data'] != null) {
            accountData = responseData['data'] as Map<String, dynamic>;
          } else {
            accountData = responseData;
          }

          if (accountData != null) {
            if (accountData['logo'] != null) {
              updatedProfile['logo'] = accountData['logo'];
            }
            if (accountData['signature'] != null) {
              updatedProfile['signature'] = accountData['signature'];
            }
          }
        }

        state = state.copyWith(isUpdating: false, profile: updatedProfile);
        await fetchBusinessProfile();
        return true;
      } else {
        String errorMessage = _getDetailedErrorMessage(response);

        if (response.statusCode == 500) {
          errorMessage = 'Server error: $errorMessage';
        } else if (response.statusCode == 400) {
          errorMessage = 'Invalid data: $errorMessage';
        } else if (response.statusCode == 422) {
          errorMessage = 'Validation error: $errorMessage';
        }

        print(
          'Update failed with status ${response.statusCode}: $errorMessage',
        );
        state = state.copyWith(isUpdating: false, error: errorMessage);
        return false;
      }
    } catch (e) {
      print('Error in updateCompanyProfileWithFiles: $e');
      state = state.copyWith(
        isUpdating: false,
        error: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  String _getDetailedErrorMessage(Response response) {
    if (response.data != null && response.data is Map) {
      final responseMap = response.data as Map<String, dynamic>;

      // Try to extract more detailed error information
      String errorMessage =
          responseMap['message'] ??
          responseMap['error'] ??
          responseMap['msg'] ??
          'Unknown server error';

      // Log the full response for debugging
      print('Full error response: ${response.data}');

      return errorMessage;
    }

    return 'Server returned status ${response.statusCode}';
  }

  // Update Company Profile (original method for backward compatibility)
  Future<bool> updateCompanyProfile(Map<String, dynamic> profileData) async {
    return updateCompanyProfileWithFiles(
      profileData: profileData,
      logoFile: null,
      signatureFile: null,
    );
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

      final cleanedData = _prepareApiData(legalData);
      print('Request data: $cleanedData');

      final response = await _dio.put(
        url,
        data: cleanedData,
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
        updatedProfile.addAll(cleanedData);

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

      final cleanedData = _prepareApiData(paymentData);
      print('Request data: $cleanedData');

      final response = await _dio.put(
        url,
        data: cleanedData,
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
        updatedProfile.addAll(cleanedData);

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

  // Update company profile with files - IMPROVED VERSION
  Future<bool> updateCompanyProfileWithFiles({
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
    File? logoFile,
    File? signatureFile,
  }) async {
    print('Helper method - Input parameters:');
    print('  name: $name');
    print('  legalName: $legalName');
    print('  displayName: $displayName');
    print('  companyDesc: $companyDesc');
    print('  industryVertical: $industryVertical');
    print('  businessType: $businessType');
    print('  website: $website');
    print('  contactName: $contactName');
    print('  email: $email');
    print('  whatsAppNumber: $whatsAppNumber');
    print('  taxIdentificationNumber1: $taxIdentificationNumber1');
    print('  taxIdentificationNumber2: $taxIdentificationNumber2');
    print('  showSignatureOnInvoice: $showSignatureOnInvoice');
    print('  showLogoOnInvoice: $showLogoOnInvoice');

    final Map<String, dynamic> data = {};

    // Helper function to clean string values - less aggressive
    String? cleanString(String? value) {
      if (value == null || value == 'undefined') {
        return null;
      }
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    // Add cleaned string fields - only exclude truly null/undefined values
    if (name != null) {
      final cleaned = cleanString(name);
      if (cleaned != null) data['name'] = cleaned;
    }

    if (legalName != null) {
      final cleaned = cleanString(legalName);
      if (cleaned != null) data['legalName'] = cleaned;
    }

    if (displayName != null) {
      final cleaned = cleanString(displayName);
      if (cleaned != null) data['displayName'] = cleaned;
    }

    if (companyDesc != null) {
      final cleaned = cleanString(companyDesc);
      if (cleaned != null) data['companyDesc'] = cleaned;
    }

    if (industryVertical != null) {
      final cleaned = cleanString(industryVertical);
      if (cleaned != null) data['industryVertical'] = cleaned;
    }

    if (website != null) {
      final cleaned = cleanString(website);
      if (cleaned != null) data['website'] = cleaned;
    }

    if (contactName != null) {
      final cleaned = cleanString(contactName);
      if (cleaned != null) data['contactName'] = cleaned;
    }

    if (email != null) {
      final cleaned = cleanString(email);
      if (cleaned != null) data['email'] = cleaned;
    }

    if (whatsAppNumber != null) {
      final cleaned = cleanString(whatsAppNumber);
      if (cleaned != null) data['whatsAppNumber'] = cleaned;
    }

    if (taxIdentificationNumber1 != null) {
      final cleaned = cleanString(taxIdentificationNumber1);
      if (cleaned != null) data['taxIdentificationNumber1'] = cleaned;
    }

    if (taxIdentificationNumber2 != null) {
      final cleaned = cleanString(taxIdentificationNumber2);
      if (cleaned != null) data['taxIdentificationNumber2'] = cleaned;
    }

    // Add business type array if provided and not empty
    if (businessType != null && businessType.isNotEmpty) {
      data['businessType'] = businessType;
    }

    // Add boolean fields - always include if provided (even if false)
    if (showSignatureOnInvoice != null) {
      data['showSignatureOnInvoice'] = showSignatureOnInvoice;
    }
    if (showLogoOnInvoice != null) {
      data['showLogoOnInvoice'] = showLogoOnInvoice;
    }

    print('Helper method - Final prepared data: $data');
    print('Helper method - Data size: ${data.length} fields');
    print('Helper method - Logo file: ${logoFile?.path ?? 'null'}');
    print('Helper method - Signature file: ${signatureFile?.path ?? 'null'}');

    // Ensure we have some data to update
    if (data.isEmpty && logoFile == null && signatureFile == null) {
      print('Helper method - No data to update');
      // Set a meaningful error
      ref
          .read(businessProfileProvider.notifier)
          .setError(
            'No data to update. Please make sure at least one field is filled.',
          );
      return false;
    }

    return await ref
        .read(businessProfileProvider.notifier)
        .updateCompanyProfileWithFiles(
          profileData: data,
          logoFile: logoFile,
          signatureFile: signatureFile,
        );
  }

  // Update company profile with validation (backward compatibility)
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
    return updateCompanyProfileWithFiles(
      name: name,
      legalName: legalName,
      displayName: displayName,
      companyDesc: companyDesc,
      industryVertical: industryVertical,
      businessType: businessType,
      website: website,
      contactName: contactName,
      email: email,
      whatsAppNumber: whatsAppNumber,
      showSignatureOnInvoice: showSignatureOnInvoice,
      showLogoOnInvoice: showLogoOnInvoice,
      taxIdentificationNumber1: taxIdentificationNumber1,
      taxIdentificationNumber2: taxIdentificationNumber2,
      logoFile: null,
      signatureFile: null,
    );
  }

  // Update legal info with validation
  Future<bool> updateLegalInfo({
    String? companyType,
    String? countryOfRegistration, // This will now be an ID
    String? legalName,
    String? registrationNo,
    bool? smeRegistrationFlag,
    String? stateOfRegistration, // This will now be an ID
    String? taxIdentificationNumber1,
    String? taxIdentificationNumber2,
  }) async {
    final Map<String, dynamic> data = {};

    if (companyType != null) data['companyType'] = companyType.trim();

    // For country and state, send the ID directly without trimming
    // since these are now ObjectIds from the API
    if (countryOfRegistration != null && countryOfRegistration.isNotEmpty) {
      data['countryOfRegistration'] = countryOfRegistration;
    }

    if (stateOfRegistration != null && stateOfRegistration.isNotEmpty) {
      data['stateOfRegistration'] = stateOfRegistration;
    }

    if (legalName != null) data['legalName'] = legalName.trim();
    if (registrationNo != null) data['registrationNo'] = registrationNo.trim();
    if (smeRegistrationFlag != null)
      data['smeRegistrationFlag'] = smeRegistrationFlag;
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
