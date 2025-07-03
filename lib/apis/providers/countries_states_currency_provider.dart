import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/dio_provider.dart';
import '../core/api_urls.dart';

// Repository class for API calls
class LocationRepository {
  final Dio dio;

  LocationRepository(this.dio);

  Future<List<Map<String, dynamic>>> getCountries() async {
    try {
      final response = await dio.get(ApiUrls.countries);
      
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> countriesJson = response.data['countries'] ?? [];
        return countriesJson.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load countries');
      }
    } catch (e) {
      throw Exception('Error fetching countries: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStates() async {
    try {
      final response = await dio.get(ApiUrls.states);
      
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> statesJson = response.data['states'] ?? [];
        return statesJson.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load states');
      }
    } catch (e) {
      throw Exception('Error fetching states: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCurrencies() async {
    try {
      final response = await dio.get(ApiUrls.currencies);
      
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> currenciesJson = response.data['currencies'] ?? [];
        return currenciesJson.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load currencies');
      }
    } catch (e) {
      throw Exception('Error fetching currencies: $e');
    }
  }
}

// Repository provider
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return LocationRepository(dio);
});

// Countries provider
final countriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(locationRepositoryProvider);
  return repository.getCountries();
});

// States provider
final statesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(locationRepositoryProvider);
  return repository.getStates();
});

// Currencies provider
final currenciesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(locationRepositoryProvider);
  return repository.getCurrencies();
});

// Helper providers for easier access
final countryByCodeProvider = Provider.family<Map<String, dynamic>?, String>((ref, countryCode) {
  final countriesAsyncValue = ref.watch(countriesProvider);
  return countriesAsyncValue.whenOrNull(
    data: (countries) {
      try {
        return countries.firstWhere(
          (country) => country['code1'] == countryCode,
        );
      } catch (e) {
        return countries.isNotEmpty ? countries.first : null;
      }
    },
  );
});

final stateByCodeProvider = Provider.family<Map<String, dynamic>?, String>((ref, stateCode) {
  final statesAsyncValue = ref.watch(statesProvider);
  return statesAsyncValue.whenOrNull(
    data: (states) {
      try {
        return states.firstWhere(
          (state) => state['stateCode'] == stateCode,
        );
      } catch (e) {
        return states.isNotEmpty ? states.first : null;
      }
    },
  );
});

final currencyByCodeProvider = Provider.family<Map<String, dynamic>?, String>((ref, currencyCode) {
  final currenciesAsyncValue = ref.watch(currenciesProvider);
  return currenciesAsyncValue.whenOrNull(
    data: (currencies) {
      try {
        return currencies.firstWhere(
          (currency) => currency['code'] == currencyCode,
        );
      } catch (e) {
        return currencies.isNotEmpty ? currencies.first : null;
      }
    },
  );
});

final currencyByCountryCodeProvider = Provider.family<Map<String, dynamic>?, String>((ref, countryCode) {
  final currenciesAsyncValue = ref.watch(currenciesProvider);
  return currenciesAsyncValue.whenOrNull(
    data: (currencies) {
      try {
        return currencies.firstWhere(
          (currency) => currency['country']?['code1'] == countryCode,
        );
      } catch (e) {
        return currencies.isNotEmpty ? currencies.first : null;
      }
    },
  );
});

// Active states only provider
final activeStatesProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final statesAsyncValue = ref.watch(statesProvider);
  return statesAsyncValue.when(
    data: (states) => AsyncValue.data(
      states.where((state) => state['isAvtive'] == true).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Helper providers for dropdown lists
final countriesDropdownProvider = Provider<AsyncValue<List<Map<String, String>>>>((ref) {
  final countriesAsyncValue = ref.watch(countriesProvider);
  return countriesAsyncValue.when(
    data: (countries) => AsyncValue.data(
      countries.map((country) => <String, String>{
        'id': (country['_id'] ?? '').toString(),
        'code': (country['code1'] ?? '').toString(),
        'name': (country['name'] ?? '').toString(),
        'dialCode': (country['code2'] ?? '').toString(),
      }).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final statesDropdownProvider = Provider<AsyncValue<List<Map<String, String>>>>((ref) {
  final statesAsyncValue = ref.watch(activeStatesProvider);
  return statesAsyncValue.when(
    data: (states) => AsyncValue.data(
      states.map((state) => <String, String>{
        'id': (state['_id'] ?? '').toString(),
        'name': (state['name'] ?? '').toString(),
        'code': (state['stateCode'] ?? '').toString(),
        'tin': (state['tin'] ?? '').toString(),
      }).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final currenciesDropdownProvider = Provider<AsyncValue<List<Map<String, String>>>>((ref) {
  final currenciesAsyncValue = ref.watch(currenciesProvider);
  return currenciesAsyncValue.when(
    data: (currencies) => AsyncValue.data(
      currencies.map((currency) => <String, String>{
        'id': (currency['_id'] ?? '').toString(),
        'code': (currency['code'] ?? '').toString(),
        'name': (currency['name'] ?? '').toString(),
        'countryName': (currency['country']?['name'] ?? '').toString(),
        'countryCode': (currency['country']?['code1'] ?? '').toString(),
      }).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});