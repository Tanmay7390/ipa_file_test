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
  final String? idKey; // Add this optional parameter

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
    this.idKey, // Add this parameter
  });
  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    if (url.toLowerCase() == 'null') return false;
    if (!url.startsWith('http://') && !url.startsWith('https://')) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Filter out items that don't have required fields or have null values
    final validItems = items.where((item) {
      if (item == null) return false;

      // Check if item has an ID using the improved extraction method
      final id = _extractId(item);
      if (id == null || id.isEmpty) return false;

      // Check if required keys exist and are not null
      final title = item is Map ? item[titleKey] : null;
      final subtitle = item is Map ? item[subtitleKey] : null;

      return title != null && subtitle != null;
    }).toList();

    final children = validItems.asMap().entries.map((entry) {
      final dynamic item = entry.value;

      // Use the improved ID extraction method
      final String itemId = _extractId(item) ?? '';

      final String title = (item is Map)
          ? (item[titleKey]?.toString() ?? 'No Title')
          : 'No Title';

      final String subtitle = (item is Map)
          ? (item[subtitleKey]?.toString() ?? 'No Subtitle')
          : 'No Subtitle';

      final String? leadingUrl = (item is Map)
          ? item[leadingKey]?.toString()
          : null;

      return SwipeActionCell(
        key: ObjectKey(item),
        trailingActions: <SwipeAction>[
          SwipeAction(
            title: "Delete",
            performsFirstActionWithFullSwipe: true,
            onTap: (handler) async {
              await handler(true);
              if (itemId.isNotEmpty) {
                onDelete(itemId);
              }
            },
            color: CupertinoColors.systemRed,
          ),
          SwipeAction(
            title: "Edit",
            onTap: (handler) async {
              if (itemId.isNotEmpty) {
                onEdit(itemId);
              }
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
          leading: _isValidImageUrl(leadingUrl)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.network(
                    leadingUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const FlutterLogo(size: 50),
                  ),
                )
              : const FlutterLogo(size: 50),
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.25,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 16,
              letterSpacing: 0.25,
            ),
          ),
          trailing: const CupertinoListTileChevron(),
          onTap: () {
            if (itemId.isNotEmpty) {
              onTap(itemId);
            }
          },
        ),
      );
    }).toList();

    // Handle empty state - return empty container if no children and not loading
    if (children.isEmpty && !isLoading) {
      return _buildEmptyState();
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

  // Add this helper method for robust ID extraction
  String? _extractId(dynamic item) {
    if (item is! Map) return null;

    // If idKey is specified, use it first
    if (idKey != null && item[idKey] != null) {
      return item[idKey].toString();
    }

    // Fallback to common ID fields in order of preference
    final idFields = ['_id', 'id', 'empId', 'customerId', 'supplierId'];

    for (final field in idFields) {
      if (item[field] != null) {
        return item[field].toString();
      }
    }

    return null;
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.person_alt_circle,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No items found',
              style: TextStyle(
                fontSize: 17,
                color: CupertinoColors.systemGrey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first item to get started',
              style: TextStyle(
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
