import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'dart:async';
import '../components/page_scaffold.dart';
import '../components/swipable_row.dart';

class EmployeeTab extends StatefulWidget {
  const EmployeeTab({super.key});

  @override
  State<EmployeeTab> createState() => _EmployeeTabState();
}

class _EmployeeTabState extends State<EmployeeTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchField = false;
  bool isloading = true;

  final List<String> _allItems = List.generate(
    20,
    (index) => 'Employee ${index + 1}',
  );
  List<String> _filteredItems = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(_allItems);
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This runs just like useEffect(..., []) or componentDidMount
      fetchDataOrInitialize();
    });
  }

  void fetchDataOrInitialize() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      isloading = false;
    });
    // Perform any API call, DB setup, or local state updates here
    log("Widget mounted and ready");
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final value = _searchController.text;
      setState(() {
        _filteredItems = value.isEmpty
            ? List.from(_allItems)
            : _allItems
                  .where(
                    (item) => item.toLowerCase().contains(value.toLowerCase()),
                  )
                  .toList();
      });
    });
  }

  void _deleteItem(int index) {
    setState(() {
      final itemToDelete = _filteredItems[index];
      _filteredItems.removeAt(index);
      _allItems.remove(itemToDelete);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPageScaffold(
      isLoading: isloading,
      heading: 'Employees',
      searchController: _searchController,
      showSearchField: _showSearchField,
      onSearchToggle: (bool value) {
        setState(() {
          _showSearchField = value;
          if (!value) {
            _searchController.clear();
            _filteredItems = List.from(_allItems);
          }
        });
      },
      onSearchChange: (value) {
        if (_debounce?.isActive ?? false) _debounce!.cancel();
        _debounce = Timer(const Duration(milliseconds: 300), () {
          setState(() {
            _filteredItems = value.isEmpty
                ? List.from(_allItems)
                : _allItems
                      .where(
                        (item) =>
                            item.toLowerCase().contains(value.toLowerCase()),
                      )
                      .toList();
          });
        });
      },
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 2));
      },
      trailing: Row(
        children: [
          PullDownButton(
            itemBuilder: (context) => [
              PullDownMenuItem(
                title: 'Photo Library',
                icon: CupertinoIcons.photo_on_rectangle,
                iconColor: CupertinoColors.systemBlue,
                itemTheme: PullDownMenuItemTheme(
                  textStyle: TextStyle(
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.25,
                  ),
                ),
                onTap: () {},
              ),
              PullDownMenuDivider.large(),
              PullDownMenuItem(
                title: 'Take Photo or Video',
                icon: CupertinoIcons.camera,
                iconColor: CupertinoColors.systemBlue,
                itemTheme: PullDownMenuItemTheme(
                  textStyle: TextStyle(
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.25,
                  ),
                ),
                onTap: () {},
              ),
              PullDownMenuItem(
                title: 'Choose File',
                icon: CupertinoIcons.folder,
                iconColor: CupertinoColors.systemBlue,
                itemTheme: PullDownMenuItemTheme(
                  textStyle: TextStyle(
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.25,
                  ),
                ),
                onTap: () {},
              ),
            ],
            buttonBuilder: (context, showMenu) => CupertinoButton(
              onPressed: showMenu,
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.ellipsis_circle, size: 25),
            ),
          ),
          CupertinoButton(
            onPressed: () {
              // showCupertinoSheet<void>(
              //   context: context,
              //   useNestedNavigation: true,
              //   pageBuilder: (BuildContext context) => const _SheetScaffold(),
              // );
              context.go('/employee/add');
            },
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.plus, size: 25),
          ),
        ],
      ),
      sliverList: CustomSwipableRow(
        isLoading: isloading,
        items: _filteredItems,
        onDelete: _deleteItem,
        onEdit: (index) => context.go('/employee/profile/$index'),
        childBuilder: (context, index, item) {
          return CupertinoListTile(
            backgroundColor: CupertinoColors.systemBackground,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            leadingSize: 47,
            leading: FlutterLogo(size: 50),
            title: Text(
              item,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.25,
              ),
            ),
            subtitle: Text(
              'Description for $item',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 16,
                letterSpacing: 0.25,
              ),
            ),
            trailing: const CupertinoListTileChevron(),
            onTap: () => context.go('/employee/profile/123'),
          );
        },
      ),
    );
  }
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold();

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      child: _SheetBody(title: 'CupertinoSheetRoute'),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(title),
          CupertinoButton.filled(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Go Back'),
          ),
          CupertinoButton.filled(
            onPressed: () {
              CupertinoSheetRoute.popSheet(context);
            },
            child: const Text('Pop Whole Sheet'),
          ),
          CupertinoButton.filled(
            onPressed: () {
              Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (BuildContext context) => const _SheetNextPage(),
                ),
              );
            },
            child: const Text('Push Nested Page'),
          ),
          CupertinoButton.filled(
            onPressed: () {
              showCupertinoSheet<void>(
                context: context,
                useNestedNavigation: true,
                pageBuilder: (BuildContext context) => const _SheetScaffold(),
              );
            },
            child: const Text('Push Another Sheet'),
          ),
        ],
      ),
    );
  }
}

class _SheetNextPage extends StatelessWidget {
  const _SheetNextPage();

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      backgroundColor: CupertinoColors.activeOrange,
      child: _SheetBody(title: 'Next Page'),
    );
  }
}
