// lib/widgets/product_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../apis/providers/inventory_provider.dart';
import '../../theme_provider.dart';
import '../adjust_stock_page.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> inventory;

  const ProductDetailPage({Key? key, required this.inventory})
    : super(key: key);

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  @override
  void initState() {
    super.initState();
    // Fetch inventory history when page loads
    final inventoryId = widget.inventory['_id']?.toString();
    if (inventoryId != null) {
      // Use Future.microtask to avoid build scheduling during frame
      Future.microtask(() {
        if (mounted) {
          ref
              .read(inventoryProvider.notifier)
              .fetchInventoryHistoryById(inventoryId);
        }
      });
    }
  }

  // Add refresh method
  Future<void> _refreshData() async {
    final inventoryId = widget.inventory['_id']?.toString();
    if (inventoryId != null) {
      // Refresh inventory history
      await ref
          .read(inventoryProvider.notifier)
          .fetchInventoryHistoryById(inventoryId);

      // Refresh main inventory data
      await ref
          .read(inventoryProvider.notifier)
          .fetchInventoryById(inventoryId);

      // Update the current inventory data if needed
      final updatedInventory = await ref
          .read(inventoryProvider.notifier)
          .getInventoryById(inventoryId);
      if (updatedInventory != null && mounted) {
        setState(() {
          // Update the widget's inventory data
          widget.inventory.clear();
          widget.inventory.addAll(updatedInventory);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorProvider);
    final inventoryId = widget.inventory['_id']?.toString() ?? '';
    final history = ref.watch(inventoryHistoryProvider(inventoryId));

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          _buildHeader(colors, inventoryId),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _refreshData(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildItemOverview(colors),
                  const SizedBox(height: 24),
                  _buildItemDetails(colors),
                  const SizedBox(height: 16),
                  _buildPricingSection(colors),
                  const SizedBox(height: 16),
                  _buildStockSection(colors, history),
                  const SizedBox(height: 16),
                  _buildOtherSections(colors),
                  const SizedBox(height: 16),
                  _buildSettingsSection(colors),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(WareozeColorScheme colors, String inventoryId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        48,
        16,
        16,
      ), // Added top padding for status bar
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(CupertinoIcons.back, color: colors.textPrimary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '#${InventoryHelper.getItemCode(widget.inventory).isNotEmpty ? InventoryHelper.getItemCode(widget.inventory) : inventoryId.substring(inventoryId.length - 7)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              if (inventoryId.isNotEmpty) {
                context.push('/inventory-list/edit/$inventoryId');
              }
            },
            icon: Icon(CupertinoIcons.pencil, color: colors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildItemOverview(WareozeColorScheme colors) {
    final name = InventoryHelper.getInventoryName(widget.inventory);
    final currentStock = InventoryHelper.getCurrentStock(widget.inventory);
    final hsnCode = InventoryHelper.getHsnCode(widget.inventory);
    final mrp = InventoryHelper.getInventoryPrice(widget.inventory);
    final photos = InventoryHelper.getPhotos(widget.inventory);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: photos.isNotEmpty
                ? Image.network(
                    photos.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholderImage(colors),
                  )
                : _buildPlaceholderImage(colors),
          ),
        ),
        const SizedBox(width: 16),
        // Product Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Item Name',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Stock',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentStock > 0 ? currentStock.toString() : '-',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HSN Code',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hsnCode.isNotEmpty ? '#$hsnCode' : '-',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MRP',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mrp > 0 ? 'Rs. ${mrp.toStringAsFixed(0)}' : 'Rs. -',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemDetails(WareozeColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ITEM DETAILS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection(WareozeColorScheme colors) {
    return _buildSectionTile(
      colors: colors,
      icon: CupertinoIcons.money_dollar_circle,
      iconColor: Colors.green,
      title: 'Pricing Details',
      subtitle: 'MRP, Sales Price, Purchase Price',
      onTap: () => _navigateToPricingDetails(colors),
    );
  }

  Widget _buildStockSection(
    WareozeColorScheme colors,
    List<Map<String, dynamic>>? history,
  ) {
    return _buildSectionTile(
      colors: colors,
      icon: CupertinoIcons.cube_box,
      iconColor: Colors.blue,
      title: 'Stock Details',
      subtitle: 'Added Or Reduced Stocks',
      onTap: () => _navigateToStockDetails(colors, history),
    );
  }

  Widget _buildOtherSections(WareozeColorScheme colors) {
    return Column(
      children: [
        _buildSectionTile(
          colors: colors,
          icon: CupertinoIcons.person_2,
          iconColor: Colors.orange,
          title: 'Party Wise Report',
          subtitle: 'Customize with settings',
          onTap: () => _navigateToPartyWiseReport(colors),
        ),
        const SizedBox(height: 12),
        _buildSectionTile(
          colors: colors,
          icon: CupertinoIcons.tag,
          iconColor: Colors.purple,
          title: 'Party Wise Price',
          subtitle: 'Customize with settings',
          onTap: () => _navigateToPartyWisePrice(colors),
        ),
        const SizedBox(height: 12),
        _buildSectionTile(
          colors: colors,
          icon: CupertinoIcons.arrow_up_down,
          iconColor: Colors.teal,
          title: 'Adjust Stocks',
          subtitle: 'Stocks Update Form',
          onTap: () => _handleAdjustStockTap(colors),
        ),
      ],
    );
  }

  void _handleAdjustStockTap(WareozeColorScheme colors) {
    final itemType = InventoryHelper.getItemType(widget.inventory);

    if (itemType == 'Service') {
      // Show message for Service type items
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Service Item',
              style: TextStyle(color: colors.textPrimary),
            ),
            content: Text(
              'This Inventory Item is a Service type. Hence we are not maintaining any stock history for the Item.',
              style: TextStyle(color: Colors.red),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      // Navigate to AdjustStockPage for Product type items
      _navigateToAdjustStock(colors);
    }
  }

  Future<void> _navigateToAdjustStock(WareozeColorScheme colors) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdjustStockPage(inventory: widget.inventory),
      ),
    );

    // If stock was adjusted successfully, refresh the history
    if (result == true) {
      final inventoryId = widget.inventory['_id']?.toString();
      if (inventoryId != null) {
        await ref
            .read(inventoryProvider.notifier)
            .fetchInventoryHistoryById(inventoryId);
      }
    }
  }

  Widget _buildSettingsSection(WareozeColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'SETTINGS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        _buildSectionTile(
          colors: colors,
          icon: CupertinoIcons.photo,
          iconColor: Colors.indigo,
          title: 'Photos',
          subtitle: _getPhotosSubtitle(),
          onTap: () => _navigateToPhotosDetail(colors),
        ),
        const SizedBox(height: 12),
        _buildSectionTile(
          colors: colors,
          icon: CupertinoIcons.settings,
          iconColor: Colors.grey,
          title: 'Custom Fields',
          subtitle: _getCustomFieldsSubtitle(),
          onTap: () => _navigateToCustomFieldsDetail(colors),
        ),
        const SizedBox(height: 12),
        _buildSectionTile(
          colors: colors,
          icon: CupertinoIcons.link,
          iconColor: Colors.cyan,
          title: 'Linked Products',
          subtitle: _getLinkedProductsSubtitle(),
          onTap: () => _navigateToLinkedProductsDetail(colors),
        ),
      ],
    );
  }

  String _getPhotosSubtitle() {
    final photos = InventoryHelper.getPhotos(widget.inventory);
    if (photos.isEmpty) {
      return 'No photos added';
    }
    return '${photos.length} photo${photos.length > 1 ? 's' : ''} added';
  }

  String _getCustomFieldsSubtitle() {
    final brand = widget.inventory['brand']?.toString() ?? '';
    final color = widget.inventory['color']?.toString() ?? '';
    final storeLocation =
        widget.inventory['storeLocation']?['storeName']?.toString() ?? '';
    final additionalFields =
        widget.inventory['additionalFields'] as List<dynamic>? ?? [];

    List<String> fields = [];
    if (brand.isNotEmpty) fields.add('Brand: $brand');
    if (color.isNotEmpty) fields.add('Color: $color');
    if (storeLocation.isNotEmpty) fields.add('Store: $storeLocation');
    if (additionalFields.isNotEmpty)
      fields.add(
        '${additionalFields.length} additional field${additionalFields.length > 1 ? 's' : ''}',
      );

    if (fields.isEmpty) {
      return 'No custom fields added';
    }
    return fields.join(', ');
  }

  String _getLinkedProductsSubtitle() {
    final tags = widget.inventory['tags'] as List<dynamic>? ?? [];
    final parentSkus = widget.inventory['parentSkus'] as List<dynamic>? ?? [];
    final crossSellSkus =
        widget.inventory['crossSellSkus'] as List<dynamic>? ?? [];
    final upSellSkus = widget.inventory['upSellSkus'] as List<dynamic>? ?? [];

    int totalLinked =
        tags.length +
        parentSkus.length +
        crossSellSkus.length +
        upSellSkus.length;

    if (totalLinked == 0) {
      return 'No linked products';
    }

    List<String> linkedTypes = [];
    if (tags.isNotEmpty)
      linkedTypes.add('${tags.length} tag${tags.length > 1 ? 's' : ''}');
    if (parentSkus.isNotEmpty) linkedTypes.add('${parentSkus.length} parent');
    if (crossSellSkus.isNotEmpty)
      linkedTypes.add('${crossSellSkus.length} cross-sell');
    if (upSellSkus.isNotEmpty) linkedTypes.add('${upSellSkus.length} up-sell');

    return linkedTypes.join(', ');
  }

  void _navigateToPhotosDetail(WareozeColorScheme colors) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotosDetailPage(inventory: widget.inventory),
      ),
    );
  }

  void _navigateToCustomFieldsDetail(WareozeColorScheme colors) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            CustomFieldsDetailPage(inventory: widget.inventory),
      ),
    );
  }

  void _navigateToLinkedProductsDetail(WareozeColorScheme colors) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            LinkedProductsDetailPage(inventory: widget.inventory),
      ),
    );
  }

  Widget _buildSectionTile({
    required WareozeColorScheme colors,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: colors.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          CupertinoIcons.chevron_right,
          color: colors.textSecondary,
          size: 16,
        ),
        onTap: onTap,
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
        size: 48,
        color: colors.textSecondary,
      ),
    );
  }

  // Navigate to full page for Pricing Details
  void _navigateToPricingDetails(WareozeColorScheme colors) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PricingDetailsPage(inventory: widget.inventory),
      ),
    );
  }

  // Navigate to full page for Stock Details
  void _navigateToStockDetails(
    WareozeColorScheme colors,
    List<Map<String, dynamic>>? history,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            StockDetailsPage(inventory: widget.inventory, history: history),
      ),
    );
  }

  // Navigate to full page for Party Wise Report
  void _navigateToPartyWiseReport(WareozeColorScheme colors) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PartyWiseReportPage(inventory: widget.inventory),
      ),
    );
  }

  // Navigate to full page for Party Wise Price
  void _navigateToPartyWisePrice(WareozeColorScheme colors) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PartyWisePricePage(inventory: widget.inventory),
      ),
    );
  }

  // Helper methods to extract pricing data
  double _getSalePrice() {
    if (widget.inventory['sale'] != null &&
        widget.inventory['sale']['price'] != null) {
      return (widget.inventory['sale']['price'] as num).toDouble();
    }
    if (widget.inventory['salePrice'] != null) {
      return (widget.inventory['salePrice'] as num).toDouble();
    }
    return 0.0;
  }

  double _getWholeSalePrice() {
    if (widget.inventory['wholeSale'] != null &&
        widget.inventory['wholeSale']['price'] != null) {
      return (widget.inventory['wholeSale']['price'] as num).toDouble();
    }
    if (widget.inventory['wholeSalePrice'] != null) {
      return (widget.inventory['wholeSalePrice'] as num).toDouble();
    }
    return 0.0;
  }

  int _getWholeSaleMinQty() {
    if (widget.inventory['wholeSale'] != null &&
        widget.inventory['wholeSale']['minQty'] != null) {
      return (widget.inventory['wholeSale']['minQty'] as num).toInt();
    }
    if (widget.inventory['wholeSaleMinQty'] != null) {
      return (widget.inventory['wholeSaleMinQty'] as num).toInt();
    }
    return 0;
  }

  int _getDiscountAboveQty() {
    if (widget.inventory['discount'] != null &&
        widget.inventory['discount']['discountAboveQty'] != null) {
      return (widget.inventory['discount']['discountAboveQty'] as num).toInt();
    }
    if (widget.inventory['discountAboveQty'] != null) {
      return (widget.inventory['discountAboveQty'] as num).toInt();
    }
    return 0;
  }

  double _getGSTRate() {
    if (widget.inventory['gst'] != null &&
        widget.inventory['gst']['value'] != null) {
      return double.tryParse(widget.inventory['gst']['value'].toString()) ??
          0.0;
    }
    if (widget.inventory['taxRate'] != null) {
      return (widget.inventory['taxRate'] as num).toDouble();
    }
    return 0.0;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}

