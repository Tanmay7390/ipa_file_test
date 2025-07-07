// lib/providers/measuring_units_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/dio_provider.dart';
import '../core/api_urls.dart';

// State for measuring units with search functionality
class MeasuringUnitsState {
  final List<Map<String, dynamic>> allUnits;
  final List<Map<String, dynamic>> filteredUnits;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const MeasuringUnitsState({
    this.allUnits = const [],
    this.filteredUnits = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  MeasuringUnitsState copyWith({
    List<Map<String, dynamic>>? allUnits,
    List<Map<String, dynamic>>? filteredUnits,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return MeasuringUnitsState(
      allUnits: allUnits ?? this.allUnits,
      filteredUnits: filteredUnits ?? this.filteredUnits,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// Measuring Units Notifier
class MeasuringUnitsNotifier extends StateNotifier<MeasuringUnitsState> {
  final Dio _dio;

  MeasuringUnitsNotifier(this._dio) : super(const MeasuringUnitsState());

  // Fetch measuring units from API
  Future<void> fetchMeasuringUnits() async {
    if (state.allUnits.isNotEmpty && !state.isLoading) {
      return; // Don't fetch if already loaded
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dio.get(
        '${ApiUrls.baseUrl}${ApiUrls.measuringUnit}',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        List<Map<String, dynamic>> units = List<Map<String, dynamic>>.from(
          data['measuringUnits'] ?? [],
        );

        // Sort alphabetically by name
        units.sort((a, b) {
          final nameA = (a['name'] ?? '').toString().toLowerCase();
          final nameB = (b['name'] ?? '').toString().toLowerCase();
          return nameA.compareTo(nameB);
        });

        state = state.copyWith(
          allUnits: units,
          filteredUnits: units,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load measuring units',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading measuring units: $e',
      );
    }
  }

  // Search/filter units
  void searchUnits(String query) {
    if (query.isEmpty) {
      state = state.copyWith(
        searchQuery: query,
        filteredUnits: state.allUnits,
      );
      return;
    }

    final queryLower = query.toLowerCase();
    final filtered = state.allUnits.where((unit) {
      final name = (unit['name'] ?? '').toString().toLowerCase();
      final code = (unit['code'] ?? '').toString().toLowerCase();
      return name.contains(queryLower) || code.contains(queryLower);
    }).toList();

    state = state.copyWith(
      searchQuery: query,
      filteredUnits: filtered,
    );
  }

  // Clear search
  void clearSearch() {
    state = state.copyWith(
      searchQuery: '',
      filteredUnits: state.allUnits,
    );
  }

  // Get unit by ID
  Map<String, dynamic>? getUnitById(String unitId) {
    try {
      return state.allUnits.firstWhere((unit) => unit['_id'] == unitId);
    } catch (e) {
      return null;
    }
  }

  // Get unit by code
  Map<String, dynamic>? getUnitByCode(String code) {
    try {
      return state.allUnits.firstWhere((unit) => unit['code'] == code);
    } catch (e) {
      return null;
    }
  }

  // Format unit display text
  String formatUnitDisplay(Map<String, dynamic> unit) {
    return "${unit['name']}(${unit['code']})";
  }

  // Get formatted display list
  List<String> getFormattedDisplayList() {
    return state.filteredUnits.map((unit) => formatUnitDisplay(unit)).toList();
  }
}

// Provider for measuring units
final measuringUnitsProvider = StateNotifierProvider<MeasuringUnitsNotifier, MeasuringUnitsState>((ref) {
  final dio = ref.watch(dioProvider);
  return MeasuringUnitsNotifier(dio);
});

// Legacy provider for backward compatibility (FutureProvider)
final measuringUnitsListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final notifier = ref.read(measuringUnitsProvider.notifier);
  await notifier.fetchMeasuringUnits();
  final state = ref.read(measuringUnitsProvider);
  return state.allUnits;
});

// Helper class for measuring units operations
class MeasuringUnitsHelper {
  static String formatUnitDisplay(Map<String, dynamic> unit) {
    return "${unit['name']}(${unit['code']})";
  }

  static String? extractCodeFromDisplay(String displayText) {
    if (displayText.contains('(') && displayText.contains(')')) {
      return displayText.substring(
        displayText.lastIndexOf('(') + 1,
        displayText.lastIndexOf(')'),
      );
    }
    return null;
  }

  static Map<String, dynamic>? findUnitByCode(
    List<Map<String, dynamic>> units, 
    String code
  ) {
    try {
      return units.firstWhere((unit) => unit['code'] == code);
    } catch (e) {
      return null;
    }
  }

  static Map<String, dynamic>? findUnitByDisplay(
    List<Map<String, dynamic>> units, 
    String displayText
  ) {
    final code = extractCodeFromDisplay(displayText);
    if (code != null) {
      return findUnitByCode(units, code);
    }
    return null;
  }
}