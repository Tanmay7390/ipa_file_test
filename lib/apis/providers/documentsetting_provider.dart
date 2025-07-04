import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test_22/apis/core/dio_provider.dart';
import 'package:flutter_test_22/apis/core/api_urls.dart';
import 'package:flutter_test_22/apis/providers/auth_provider.dart';

// Document Settings State
class DocumentSettingsState {
  final List<Map<String, dynamic>> documentSettings;
  final Map<String, dynamic>? selectedDocumentSettings;
  final bool isLoading;
  final bool isFetchingById;
  final String? error;

  const DocumentSettingsState({
    this.documentSettings = const [],
    this.selectedDocumentSettings,
    this.isLoading = false,
    this.isFetchingById = false,
    this.error,
  });

  DocumentSettingsState copyWith({
    List<Map<String, dynamic>>? documentSettings,
    Map<String, dynamic>? selectedDocumentSettings,
    bool? isLoading,
    bool? isFetchingById,
    String? error,
  }) {
    return DocumentSettingsState(
      documentSettings: documentSettings ?? this.documentSettings,
      selectedDocumentSettings:
          selectedDocumentSettings ?? this.selectedDocumentSettings,
      isLoading: isLoading ?? this.isLoading,
      isFetchingById: isFetchingById ?? this.isFetchingById,
      error: error,
    );
  }
}

// Document Settings Notifier
class DocumentSettingsNotifier extends StateNotifier<DocumentSettingsState> {
  final Dio _dio;
  final Ref _ref;

  DocumentSettingsNotifier(this._dio, this._ref)
    : super(const DocumentSettingsState());

  String? get _accountId => _ref.read(authProvider).accountId;

