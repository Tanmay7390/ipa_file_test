import 'dart:developer';
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

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

  final TextEditingController? searchController;
  final bool showSearchField;
  final Function(bool)? onSearchToggle;
  final bool hideSearch;
  final bool hideLargeTitle;

  const CustomPageScaffold({
    super.key,
    required this.heading,
    this.leading,
    this.trailing,
    this.onSearchChange,
    this.onRefresh,
    this.onBottomRefresh,
    required this.sliverList,
    this.searchController,
    this.showSearchField = false,
    this.onSearchToggle,
    required this.isLoading,
    this.scrollController,
    this.hideSearch = false,
    this.hideLargeTitle = false,
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
    // Skip bottom refresh handling if hideLargeTitle is true
    if (widget.hideLargeTitle) {
      return false;
    }

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
        duration: const Duration(milliseconds: 150),
        height: indicatorHeight,
        child: indicatorHeight > 0
            ? AnimatedBuilder(
                animation: _bottomRefreshAnimation,
                builder: (context, child) {
                  if (_isBottomRefreshing) {
                    return const Center(
                      child: CupertinoActivityIndicator(radius: 15),
                    );
                  }

                  if (_bottomDragOffset > 0) {
                    return Center(
                      child: CupertinoActivityIndicator.partiallyRevealed(
                        progress: progress,
                        radius: 15,
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
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      child: widget.hideLargeTitle
          ? Stack(
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: _handleScrollNotification,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: <Widget>[
                      SliverPadding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 44.0,
                        ),
                      ),
                      if (!widget.isLoading && !widget.showSearchField)
                        CupertinoSliverRefreshControl(
                          onRefresh: widget.onRefresh ?? () async {},
                        ),
                      widget.sliverList,
                      if (!widget.hideLargeTitle)
                        _buildBottomRefreshIndicator(),
                      // Add bottom safe area padding so content is visible above bottom bar
                      SliverPadding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              CupertinoTheme.of(context).brightness ==
                                  Brightness.dark
                              ? const Color(0xFF1C1C1E).withValues(alpha: 0.75)
                              : CupertinoColors.systemBackground.withValues(
                                  alpha: 0.80,
                                ),
                          border: Border(
                            bottom: BorderSide(
                              color: CupertinoColors.systemGrey,
                              width: 0.2,
                            ),
                          ),
                        ),
                        child: CupertinoNavigationBar(
                          leading: widget.leading,
                          middle: Text(widget.heading),
                          backgroundColor: const Color(0x00000000),
                          border: null,
                          trailing: widget.trailing,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: <Widget>[
                  if (widget.hideSearch)
                    CupertinoSliverNavigationBar(
                      leading: widget.leading,
                      largeTitle: Text(widget.heading),
                      transitionBetweenRoutes: true,
                      backgroundColor:
                          CupertinoTheme.of(context).brightness ==
                              Brightness.dark
                          ? const Color(0xFF1C1C1E).withValues(alpha: 0.55)
                          : CupertinoColors.systemBackground.withValues(
                              alpha: 0.55,
                            ),
                      enableBackgroundFilterBlur: true,
                      border: Border(
                        bottom: BorderSide(
                          color: CupertinoColors.systemGrey,
                          width: 0.2,
                        ),
                      ),
                      trailing: widget.trailing,
                    )
                  else
                    CupertinoSliverNavigationBar.search(
                      leading: widget.leading,
                      largeTitle: Text(widget.heading),
                      transitionBetweenRoutes: true,
                      searchField: CupertinoSearchTextField(
                        controller: widget.searchController!,
                        autofocus: widget.showSearchField,
                        placeholder: widget.showSearchField
                            ? 'Enter search text'
                            : 'Search',
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
                          widget.searchController!.clear();
                          widget.onSearchChange?.call('');
                        },
                        onChanged: widget.onSearchChange,
                      ),
                      onSearchableBottomTap: widget.onSearchToggle,
                      bottomMode: NavigationBarBottomMode.always,
                      backgroundColor:
                          CupertinoTheme.of(context).brightness ==
                              Brightness.dark
                          ? const Color(0xFF1C1C1E).withValues(alpha: 0.75)
                          : CupertinoColors.systemBackground.withValues(
                              alpha: 0.80,
                            ),
                      enableBackgroundFilterBlur: true,
                      border: Border(
                        bottom: BorderSide(
                          color: CupertinoColors.systemGrey,
                          width: 0.2,
                        ),
                      ),
                      trailing: widget.trailing,
                    ),
                  // Top refresh control (pull down)
                  if (!widget.isLoading && !widget.showSearchField)
                    CupertinoSliverRefreshControl(
                      onRefresh: widget.onRefresh ?? () async {},
                    ),

                  widget.sliverList,

                  // Bottom refresh indicator (disabled when hideLargeTitle is true)
                  if (!widget.hideLargeTitle) _buildBottomRefreshIndicator(),

                  // Add bottom safe area padding so content is visible above bottom bar
                  SliverPadding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
