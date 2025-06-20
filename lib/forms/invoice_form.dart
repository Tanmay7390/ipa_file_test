import 'package:flutter/cupertino.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:flutter_test_22/components/form_fields.dart';
import 'package:flutter_test_22/forms/buyer_section.dart'; // Import the new component
import 'package:flutter_test_22/forms/items_section.dart'; // Import the new component

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

// Invoice Item model (Item + quantity + calculated fields)
class InvoiceItem {
  final String id;
  final Item item;
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

void showInvoiceFormSheet(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    CupertinoModalSheetRoute(
      swipeDismissible: true,
      builder: (context) => const InvoiceFormSheet(),
    ),
  );
}

class InvoiceFormSheet extends StatefulWidget {
  const InvoiceFormSheet({super.key});

  @override
  State<InvoiceFormSheet> createState() => _InvoiceFormSheetState();
}

class _InvoiceFormSheetState extends State<InvoiceFormSheet> {
  final Map<String, dynamic> formData = {};
  final Map<String, String> validationErrors = {};
  dynamic selectedClient;
  List<dynamic> invoiceItems = [];

  final emailPattern = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
  final phonePattern = RegExp(r'^[6-9]\d{9}$');

  // Sample items data
  final List<Item> availableItems = [
    Item(
      id: '1',
      name: 'Brick_1',
      description: 'Brick 1 is brick',
      hsnSac: '5677',
      mrp: 1000.0,
    ),
    Item(
      id: '2',
      name: 'Consultation',
      description: 'consultation',
      hsnSac: '',
      mrp: 0.0,
    ),
    Item(
      id: '3',
      name: 'Cement Bag',
      description: 'High quality cement bag',
      hsnSac: '2523',
      mrp: 350.0,
    ),
    Item(
      id: '4',
      name: 'Steel Rod',
      description: 'TMT steel rod per meter',
      hsnSac: '7213',
      mrp: 55.0,
    ),
  ];

  void _updateFormData(String key, dynamic value) {
    setState(() {
      formData[key] = value;
      validationErrors.remove(key);
    });
  }

  void _selectClient(dynamic client) {
    setState(() {
      selectedClient = client;
      formData['clientId'] = client['_id'];
      validationErrors.remove('client');
    });
  }