  // Fetch all document settings
  Future<void> fetchDocumentSettings() async {
    if (_accountId == null) {
      state = state.copyWith(
        error: 'Account ID not found. Please login again.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final url = ApiUrls.replaceParams(ApiUrls.documentSettingsList, {
        'accountId': _accountId!,
      });

      print('Fetching document settings from: $url'); // Debug log

      final response = await _dio.get(url);

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response data: ${response.data}'); // Debug log

      if (response.statusCode == 200) {
        // Fixed: Look for 'documentSettings' key instead of 'data'
        final List<dynamic> data =
            response.data['documentSettings'] ??
            response.data['data'] ??
            response.data ??
            [];

        print('Parsed document settings count: ${data.length}'); // Debug log

        state = state.copyWith(
          documentSettings: data.cast<Map<String, dynamic>>(),
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch document settings',
        );
      }
    } on DioException catch (e) {
      print('DioException: ${e.message}'); // Debug log
      state = state.copyWith(isLoading: false, error: _handleDioError(e));
    } catch (e) {
      print('General exception: $e'); // Debug log
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred: $e',
      );
    }
  }

  // Get document settings by ID
  Future<Map<String, dynamic>?> getDocumentSettingsById(
    String settingsId,
  ) async {
    state = state.copyWith(isFetchingById: true, error: null);

    try {
      final url = ApiUrls.replaceParams(ApiUrls.getDocumentSettingsById, {
        'id': settingsId,
      });

      print('Fetching document settings by ID from: $url'); // Debug log

      final response = await _dio.get(url);

      print(
        'Get Document Settings By ID Response status: ${response.statusCode}',
      ); // Debug log
      print(
        'Get Document Settings By ID Response: ${response.data}',
      ); // Debug log

      if (response.statusCode == 200) {
        Map<String, dynamic>? documentSettingsData;

        if (response.data is Map<String, dynamic>) {
          // Try different possible keys where document settings data might be stored
          documentSettingsData =
              response.data['documentSettings'] ??
              response.data['data'] ??
              response.data['documentSetting'] ??
              response.data['settings'] ??
              response.data['result'] ??
              response.data;
        }

        print('Extracted document settings data: $documentSettingsData');

        // Validate the document settings data
        if (documentSettingsData != null &&
            documentSettingsData['_id'] != null) {
          state = state.copyWith(
            selectedDocumentSettings: documentSettingsData,
            isFetchingById: false,
          );
          return documentSettingsData;
        } else {
          state = state.copyWith(
            isFetchingById: false,
            error: 'Invalid document settings data received',
          );
          return null;
        }
      } else {
        state = state.copyWith(
          isFetchingById: false,
          error:
              'Failed to fetch document settings. Status: ${response.statusCode}',
        );
        return null;
      }
    } on DioException catch (e) {
      print('DioException in getDocumentSettingsById: ${e.message}');
      print('Response data: ${e.response?.data}');
      state = state.copyWith(isFetchingById: false, error: _handleDioError(e));
      return null;
    } catch (e) {
      print('General Exception in getDocumentSettingsById: $e');
      state = state.copyWith(
        isFetchingById: false,
        error: 'An unexpected error occurred: $e',
      );
      return null;
    }
  }

  // Create new document settings
  Future<bool> createDocumentSettings(
    Map<String, dynamic> documentSettingsData,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Add accountId to the data
      final dataWithAccountId = {
        ...documentSettingsData,
        'accountId': _accountId,
      };

      final response = await _dio.post(
        ApiUrls.createDocumentSettings,
        data: dataWithAccountId,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh the list after successful creation
        await fetchDocumentSettings();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to create document settings',
        );
        return false;
      }
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _handleDioError(e));
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      return false;
    }
  }

  // Update document settings
  Future<bool> updateDocumentSettings(
    String settingsId,
    Map<String, dynamic> documentSettingsData,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final url = ApiUrls.replaceParams(ApiUrls.updateDocumentSettings, {
        'id': settingsId,
      });

      final response = await _dio.put(url, data: documentSettingsData);

      if (response.statusCode == 200) {
        // Refresh the list after successful update
        await fetchDocumentSettings();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update document settings',
        );
        return false;
      }
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _handleDioError(e));
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      return false;
    }
  }

  // Delete document settings
  Future<bool> deleteDocumentSettings(String settingsId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final url = ApiUrls.replaceParams(ApiUrls.deleteDocumentSettings, {
        'id': settingsId,
      });

      final response = await _dio.delete(url);

      if (response.statusCode == 200) {
        // Refresh the list after successful deletion
        await fetchDocumentSettings();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to delete document settings',
        );
        return false;
      }
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: _handleDioError(e));
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      return false;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Clear selected document settings
  void clearSelectedDocumentSettings() {
    state = state.copyWith(selectedDocumentSettings: null);
  }

  // Handle Dio errors
  String _handleDioError(DioException e) {
    if (e.response != null) {
      switch (e.response!.statusCode) {
        case 400:
          return e.response!.data['message'] ?? 'Invalid request data';
        case 401:
          return 'Unauthorized. Please login again.';
        case 403:
          return 'Access forbidden';
        case 404:
          return 'Resource not found';
        case 500:
          return 'Server error. Please try again later.';
        default:
          return 'Request failed. Please try again.';
      }
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your internet.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Request timeout. Please try again.';
    } else {
      return 'Network error. Please check your connection.';
    }
  }
}

// Document Settings Provider
final documentSettingsProvider =
    StateNotifierProvider<DocumentSettingsNotifier, DocumentSettingsState>((
      ref,
    ) {
      final dio = ref.watch(dioProvider);
      return DocumentSettingsNotifier(dio, ref);
    });

// Auto-fetch provider that watches auth state changes
final documentSettingsAutoFetchProvider = Provider<void>((ref) {
  final authState = ref.watch(authProvider);
  final documentSettingsNotifier = ref.read(documentSettingsProvider.notifier);

  // Auto-fetch when user becomes authenticated and has accountId
  if (authState.isAuthenticated && authState.accountId != null) {
    Future.microtask(() => documentSettingsNotifier.fetchDocumentSettings());
  }
});

// Provider for getting specific document settings by ID
final getDocumentSettingsByIdProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((
      ref,
      settingsId,
    ) async {
      final documentSettingsNotifier = ref.read(
        documentSettingsProvider.notifier,
      );
      return await documentSettingsNotifier.getDocumentSettingsById(settingsId);
    });
