import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme_provider.dart';

class CustomPageScaffold extends StatefulWidget {
  final String heading;
  final Widget? leading;
  final Widget? trailing;
  final Function(String)? onSearchChange;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onBottomRefresh; // Bottom swipe action
  final Widget sliverList;
  final bool isLoading;
  final ScrollController? scrollController;

  final TextEditingController searchController;
  final bool showSearchField;
  final Function(bool)? onSearchToggle;

  final Widget? customHeaderWidget;
  final WareozeColorScheme? colorScheme;
  final Widget? floatingActionButton;

  const CustomPageScaffold({
    super.key,
    required this.heading,
    this.leading,
    this.trailing,
    this.onSearchChange,
    this.onRefresh,
    this.onBottomRefresh,
    required this.sliverList,
    required this.searchController,
    this.showSearchField = false,
    this.onSearchToggle,
    required this.isLoading,
    this.scrollController,
    this.customHeaderWidget,
    this.colorScheme,
    this.floatingActionButton,
  });

  @override
  State<CustomPageScaffold> createState() => _CustomPageScaffoldState();
}

class _CustomPageScaffoldState extends State<CustomPageScaffold>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _bottomRefreshController;
  late Animation<double> _bottomRefreshAnimation;

  bool _isBottomRefreshing = false;
  double _bottomDragOffset = 0.0;
  static const double _bottomRefreshThreshold = 80.0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();

    _bottomRefreshController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _bottomRefreshAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bottomRefreshController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _bottomRefreshController.dispose();
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  Future<void> _triggerBottomRefresh() async {
    log('Bottom refresh triggered');
    if (_isBottomRefreshing || widget.onBottomRefresh == null) return;

    setState(() {
      _isBottomRefreshing = true;
    });

    _bottomRefreshController.forward();

    try {
      await widget.onBottomRefresh!();
    } finally {
      await _bottomRefreshController.reverse();
      if (mounted) {
        setState(() {
          _isBottomRefreshing = false;
          _bottomDragOffset = 0.0;
        });
      }
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      // Check if we're at the bottom and pulling further
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent) {
        final overscroll =
            notification.metrics.pixels - notification.metrics.maxScrollExtent;
        if (overscroll > 0) {
          setState(() {
            _bottomDragOffset = math.min(overscroll, 80.0);
          });
        }
      }
    }

    if (notification is ScrollEndNotification) {
      // Trigger refresh if pulled enough
      if (_bottomDragOffset >= _bottomRefreshThreshold &&
          !_isBottomRefreshing) {
        _triggerBottomRefresh();
      } else {
        // Reset drag offset
        setState(() {
          _bottomDragOffset = 0.0;
        });
      }
    }

    return false;
  }

  Widget _buildBottomRefreshIndicator() {
    final colors = widget.colorScheme ?? WareozeColorScheme.light();
    final progress = (_bottomDragOffset / _bottomRefreshThreshold).clamp(
      0.0,
      1.0,
    );
    final indicatorHeight = math.max(
      _bottomDragOffset,
      _isBottomRefreshing ? 60.0 : 0.0,
    );

    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: indicatorHeight,
        child: indicatorHeight > 0
            ? AnimatedBuilder(
                animation: _bottomRefreshAnimation,
                builder: (context, child) {
                  if (_isBottomRefreshing) {
                    return Center(
                      child: CupertinoActivityIndicator(
                        radius: 15,
                        color: colors.primary,
                      ),
                    );
                  }

                  if (_bottomDragOffset > 0) {
                    return Center(
                      child: CupertinoActivityIndicator.partiallyRevealed(
                        progress: progress,
                        radius: 15,
                        color: colors.primary,
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colorScheme ?? WareozeColorScheme.light();

    return Builder(
      builder: (innerContext) {
        return CupertinoPageScaffold(
          backgroundColor: colors.background,
          child: Stack(
            // Wrap with Stack
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: <Widget>[
                    CupertinoSliverNavigationBar.search(
                      largeTitle: Text(
                        widget.heading,
                        style: TextStyle(color: colors.textPrimary),
                      ),
                      leading: widget.leading,
                      transitionBetweenRoutes: true,
                      searchField: CupertinoSearchTextField(
                        controller: widget.searchController,
                        autofocus: widget.showSearchField,
                        placeholder: widget.showSearchField
                            ? 'Enter search text'
                            : 'Search',
                        prefixIcon: Icon(
                          CupertinoIcons.search,
                          color: colors.textSecondary,
                        ),
                        suffixIcon: Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: colors.textSecondary,
                        ),
                        suffixMode: OverlayVisibilityMode.editing,
                        onSuffixTap: () {
                          widget.searchController.clear();
                          widget.onSearchChange?.call('');
                        },
                        onChanged: widget.onSearchChange,
                        style: TextStyle(color: colors.textPrimary),
                        placeholderStyle: TextStyle(
                          color: colors.textSecondary,
                        ),
                      ),
                      onSearchableBottomTap: widget.onSearchToggle,
                      bottomMode: NavigationBarBottomMode.always,
                      backgroundColor: colors.surface.withOpacity(0.8),
                      enableBackgroundFilterBlur: true,
                      border: Border(
                        bottom: BorderSide(color: colors.border, width: 0.5),
                      ),
                      // Remove the trailing parameter entirely
                    ),
                    if (!widget.isLoading && !widget.showSearchField)
                      CupertinoSliverRefreshControl(
                        onRefresh: widget.onRefresh ?? () async {},
                      ),
                    if (widget.customHeaderWidget != null)
                      SliverToBoxAdapter(child: widget.customHeaderWidget!),
                    widget.sliverList,
                    _buildBottomRefreshIndicator(),
                  ],
                ),
              ),
              // Add floating action button here
              if (widget.floatingActionButton != null)
                Positioned(
                  bottom: 30,
                  right: 20,
                  child: widget.floatingActionButton!,
                ),
            ],
          ),
        );
      },
    );
  }
}
