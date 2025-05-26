import 'package:flutter/cupertino.dart';
import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';
import 'package:shimmer/shimmer.dart';

class CustomSwipableRow extends StatelessWidget {
  final List<String> items;
  final void Function(int index) onDelete;
  final void Function(int index) onEdit;
  final bool isLoading;

  /// Builder to provide the main content of each list tile
  final Widget Function(BuildContext context, int index, String item)
  childBuilder;

  const CustomSwipableRow({
    super.key,
    required this.items,
    required this.onDelete,
    required this.onEdit,
    required this.childBuilder,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: CupertinoListSection(
        margin: EdgeInsets.zero,
        additionalDividerMargin: 60,
        backgroundColor: CupertinoColors.white,
        topMargin: 0,
        children: isLoading
            ? List<Widget>.generate(10, (int index) => _buildShimmerTile())
            : items.asMap().entries.map((entry) {
                final int index = entry.key;
                final String item = entry.value;
                return SwipeActionCell(
                  key: ObjectKey(item),
                  trailingActions: <SwipeAction>[
                    SwipeAction(
                      title: "Delete",
                      performsFirstActionWithFullSwipe: true,
                      onTap: (handler) async {
                        await handler(true);
                        onDelete(index);
                      },
                      color: CupertinoColors.systemRed,
                    ),
                    SwipeAction(
                      title: "Edit",
                      onTap: (handler) async {
                        onEdit(index);
                        await handler(false);
                      },
                      color: CupertinoColors.systemOrange,
                    ),
                  ],
                  child: childBuilder(context, index, item),
                );
              }).toList(),
      ),
    );
  }

  Widget _buildShimmerTile() {
    return Shimmer.fromColors(
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
            // const SizedBox(width: 12),
            // Container(
            //   width: 20,
            //   height: 20,
            //   decoration: BoxDecoration(
            //     color: CupertinoColors.systemGrey4,
            //     borderRadius: BorderRadius.circular(25),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
