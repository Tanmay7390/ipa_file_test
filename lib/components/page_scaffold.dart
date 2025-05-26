import 'package:flutter/cupertino.dart';

class CustomPageScaffold extends StatelessWidget {
  final String heading;
  final Widget? leading;
  final Widget? trailing;
  final Function(String)? onSearchChange;
  final Future<void> Function()? onRefresh;
  final Widget sliverList;
  final bool isLoading;

  final TextEditingController searchController;
  final bool showSearchField;
  final Function(bool)? onSearchToggle;

  const CustomPageScaffold({
    super.key,
    required this.heading,
    this.leading,
    this.trailing,
    this.onSearchChange,
    this.onRefresh,
    required this.sliverList,
    required this.searchController,
    this.showSearchField = false,
    this.onSearchToggle,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: <Widget>[
          CupertinoSliverNavigationBar.search(
            largeTitle: Text(heading),
            transitionBetweenRoutes: true,
            searchField: CupertinoSearchTextField(
              controller: searchController,
              autofocus: showSearchField,
              placeholder: showSearchField ? 'Enter search text' : 'Search',
              prefixIcon: const Icon(
                CupertinoIcons.search,
                color: CupertinoColors.systemGrey,
              ),
              suffixIcon: const Icon(
                CupertinoIcons.xmark_circle_fill,
                color: CupertinoColors.systemGrey,
              ),
              suffixMode: OverlayVisibilityMode.editing,
              onSuffixTap: () {
                searchController.clear();
              },
              onChanged: onSearchChange,
            ),
            onSearchableBottomTap: onSearchToggle,
            bottomMode: NavigationBarBottomMode.always,
            backgroundColor: CupertinoColors.systemBackground.withOpacity(0.8),
            enableBackgroundFilterBlur: true,
            border: const Border(
              bottom: BorderSide(
                color: CupertinoColors.systemGrey5,
                width: 0.5,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [if (trailing != null) trailing!],
            ),
          ),
          if (!isLoading)
            CupertinoSliverRefreshControl(onRefresh: onRefresh ?? () async {}),
          sliverList,
        ],
      ),
    );
  }
}