// Full page for Pricing Details
class PricingDetailsPage extends ConsumerWidget {
  final Map<String, dynamic> inventory;

  const PricingDetailsPage({Key? key, required this.inventory})
    : super(key: key);

  Future<void> _refreshPricingData(WidgetRef ref) async {
    final inventoryId = inventory['_id']?.toString();
    if (inventoryId != null) {
      final updatedInventory = await ref
          .read(inventoryProvider.notifier)
          .getInventoryById(inventoryId);
      if (updatedInventory != null) {
        inventory.clear();
        inventory.addAll(updatedInventory);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);
    final salePrice = _getSalePrice();
    final purchasePrice = InventoryHelper.getPurchasePrice(inventory);
    final mrp = InventoryHelper.getInventoryPrice(inventory);
    final hsnCode = InventoryHelper.getHsnCode(inventory);
    final wholeSalePrice = _getWholeSalePrice();
    final wholeSaleMinQty = _getWholeSaleMinQty();
    final discountPercent = InventoryHelper.getDiscountPercent(inventory);
    final discountAmount = InventoryHelper.getDiscountAmount(inventory);
    final discountAboveQty = _getDiscountAboveQty();
    final gstRate = _getGSTRate();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back, color: colors.textPrimary),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: InventoryHelper.getPhotos(inventory).isNotEmpty
                  ? NetworkImage(InventoryHelper.getPhotos(inventory).first)
                  : null,
              backgroundColor: colors.background,
              child: InventoryHelper.getPhotos(inventory).isEmpty
                  ? Icon(
                      Icons.inventory_2_outlined,
                      color: colors.textSecondary,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    InventoryHelper.getInventoryName(inventory),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    InventoryHelper.getItemCode(inventory).isNotEmpty
                        ? InventoryHelper.getItemCode(inventory)
                        : 'No item code',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              final inventoryId = inventory['_id']?.toString();
              if (inventoryId != null && inventoryId.isNotEmpty) {
                context.push('/inventory-list/edit/$inventoryId');
              }
            },
            icon: Icon(CupertinoIcons.pencil, color: colors.primary),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshPricingData(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: colors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pricing Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildPriceField(
                'Sales Price',
                salePrice > 0 ? 'Rs. ${salePrice.toStringAsFixed(0)}' : 'Rs. -',
                colors,
              ),
              const SizedBox(height: 16),
              _buildPriceField(
                'Purchase Price',
                purchasePrice > 0
                    ? 'Rs. ${purchasePrice.toStringAsFixed(0)}'
                    : 'Rs. -',
                colors,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildPriceField(
                      'MRP',
                      mrp > 0 ? 'Rs. ${mrp.toStringAsFixed(0)}' : 'Rs. 750',
                      colors,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPriceField('Sale Unit', '-', colors)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildPriceField(
                      'HSN',
                      hsnCode.isNotEmpty ? hsnCode : '8999',
                      colors,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPriceField('Purchase Unit', '-', colors),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildPriceField(
                'GST Tax Rate',
                gstRate > 0 ? '${gstRate.toStringAsFixed(0)}%' : '-',
                colors,
              ),
              const SizedBox(height: 24),
              _buildPriceField(
                'Wholesale Price',
                wholeSalePrice > 0
                    ? 'Rs. ${wholeSalePrice.toStringAsFixed(0)}'
                    : 'Rs. -',
                colors,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildPriceField(
                      'Min. Wholesale Quantity',
                      wholeSaleMinQty > 0 ? wholeSaleMinQty.toString() : '-',
                      colors,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPriceField(
                      'Discount Above Quantity',
                      discountAboveQty > 0 ? discountAboveQty.toString() : '-',
                      colors,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildPriceField(
                'Discount',
                discountPercent > 0
                    ? '${discountPercent.toInt()}% ${discountAmount > 0 ? '(${discountAmount.toInt()})' : '(7)'}'
                    : '10% (7)',
                colors,
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceField(
    String label,
    String value,
    WareozeColorScheme colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: colors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  // Helper methods
  double _getSalePrice() {
    if (inventory['sale'] != null && inventory['sale']['price'] != null) {
      return (inventory['sale']['price'] as num).toDouble();
    }
    if (inventory['salePrice'] != null) {
      return (inventory['salePrice'] as num).toDouble();
    }
    return 0.0;
  }

  double _getWholeSalePrice() {
    if (inventory['wholeSale'] != null &&
        inventory['wholeSale']['price'] != null) {
      return (inventory['wholeSale']['price'] as num).toDouble();
    }
    if (inventory['wholeSalePrice'] != null) {
      return (inventory['wholeSalePrice'] as num).toDouble();
    }
    return 0.0;
  }

  int _getWholeSaleMinQty() {
    if (inventory['wholeSale'] != null &&
        inventory['wholeSale']['minQty'] != null) {
      return (inventory['wholeSale']['minQty'] as num).toInt();
    }
    if (inventory['wholeSaleMinQty'] != null) {
      return (inventory['wholeSaleMinQty'] as num).toInt();
    }
    return 0;
  }

  int _getDiscountAboveQty() {
    if (inventory['discount'] != null &&
        inventory['discount']['discountAboveQty'] != null) {
      return (inventory['discount']['discountAboveQty'] as num).toInt();
    }
    if (inventory['discountAboveQty'] != null) {
      return (inventory['discountAboveQty'] as num).toInt();
    }
    return 0;
  }

  double _getGSTRate() {
    if (inventory['gst'] != null && inventory['gst']['value'] != null) {
      return double.tryParse(inventory['gst']['value'].toString()) ?? 0.0;
    }
    if (inventory['taxRate'] != null) {
      return (inventory['taxRate'] as num).toDouble();
    }
    return 0.0;
  }
}

// Full page for Stock Details
class StockDetailsPage extends ConsumerWidget {
  final Map<String, dynamic> inventory;
  final List<Map<String, dynamic>>? history;

  const StockDetailsPage({Key? key, required this.inventory, this.history})
    : super(key: key);

  Future<void> _refreshStockData(WidgetRef ref) async {
    final inventoryId = inventory['_id']?.toString();
    if (inventoryId != null) {
      await ref
          .read(inventoryProvider.notifier)
          .fetchInventoryHistoryById(inventoryId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back, color: colors.textPrimary),
        ),
        title: Text(
          'Stock Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _navigateToAdjustStock(context, ref),
            icon: Icon(CupertinoIcons.plus, color: colors.primary),
          ),
        ],
      ),
      body: history == null
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            )
          : history!.isEmpty
          ? RefreshIndicator(
              onRefresh: () => _refreshStockData(ref),
              child: ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.cube_box,
                          size: 64,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          InventoryHelper.getItemType(inventory) == 'Service'
                              ? 'This Inventory Item is a Service type. Hence we are not maintaining any stock history for the Item.'
                              : 'No stock history available',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                InventoryHelper.getItemType(inventory) ==
                                    'Service'
                                ? Colors.red
                                : colors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          InventoryHelper.getItemType(inventory) == 'Service'
                              ? ''
                              : 'Pull down to refresh',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _refreshStockData(ref),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: history!.length,
                itemBuilder: (context, index) {
                  final item = history![index];
                  return _buildStockHistoryItem(item, colors);
                },
              ),
            ),
    );
  }

  Future<void> _navigateToAdjustStock(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdjustStockPage(inventory: inventory),
      ),
    );

    // If stock was adjusted successfully, refresh the history
    if (result == true) {
      final inventoryId = inventory['_id']?.toString();
      if (inventoryId != null) {
        await ref
            .read(inventoryProvider.notifier)
            .fetchInventoryHistoryById(inventoryId);
      }
    }
  }

  Widget _buildStockHistoryItem(
    Map<String, dynamic> item,
    WareozeColorScheme colors,
  ) {
    final type = item['type'] ?? 'Unknown';
    final qty = item['qty']?.toString() ?? '0';
    final closingStock = item['closingStock']?.toString() ?? '0';
    final date = item['date'] ?? '';
    final remarks = item['remarks'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: type == 'Add Stock'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: type == 'Add Stock' ? Colors.green : Colors.red,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Qty: $qty',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Closing Stock: $closingStock',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Date: ${_formatDate(date)}',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ],
          if (remarks.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Remarks: $remarks',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}

// Full page for Party Wise Report
class PartyWiseReportPage extends ConsumerWidget {
  final Map<String, dynamic> inventory;

  const PartyWiseReportPage({Key? key, required this.inventory})
    : super(key: key);

  Future<void> _refreshPartyData(WidgetRef ref) async {
    final inventoryId = inventory['_id']?.toString();
    if (inventoryId != null) {
      final updatedInventory = await ref
          .read(inventoryProvider.notifier)
          .getInventoryById(inventoryId);
      if (updatedInventory != null) {
        inventory.clear();
        inventory.addAll(updatedInventory);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back, color: colors.textPrimary),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: InventoryHelper.getPhotos(inventory).isNotEmpty
                  ? NetworkImage(InventoryHelper.getPhotos(inventory).first)
                  : null,
              backgroundColor: colors.background,
              child: InventoryHelper.getPhotos(inventory).isEmpty
                  ? Icon(
                      Icons.inventory_2_outlined,
                      color: colors.textSecondary,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    InventoryHelper.getInventoryName(inventory),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    InventoryHelper.getItemCode(inventory).isNotEmpty
                        ? InventoryHelper.getItemCode(inventory)
                        : 'No item code',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshPartyData(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Party Wise Report Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Text(
                      'Party Wise Report',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      CupertinoIcons.chevron_right,
                      color: colors.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Party Name Section
              _buildInfoField(
                'Party Name',
                InventoryHelper.getInventoryName(inventory),
                colors,
              ),
              const SizedBox(height: 24),

              // Sales and Purchase Section
              Row(
                children: [
                  Expanded(
                    child: _buildInfoField('Sales Quantity', '-', colors),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoField('Purchase Quantity', '-', colors),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(child: _buildInfoField('Sales Amount', '-', colors)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoField('Purchase Amount', '-', colors),
                  ),
                ],
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField(
    String label,
    String value,
    WareozeColorScheme colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: colors.textSecondary),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// Full page for Party Wise Price
class PartyWisePricePage extends ConsumerWidget {
  final Map<String, dynamic> inventory;

  const PartyWisePricePage({Key? key, required this.inventory})
    : super(key: key);

  Future<void> _refreshPartyData(WidgetRef ref) async {
    final inventoryId = inventory['_id']?.toString();
    if (inventoryId != null) {
      final updatedInventory = await ref
          .read(inventoryProvider.notifier)
          .getInventoryById(inventoryId);
      if (updatedInventory != null) {
        inventory.clear();
        inventory.addAll(updatedInventory);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back, color: colors.textPrimary),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: InventoryHelper.getPhotos(inventory).isNotEmpty
                  ? NetworkImage(InventoryHelper.getPhotos(inventory).first)
                  : null,
              backgroundColor: colors.background,
              child: InventoryHelper.getPhotos(inventory).isEmpty
                  ? Icon(
                      Icons.inventory_2_outlined,
                      color: colors.textSecondary,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    InventoryHelper.getInventoryName(inventory),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    InventoryHelper.getItemCode(inventory).isNotEmpty
                        ? InventoryHelper.getItemCode(inventory)
                        : 'No item code',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshPartyData(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Party Wise Price Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Text(
                      'Party Wise Price',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      CupertinoIcons.chevron_right,
                      color: colors.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Party Name Section
              _buildInfoField('Party Name', 'Tanmay Buradkar', colors),
              const SizedBox(height: 24),

              // Sales and Purchase Section
              Row(
                children: [
                  Expanded(
                    child: _buildInfoField('Sales Quantity', '3', colors),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoField('Purchase Quantity', '1', colors),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _buildInfoField('Sales Amount', '243.22', colors),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoField('Purchase Amount', '100', colors),
                  ),
                ],
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField(
    String label,
    String value,
    WareozeColorScheme colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: colors.textSecondary),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// Photos Detail Page
class PhotosDetailPage extends ConsumerWidget {
  final Map<String, dynamic> inventory;

  const PhotosDetailPage({Key? key, required this.inventory}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);
    final photos = InventoryHelper.getPhotos(inventory);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back, color: colors.textPrimary),
        ),
        title: Text(
          'Photos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              final inventoryId = inventory['_id']?.toString();
              if (inventoryId != null && inventoryId.isNotEmpty) {
                context.push('/inventory-list/edit/$inventoryId');
              }
            },
            icon: Icon(CupertinoIcons.pencil, color: colors.primary),
          ),
        ],
      ),
      body: photos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.photo,
                    size: 64,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No photos added',
                    style: TextStyle(fontSize: 16, color: colors.textSecondary),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    photos[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: colors.surface,
                      child: Icon(
                        Icons.broken_image,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// Custom Fields Detail Page
class CustomFieldsDetailPage extends ConsumerWidget {
  final Map<String, dynamic> inventory;

  const CustomFieldsDetailPage({Key? key, required this.inventory})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);
    final brand = inventory['brand']?.toString() ?? '';
    final color = inventory['color']?.toString() ?? '';
    final storeLocation =
        inventory['storeLocation']?['storeName']?.toString() ?? '';
    final additionalFields =
        inventory['additionalFields'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back, color: colors.textPrimary),
        ),
        title: Text(
          'Custom Fields',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              final inventoryId = inventory['_id']?.toString();
              if (inventoryId != null && inventoryId.isNotEmpty) {
                context.push('/inventory-list/edit/$inventoryId');
              }
            },
            icon: Icon(CupertinoIcons.pencil, color: colors.primary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (brand.isNotEmpty) ...[
              _buildCustomField('Brand', brand, colors),
              const SizedBox(height: 16),
            ],
            if (color.isNotEmpty) ...[
              _buildCustomField('Color', color, colors),
              const SizedBox(height: 16),
            ],
            if (storeLocation.isNotEmpty) ...[
              _buildCustomField('Store Location', storeLocation, colors),
              const SizedBox(height: 16),
            ],
            if (additionalFields.isNotEmpty) ...[
              Text(
                'Additional Fields',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...additionalFields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildCustomField(
                    'Field ${additionalFields.indexOf(field) + 1}',
                    field.toString(),
                    colors,
                  ),
                ),
              ),
            ],
            if (brand.isEmpty &&
                color.isEmpty &&
                storeLocation.isEmpty &&
                additionalFields.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.settings,
                      size: 64,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No custom fields added',
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomField(
    String label,
    String value,
    WareozeColorScheme colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// Linked Products Detail Page
class LinkedProductsDetailPage extends ConsumerWidget {
  final Map<String, dynamic> inventory;

  const LinkedProductsDetailPage({Key? key, required this.inventory})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);
    final tags = inventory['tags'] as List<dynamic>? ?? [];
    final parentSkus = inventory['parentSkus'] as List<dynamic>? ?? [];
    final crossSellSkus = inventory['crossSellSkus'] as List<dynamic>? ?? [];
    final upSellSkus = inventory['upSellSkus'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back, color: colors.textPrimary),
        ),
        title: Text(
          'Linked Products',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              final inventoryId = inventory['_id']?.toString();
              if (inventoryId != null && inventoryId.isNotEmpty) {
                context.push('/inventory-list/edit/$inventoryId');
              }
            },
            icon: Icon(CupertinoIcons.pencil, color: colors.primary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tags.isNotEmpty) ...[
              _buildLinkedSection('Tags', tags, colors),
              const SizedBox(height: 16),
            ],
            if (parentSkus.isNotEmpty) ...[
              _buildLinkedSection('Parent SKUs', parentSkus, colors),
              const SizedBox(height: 16),
            ],
            if (crossSellSkus.isNotEmpty) ...[
              _buildLinkedSection('Cross-Sell SKUs', crossSellSkus, colors),
              const SizedBox(height: 16),
            ],
            if (upSellSkus.isNotEmpty) ...[
              _buildLinkedSection('Up-Sell SKUs', upSellSkus, colors),
              const SizedBox(height: 16),
            ],
            if (tags.isEmpty &&
                parentSkus.isEmpty &&
                crossSellSkus.isEmpty &&
                upSellSkus.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.link,
                      size: 64,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No linked products',
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedSection(
    String title,
    List<dynamic> items,
    WareozeColorScheme colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                item.toString(),
                style: TextStyle(fontSize: 14, color: colors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
