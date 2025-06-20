import 'package:flutter/cupertino.dart';

// Item model
class Item {
  final String id;
  final String name;
  final String description;
  final String hsnSac;
  final double mrp;

  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.hsnSac,
    required this.mrp,
  });
}

// Invoice Item model
class InvoiceItem {
  final String id;
  final dynamic item;
  int quantity;
  double price;
  double discount;
  double tax;

  InvoiceItem({
    required this.id,
    required this.item,
    this.quantity = 1,
    double? price,
    this.discount = 0.0,
    this.tax = 0.0,
  }) : price = price ?? item.mrp;

  double get amount => quantity * price;
  double get discountAmount => amount * (discount / 100);
  double get taxableAmount => amount - discountAmount;
  double get taxAmount => taxableAmount * (tax / 100);
  double get finalAmount => taxableAmount + taxAmount;
}

class ItemsSection extends StatelessWidget {
  final List<dynamic> invoiceItems;
  final List<dynamic> availableItems;
  final Function(dynamic, int) onItemAdded;
  final Function(String) onItemRemoved;
  final Function(String, {int? quantity, double? price}) onItemUpdated;
  final String? validationError;

  const ItemsSection({
    super.key,
    required this.invoiceItems,
    required this.availableItems,
    required this.onItemAdded,
    required this.onItemRemoved,
    required this.onItemUpdated,
    this.validationError,
  });

  void _showItemSelection(BuildContext context) {
    showCupertinoSheet(
      context: context,
      pageBuilder: (context) =>
          ItemSelectionSheet(items: availableItems, onItemAdded: onItemAdded),
    );
  }

  void _showItemEditSheet(BuildContext context, InvoiceItem invoiceItem) {
    showCupertinoSheet(
      context: context,
      pageBuilder: (context) => ItemEditSheet(
        invoiceItem: invoiceItem,
        onItemUpdated: (quantity, price) {
          onItemUpdated(invoiceItem.id, quantity: quantity, price: price);
        },
      ),
    );
  }