  void _addInvoiceItem(dynamic item, int quantity) {
    setState(() {
      final invoiceItem = InvoiceItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        item: item,
        quantity: quantity,
      );
      invoiceItems.add(invoiceItem);
    });
  }

  void _updateInvoiceItem(String id, {int? quantity, double? price}) {
    setState(() {
      final index = invoiceItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        if (quantity != null) invoiceItems[index].quantity = quantity;
        if (price != null) invoiceItems[index].price = price;
      }
    });
  }

  void _removeInvoiceItem(String id) {
    setState(() {
      invoiceItems.removeWhere((item) => item.id == id);
    });
  }

  bool _validateForm() {
    validationErrors.clear();

    // Check if client is selected
    if (selectedClient == null) {
      validationErrors['client'] = 'Please select a client';
    }

    // Check if items are added
    if (invoiceItems.isEmpty) {
      validationErrors['items'] = 'Please add at least one item';
    }

    void checkRequired(String key, String label) {
      if (formData[key]?.toString().trim().isEmpty ?? true) {
        validationErrors[key] = '$label is required';
      }
    }

    checkRequired('invoiceNumber', 'Invoice number');
    checkRequired('paymentTerm', 'Payment term');
    checkRequired('invoiceDate', 'Invoice date');
    checkRequired('dueDate', 'Due date');
    checkRequired('quotationDate', 'Quotation date');
    checkRequired('quotationNumber', 'Quotation number');
    checkRequired('poDate', 'PO date');
    checkRequired('poNumber', 'PO number');

    return validationErrors.isEmpty;
  }

  void _saveForm() {
    if (_validateForm()) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Success'),
          content: const Text('Invoice added successfully!'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context)
                ..pop()
                ..pop(),
            ),
          ],
        ),
      );
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('New Invoice'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saveForm,
          child: const Text('Save'),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Buyer Selection Section - Now using the extracted component
              BuyerSelectionSection(
                selectedClient: selectedClient,
                onClientSelected: _selectClient,
                validationError: validationErrors['client'],
              ),
              const SizedBox(height: 20),

              // Invoice Details Section
              _buildSection([
                FormFieldWidgets.buildTextField(
                  'invoiceNumber',
                  'Invoice No',
                  'text',
                  context,
                  isRequired: true,
                  onChanged: _updateFormData,
                  formData: formData,
                  validationErrors: validationErrors,
                ),
                FormFieldWidgets.buildTextField(
                  'paymentTerm',
                  'Payment Term',
                  'text',
                  context,
                  isRequired: true,
                  onChanged: _updateFormData,
                  formData: formData,
                  validationErrors: validationErrors,
                ),
                FormFieldWidgets.buildDateField(
                  'invoiceDate',
                  'Date',
                  isRequired: true,
                  context: context,
                  minimumDate: DateTime(1920),
                  maximumDate: DateTime.now(),
                  dateFormat: 'dd/MM/yyyy',
                  onChanged: _updateFormData,
                  formData: formData,
                  validationErrors: validationErrors,
                ),
                FormFieldWidgets.buildDateField(
                  'dueDate',
                  'Due Date',
                  isRequired: true,
                  context: context,
                  minimumDate: DateTime(1920),
                  maximumDate: DateTime.now().add(const Duration(days: 365)),
                  dateFormat: 'dd/MM/yyyy',
                  onChanged: _updateFormData,
                  formData: formData,
                  validationErrors: validationErrors,
                ),
              ]),

              // Quotation and PO Section
              _buildSection(title: 'QUOTATION AND PO', [
                FormFieldWidgets.buildDateField(
                  'quotationDate',
                  'Quo. Date',
                  isRequired: true,
                  context: context,
                  minimumDate: DateTime(1920),
                  maximumDate: DateTime.now(),
                  dateFormat: 'dd/MM/yyyy',
                  onChanged: _updateFormData,
                  formData: formData,
                  validationErrors: validationErrors,
                ),
                FormFieldWidgets.buildTextField(
                  'quotationNumber',
                  'Quo. Number',
                  'text',
                  context,
                  isRequired: true,
                  onChanged: _updateFormData,
                  formData: formData,
                  validationErrors: validationErrors,
                ),
                FormFieldWidgets.buildDateField(
                  'poDate',
                  'PO Date',
                  isRequired: true,
                  context: context,
                  minimumDate: DateTime(1920),
                  maximumDate: DateTime.now(),
                  dateFormat: 'dd/MM/yyyy',
                  onChanged: _updateFormData,
                  formData: formData,
                  validationErrors: validationErrors,
                ),
                FormFieldWidgets.buildTextField(
                  'poNumber',
                  'PO Number',
                  'text',
                  context,
                  isRequired: true,
                  onChanged: _updateFormData,
                  formData: formData,
                  validationErrors: validationErrors,
                ),
              ]),

              // Items Section
              ItemsSection(
                invoiceItems: invoiceItems,
                availableItems: availableItems,
                onItemAdded: _addInvoiceItem,
                onItemRemoved: _removeInvoiceItem,
                onItemUpdated: _updateInvoiceItem,
                validationError: validationErrors['items'],
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

class CollapsibleSection extends StatefulWidget {
  final List<Widget> fields;
  final String title;
  final bool compact;
  final bool initiallyExpanded;

  const CollapsibleSection({
    super.key,
    required this.fields,
    this.title = '',
    this.compact = false,
    this.initiallyExpanded = true,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _iconAnimation;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title.isNotEmpty)
          GestureDetector(
            onTap: _toggleExpansion,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 16,
                bottom: 8,
                top: 8,
              ),
              child: Transform.translate(
                offset: const Offset(-4, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SF Pro Display',
                          letterSpacing: 0.25,
                          fontSize: 13,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _iconAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _iconAnimation.value * 3.14159,
                          child: const Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: CupertinoColors.systemGrey2,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1.0,
          child: CupertinoListSection(
            backgroundColor: CupertinoColors.systemBackground.resolveFrom(
              context,
            ),
            dividerMargin: widget.compact ? 0 : 100,
            margin: EdgeInsets.zero,
            topMargin: 0,
            additionalDividerMargin: widget.compact ? 0 : 30,
            children: widget.fields,
          ),
        ),
      ],
    );
  }
}

// Updated helper method to use the new widget
Widget _buildSection(
  List<Widget> fields, {
  String title = '',
  bool compact = false,
  bool initiallyExpanded = true,
}) {
  return CollapsibleSection(
    fields: fields,
    title: title,
    compact: compact,
    initiallyExpanded: initiallyExpanded,
  );
}
