import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test_22/apis/providers/customer_address_provider.dart';
import '../apis/providers/new_inventory_provider.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:flutter_test_22/components/form_fields.dart';
import 'package:flutter_test_22/forms/buyer_section.dart';
import 'package:flutter_test_22/forms/address_section.dart';
import 'package:flutter_test_22/forms/items_section.dart';
import 'package:flutter_test_22/apis/providers/new_invoice_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

void showInvoiceFormSheet(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    CupertinoModalSheetRoute(
      swipeDismissible: true,
      builder: (context) => const InvoiceFormSheet(),
    ),
  );
}

// Bottom Fixed Area Widget
class InvoiceBottomFixedArea extends StatelessWidget {
  const InvoiceBottomFixedArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            onPressed: () => showInvoiceFormSheet(context),
            child: const Text('Create New Invoice'),
          ),
        ),
      ),
    );
  }
}

class InvoiceFormSheet extends ConsumerStatefulWidget {
  const InvoiceFormSheet({super.key});

  @override
  ConsumerState<InvoiceFormSheet> createState() => _InvoiceFormSheetState();
}

class _InvoiceFormSheetState extends ConsumerState<InvoiceFormSheet> {
  final Map<String, dynamic> formData = {};
  final Map<String, String> validationErrors = {};

  // Client and address data
  Map<String, dynamic>? selectedClient;
  Map<String, dynamic>? billToAddress;
  Map<String, dynamic>? shipToAddress;

  List<dynamic> invoiceItems = [];
  bool shipToDifferent = false;

  // Invoice specific data - Add loading states
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> states = [];
  List<Map<String, dynamic>> templates = [];
  List<Map<String, dynamic>> bankAccounts = [];
  Map<String, dynamic>? invoiceSequenceData;

  // Add loading states for items
  bool isLoadingItems = false;
  bool isLoadingStates = false;
  bool isLoadingTemplates = false;
  bool isLoadingBankAccounts = false;
  bool isLoadingSequence = false;

  final emailPattern = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
  final phonePattern = RegExp(r'^[6-9]\d{9}$');

  void _updateFormData(String key, dynamic value) {
    setState(() {
      formData[key] = value;
      validationErrors.remove(key);
    });
  }

