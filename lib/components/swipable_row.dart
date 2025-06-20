import 'package:flutter/cupertino.dart';
import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';
import 'package:shimmer/shimmer.dart';

class CustomSwipableRow extends StatelessWidget {
  final List items;
  final void Function(String id) onDelete;
  final void Function(String id) onTap;
  final void Function(String id) onEdit;
  final bool isLoading;
  final String titleKey;
  final String subtitleKey;
  final String leadingKey;

  /// Builder to provide the main content of each list tile
  // final Widget Function(BuildContext context, int index) childBuilder;

  const CustomSwipableRow({
    super.key,
    required this.items,
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
    required this.isLoading,
    required this.titleKey,
    required this.subtitleKey,
    required this.leadingKey,
  });

  @override
  Widget build(BuildContext context) {
    final children = items.asMap().entries.map((entry) {
      final dynamic item = entry.value;
      return SwipeActionCell(
        key: ObjectKey(item),
        trailingActions: <SwipeAction>[
          SwipeAction(
            title: "Delete",
            performsFirstActionWithFullSwipe: true,
            onTap: (handler) async {
              await handler(true);
              onDelete(item?._id ?? item['_id'] ?? '');
            },
            color: CupertinoColors.systemRed,
          ),
          SwipeAction(
            title: "Edit",
            onTap: (handler) async {
              onEdit(item?._id ?? item['_id'] ?? '');
              await handler(false);
            },
            color: CupertinoColors.systemOrange,
          ),
        ],
        child: CupertinoListTile(
          backgroundColor: CupertinoColors.systemBackground.resolveFrom(
            context,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          leadingSize: 47,
          leading: item[leadingKey] != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.network(
                    item[leadingKey]!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const FlutterLogo(size: 50),
                  ),
                )
              : const FlutterLogo(size: 50),
          title: Text(
            item[titleKey],
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.25,
            ),
          ),
          subtitle: Text(
            item[subtitleKey],
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 16,
              letterSpacing: 0.25,
            ),
          ),
          trailing: const CupertinoListTileChevron(),
          onTap: () => onEdit(item['_id'] ?? item['_id'] ?? ''),
        ),
      );
    }).toList();

    // Handle empty state - return empty container if no children and not loading
    if (children.isEmpty && !isLoading) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(), // Or your empty state widget
      );
    }

    return SliverToBoxAdapter(
      child: CupertinoListSection(
        margin: EdgeInsets.zero,
        additionalDividerMargin: 60,
        backgroundColor: CupertinoColors.white,
        topMargin: 0,
        children: children,
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.person_alt_circle,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'No employees found',
              style: const TextStyle(
                fontSize: 17,
                color: CupertinoColors.systemGrey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first employee to get started',
              style: const TextStyle(
                fontSize: 15,
                color: CupertinoColors.systemGrey2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class BuildErrorState extends StatelessWidget {
  final void Function() onRefresh;
  final Object error;

  const BuildErrorState({
    super.key,
    required this.onRefresh,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle_fill,
              size: 64,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(
                fontSize: 15,
                color: CupertinoColors.systemGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: onRefresh,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class BuildShimmerTile extends StatelessWidget {
  const BuildShimmerTile({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Shimmer.fromColors(
          baseColor: CupertinoColors.systemGrey4,
          highlightColor: CupertinoColors.systemGrey2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey4,
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 20,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey4,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 12,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey4,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        childCount: 10,
      ),
    );
  }
}