  Widget _buildItemDetailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _buildInvoiceItemTile(
    BuildContext context,
    InvoiceItem invoiceItem,
    int index,
  ) {
    return GestureDetector(
      onTap: () => _showItemEditSheet(context, invoiceItem),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: CupertinoColors.systemGrey4,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      index.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoiceItem.item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (invoiceItem.item.description.isNotEmpty)
                        Text(
                          invoiceItem.item.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => onItemRemoved(invoiceItem.id),
                  child: const Icon(
                    CupertinoIcons.trash,
                    color: CupertinoColors.destructiveRed,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildItemDetailChip(
                  'HSN/SAC',
                  invoiceItem.item.hsnSac.isEmpty
                      ? '-'
                      : invoiceItem.item.hsnSac,
                ),
                const SizedBox(width: 8),
                _buildItemDetailChip('QTY', invoiceItem.quantity.toString()),
                const SizedBox(width: 8),
                _buildItemDetailChip(
                  'Price',
                  '₹${invoiceItem.price.toStringAsFixed(2)}',
                ),
                const Spacer(),
                Text(
                  '₹${invoiceItem.finalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection(
      header: Transform.translate(
        offset: const Offset(-4, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ITEMS',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Display',
                letterSpacing: 0.25,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showItemSelection(context),
              child: const Text('Add Items', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
      backgroundColor: CupertinoColors.systemBackground,
      margin: EdgeInsets.zero,
      topMargin: 10,
      children: [
        if (invoiceItems.isEmpty)
          CupertinoListTile(
            title: const Text('No items added'),
            subtitle: const Text('Tap "Add Items" to get started'),
            trailing: const Icon(CupertinoIcons.plus_circle),
            onTap: () => _showItemSelection(context),
          )
        else
          ...invoiceItems.asMap().entries.map((entry) {
            final index = entry.key;
            final invoiceItem = entry.value;
            return _buildInvoiceItemTile(context, invoiceItem, index + 1);
          }),

        if (validationError != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              validationError!,
              style: const TextStyle(
                color: CupertinoColors.destructiveRed,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

class ItemSelectionSheet extends StatefulWidget {
  final List<dynamic> items;
  final Function(dynamic, int) onItemAdded;

  const ItemSelectionSheet({
    super.key,
    required this.items,
    required this.onItemAdded,
  });

  @override
  State<ItemSelectionSheet> createState() => _ItemSelectionSheetState();
}

class _ItemSelectionSheetState extends State<ItemSelectionSheet> {
  String searchQuery = '';

  List<dynamic> get filteredItems {
    if (searchQuery.isEmpty) {
      return widget.items;
    }
    return widget.items
        .where(
          (item) =>
              item.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              item.description.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              item.hsnSac.contains(searchQuery),
        )
        .toList();
  }

  void _showQuantityDialog(dynamic item) {
    int quantity = 1;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Add ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text('Enter quantity:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.separator),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CupertinoTextField(
                decoration: null,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                placeholder: '1',
                onChanged: (value) {
                  quantity = int.tryParse(value) ?? 1;
                },
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Add'),
            onPressed: () {
              widget.onItemAdded(item, quantity);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close sheet
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.94,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const Expanded(
                  child: Text(
                    'Add Items',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 60),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: CupertinoSearchTextField(
              placeholder: 'Search items...',
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),

          // Items List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];

                return Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: CupertinoColors.separator,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: CupertinoListTile(
                    onTap: () => _showQuantityDialog(item),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: CupertinoColors.activeBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.cube_box,
                        color: CupertinoColors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.description.isNotEmpty)
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (item.hsnSac.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemGrey6
                                      .resolveFrom(context),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'HSN: ${item.hsnSac}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: CupertinoColors.activeBlue.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '₹${item.mrp.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: CupertinoColors.activeBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(
                      CupertinoIcons.plus_circle,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ItemEditSheet extends StatefulWidget {
  final InvoiceItem invoiceItem;
  final Function(int, double) onItemUpdated;

  const ItemEditSheet({
    super.key,
    required this.invoiceItem,
    required this.onItemUpdated,
  });

  @override
  State<ItemEditSheet> createState() => _ItemEditSheetState();
}

class _ItemEditSheetState extends State<ItemEditSheet> {
  late TextEditingController quantityController;
  late TextEditingController priceController;

  @override
  void initState() {
    super.initState();
    quantityController = TextEditingController(
      text: widget.invoiceItem.quantity.toString(),
    );
    priceController = TextEditingController(
      text: widget.invoiceItem.price.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    quantityController.dispose();
    priceController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final quantity = int.tryParse(quantityController.text) ?? 1;
    final price = double.tryParse(priceController.text) ?? 0.0;

    widget.onItemUpdated(quantity, price);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.6,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const Expanded(
                  child: Text(
                    'Edit Item',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _saveChanges,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.invoiceItem.item.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.invoiceItem.item.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.invoiceItem.item.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (widget.invoiceItem.item.hsnSac.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemBackground
                                      .resolveFrom(context),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'HSN/SAC: ${widget.invoiceItem.item.hsnSac}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: CupertinoColors.activeBlue.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'MRP: ₹${widget.invoiceItem.item.mrp.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.activeBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Edit Fields
                  CupertinoListSection(
                    header: const Text('ITEM DETAILS'),
                    backgroundColor: CupertinoColors.systemBackground
                        .resolveFrom(context),
                    margin: EdgeInsets.zero,
                    children: [
                      CupertinoListTile(
                        title: const Text('Quantity'),
                        trailing: SizedBox(
                          width: 80,
                          child: CupertinoTextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: CupertinoColors.separator,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      CupertinoListTile(
                        title: const Text('Price per item'),
                        trailing: SizedBox(
                          width: 100,
                          child: CupertinoTextField(
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.center,
                            prefix: const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Text('₹'),
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: CupertinoColors.separator,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Calculation Preview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeBlue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CupertinoColors.activeBlue.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Amount Calculation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.activeBlue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildCalculationRow(
                          'Quantity',
                          quantityController.text.isEmpty
                              ? '1'
                              : quantityController.text,
                        ),
                        _buildCalculationRow(
                          'Price per item',
                          '₹${priceController.text.isEmpty ? '0.00' : double.tryParse(priceController.text)?.toStringAsFixed(2) ?? '0.00'}',
                        ),
                        // const Divider(color: CupertinoColors.separator),
                        _buildCalculationRow(
                          'Total Amount',
                          '₹${_calculateTotal().toStringAsFixed(2)}',
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(
    String label,
    String value, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: isTotal ? CupertinoColors.activeBlue : null,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotal() {
    final quantity = int.tryParse(quantityController.text) ?? 1;
    final price = double.tryParse(priceController.text) ?? 0.0;
    return quantity * price;
  }
}

// Keep the ItemSelectionSheet and ItemEditSheet classes here as they are part of the items functionality
