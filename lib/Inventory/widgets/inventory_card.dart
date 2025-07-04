// widgets/inventory_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../apis/providers/inventory_provider.dart';
import '../../theme_provider.dart';

class InventoryGridCard extends ConsumerWidget {
  final Map<String, dynamic> inventory;
  final bool isListView;

  const InventoryGridCard({
    Key? key,
    required this.inventory,
    this.isListView = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);
    final name = InventoryHelper.getInventoryName(inventory);
    final description = InventoryHelper.getInventoryDescription(inventory);
    final price = InventoryHelper.getInventoryPrice(inventory);
    final currentStock = InventoryHelper.getCurrentStock(inventory);
    final itemCode = InventoryHelper.getItemCode(inventory);
    final itemType = InventoryHelper.getItemType(inventory);
    final photos = InventoryHelper.getPhotos(inventory);
    final isLowStock = InventoryHelper.isLowStock(inventory);
    final isOutOfStock = InventoryHelper.isOutOfStock(inventory);
    final discountPercent = InventoryHelper.getDiscountPercent(inventory);
    final status = InventoryHelper.getStatus(inventory);

    if (isListView) {
      return _buildListView(
        context,
        colors,
        name,
        description,
        price,
        currentStock,
        itemCode,
        itemType,
        photos,
        isLowStock,
        isOutOfStock,
        discountPercent,
        status,
      );
    } else {
      return _buildBackgroundGridView(
        context,
        colors,
        name,
        description,
        price,
        currentStock,
        itemCode,
        itemType,
        photos,
        isLowStock,
        isOutOfStock,
        discountPercent,
        status,
      );
    }
  }

