import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:Wareozo/apis/core/dio_provider.dart';
import 'package:Wareozo/apis/core/api_urls.dart';
import 'package:Wareozo/apis/providers/auth_provider.dart';

// Category state model
class CategoryState {
  final bool isLoading;
  final List<Map<String, dynamic>> categories;
  final Map<String, List<Map<String, dynamic>>> subCategories;
  final String? error;

  const CategoryState({
    this.isLoading = false,
    this.categories = const [],
    this.subCategories = const {},
    this.error,
  });

  CategoryState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? categories,
    Map<String, List<Map<String, dynamic>>>? subCategories,
    String? error,
  }) {
    return CategoryState(
      isLoading: isLoading ?? this.isLoading,
      categories: categories ?? this.categories,
      subCategories: subCategories ?? this.subCategories,
      error: error,
    );
  }
}

// Category notifier
class CategoryNotifier extends StateNotifier<CategoryState> {
  final Dio _dio;
  final Ref _ref;

  CategoryNotifier(this._dio, this._ref) : super(const CategoryState());

  String? get _accountId => _ref.read(authProvider).accountId;

  // Get all categories
  Future<void> getCategories() async {
    if (_accountId == null) {
      state = state.copyWith(error: 'Account ID not found');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dio.get(ApiUrls.inventoryCategoryList);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data ?? [];
        final categories = data.cast<Map<String, dynamic>>();

        state = state.copyWith(isLoading: false, categories: categories);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load categories',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to load categories';

      if (e.response != null) {
        switch (e.response!.statusCode) {
          case 401:
            errorMessage = 'Unauthorized access';
            break;
          case 403:
            errorMessage = 'Access forbidden';
            break;
          case 404:
            errorMessage = 'Categories not found';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later';
            break;
          default:
            errorMessage = e.response!.data?['message'] ?? errorMessage;
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please check your internet';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Request timeout. Please try again';
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  // Get sub-categories for a specific category
  Future<void> getSubCategories(String categoryId) async {
    if (_accountId == null) {
      state = state.copyWith(error: 'Account ID not found');
      return;
    }

    try {
      final url = ApiUrls.inventorySubCategoryList.replaceAll(
        'categoryObjectId',
        categoryId,
      );

      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data ?? [];
        final subCategories = data.cast<Map<String, dynamic>>();

        Map<String, List<Map<String, dynamic>>> updatedSubCategories = Map.from(
          state.subCategories,
        );
        updatedSubCategories[categoryId] = subCategories;

        state = state.copyWith(subCategories: updatedSubCategories);
      }
    } on DioException catch (e) {
      print('Error loading sub-categories: ${e.message}');
    } catch (e) {
      print('Unexpected error loading sub-categories: $e');
    }
  }

  // Create category
  Future<bool> createCategory({required String name, String? alias}) async {
    if (_accountId == null) {
      state = state.copyWith(error: 'Account ID not found');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dio.post(
        ApiUrls.createInventoryCategory,
        data: {
          'name': name.trim(),
          if (alias != null && alias.trim().isNotEmpty) 'alias': alias.trim(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh categories list
        await getCategories();
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to create category',
        );
        return false;
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to create category';

      if (e.response != null) {
        errorMessage = e.response!.data?['message'] ?? errorMessage;
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      return false;
    }
  }

  // Update category
  Future<bool> updateCategory({
    required String categoryId,
    required String name,
    String? alias,
  }) async {
    if (_accountId == null) {
      state = state.copyWith(error: 'Account ID not found');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final url = ApiUrls.updateInventoryCategory.replaceAll(
        '{id}',
        categoryId,
      );

      final response = await _dio.put(
        url,
        data: {
          'name': name.trim(),
          if (alias != null && alias.trim().isNotEmpty) 'alias': alias.trim(),
        },
      );

      if (response.statusCode == 200) {
        // Refresh categories list
        await getCategories();
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update category',
        );
        return false;
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to update category';

      if (e.response != null) {
        errorMessage = e.response!.data?['message'] ?? errorMessage;
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      return false;
    }
  }

  // Create sub-category
  Future<bool> createSubCategory({
    required String name,
    required String categoryId,
    String? alias,
  }) async {
    if (_accountId == null) {
      state = state.copyWith(error: 'Account ID not found');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dio.post(
        ApiUrls.createInventorySubCategory,
        data: {
          'name': name.trim(),
          'category': categoryId,
          if (alias != null && alias.trim().isNotEmpty) 'alias': alias.trim(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh sub-categories for this category
        await getSubCategories(categoryId);
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to create sub-category',
        );
        return false;
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to create sub-category';

      if (e.response != null) {
        errorMessage = e.response!.data?['message'] ?? errorMessage;
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      return false;
    }
  }

  // Update sub-category
  Future<bool> updateSubCategory({
    required String subCategoryId,
    required String name,
    required String categoryId,
    String? alias,
  }) async {
    if (_accountId == null) {
      state = state.copyWith(error: 'Account ID not found');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final url = ApiUrls.updateInventorySubCategory.replaceAll(
        '{id}',
        subCategoryId,
      );

      final response = await _dio.put(
        url,
        data: {
          'name': name.trim(),
          'category': categoryId,
          if (alias != null && alias.trim().isNotEmpty) 'alias': alias.trim(),
        },
      );

      if (response.statusCode == 200) {
        // Refresh sub-categories for this category
        await getSubCategories(categoryId);
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update sub-category',
        );
        return false;
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to update sub-category';

      if (e.response != null) {
        errorMessage = e.response!.data?['message'] ?? errorMessage;
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
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
}

// Provider
final categoryProvider = StateNotifierProvider<CategoryNotifier, CategoryState>(
  (ref) {
    final dio = ref.watch(dioProvider);
    return CategoryNotifier(dio, ref);
  },
);
