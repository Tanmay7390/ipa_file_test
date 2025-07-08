import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../components/page_scaffold.dart';
import '../components/swipable_row.dart';
import '../apis/providers/customer_provider.dart';
import '../apis/providers/supplier_provider.dart';

class CustomerSupplierTab extends ConsumerStatefulWidget {
  const CustomerSupplierTab({super.key});

  @override
  ConsumerState<CustomerSupplierTab> createState() =>
      _CustomerSupplierTabState();
}

class _CustomerSupplierTabState extends ConsumerState<CustomerSupplierTab> {
  final TextEditingController _searchController = TextEditingController();

  bool _showSearchField = false;
  Timer? _debounce;
  String _lastSearchQuery = '';
  bool _hasInitialized = false;
  bool _isLoading = true;
  int _selectedSegment = 0; // 0 for Customers, 1 for Suppliers

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Load initial data when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitialData();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _loadInitialData() async {
    if (!mounted || _hasInitialized) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // Load both customers and suppliers
      await Future.wait([
        ref
            .read(customerListProvider.notifier)
            .loadCustomers(page: 1, refresh: true),
        ref
            .read(supplierListProvider.notifier)
            .loadsuppliers(page: 1, refresh: true),
      ]);
      _hasInitialized = true;
    } catch (e) {
      log('Error loading initial data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    if (!mounted) return;

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;

      final query = _searchController.text.trim();

      // Always update search query and trigger search, even if empty
      _lastSearchQuery = query;

      if (mounted) {
        setState(() => _isLoading = true);
      }

      try {
        if (_selectedSegment == 0) {
          // Search customers
          if (mounted) {
            ref.read(customerSearchProvider.notifier).state = query;
            await ref
                .read(customerListProvider.notifier)
                .loadCustomers(
                  page: 1,
                  refresh: true,
                  searchQuery: query.isEmpty ? null : query,
                );
          }
        } else {
          // Search suppliers
          if (mounted) {
            ref.read(suppliersearchProvider.notifier).state = query;
            await ref
                .read(supplierListProvider.notifier)
                .loadsuppliers(
                  page: 1,
                  refresh: true,
                  searchQuery: query.isEmpty ? null : query,
                );
          }
        }
      } catch (e) {
        log('Error searching: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      if (_selectedSegment == 0) {
        if (mounted) {
          final searchQuery = ref.read(customerSearchProvider);
          await ref
              .read(customerListProvider.notifier)
              .loadCustomers(
                page: 1,
                refresh: true,
                searchQuery: searchQuery.isEmpty ? null : searchQuery,
              );
        }
      } else {
        if (mounted) {
          final searchQuery = ref.read(suppliersearchProvider);
          await ref
              .read(supplierListProvider.notifier)
              .loadsuppliers(
                page: 1,
                refresh: true,
                searchQuery: searchQuery.isEmpty ? null : searchQuery,
              );
        }
      }
    } catch (e) {
      log('Error refreshing: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleSearch() {
    if (!mounted) return;

    setState(() {
      _showSearchField = !_showSearchField;

      if (!_showSearchField) {
        // Clear search and reload all data
        _searchController.clear();
        _lastSearchQuery = '';

        // Clear search state for both providers
        if (mounted) {
          ref.read(customerSearchProvider.notifier).state = '';
          ref.read(suppliersearchProvider.notifier).state = '';
        }

        // Reload all data when search is cleared
        // _loadDataForCurrentSegment();
      }
    });
  }

  // void _loadDataForCurrentSegment() async {
  //   if (!mounted) return;

  //   setState(() => _isLoading = true);

  //   try {
  //     if (_selectedSegment == 0) {
  //       await ref
  //           .read(customerListProvider.notifier)
  //           .loadCustomers(page: 1, refresh: true);
  //     } else {
  //       await ref
  //           .read(supplierListProvider.notifier)
  //           .loadsuppliers(page: 1, refresh: true);
  //     }
  //   } catch (e) {
  //     log('Error loading data for current segment: $e');
  //   } finally {
  //     if (mounted) {
  //       setState(() => _isLoading = false);
  //     }
  //   }
  // }

  void _onSegmentChanged(int? value) {
    if (!mounted || value == null || value == _selectedSegment) return;

    setState(() {
      _selectedSegment = value;
      // Clear search when switching tabs
      _searchController.clear();
      _lastSearchQuery = '';

      if (mounted) {
        ref.read(customerSearchProvider.notifier).state = '';
        ref.read(suppliersearchProvider.notifier).state = '';
      }
    });

    // Load data for the new segment
    // _loadDataForCurrentSegment();
  }

  void _deleteCustomer(String customerId) async {
    if (!mounted) return;

    try {
      await ref.read(customerActionsProvider).deleteCustomer(customerId);

      // Refresh the list after successful deletion
      if (mounted) {
        await _onRefresh();
      }

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: const Text('Customer deleted successfully'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to delete customer: $e'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _deleteSupplier(String supplierId) async {
    if (!mounted) return;

    try {
      await ref.read(supplierActionsProvider).deleteSupplier(supplierId);

      // Refresh the list after successful deletion
      if (mounted) {
        await _onRefresh();
      }

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: const Text('Supplier deleted successfully'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to delete supplier: $e'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    final customerListState = ref.watch(customerListProvider);
    final supplierListState = ref.watch(supplierListProvider);

    return CustomPageScaffold(
      isLoading: _isLoading,
      heading: 'Parties',
      onBottomRefresh: () => _onRefresh(),
      onRefresh: _onRefresh,
      onSearchChange: (query) {
        // Handle search input changes
        if (_searchController.text != query) {
          _searchController.text = query;
        }
      },

      // Add segmented control above the list
      customHeaderWidget: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: CupertinoSlidingSegmentedControl<int>(
          groupValue: _selectedSegment,
          onValueChanged: _onSegmentChanged,
          children: const {
            0: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Buyers'),
            ),
            1: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Suppliers'),
            ),
          },
        ),
      ),
      sliverList: _selectedSegment == 0
          ? _buildCustomerSwipableList(customerListState)
          : _buildSupplierSwipableList(supplierListState),

      searchController: _searchController,
      showSearchField: _showSearchField,
      onSearchToggle: (_) => _toggleSearch(),
      // floating action button
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Color(0xFF4C9656),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            // Navigate to add form based on selected segment
            if (_selectedSegment == 0) {
              context.go('/customersuppliers/add');
            } else {
              context.go('/customersuppliers/add');
            }
          },
          child: Icon(
            CupertinoIcons.add,
            color: CupertinoColors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSwipableList(AsyncValue customerListState) {
    return customerListState.when(
      data: (customerData) {
        // Apply client-side filtering if needed as backup
        final searchQuery = ref.watch(customerSearchProvider);
        List filteredCustomers = customerData.customers;

        if (searchQuery.isNotEmpty) {
          filteredCustomers = customerData.customers.where((customer) {
            final name = customer['name']?.toString().toLowerCase() ?? '';
            final legalName =
                customer['legalName']?.toString().toLowerCase() ?? '';
            final query = searchQuery.toLowerCase();
            return name.contains(query) || legalName.contains(query);
          }).toList();
        }

        // Sort by creation date (newest first)
        filteredCustomers.sort((a, b) {
          final aDate =
              DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
              DateTime(1970);
          final bDate =
              DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
              DateTime(1970);
          return bDate.compareTo(aDate); // Descending order (newest first)
        });

        return CustomSwipableRow(
          isLoading: _isLoading,
          items: filteredCustomers,
          // onTap: (id) {
          //   if (mounted) {
          //     context.go('/customersuppliers/profile/$id');
          //   }
          // },
          onTap: (id) {
            if (mounted) {
              context.go('/customersuppliers/profile/$id?type=customer');
            }
          },
          onDelete: (id) => _deleteCustomer(id),
          onEdit: (id) {
            if (mounted) {
              context.go('/customersuppliers/one/$id');
            }
          },
          titleKey: 'name',
          subtitleKey: 'legalName',
          leadingKey: 'photo',
        );
      },
      loading: () => const BuildShimmerTile(),
      error: (error, stack) =>
          BuildErrorState(error: error, onRefresh: _onRefresh),
    );
  }

  Widget _buildSupplierSwipableList(AsyncValue supplierListState) {
    return supplierListState.when(
      data: (supplierData) {
        // Apply client-side filtering if needed as backup
        final searchQuery = ref.watch(suppliersearchProvider);
        List filteredSuppliers = supplierData.suppliers;

        if (searchQuery.isNotEmpty) {
          filteredSuppliers = supplierData.suppliers.where((supplier) {
            final name = supplier['name']?.toString().toLowerCase() ?? '';
            final legalName =
                supplier['legalName']?.toString().toLowerCase() ?? '';
            final query = searchQuery.toLowerCase();
            return name.contains(query) || legalName.contains(query);
          }).toList();
        }

        // Sort by creation date (newest first)
        filteredSuppliers.sort((a, b) {
          final aDate =
              DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
              DateTime(1970);
          final bDate =
              DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
              DateTime(1970);
          return bDate.compareTo(aDate); // Descending order (newest first)
        });

        return CustomSwipableRow(
          isLoading: _isLoading,
          items: filteredSuppliers,
          // onTap: (id) {
          //   if (mounted) {
          //     context.go('/customersuppliers/supplier/profile/$id');
          //   }
          // },
          onTap: (id) {
            if (mounted) {
              context.go('/customersuppliers/profile/$id?type=supplier');
            }
          },
          onDelete: (id) => _deleteSupplier(id),
          // onEdit: (id) {
          //   if (mounted) {
          //     context.go('/customersuppliers/supplier/profile/$id');
          //   }
          // },
          onEdit: (id) {
            if (mounted) {
              context.go('/customersuppliers/profile/$id?type=supplier');
            }
          },
          titleKey: 'name',
          subtitleKey: 'legalName',
          leadingKey: 'logo',
        );
      },
      loading: () => const BuildShimmerTile(),
      error: (error, stack) =>
          BuildErrorState(error: error, onRefresh: _onRefresh),
    );
  }
}