  Widget _buildBackgroundGridView(
    BuildContext context,
    WareozeColorScheme colors,
    String name,
    String description,
    double price,
    int currentStock,
    String itemCode,
    String itemType,
    List<String> photos,
    bool isLowStock,
    bool isOutOfStock,
    double discountPercent,
    String status,
  ) {
    return InkWell(
      onTap: () => _showProductDetails(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with badges
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.border, width: 1),
                    ),
                    child: photos.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              photos.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholderImage(colors),
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colors.primary,
                                      ),
                                    );
                                  },
                            ),
                          )
                        : _buildPlaceholderImage(colors),
                  ),

                  // Stock status badge
                  if (isOutOfStock || isLowStock)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isOutOfStock ? colors.error : colors.warning,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isOutOfStock ? 'OUT OF STOCK' : 'LOW STOCK',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Discount badge
                  if (discountPercent > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${discountPercent.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Menu button
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colors.surface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: colors.textPrimary.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.more_vert,
                          color: colors.textSecondary,
                          size: 16,
                        ),
                        onSelected: (value) =>
                            _handleMenuAction(context, value),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 16),
                                SizedBox(width: 4),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          // const PopupMenuItem(
                          //   value: 'duplicate',
                          //   child: Row(
                          //     children: [
                          //       Icon(Icons.copy_outlined, size: 16),
                          //       SizedBox(width: 8),
                          //       Text('Duplicate'),
                          //     ],
                          //   ),
                          // ),
                          // const PopupMenuItem(
                          //   value: 'delete',
                          //   child: Row(
                          //     children: [
                          //       Icon(
                          //         Icons.delete_outline,
                          //         size: 16,
                          //         color: Colors.red,
                          //       ),
                          //       SizedBox(width: 8),
                          //       Text(
                          //         'Delete',
                          //         style: TextStyle(color: Colors.red),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Product Details
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Item type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: itemType == 'Service'
                          ? colors.primary.withOpacity(0.1)
                          : colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      itemType,
                      style: TextStyle(
                        fontSize: 9,
                        color: colors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // const Spacer(),
                  const SizedBox(height: 8),
                  // Price
                  if (price > 0) ...[
                    Text(
                      '₹${price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Price not set',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                  const SizedBox(height: 4),

                  // Stock info
                  Row(
                    children: [
                      Icon(
                        isOutOfStock
                            ? Icons.error_outline
                            : isLowStock
                            ? Icons.warning_amber_outlined
                            : Icons.check_circle_outline,
                        size: 11,
                        color: isOutOfStock
                            ? colors.error
                            : isLowStock
                            ? colors.warning
                            : colors.success,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '$currentStock left',
                          style: TextStyle(
                            fontSize: 10,
                            color: isOutOfStock
                                ? colors.error
                                : isLowStock
                                ? colors.warning
                                : colors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(
    BuildContext context,
    WareozeColorScheme colors,
    String name,
    String description,
    double price,
    int currentStock,
    String itemCode,
    String itemType,
    List<String> photos,
    bool isLowStock,
    bool isOutOfStock,
    double discountPercent,
    String status,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showProductDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: photos.isNotEmpty
                          ? Image.network(
                              photos.first,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholderImage(colors),
                            )
                          : _buildPlaceholderImage(colors),
                    ),

                    // Discount badge
                    if (discountPercent > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-${discountPercent.toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Description
                    if (description.isNotEmpty) ...[
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Item Code and Type
                    Row(
                      children: [
                        if (itemCode.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.background,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              itemCode,
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            itemType,
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Price and Stock Info
                    Row(
                      children: [
                        // Price
                        if (price > 0) ...[
                          Text(
                            '₹${price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Price not set',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],

                        const Spacer(),

                        // Stock Status
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isOutOfStock
                                ? colors.error.withOpacity(0.1)
                                : isLowStock
                                ? colors.warning.withOpacity(0.1)
                                : colors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOutOfStock
                                    ? Icons.error_outline
                                    : isLowStock
                                    ? Icons.warning_amber_outlined
                                    : Icons.check_circle_outline,
                                size: 14,
                                color: isOutOfStock
                                    ? colors.error
                                    : isLowStock
                                    ? colors.warning
                                    : colors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$currentStock left',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOutOfStock
                                      ? colors.error
                                      : isLowStock
                                      ? colors.warning
                                      : colors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Menu Button
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: colors.textSecondary,
                  size: 20,
                ),
                onSelected: (value) => _handleMenuAction(context, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  // const PopupMenuItem(
                  //   value: 'duplicate',
                  //   child: Row(
                  //     children: [
                  //       Icon(Icons.copy_outlined, size: 16),
                  //       SizedBox(width: 8),
                  //       Text('Duplicate'),
                  //     ],
                  //   ),
                  // ),
                  // const PopupMenuItem(
                  //   value: 'delete',
                  //   child: Row(
                  //     children: [
                  //       Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  //       SizedBox(width: 8),
                  //       Text('Delete', style: TextStyle(color: Colors.red)),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(WareozeColorScheme colors) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: colors.background,
      child: Icon(
        Icons.inventory_2_outlined,
        size: 32,
        color: colors.textSecondary,
      ),
    );
  }

  void _showProductDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailBottomSheet(inventory: inventory),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final inventoryId = inventory['_id']?.toString();

    switch (action) {
      case 'edit':
        if (inventoryId != null) {
          // Navigate to edit form
          context.push('/inventory-list/edit/$inventoryId');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to edit: Inventory ID not found'),
            ),
          );
        }
        break;
      // case 'duplicate':
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Duplicate functionality coming soon')),
      //   );
      //   break;
      // case 'delete':
      //   _showDeleteConfirmation(context, inventoryId);
      //   break;
    }
  }

  void _showDeleteConfirmation(BuildContext context, String? inventoryId) {
    if (inventoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete: Inventory ID not found'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Inventory'),
        content: Text(
          'Are you sure you want to delete "${InventoryHelper.getInventoryName(inventory)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement delete functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete functionality coming soon'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Keep the existing ProductDetailBottomSheet class as is
class ProductDetailBottomSheet extends ConsumerWidget {
  final Map<String, dynamic> inventory;

  const ProductDetailBottomSheet({Key? key, required this.inventory})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);
    final name = InventoryHelper.getInventoryName(inventory);
    final description = InventoryHelper.getInventoryDescription(inventory);
    final price = InventoryHelper.getInventoryPrice(inventory);
    final purchasePrice = InventoryHelper.getPurchasePrice(inventory);
    final currentStock = InventoryHelper.getCurrentStock(inventory);
    final itemCode = InventoryHelper.getItemCode(inventory);
    final hsnCode = InventoryHelper.getHsnCode(inventory);
    final photos = InventoryHelper.getPhotos(inventory);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Product Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: colors.textPrimary),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Images
                  if (photos.isNotEmpty) ...[
                    SizedBox(
                      height: 200,
                      child: PageView.builder(
                        itemCount: photos.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.border),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                photos[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: colors.background,
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 48,
                                      color: colors.textSecondary,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Product Info
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),

                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Price Info
                  Row(
                    children: [
                      if (price > 0) ...[
                        Text(
                          '₹${price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Details Grid
                  _buildDetailItem(
                    colors,
                    'Item Code',
                    itemCode.isEmpty ? '-' : itemCode,
                  ),
                  _buildDetailItem(
                    colors,
                    'HSN Code',
                    hsnCode.isEmpty ? '-' : hsnCode,
                  ),
                  _buildDetailItem(
                    colors,
                    'Current Stock',
                    '$currentStock units',
                  ),
                  if (purchasePrice > 0)
                    _buildDetailItem(
                      colors,
                      'Purchase Price',
                      '₹${purchasePrice.toStringAsFixed(2)}',
                    ),
                  _buildDetailItem(
                    colors,
                    'Item Type',
                    InventoryHelper.getItemType(inventory),
                  ),
                  _buildDetailItem(
                    colors,
                    'Status',
                    InventoryHelper.getStatus(inventory),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    WareozeColorScheme colors,
    String label,
    String value,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