  @override
  void initState() {
    super.initState();
    // Call API loading methods immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInvoiceData();
    });
  }

  Future<void> _loadInvoiceData() async {
    // Load all data concurrently with proper error handling
    await Future.wait([
      _loadItems(),
      _loadStates(),
      _loadTemplates(),
      _loadBankAccounts(),
      _loadInvoiceSequence(),
    ]);
  }

  Future<void> _loadItems() async {
    if (!mounted) return;

    setState(() {
      isLoadingItems = true;
    });

    try {
      // Use the correct provider name from new_inventory_provider.dart
      final itemData = await ref.read(
        inventoryListProvider('6434642d86b9bb6018ef2528').future,
      );

      if (mounted) {
        setState(() {
          // Handle the data properly with type safety
          items = itemData.map((item) {
            return Map<String, dynamic>.from(item);
          }).toList();
          isLoadingItems = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          items = <Map<String, dynamic>>[];
          isLoadingItems = false;
        });
        _showErrorDialog('Failed to load items: $e');
      }
    }
  }

  Future<void> _loadStates() async {
    if (!mounted) return;

    setState(() {
      isLoadingStates = true;
    });

    try {
      final statesData = await ref.read(statesProvider.future);

      if (mounted) {
        setState(() {
          // Ensure we handle the data properly regardless of its structure
          states = statesData.map((state) {
            return Map<String, dynamic>.from(state);
          }).toList();
          isLoadingStates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          states = <Map<String, dynamic>>[];
          isLoadingStates = false;
        });
        _showErrorDialog('Failed to load states: $e');
      }
    }
  }

  Future<void> _loadTemplates() async {
    if (!mounted) return;

    setState(() {
      isLoadingTemplates = true;
    });

    try {
      final templatesData = await ref.read(invoiceTemplatesProvider.future);

      if (mounted) {
        setState(() {
          // Ensure we handle the data properly
          templates = templatesData.map((template) {
            return Map<String, dynamic>.from(template);
          }).toList();
          isLoadingTemplates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          templates = <Map<String, dynamic>>[];
          isLoadingTemplates = false;
        });
        _showErrorDialog('Failed to load templates: $e');
      }
    }
  }

  Future<void> _loadBankAccounts() async {
    if (!mounted) return;

    setState(() {
      isLoadingBankAccounts = true;
    });

    try {
      // You might need to get the actual account ID dynamically
      // For now, using the hardcoded one, but consider making this dynamic
      final banksData = await ref.read(
        bankAccountsProvider('6434642d86b9bb6018ef2528').future,
      );

      if (mounted) {
        setState(() {
          // Ensure we handle the data properly
          bankAccounts = banksData.map((bank) {
            return Map<String, dynamic>.from(bank);
          }).toList();
          isLoadingBankAccounts = false;
          formData['bank'] = banksData[0]['_id'];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          bankAccounts = <Map<String, dynamic>>[];
          isLoadingBankAccounts = false;
        });
        _showErrorDialog('Failed to load bank accounts: $e');
      }
    }
  }

  Future<void> _loadInvoiceSequence() async {
    if (!mounted) return;

    setState(() {
      isLoadingSequence = true;
    });

    try {
      final seqData = await ref.read(invoiceSequenceProvider('Invoice').future);
      if (mounted) {
        setState(() {
          invoiceSequenceData = Map<String, dynamic>.from(seqData);
          isLoadingSequence = false;

          // Auto-fill fields from sequence data
          final sequenceData = invoiceSequenceData ?? {};
          if (sequenceData.containsKey('invoiceNumber')) {
            formData['invoiceNumber'] = sequenceData['invoiceNumber'];
          }
          if (sequenceData.containsKey('paymentInfo')) {
            formData['paymentTerm'] = sequenceData['paymentInfo'];
          }
          if (sequenceData.containsKey('termsAndConditions')) {
            formData['termsCondition'] = sequenceData['termsAndConditions'];
          }
          if (sequenceData.containsKey('defaultPdfTemplate')) {
            formData['voucherType'] = sequenceData['defaultPdfTemplate'];
          }
          if (sequenceData.containsKey('paymentTermDays')) {
            final dueDate = DateTime.now().add(
              Duration(days: sequenceData['paymentTermDays'] ?? 0),
            );
            formData['invoiceDate'] = DateTime.now();
            formData['dueDate'] = dueDate;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          invoiceSequenceData = <String, dynamic>{};
          isLoadingSequence = false;
        });
        _showErrorDialog('Failed to load invoice sequence: $e');
      }
    }
  }

  // Add method to retry loading data
  Future<void> _retryLoadingData() async {
    await _loadInvoiceData();
  }

  void _selectClient(Map<String, dynamic> client) {
    setState(() {
      selectedClient = client;
      formData['clientId'] = client['_id'];
      validationErrors.remove('client');

      // Reset addresses when client changes
      billToAddress = null;
      shipToAddress = null;

      // Auto-select first address if available
      final addresses = client['addresses'] as List? ?? [];
      if (addresses.isNotEmpty) {
        billToAddress = addresses[0];
        if (!shipToDifferent) {
          shipToAddress = addresses[0];
        }
      }
    });
  }

  void _setBillToAddress(Map<String, dynamic> address) {
    setState(() {
      billToAddress = address;
      validationErrors.remove('billToAddress');

      // If ship to is same as bill to, update it as well
      if (!shipToDifferent) {
        shipToAddress = address;
      }
    });
  }

  void _setShipToAddress(Map<String, dynamic> address) {
    setState(() {
      shipToAddress = address;
      validationErrors.remove('shipToAddress');
    });
  }

  void _toggleShipToDifferent(bool value) {
    setState(() {
      shipToDifferent = value;
      if (!value) {
        // If ship to same as bill to, copy bill to address
        shipToAddress = billToAddress;
      } else {
        // If ship to different, reset ship to address
        shipToAddress = null;
      }
    });
  }

  void _addInvoiceItem(dynamic item, int quantity) {
    setState(() {
      final invoiceItem = {...item, quantity: quantity};
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

  // Add loading indicator widget
  Widget _buildLoadingIndicator(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const CupertinoActivityIndicator(),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    List<File> attachedDocuments = List<File>.from(
      formData['attachedDocuments'] ?? [],
    );

    return BuildSection(title: 'DOCUMENTS', [
      Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    'Attach Documents',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.25,
                      color: CupertinoColors.black,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CupertinoButton(
                    onPressed: () => _pickDocument(),
                    padding: EdgeInsets.zero,
                    minimumSize: Size(0, 0),
                    child: Container(
                      decoration: BoxDecoration(),
                      padding: EdgeInsets.zero,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            attachedDocuments.isEmpty
                                ? 'Attach Documents'
                                : '${attachedDocuments.length} document(s) attached',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'SF Pro Display',
                              letterSpacing: 0.25,
                              color: attachedDocuments.isEmpty
                                  ? CupertinoColors.systemGrey
                                  : CupertinoColors.black,
                            ),
                          ),
                          Icon(CupertinoIcons.paperclip, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (attachedDocuments.isNotEmpty) ...[
              SizedBox(height: 16),
              ...attachedDocuments.asMap().entries.map((entry) {
                int index = entry.key;
                File document = entry.value;
                String fileName = document.path.split('/').last;

                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6.resolveFrom(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.doc,
                        size: 20,
                        color: CupertinoColors.systemGrey,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          fileName,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'SF Pro Display',
                            letterSpacing: 0.25,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(24, 24),
                        onPressed: () => _removeDocument(index),
                        child: Icon(
                          CupertinoIcons.xmark_circle_fill,
                          size: 20,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    ]);
  }

  Widget _buildAdditionalFieldsSection() {
    List<Map<String, String>> additionalFields = List<Map<String, String>>.from(
      formData['additionalFields'] ?? [],
    );

    return BuildSection(title: 'ADDITIONAL FIELDS', [
      Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Field Button
            CupertinoButton(
              onPressed: _addAdditionalField,
              padding: EdgeInsets.zero,
              child: Container(
                decoration: BoxDecoration(),
                padding: EdgeInsets.zero,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.add_circled,
                      size: 20,
                      color: CupertinoColors.activeBlue,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Add Another Field',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'SF Pro Display',
                        letterSpacing: 0.25,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (additionalFields.isNotEmpty) ...[
              SizedBox(height: 16),
              ...additionalFields.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, String> field = entry.value;

                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6.resolveFrom(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoTextField(
                              onChanged: (value) =>
                                  _updateAdditionalField(index, 'name', value),
                              controller: TextEditingController(
                                text: field['name'],
                              ),
                              decoration: BoxDecoration(),
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'SF Pro Display',
                                letterSpacing: 0.25,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: Size(24, 24),
                            onPressed: () => _removeAdditionalField(index),
                            child: Icon(
                              CupertinoIcons.xmark_circle_fill,
                              size: 20,
                              color: CupertinoColors.systemRed,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      CupertinoTextField(
                        onChanged: (value) =>
                            _updateAdditionalField(index, 'value', value),
                        controller: TextEditingController(text: field['value']),
                        decoration: BoxDecoration(),
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'SF Pro Display',
                          letterSpacing: 0.25,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    ]);
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result != null) {
        List<File> currentDocuments = List<File>.from(
          formData['attachedDocuments'] ?? [],
        );
        List<File> newDocuments = result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();

        currentDocuments.addAll(newDocuments);
        _updateFormData('attachedDocuments', currentDocuments);
      }
    } catch (e) {
      _showErrorDialog('Failed to pick document: $e');
    }
  }

  void _removeDocument(int index) {
    List<File> currentDocuments = List<File>.from(
      formData['attachedDocuments'] ?? [],
    );
    if (index < currentDocuments.length) {
      currentDocuments.removeAt(index);
      _updateFormData('attachedDocuments', currentDocuments);
    }
  }

  void _addAdditionalField() {
    List<Map<String, String>> currentFields = List<Map<String, String>>.from(
      formData['additionalFields'] ?? [],
    );
    currentFields.add({'name': '', 'value': ''});
    _updateFormData('additionalFields', currentFields);
  }

  void _updateAdditionalField(int index, String key, String value) {
    List<Map<String, String>> currentFields = List<Map<String, String>>.from(
      formData['additionalFields'] ?? [],
    );
    if (index < currentFields.length) {
      currentFields[index][key] = value;
      _updateFormData('additionalFields', currentFields);
    }
  }

  void _removeAdditionalField(int index) {
    List<Map<String, String>> currentFields = List<Map<String, String>>.from(
      formData['additionalFields'] ?? [],
    );
    if (index < currentFields.length) {
      currentFields.removeAt(index);
      _updateFormData('additionalFields', currentFields);
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text('Retry'),
            onPressed: () {
              Navigator.of(context).pop();
              _retryLoadingData();
            },
          ),
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  bool _validateForm() {
    validationErrors.clear();

    // Check if client is selected
    if (selectedClient == null) {
      validationErrors['client'] = 'Please select a client';
    }

    // Check if bill to address is selected
    if (billToAddress == null) {
      validationErrors['billToAddress'] = 'Please select a billing address';
    }

    // Check if ship to address is selected
    if (shipToAddress == null) {
      validationErrors['shipToAddress'] = 'Please select a shipping address';
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
          content: const Text('Invoice created successfully!'),
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
              // Add loading indicator at the top if any API is loading
              if (isLoadingStates ||
                  isLoadingItems ||
                  isLoadingTemplates ||
                  isLoadingBankAccounts ||
                  isLoadingSequence)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CupertinoActivityIndicator(),
                      const SizedBox(width: 12),
                      Text(
                        'Loading invoice data...',
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.systemGrey.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Buyer and Address Section (Collapsible)
              CollapsibleSection(
                title: 'BUYER & ADDRESSES',
                initiallyExpanded: true,
                fields: [
                  // Buyer Selection
                  BuyerSelectionSection(
                    selectedClient: selectedClient,
                    onClientSelected: _selectClient,
                    validationError: validationErrors['client'],
                    showHeader: false,
                  ),
                ],
              ),

              // Bill To Section (Collapsible)
              if (selectedClient != null) ...[
                const SizedBox(height: 0),
                CollapsibleSection(
                  title: 'BILL TO',
                  initiallyExpanded: true,
                  fields: [
                    AddressSection(
                      title: '',
                      selectedClient: selectedClient,
                      selectedAddress: billToAddress,
                      onAddressSelected: _setBillToAddress,
                      validationError: validationErrors['billToAddress'],
                      showTitle: false,
                    ),
                  ],
                ),
              ],

              // Ship To Different Toggle and Section
              if (selectedClient != null) ...[
                const SizedBox(height: 0),
                CupertinoListSection(
                  backgroundColor: CupertinoColors.systemBackground.resolveFrom(
                    context,
                  ),
                  margin: EdgeInsets.zero,
                  topMargin: 0,
                  children: [
                    CupertinoListTile(
                      title: const Text('Ship to different address'),
                      trailing: CupertinoSwitch(
                        value: shipToDifferent,
                        onChanged: _toggleShipToDifferent,
                      ),
                    ),
                  ],
                ),

                // Ship To Section (Collapsible, only if different from bill to)
                if (shipToDifferent) ...[
                  CollapsibleSection(
                    title: 'SHIP TO',
                    initiallyExpanded: true,
                    fields: [
                      AddressSection(
                        title: '',
                        selectedClient: selectedClient,
                        selectedAddress: shipToAddress,
                        onAddressSelected: _setShipToAddress,
                        validationError: validationErrors['shipToAddress'],
                        showTitle: false,
                      ),
                    ],
                  ),
                ],
              ],

              const SizedBox(height: 0),

              // Invoice Details Section
              BuildSection(title: 'BASIC INFO', [
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
              BuildSection(title: 'QUOTATION AND PO', [
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
                availableItems: items,
                onItemAdded: _addInvoiceItem,
                onItemRemoved: _removeInvoiceItem,
                onItemUpdated: _updateInvoiceItem,
                validationError: validationErrors['items'],
              ),

              const SizedBox(height: 16),

              // Place of Supply and Voucher Type Section
              BuildSection(title: 'INVOICE SETTINGS', [
                // Show loading or dropdown for states
                if (isLoadingStates)
                  _buildLoadingIndicator('Loading states...')
                else
                  FormFieldWidgets.buildSelectField(
                    'placeOfSupply',
                    'Place of Supply',
                    states
                        .map(
                          (state) =>
                              state['name']?.toString() ?? 'Unknown State',
                        )
                        .toList(),
                    onChanged: (key, value) {
                      // Find the state ID based on the selected name and store it
                      final selectedState = states.firstWhere(
                        (state) => state['name'] == value,
                        orElse: () => {},
                      );
                      _updateFormData('placeOfSupplyId', selectedState['_id']);
                      _updateFormData(key, value);
                    },
                    formData: formData,
                    validationErrors: validationErrors,
                    isRequired: false,
                  ),
                // Show loading or dropdown for templates
                if (isLoadingTemplates)
                  _buildLoadingIndicator('Loading templates...')
                else
                  FormFieldWidgets.buildSelectField(
                    'voucherType',
                    'Voucher Type',
                    templates
                        .map(
                          (template) =>
                              template['template']?.toString() ??
                              'Unknown Template',
                        )
                        .toList(),
                    onChanged: (key, value) {
                      // Find the template ID based on the selected name and store it
                      final selectedTemplate = templates.firstWhere(
                        (template) => template['template'] == value,
                        orElse: () => {},
                      );
                      _updateFormData('voucherTypeId', selectedTemplate['_id']);
                      _updateFormData(key, value);
                    },
                    formData: formData,
                    validationErrors: validationErrors,
                    isRequired: false,
                  ),
              ]),

              // Documents Section
              _buildDocumentsSection(),

              // Additional Fields Section
              _buildAdditionalFieldsSection(),

              // Bank Section
              BuildSection(title: 'BANK', [
                if (isLoadingBankAccounts)
                  _buildLoadingIndicator('Loading bank accounts...')
                else
                  FormFieldWidgets.buildSelectField(
                    'bank',
                    'Bank',
                    bankAccounts
                        .map(
                          (bank) =>
                              bank['bankName']?.toString() ?? 'Unknown Bank',
                        )
                        .toList(),
                    onChanged: (key, value) {
                      // Find the bank ID based on the selected name and store it
                      final selectedBank = bankAccounts.firstWhere(
                        (bank) => bank['bankName'] == value,
                        orElse: () => {},
                      );
                      _updateFormData('bankId', selectedBank['_id']);
                      _updateFormData(key, value);
                    },
                    formData: formData,
                    validationErrors: validationErrors,
                    isRequired: false,
                  ),
              ]),

              BuildSection(title: 'TERMS & CONDITION', [
                FormFieldWidgets.buildTextAreaField(
                  'termsCondition',
                  'Terms & Condition',
                  onChanged: _updateFormData,
                  formData: formData,
                  validationErrors: validationErrors,
                  isRequired: false,
                  compactFull: true,
                ),
              ]),

              BuildSection(title: 'NOTES', [
                FormFieldWidgets.buildTextAreaField(
                  'notes',
                  'Notes',
                  onChanged: _updateFormData,
                  formData: formData,
                  validationErrors: validationErrors,
                  isRequired: false,
                  compactFull: true,
                ),
              ]),

              BuildSection(title: 'SUBJECT', [
                FormFieldWidgets.buildTextField(
                  'subject',
                  'Subject',
                  'text',
                  context,
                  onChanged: _updateFormData,
                  formData: formData,
                  validationErrors: validationErrors,
                  isRequired: false,
                  compactFull: true,
                ),
              ]),

              BuildSection(title: 'EMAIL TEXT', [
                FormFieldWidgets.buildTextField(
                  'email_text',
                  'Email Text',
                  'text',
                  context,
                  onChanged: _updateFormData,
                  formData: formData,
                  validationErrors: validationErrors,
                  isRequired: false,
                  compactFull: true,
                ),
              ]),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
