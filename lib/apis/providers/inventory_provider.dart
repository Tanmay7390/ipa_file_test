// lib/providers/inventory_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/dio_provider.dart';
import '../core/api_urls.dart';
import 'package:Wareozo/apis/providers/auth_provider.dart';

// Inventory state
class InventoryState {
  final List<Map<String, dynamic>> inventories;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;
  final int total;

  const InventoryState({
    this.inventories = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
    this.total = 0,
  });

  InventoryState copyWith({
    List<Map<String, dynamic>>? inventories,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
    int? total,
  }) {
    return InventoryState(
      inventories: inventories ?? this.inventories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
    );
  }
}

// Inventory notifier
class InventoryNotifier extends StateNotifier<InventoryState> {
  final Dio _dio;
  final Ref _ref; // Add reference to access other providers

  InventoryNotifier(this._dio, this._ref) : super(const InventoryState());
  List<Map<String, dynamic>> _originalInventories = [];

  // Get dynamic account ID from auth state
  String? get _accountId {
    final authState = _ref.read(authProvider);
    return authState.accountId;
  }

  // Get auth token
  String? get _authToken {
    final authState = _ref.read(authProvider);
    return authState.token;
  }

  // Build payload for create/update operations

  static Map<String, dynamic> buildPayload(
    Map<String, dynamic> formData,
    String accountId, {
    bool isUpdate = false,
  }) {
    // Prepare form data with proper data types
    final Map<String, dynamic> payload = {
      'name': formData['name'],
      'itemType': formData['itemType'],
      'status': formData['status'] ?? 'Active',
    };

    // Add account only for create operation
    if (!isUpdate) {
      payload['account'] = accountId;
    }

    // Add optional fields with proper validation
    if (formData['description'] != null &&
        formData['description'].toString().isNotEmpty) {
      payload['description'] = formData['description'];
    }

    if (formData['spec'] != null && formData['spec'].toString().isNotEmpty) {
      payload['spec'] = formData['spec'];
    }

    if (formData['category'] != null &&
        formData['category'].toString().isNotEmpty) {
      payload['category'] = formData['category'];
    }

    if (formData['subCategory'] != null &&
        formData['subCategory'].toString().isNotEmpty) {
      payload['subCategory'] = formData['subCategory'];
    }

    if (formData['itemCode'] != null &&
        formData['itemCode'].toString().isNotEmpty) {
      payload['itemCode'] = formData['itemCode'];
    }

    if (formData['hsnCode'] != null &&
        formData['hsnCode'].toString().isNotEmpty) {
      payload['hsnCode'] = formData['hsnCode'];
    }

    // Photos field for both Product and Service
    if (formData['photos'] != null && (formData['photos'] as List).isNotEmpty) {
      payload['photos'] = formData['photos'];
    }

    // PRICING FIELDS - ALL AS FLAT NUMBERS (FIXED)

    // Sale price as number
    if (formData['salePrice'] != null &&
        formData['salePrice'].toString().isNotEmpty) {
      payload['salePrice'] =
          double.tryParse(formData['salePrice'].toString()) ?? 0;
    }

    // Sale unit as string ID
    if (formData['saleUnit'] != null &&
        formData['saleUnit'].toString().isNotEmpty) {
      payload['saleUnit'] = formData['saleUnit'];
    }

    // Purchase price as flat number (FIXED - not as object)
    if (formData['purchasePrice'] != null &&
        formData['purchasePrice'].toString().isNotEmpty) {
      payload['purchasePrice'] =
          double.tryParse(formData['purchasePrice'].toString()) ?? 0;
    }

    // Purchase unit as string ID
    if (formData['purchaseUnit'] != null &&
        formData['purchaseUnit'].toString().isNotEmpty) {
      payload['purchaseUnit'] = formData['purchaseUnit'];
    }

    // Base and secondary units
    if (formData['baseUnit'] != null &&
        formData['baseUnit'].toString().isNotEmpty) {
      payload['baseUnit'] = formData['baseUnit'];
    }

    if (formData['secondaryUnit'] != null &&
        formData['secondaryUnit'].toString().isNotEmpty) {
      payload['secondaryUnit'] = formData['secondaryUnit'];
    }

    if (formData['conversationRate'] != null &&
        formData['conversationRate'].toString().isNotEmpty) {
      payload['conversationRate'] =
          double.tryParse(formData['conversationRate'].toString()) ?? 1;
    }

    // GST and tax
    if (formData['gst'] != null && formData['gst'].toString().isNotEmpty) {
      payload['gst'] = formData['gst'];
    }

    if (formData['taxRate'] != null) {
      payload['taxRate'] = double.tryParse(formData['taxRate'].toString()) ?? 0;
    }

    // Product-specific fields
    if (formData['itemType'] == 'Product') {
      // MRP as number
      if (formData['mrp'] != null && formData['mrp'].toString().isNotEmpty) {
        payload['mrp'] = double.tryParse(formData['mrp'].toString()) ?? 0;
      }

      // Wholesale pricing as numbers
      if (formData['wholeSalePrice'] != null &&
          formData['wholeSalePrice'].toString().isNotEmpty) {
        payload['wholeSalePrice'] =
            double.tryParse(formData['wholeSalePrice'].toString()) ?? 0;
      }

      if (formData['wholeSalePriceWithTax'] != null) {
        payload['wholeSalePriceWithTax'] = formData['wholeSalePriceWithTax'];
      }

      if (formData['wholeSaleMinQty'] != null &&
          formData['wholeSaleMinQty'].toString().isNotEmpty) {
        payload['wholeSaleMinQty'] =
            int.tryParse(formData['wholeSaleMinQty'].toString()) ?? 1;
      }

      // Discount fields as numbers
      if (formData['discountPercent'] != null &&
          formData['discountPercent'].toString().isNotEmpty) {
        payload['discountPercent'] =
            double.tryParse(formData['discountPercent'].toString()) ?? 0;
      }

      if (formData['discountAmount'] != null &&
          formData['discountAmount'].toString().isNotEmpty) {
        payload['discountAmount'] =
            double.tryParse(formData['discountAmount'].toString()) ?? 0;
      }

      if (formData['discountAboveQty'] != null &&
          formData['discountAboveQty'].toString().isNotEmpty) {
        payload['discountAboveQty'] =
            int.tryParse(formData['discountAboveQty'].toString()) ?? 0;
      }

      // Stock details as numbers
      if (formData['openingStock'] != null &&
          formData['openingStock'].toString().isNotEmpty) {
        payload['openingStock'] =
            int.tryParse(formData['openingStock'].toString()) ?? 0;
      }

      if (formData['currentStock'] != null &&
          formData['currentStock'].toString().isNotEmpty) {
        payload['currentStock'] =
            int.tryParse(formData['currentStock'].toString()) ?? 0;
      }

      if (formData['stockAsOfDate'] != null) {
        payload['stockAsOfDate'] = (formData['stockAsOfDate'] as DateTime)
            .toIso8601String();
      }

      if (formData['lowStockWarning'] != null) {
        payload['lowStockWarning'] = formData['lowStockWarning'];
      }

      if (formData['lowStockQuantity'] != null &&
          formData['lowStockQuantity'].toString().isNotEmpty) {
        payload['lowStockQuantity'] =
            int.tryParse(formData['lowStockQuantity'].toString()) ?? 0;
      }

      if (formData['reorderQty'] != null &&
          formData['reorderQty'].toString().isNotEmpty) {
        payload['reorderQty'] =
            int.tryParse(formData['reorderQty'].toString()) ?? 0;
      }

      if (formData['isRefrigerated'] != null) {
        payload['isRefrigerated'] = formData['isRefrigerated'];
      }

      // Additional product fields
      if (formData['brand'] != null &&
          formData['brand'].toString().isNotEmpty) {
        payload['brand'] = formData['brand'];
      }

      if (formData['color'] != null &&
          formData['color'].toString().isNotEmpty) {
        payload['color'] = formData['color'];
      }

      if (formData['storeName'] != null &&
          formData['storeName'].toString().isNotEmpty) {
        payload['storeName'] = formData['storeName'];
      }

      if (formData['storeLocation'] != null &&
          formData['storeLocation'].toString().isNotEmpty) {
        payload['storeLocation'] = formData['storeLocation'];
      }

      if (formData['storeName'] != null &&
          formData['storeName'].toString().isNotEmpty) {
        payload['storeName'] = formData['storeName'];
      }

      // Only add storeLocation as an object if we have location data
      if (formData['storeLocation'] != null &&
          formData['storeLocation'].toString().isNotEmpty) {
        payload['storeLocation'] = {
          if (formData['storeName'] != null &&
              formData['storeName'].toString().isNotEmpty)
            'storeName': formData['storeName'],
          'location': formData['storeLocation'],
        };
      } else if (formData['storeName'] != null &&
          formData['storeName'].toString().isNotEmpty) {
        // If we only have storeName, send it as a simple object
        payload['storeLocation'] = {'storeName': formData['storeName']};
      }
    }
    // Custom fields - filter out empty fields
    if (formData['customFields'] != null) {
      List<Map<String, String>> validCustomFields =
          (formData['customFields'] as List<Map<String, String>>)
              .where(
                (field) =>
                    field['name']?.isNotEmpty == true &&
                    field['value']?.isNotEmpty == true,
              )
              .toList();

      if (validCustomFields.isNotEmpty) {
        payload['additionalFields'] = validCustomFields;
      }
    }

    // Tags
    if (formData['tags'] != null && (formData['tags'] as List).isNotEmpty) {
      payload['tags'] = formData['tags'];
    }

    // Debug print to see the final payload
    print('=== FINAL API PAYLOAD (CORRECTED) ===');
    print(payload);
    print('=====================================');

    return payload;
  }

