import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../components/page_scaffold.dart';
import '../components/swipable_row.dart';
import '../apis/providers/employee_provider.dart';
import '../theme_provider.dart';

class EmployeeTab extends ConsumerStatefulWidget {
  const EmployeeTab({super.key});

  @override
  ConsumerState<EmployeeTab> createState() => _EmployeeTabState();
}

class _EmployeeTabState extends ConsumerState<EmployeeTab> {
  final TextEditingController _searchController = TextEditingController();

  bool _showSearchField = false;
  Timer? _debounce;
  String _lastSearchQuery = '';
  bool _hasInitialized = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Load employees when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
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
    if (!_hasInitialized) {
      setState(() => _isLoading = true);

      try {
        await ref
            .read(employeeListProvider.notifier)
            .loadEmployees(page: 1, refresh: true);
        _hasInitialized = true;
      } catch (e) {
        log('Error loading initial data: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 100), () async {
      final query = _searchController.text.trim();

      // Only make API call if search query has actually changed
      if (query != _lastSearchQuery) {
        setState(() => _isLoading = true);

        _lastSearchQuery = query;
        ref.read(employeeSearchProvider.notifier).state = query;

        // Reset pagination and load with search
        try {
          // Reset pagination and load with search
          await ref
              .read(employeeListProvider.notifier)
              .loadEmployees(
                page: 1,
                refresh: true,
                searchQuery: query.isEmpty ? null : query,
              );
        } catch (e) {
          log('Error searching employees: $e');
        } finally {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      }
    });
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    try {
      final searchQuery = ref.read(employeeSearchProvider);
      await ref
          .read(employeeListProvider.notifier)
          .loadEmployees(
            page: 1,
            refresh: true,
            searchQuery: searchQuery.isEmpty ? null : searchQuery,
          );
    } catch (e) {
      log('Error refreshing employees: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleSearch() {
    setState(() {
      _showSearchField = !_showSearchField;

      if (!_showSearchField) {
        // Only make API call if there was actually a search query
        final hadSearchQuery = _searchController.text.trim().isNotEmpty;

        _searchController.clear();
        _lastSearchQuery = '';
        ref.read(employeeSearchProvider.notifier).state = '';

        // Only reload if we were actually searching
        if (hadSearchQuery) {
          _onRefresh();
        }
      }
    });
  }

  void _deleteEmployee(String employeeId) async {
    final colors = ref.read(colorProvider);

    try {
      await ref.read(employeeActionsProvider).deleteEmployee(employeeId);

      // Refresh the list after successful deletion
      await _onRefresh();

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('Success', style: TextStyle(color: colors.textPrimary)),
            content: Text(
              'Employee deleted successfully',
              style: TextStyle(color: colors.textSecondary),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK', style: TextStyle(color: colors.primary)),
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
            title: Text('Error', style: TextStyle(color: colors.error)),
            content: Text(
              'Failed to delete employee: $e',
              style: TextStyle(color: colors.textSecondary),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK', style: TextStyle(color: colors.primary)),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeListState = ref.watch(employeeListProvider);
    final colors = ref.watch(colorProvider);

    return CustomPageScaffold(
      isLoading: _isLoading,
      heading: 'Employees',
      searchController: _searchController,
      showSearchField: _showSearchField,
      onSearchToggle: (_) => _toggleSearch(),
      onBottomRefresh: () => _onRefresh(),
      onRefresh: _onRefresh,

      // Add this floating action button
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
            context.go('/employee/add');
          },
          child: Icon(
            CupertinoIcons.add,
            color: CupertinoColors.white,
            size: 24,
          ),
        ),
      ),

      sliverList: employeeListState.when(
        data: (employeeData) => CustomSwipableRow(
          isLoading: _isLoading,
          items: employeeData.employees,
          onTap: (id) => context.go('/employee/profile/$id'),
          onDelete: (id) => _deleteEmployee(id),
          onEdit: (id) => context.go('/employee/edit/$id'),
          titleKey: 'name',
          subtitleKey: 'personalEmail',
          leadingKey: 'photo',
          idKey: '_id', // Optional: explicitly specify the ID field
        ),
        loading: () => BuildShimmerTile(),
        error: (error, stack) =>
            BuildErrorState(error: error, onRefresh: _onRefresh),
      ),
    );
  }
}