  // Create inventory with form data
  Future<InventoryResult> createInventoryFromForm(
    Map<String, dynamic> formData,
  ) async {
    if (_accountId == null) {
      return InventoryResult.error('Account ID not found');
    }

    if (_authToken == null) {
      return InventoryResult.error('Authentication token not found');
    }

    try {
      final payload = buildPayload(formData, _accountId!, isUpdate: false);

      final response = await _dio.post(
        ApiUrls.createInventory,
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_authToken',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      print('Create Response status: ${response.statusCode}');
      print('Create Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;

        // Add the new inventory to the local state
        final updatedInventories = [data, ...state.inventories];
        state = state.copyWith(
          inventories: updatedInventories,
          total: state.total + 1,
        );

        return InventoryResult.success(
          data,
          message: formData['itemType'] == 'Service'
              ? 'Service created successfully'
              : 'Inventory item created successfully',
        );
      } else {
        return _handleErrorResponse(response, isUpdate: false);
      }
    } on DioException catch (e) {
      return _handleDioException(e, isUpdate: false);
    } catch (e) {
      print('General Exception: $e');
      return InventoryResult.error('An unexpected error occurred');
    }
  }

  // Update inventory with form data
  Future<InventoryResult> updateInventoryFromForm(
    String inventoryId,
    Map<String, dynamic> formData,
  ) async {
    if (_accountId == null) {
      return InventoryResult.error('Account ID not found');
    }

    if (_authToken == null) {
      return InventoryResult.error('Authentication token not found');
    }

    try {
      final payload = buildPayload(formData, _accountId!, isUpdate: true);

      final url = ApiUrls.replaceParams(ApiUrls.updateInventory, {
        'id': inventoryId,
      });

      final response = await _dio.put(
        url,
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_authToken',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      print('Update Response status: ${response.statusCode}');
      print('Update Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;

        // Update the inventory in the local state
        final updatedInventories = state.inventories.map((item) {
          if (item['_id'] == inventoryId) {
            return {...item, ...data};
          }
          return item;
        }).toList();

        state = state.copyWith(inventories: updatedInventories);

        return InventoryResult.success(
          data,
          message: formData['itemType'] == 'Service'
              ? 'Service updated successfully'
              : 'Inventory item updated successfully',
        );
      } else {
        return _handleErrorResponse(response, isUpdate: true);
      }
    } on DioException catch (e) {
      return _handleDioException(e, isUpdate: true);
    } catch (e) {
      print('General Exception: $e');
      return InventoryResult.error('An unexpected error occurred');
    }
  }

  // Handle error responses
  InventoryResult _handleErrorResponse(
    Response response, {
    required bool isUpdate,
  }) {
    String errorMessage = isUpdate
        ? 'Failed to update inventory item'
        : 'Failed to create inventory item';

    if (response.data != null && response.data is Map) {
      if (response.data['message'] != null) {
        errorMessage = response.data['message'];
      } else if (response.data['errors'] != null) {
        final errors = response.data['errors'] as Map;
        List<String> errorMessages = [];

        errors.forEach((key, value) {
          if (value is Map && value['message'] != null) {
            errorMessages.add('${key}: ${value['message']}');
          } else {
            errorMessages.add('${key}: Invalid value');
          }
        });

        errorMessage = errorMessages.join('\n');
      }
    }

    return InventoryResult.error(errorMessage);
  }

  // Handle Dio exceptions
  InventoryResult _handleDioException(
    DioException e, {
    required bool isUpdate,
  }) {
    String errorMessage = isUpdate
        ? 'Failed to update inventory'
        : 'Failed to create inventory';

    if (e.response != null) {
      print('Error Response: ${e.response!.data}');
      print('Error Status Code: ${e.response!.statusCode}');

      switch (e.response!.statusCode) {
        case 401:
          errorMessage = 'Authentication required';
          break;
        case 403:
          errorMessage = 'Access denied';
          break;
        case 422:
          errorMessage = 'Validation error';
          if (e.response!.data != null && e.response!.data is Map) {
            final errors = e.response!.data;
            if (errors['message'] != null) {
              errorMessage = errors['message'];
            }
          }
          break;
        case 500:
          errorMessage = 'Server error';
          break;
      }
    } else if (e.type == DioExceptionType.connectionTimeout) {
      errorMessage = 'Connection timeout';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Request timeout';
    }

    return InventoryResult.error(errorMessage);
  }

  // Fetch inventories - basic fetch or with filters
  Future<void> fetchInventories({
    bool isRefresh = false,
    String? searchQuery,
    String? itemType,
    String? status,
    double? minPrice,
    double? maxPrice,
    String? stockFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Check if account ID is available
    if (_accountId == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'Account ID not found. Please login again.',
      );
      return;
    }

    if (state.isLoading && !isRefresh) return;

    if (isRefresh) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 1,
        hasMore: true,
      );
    } else {
      if (!state.hasMore) return;
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      // Use the same inventoryList endpoint for both basic and filtered requests
      final url = ApiUrls.replaceParams(ApiUrls.inventoryList, {
        'accountId': _accountId!,
      });

      Map<String, dynamic> queryParams = {};

      // Check if any filters or search are applied
      bool hasFilters =
          searchQuery != null && searchQuery.isNotEmpty ||
          itemType != null ||
          status != null ||
          minPrice != null ||
          maxPrice != null ||
          startDate != null ||
          endDate != null;

      if (hasFilters) {
        // Add filter-specific parameters
        queryParams['limit'] = 50; // Higher limit for filtered results
        queryParams['page'] = 1; // Always start from page 1 for filters

        // Add search filter
        if (searchQuery != null && searchQuery.isNotEmpty) {
          queryParams['search'] = searchQuery;
        }

        // Add date filters
        if (startDate != null) {
          queryParams['start'] = startDate.toIso8601String();
        }
        if (endDate != null) {
          queryParams['end'] = endDate.toIso8601String();
        }

        // Add other filters
        if (itemType != null && itemType.isNotEmpty) {
          queryParams['itemType'] = itemType;
        }
        if (status != null && status.isNotEmpty) {
          queryParams['status'] = status;
        }
        if (minPrice != null) {
          queryParams['minPrice'] = minPrice;
        }
        if (maxPrice != null) {
          queryParams['maxPrice'] = maxPrice;
        }
      } else {
        // Basic pagination for normal listing
        if (!isRefresh && state.currentPage > 1) {
          queryParams = {'page': state.currentPage, 'limit': 20};
        }
      }

      print('API URL: $url');
      print('Query Params: $queryParams');

      final response = await _dio.get(
        url,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(headers: {'Authorization': 'Bearer $_authToken'}),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        print('API Response: $data');

        // Replace this section in fetchInventories method:
        List<Map<String, dynamic>> newInventories = [];

        // Check different possible keys for inventories data
        if (data['inventories'] != null && data['inventories'] is List) {
          final inventoriesList = data['inventories'] as List;
          print('Inventories count: ${inventoriesList.length}');
          print('Total from API: ${data['total']}');

          // If inventories array is empty but total > 0, there might be a parameter issue
          if (inventoriesList.isEmpty && (data['total'] ?? 0) > 0) {
            print(
              'Warning: API returned empty inventories array but total > 0',
            );
            print('This might indicate parameter naming issues');

            // Try to find inventories in other possible keys
            const possibleKeys = [
              'data',
              'items',
              'results',
              'records',
              'list',
            ];
            for (String key in possibleKeys) {
              if (data[key] != null &&
                  data[key] is List &&
                  (data[key] as List).isNotEmpty) {
                print('Found inventories in key: $key');
                newInventories = (data[key] as List)
                    .map((item) => item as Map<String, dynamic>)
                    .toList();
                break;
              }
            }
          } else if (inventoriesList.isNotEmpty) {
            newInventories = inventoriesList
                .map((item) => item as Map<String, dynamic>)
                .toList();
          }
        } else {
          // Try alternative keys
          const possibleKeys = ['data', 'items', 'results', 'records'];
          for (String key in possibleKeys) {
            if (data[key] != null && data[key] is List) {
              newInventories = (data[key] as List)
                  .map((item) => item as Map<String, dynamic>)
                  .toList();
              print('Found inventories in alternative key: $key');
              break;
            }
          }
        }

        print('Final newInventories count: ${newInventories.length}');

        // Apply client-side stock filtering if needed
        if (stockFilter != null && stockFilter != 'all') {
          newInventories = newInventories.where((item) {
            switch (stockFilter) {
              case 'in_stock':
                return InventoryHelper.getCurrentStock(item) > 0;
              case 'low_stock':
                return InventoryHelper.isLowStock(item) &&
                    !InventoryHelper.isOutOfStock(item);
              case 'out_of_stock':
                return InventoryHelper.isOutOfStock(item);
              default:
                return true;
            }
          }).toList();
        }

        final int total =
            data['total'] ?? data['totalCount'] ?? data['count'] ?? 0;

        List<Map<String, dynamic>> updatedInventories;
        if (isRefresh) {
          _originalInventories = newInventories;
          updatedInventories = newInventories;
        } else {
          _originalInventories.addAll(newInventories);
          updatedInventories = [...state.inventories, ...newInventories];
        }

        state = state.copyWith(
          inventories: updatedInventories,
          isLoading: false,
          hasMore: newInventories.length >= 20,
          currentPage: isRefresh ? 2 : state.currentPage + 1,
          total: stockFilter != null && stockFilter != 'all'
              ? updatedInventories.length
              : total,
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to load inventories';

      if (e.response != null) {
        print('Error Response: ${e.response!.data}');
        print('Error Status Code: ${e.response!.statusCode}');

        switch (e.response!.statusCode) {
          case 401:
            errorMessage = 'Authentication required';
            break;
          case 403:
            errorMessage = 'Access denied';
            break;
          case 404:
            errorMessage = 'Inventories not found';
            break;
          case 500:
            errorMessage = 'Server error';
            break;
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Request timeout';
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
    } catch (e) {
      print('General Exception: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  // Get inventory by ID
  Future<Map<String, dynamic>?> getInventoryById(String inventoryId) async {
    try {
      final url = ApiUrls.replaceParams(ApiUrls.getInventorybyId, {
        'id': inventoryId,
      });

      final response = await _dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $_authToken'}),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      }
      return null;
    } on DioException catch (e) {
      String errorMessage = 'Failed to load inventory';

      if (e.response != null) {
        print('Error Response: ${e.response!.data}');
        print('Error Status Code: ${e.response!.statusCode}');

        switch (e.response!.statusCode) {
          case 401:
            errorMessage = 'Authentication required';
            break;
          case 403:
            errorMessage = 'Access denied';
            break;
          case 404:
            errorMessage = 'Inventory not found';
            break;
          case 500:
            errorMessage = 'Server error';
            break;
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Request timeout';
      }

      throw Exception(errorMessage);
    } catch (e) {
      print('General Exception: $e');
      throw Exception('An unexpected error occurred');
    }
  }

  // Legacy methods (kept for backward compatibility)
  Future<Map<String, dynamic>?> updateInventory(
    String inventoryId,
    Map<String, dynamic> updateData,
  ) async {
    final result = await updateInventoryFromForm(inventoryId, updateData);
    if (result.isSuccess) {
      return result.data;
    } else {
      throw Exception(result.errorMessage);
    }
  }

  Future<Map<String, dynamic>?> createInventory(
    Map<String, dynamic> inventoryData,
  ) async {
    final result = await createInventoryFromForm(inventoryData);
    if (result.isSuccess) {
      return result.data;
    } else {
      throw Exception(result.errorMessage);
    }
  }

  // Optional: Add a provider for single inventory if you need state management
  final singleInventoryProvider =
      StateProvider.family<Map<String, dynamic>?, String>(
        (ref, inventoryId) => null,
      );

  // Method to fetch and store single inventory in provider
  Future<void> fetchInventoryById(String inventoryId) async {
    try {
      final inventory = await getInventoryById(inventoryId);
      if (inventory != null) {
        _ref.read(singleInventoryProvider(inventoryId).notifier).state =
            inventory;
      }
    } catch (e) {
      // Handle error as needed
      print('Error fetching inventory: $e');
      _ref.read(singleInventoryProvider(inventoryId).notifier).state = null;
    }
  }

  // Search inventories using the same endpoint with filter parameter
  Future<void> searchInventories(String query) async {
    if (_accountId == null) {
      state = state.copyWith(
        error: 'Account ID not found. Please login again.',
      );
      return;
    }

    if (query.isEmpty) {
      await fetchInventories(isRefresh: true);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final url = ApiUrls.replaceParams(ApiUrls.inventoryList, {
        'accountId': _accountId!,
      });

      // Try different parameter names that APIs commonly use
      final response = await _dio.get(
        url,
        queryParameters: {
          'search': query, // Changed from 'filter' to 'search'
          'page': 1,
          'limit': 50,
        },
        options: Options(headers: {'Authorization': 'Bearer $_authToken'}),
      );

      print('Search API URL: $url');
      print('Search Query Params: {search: $query, page: 1, limit: 50}');
      print('Search Response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Handle different possible response structures
        List<Map<String, dynamic>> searchResults = [];

        if (data['inventories'] != null && data['inventories'] is List) {
          searchResults = (data['inventories'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        } else if (data['data'] != null && data['data'] is List) {
          searchResults = (data['data'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        } else if (data['results'] != null && data['results'] is List) {
          searchResults = (data['results'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        }

        // If API returns total but empty array, try client-side filtering
        if (searchResults.isEmpty && (data['total'] ?? 0) > 0) {
          print(
            'API returned empty results but total > 0, trying client-side search...',
          );
          await _performClientSideSearch(query);
          return;
        }

        print('Search Results Count: ${searchResults.length}');
        print('API Total: ${data['total']}');

        state = state.copyWith(
          inventories: searchResults,
          isLoading: false,
          hasMore: false,
          currentPage: 1,
          total: data['total'] ?? searchResults.length,
        );
      }
    } catch (e) {
      print('Search error: $e');
      // Fallback to client-side search if API search fails
      await _performClientSideSearch(query);
    }
  }

  // Add this new method for client-side search fallback
  Future<void> _performClientSideSearch(String query) async {
    try {
      // Fetch all inventories first if not already loaded
      if (_originalInventories.isEmpty) {
        await fetchInventories(isRefresh: true);
      }

      final queryLower = query.toLowerCase();
      final filteredResults = _originalInventories.where((item) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        final description = (item['description'] ?? '')
            .toString()
            .toLowerCase();
        final itemCode = (item['itemCode'] ?? '').toString().toLowerCase();
        final hsnCode = (item['hsnCode'] ?? '').toString().toLowerCase();

        return name.contains(queryLower) ||
            description.contains(queryLower) ||
            itemCode.contains(queryLower) ||
            hsnCode.contains(queryLower);
      }).toList();

      state = state.copyWith(
        inventories: filteredResults,
        isLoading: false,
        hasMore: false,
        currentPage: 1,
        total: filteredResults.length,
      );

      print('Client-side search completed: ${filteredResults.length} results');
    } catch (e) {
      print('Client-side search error: $e');
      state = state.copyWith(isLoading: false, error: 'Search failed');
    }
  }

  // Filter inventories with all parameters
  Future<void> filterInventories({
    String? itemType,
    String? status,
    double? minPrice,
    double? maxPrice,
    String? stockFilter,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async {
    if (_accountId == null) {
      state = state.copyWith(
        error: 'Account ID not found. Please login again.',
      );
      return;
    }

    // If no filters are applied, use basic fetch
    bool hasServerFilters =
        searchQuery != null && searchQuery.isNotEmpty ||
        itemType != null ||
        status != null ||
        minPrice != null ||
        maxPrice != null ||
        startDate != null ||
        endDate != null;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Always fetch all data first
      await _fetchAllInventoriesForFiltering();

      // Apply filters client-side
      List<Map<String, dynamic>> filteredResults = List.from(
        _originalInventories,
      );

      // Apply search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final queryLower = searchQuery.toLowerCase();
        filteredResults = filteredResults.where((item) {
          final name = (item['name'] ?? '').toString().toLowerCase();
          final description = (item['description'] ?? '')
              .toString()
              .toLowerCase();
          final itemCode = (item['itemCode'] ?? '').toString().toLowerCase();
          final hsnCode = (item['hsnCode'] ?? '').toString().toLowerCase();

          return name.contains(queryLower) ||
              description.contains(queryLower) ||
              itemCode.contains(queryLower) ||
              hsnCode.contains(queryLower);
        }).toList();
      }

      // Apply item type filter
      if (itemType != null) {
        filteredResults = filteredResults.where((item) {
          return InventoryHelper.getItemType(item) == itemType;
        }).toList();
      }

      // Apply status filter
      if (status != null) {
        filteredResults = filteredResults.where((item) {
          return InventoryHelper.getStatus(item) == status;
        }).toList();
      }

      // Apply price range filter
      if (minPrice != null || maxPrice != null) {
        filteredResults = filteredResults.where((item) {
          final price = InventoryHelper.getInventoryPrice(item);
          bool matchesMin = minPrice == null || price >= minPrice;
          bool matchesMax = maxPrice == null || price <= maxPrice;
          return matchesMin && matchesMax;
        }).toList();
      }

      // Apply date filter
      if (startDate != null || endDate != null) {
        filteredResults = filteredResults.where((item) {
          DateTime? createdDate;
          if (item['createdAt'] != null) {
            try {
              createdDate = DateTime.parse(item['createdAt']);
            } catch (e) {
              return false;
            }
          }

          if (createdDate == null) return false;

          bool matchesStart =
              startDate == null ||
              createdDate.isAfter(startDate.subtract(Duration(days: 1)));
          bool matchesEnd =
              endDate == null ||
              createdDate.isBefore(endDate.add(Duration(days: 1)));

          return matchesStart && matchesEnd;
        }).toList();
      }

      // Apply stock filter
      if (stockFilter != null && stockFilter != 'all') {
        filteredResults = filteredResults.where((item) {
          switch (stockFilter) {
            case 'in_stock':
              return InventoryHelper.getCurrentStock(item) > 0;
            case 'low_stock':
              return InventoryHelper.isLowStock(item) &&
                  !InventoryHelper.isOutOfStock(item);
            case 'out_of_stock':
              return InventoryHelper.isOutOfStock(item);
            default:
              return true;
          }
        }).toList();
      }

      print('Filter Results: ${filteredResults.length} items found');
      print(
        'Applied filters: itemType=$itemType, status=$status, stockFilter=$stockFilter',
      );
      print('Price range: $minPrice - $maxPrice');
      print('Date range: $startDate - $endDate');

      state = state.copyWith(
        inventories: filteredResults,
        isLoading: false,
        hasMore: false,
        currentPage: 1,
        total: filteredResults.length,
      );
    } catch (e) {
      print('Filter error: $e');
      state = state.copyWith(isLoading: false, error: 'Filter failed: $e');
    }
  }

  // Helper method to fetch all inventories for filtering
  Future<void> _fetchAllInventoriesForFiltering() async {
    if (_originalInventories.isEmpty) {
      try {
        final url = ApiUrls.replaceParams(ApiUrls.inventoryList, {
          'accountId': _accountId!,
        });

        final response = await _dio.get(
          url,
          queryParameters: {'limit': 1000}, // Fetch more items for filtering
          options: Options(headers: {'Authorization': 'Bearer $_authToken'}),
        );

        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;

          List<Map<String, dynamic>> allInventories = [];

          if (data['inventories'] != null && data['inventories'] is List) {
            allInventories = (data['inventories'] as List)
                .map((item) => item as Map<String, dynamic>)
                .toList();
          } else if (data['data'] != null && data['data'] is List) {
            allInventories = (data['data'] as List)
                .map((item) => item as Map<String, dynamic>)
                .toList();
          }

          _originalInventories = allInventories;
          print(
            'Fetched ${_originalInventories.length} inventories for filtering',
          );
        }
      } catch (e) {
        print('Error fetching all inventories: $e');
        // Use current state inventories as fallback
        _originalInventories = List.from(state.inventories);
      }
    }
  }

  // Client-side filtering method (kept for legacy support)
  Future<void> filterInventoriesClientSide({
    String? itemType,
    String? status,
    double? minPrice,
    double? maxPrice,
    String? stockFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await filterInventories(
      itemType: itemType,
      status: status,
      minPrice: minPrice,
      maxPrice: maxPrice,
      stockFilter: stockFilter,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Refresh inventories
  Future<void> refresh() async {
    await fetchInventories(isRefresh: true);
  }
}

// Result class for create/update operations
class InventoryResult {
  final bool isSuccess;
  final Map<String, dynamic>? data;
  final String? errorMessage;
  final String? successMessage;

  const InventoryResult._({
    required this.isSuccess,
    this.data,
    this.errorMessage,
    this.successMessage,
  });

  factory InventoryResult.success(
    Map<String, dynamic> data, {
    String? message,
  }) {
    return InventoryResult._(
      isSuccess: true,
      data: data,
      successMessage: message,
    );
  }

  factory InventoryResult.error(String message) {
    return InventoryResult._(isSuccess: false, errorMessage: message);
  }
}

// Updated inventory provider with ref parameter
final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
      final dio = ref.watch(dioProvider);
      return InventoryNotifier(dio, ref);
    });

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filter providers
final itemTypeFilterProvider = StateProvider<String?>((ref) => null);
final statusFilterProvider = StateProvider<String?>((ref) => null);
final priceRangeFilterProvider = StateProvider<Map<String, double?>>(
  (ref) => {'min': null, 'max': null},
);

// Date filter providers
final dateFilterProvider = StateProvider<String?>((ref) => null);
final customStartDateProvider = StateProvider<DateTime?>((ref) => null);
final customEndDateProvider = StateProvider<DateTime?>((ref) => null);

// Helper functions for inventory data
class InventoryHelper {
  static String getInventoryName(Map<String, dynamic> inventory) {
    return inventory['name'] ?? 'Unknown Item';
  }

  static String getInventoryDescription(Map<String, dynamic> inventory) {
    return inventory['description'] ?? '';
  }

  static double getInventoryPrice(Map<String, dynamic> inventory) {
    // Try different price fields
    if (inventory['mrp'] != null) {
      return (inventory['mrp'] as num).toDouble();
    }
    if (inventory['sale'] != null && inventory['sale']['price'] != null) {
      return (inventory['sale']['price'] as num).toDouble();
    }
    if (inventory['salesPrice'] != null) {
      return (inventory['salesPrice'] as num).toDouble();
    }
    return 0.0;
  }

  static double getPurchasePrice(Map<String, dynamic> inventory) {
    if (inventory['purchase'] != null &&
        inventory['purchase']['price'] != null) {
      return (inventory['purchase']['price'] as num).toDouble();
    }
    if (inventory['purchasePrice'] != null) {
      return (inventory['purchasePrice'] as num).toDouble();
    }
    return 0.0;
  }

  static int getCurrentStock(Map<String, dynamic> inventory) {
    if (inventory['currentStock'] != null) {
      return (inventory['currentStock'] as num).toInt();
    }
    if (inventory['stock'] != null &&
        inventory['stock']['currentStock'] != null) {
      return (inventory['stock']['currentStock'] as num).toInt();
    }
    return 0;
  }

  static String getItemType(Map<String, dynamic> inventory) {
    return inventory['itemType'] ?? 'Product';
  }

  static String getStatus(Map<String, dynamic> inventory) {
    return inventory['status'] ?? 'Active';
  }

  static String getItemCode(Map<String, dynamic> inventory) {
    return inventory['itemCode'] ?? '';
  }

  static String getHsnCode(Map<String, dynamic> inventory) {
    return inventory['hsnCode'] ?? '';
  }

  static List<String> getPhotos(Map<String, dynamic> inventory) {
    if (inventory['photos'] != null && inventory['photos'] is List) {
      return (inventory['photos'] as List).cast<String>();
    }
    return [];
  }

  static Map<String, dynamic>? getDiscount(Map<String, dynamic> inventory) {
    return inventory['discount'];
  }

  static double getDiscountAmount(Map<String, dynamic> inventory) {
    if (inventory['discountAmount'] != null) {
      return (inventory['discountAmount'] as num).toDouble();
    }
    final discount = getDiscount(inventory);
    if (discount != null && discount['discountAmount'] != null) {
      return (discount['discountAmount'] as num).toDouble();
    }
    return 0.0;
  }

  static double getDiscountPercent(Map<String, dynamic> inventory) {
    if (inventory['discountPercent'] != null) {
      return (inventory['discountPercent'] as num).toDouble();
    }
    final discount = getDiscount(inventory);
    if (discount != null && discount['discountPercent'] != null) {
      return (discount['discountPercent'] as num).toDouble();
    }
    return 0.0;
  }

  static bool isLowStock(Map<String, dynamic> inventory) {
    final currentStock = getCurrentStock(inventory);
    final lowStockQty =
        inventory['lowStockQuantity'] ?? inventory['lowStockQty'] ?? 10;
    return currentStock <= lowStockQty && currentStock > 0;
  }

  static bool isOutOfStock(Map<String, dynamic> inventory) {
    return getCurrentStock(inventory) <= 0;
  }
}

// Date helper functions
class DateFilterHelper {
  static Map<String, DateTime> getDateRange(String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (filter) {
      case 'today':
        return {
          'start': today,
          'end': today
              .add(const Duration(days: 1))
              .subtract(const Duration(seconds: 1)),
        };

      case 'yesterday':
        final yesterday = today.subtract(const Duration(days: 1));
        return {
          'start': yesterday,
          'end': yesterday
              .add(const Duration(days: 1))
              .subtract(const Duration(seconds: 1)),
        };

      case 'this_week':
        final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        return {'start': startOfWeek, 'end': endOfWeek};

      case 'last_week':
        final startOfLastWeek = today.subtract(Duration(days: now.weekday + 6));
        final endOfLastWeek = startOfLastWeek.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        return {'start': startOfLastWeek, 'end': endOfLastWeek};

      case 'this_month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(
          now.year,
          now.month + 1,
          1,
        ).subtract(const Duration(seconds: 1));
        return {'start': startOfMonth, 'end': endOfMonth};

      case 'last_month':
        final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
        final endOfLastMonth = DateTime(
          now.year,
          now.month,
          1,
        ).subtract(const Duration(seconds: 1));
        return {'start': startOfLastMonth, 'end': endOfLastMonth};

      case 'fy_q1':
        final currentYear = now.year;
        final fyStart = now.month >= 4 ? currentYear : currentYear - 1;
        return {
          'start': DateTime(fyStart, 4, 1),
          'end': DateTime(fyStart, 6, 30, 23, 59, 59),
        };

      case 'fy_q2':
        final currentYear = now.year;
        final fyStart = now.month >= 4 ? currentYear : currentYear - 1;
        return {
          'start': DateTime(fyStart, 7, 1),
          'end': DateTime(fyStart, 9, 30, 23, 59, 59),
        };

      case 'fy_q3':
        final currentYear = now.year;
        final fyStart = now.month >= 4 ? currentYear : currentYear - 1;
        return {
          'start': DateTime(fyStart, 10, 1),
          'end': DateTime(fyStart, 12, 31, 23, 59, 59),
        };

      case 'fy_q4':
        final currentYear = now.year;
        final fyStart = now.month >= 4 ? currentYear : currentYear - 1;
        final fyEnd = fyStart + 1;
        return {
          'start': DateTime(fyEnd, 1, 1),
          'end': DateTime(fyEnd, 3, 31, 23, 59, 59),
        };

      case 'this_year':
        return {
          'start': DateTime(now.year, 1, 1),
          'end': DateTime(now.year, 12, 31, 23, 59, 59),
        };

      default:
        return {
          'start': today,
          'end': today
              .add(const Duration(days: 1))
              .subtract(const Duration(seconds: 1)),
        };
    }
  }
}
