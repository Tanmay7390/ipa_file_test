import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'out_payment_provider.dart';
import '../theme_provider.dart';

class AddPaymentOutScreen extends ConsumerStatefulWidget {
  const AddPaymentOutScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddPaymentOutScreen> createState() =>
      _AddPaymentOutScreenState();
}

class _AddPaymentOutScreenState extends ConsumerState<AddPaymentOutScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  final _amountController = TextEditingController();
  final _paymentDateController = TextEditingController();
  final _supplierSearchController = TextEditingController();
  final _bankAccountSearchController = TextEditingController();
  final _paymentModeController = TextEditingController();
  final _instrumentIdController = TextEditingController();
  final _ref1Controller = TextEditingController();
  final _ref2Controller = TextEditingController();
  final _remarkController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedPaymentMode = 'CASH';
  String? _selectedSupplierId;
  String? _selectedSupplierName;
  String? _selectedBankAccountId;
  String? _selectedBankAccountDisplay;

  List<Map<String, dynamic>> _selectedInvoices = [];
  bool _isApplyingToInvoices = false;
  bool _showSupplierDropdown = false;
  bool _showBankAccountDropdown = false;
  bool _showPaymentModeDropdown = false;

  final List<String> _paymentModes = [
    'CASH',
    'CHEQUE',
    'CARD',
    'UPI',
    'NETBANKING',
  ];

  @override
  void initState() {
    super.initState();
    _paymentDateController.text = DateFormat(
      'dd/MM/yyyy',
    ).format(_selectedDate);
    _paymentModeController.text = _selectedPaymentMode;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _paymentDateController.dispose();
    _supplierSearchController.dispose();
    _bankAccountSearchController.dispose();
    _paymentModeController.dispose();
    _instrumentIdController.dispose();
    _ref1Controller.dispose();
    _ref2Controller.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  // Show snackbar
  void _showSnackBar(String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    final colorScheme = ref.read(colorProvider);

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 60,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isError ? colorScheme.error : colorScheme.success,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isError ? Icons.error_rounded : Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  // Select date
  Future<void> _selectDate(BuildContext context) async {
    final colorScheme = ref.read(colorProvider);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: colorScheme.primary,
              onPrimary: Colors.white,
              surface: colorScheme.surface,
              onSurface: colorScheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _paymentDateController.text = DateFormat(
          'dd/MM/yyyy',
        ).format(pickedDate);
      });
    }
  }

  // Custom input decoration
  InputDecoration _getInputDecoration({
    required String hintText,
    Widget? suffixIcon,
    Widget? prefixIcon,
    String? prefixText,
  }) {
    final colorScheme = ref.read(colorProvider);

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: colorScheme.textSecondary, fontSize: 14),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      prefixText: prefixText,
      prefixStyle: TextStyle(color: colorScheme.textPrimary, fontSize: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      filled: true,
      fillColor: colorScheme.surface,
    );
  }

  // Section header widget
  Widget _buildSectionHeader(String title, {IconData? icon}) {
    final colorScheme = ref.read(colorProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 24),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: colorScheme.textSecondary),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // Build supplier dropdown with search
  Widget _buildSupplierDropdown() {
    final paymentState = ref.watch(paymentOutProvider);
    final colorScheme = ref.read(colorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _supplierSearchController,
          decoration: _getInputDecoration(
            hintText: 'Search and select supplier',
            suffixIcon: Icon(
              Icons.expand_more_rounded,
              color: colorScheme.textSecondary,
            ),
            prefixIcon: Icon(
              Icons.business_rounded,
              color: colorScheme.textSecondary,
            ),
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              ref.read(paymentOutProvider.notifier).searchSuppliers(value);
            }
            setState(() {
              _showSupplierDropdown = value.isNotEmpty;
            });
          },
          onTap: () {
            setState(() {
              _showSupplierDropdown = true;
            });
            if (_supplierSearchController.text.isEmpty) {
              ref.read(paymentOutProvider.notifier).fetchAllSuppliers();
            }
          },
          validator: (value) {
            if (_selectedSupplierId == null) {
              return 'Please select a supplier';
            }
            return null;
          },
        ),
        if (_showSupplierDropdown && paymentState.suppliers.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border.all(color: colorScheme.border),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: paymentState.suppliers.length,
              itemBuilder: (context, index) {
                final supplier = paymentState.suppliers[index];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSupplierId = supplier['_id'];
                      _selectedSupplierName = supplier['name'];
                      _supplierSearchController.text = supplier['name'];
                      _showSupplierDropdown = false;
                    });
                    ref
                        .read(paymentOutProvider.notifier)
                        .fetchSupplierInvoices(_selectedSupplierId!);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: index < paymentState.suppliers.length - 1
                          ? Border(
                              bottom: BorderSide(color: colorScheme.border),
                            )
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.textPrimary,
                          ),
                        ),
                        if (supplier['email']?.isNotEmpty == true)
                          Text(
                            supplier['email'][0],
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        if (_selectedSupplierId != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.success.withOpacity(0.1),
              border: Border.all(color: colorScheme.success.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: colorScheme.success,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Selected: $_selectedSupplierName',
                    style: TextStyle(
                      color: colorScheme.success,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: colorScheme.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedSupplierId = null;
                      _selectedSupplierName = null;
                      _supplierSearchController.clear();
                      _showSupplierDropdown = false;
                      _selectedInvoices.clear();
                      _isApplyingToInvoices = false;
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Build bank account dropdown with search
  Widget _buildBankAccountDropdown() {
    final paymentState = ref.watch(paymentOutProvider);
    final colorScheme = ref.read(colorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _bankAccountSearchController,
          decoration: _getInputDecoration(
            hintText: 'Search and select bank account',
            suffixIcon: Icon(
              Icons.expand_more_rounded,
              color: colorScheme.textSecondary,
            ),
            prefixIcon: Icon(
              Icons.account_balance_rounded,
              color: colorScheme.textSecondary,
            ),
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              ref.read(paymentOutProvider.notifier).searchBankAccounts(value);
            }
            setState(() {
              _showBankAccountDropdown = value.isNotEmpty;
            });
          },
          onTap: () {
            setState(() {
              _showBankAccountDropdown = true;
            });
            if (_bankAccountSearchController.text.isEmpty) {
              ref.read(paymentOutProvider.notifier).fetchBankAccounts();
            }
          },
          validator: (value) {
            if (_selectedBankAccountId == null) {
              return 'Please select a bank account';
            }
            return null;
          },
        ),
        if (_showBankAccountDropdown && paymentState.bankAccounts.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border.all(color: colorScheme.border),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: paymentState.bankAccounts.length,
              itemBuilder: (context, index) {
                final bankAccount = paymentState.bankAccounts[index];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedBankAccountId = bankAccount['_id'];
                      _selectedBankAccountDisplay =
                          '${bankAccount['bankName']} - ${bankAccount['accountNumber']}';
                      _bankAccountSearchController.text =
                          _selectedBankAccountDisplay!;
                      _showBankAccountDropdown = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: index < paymentState.bankAccounts.length - 1
                          ? Border(
                              bottom: BorderSide(color: colorScheme.border),
                            )
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bankAccount['bankName'] ?? 'Unknown Bank',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Account: ${bankAccount['accountNumber'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        if (_selectedBankAccountId != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Selected: $_selectedBankAccountDisplay',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: colorScheme.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedBankAccountId = null;
                      _selectedBankAccountDisplay = null;
                      _bankAccountSearchController.clear();
                      _showBankAccountDropdown = false;
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Build payment mode dropdown
  Widget _buildPaymentModeDropdown() {
    final colorScheme = ref.read(colorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _paymentModeController,
          readOnly: true,
          decoration: _getInputDecoration(
            hintText: 'Select payment mode',
            suffixIcon: Icon(
              Icons.expand_more_rounded,
              color: colorScheme.textSecondary,
            ),
            prefixIcon: Icon(
              Icons.payment_rounded,
              color: colorScheme.textSecondary,
            ),
          ),
          onTap: () {
            setState(() {
              _showPaymentModeDropdown = !_showPaymentModeDropdown;
            });
          },
        ),
        if (_showPaymentModeDropdown)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border.all(color: colorScheme.border),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _paymentModes.length,
              itemBuilder: (context, index) {
                final mode = _paymentModes[index];
                final isSelected = _selectedPaymentMode == mode;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMode = mode;
                      _paymentModeController.text = mode;
                      _showPaymentModeDropdown = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withOpacity(0.1)
                          : null,
                      border: index < _paymentModes.length - 1
                          ? Border(
                              bottom: BorderSide(color: colorScheme.border),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getPaymentModeIcon(mode),
                          size: 20,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          mode,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(
                            Icons.check_rounded,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // Get icon for payment mode
  IconData _getPaymentModeIcon(String mode) {
    switch (mode) {
      case 'CASH':
        return Icons.money_rounded;
      case 'CHEQUE':
        return Icons.receipt_long_rounded;
      case 'CARD':
        return Icons.credit_card_rounded;
      case 'UPI':
        return Icons.qr_code_scanner_rounded;
      case 'NETBANKING':
        return Icons.account_balance_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  Future<void> _showInvoiceSelectionDialog() async {
    final paymentState = ref.watch(paymentOutProvider);
    final colorScheme = ref.read(colorProvider);

    if (paymentState.invoices.isEmpty) {
      _showSnackBar(
        'No pending invoices found for this supplier',
        isError: true,
      );
      return;
    }

    List<Map<String, dynamic>> tempSelectedInvoices = List.from(
      _selectedInvoices,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Select Invoices',
                style: TextStyle(color: colorScheme.textPrimary),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView.builder(
                  itemCount: paymentState.invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = paymentState.invoices[index];
                    final isSelected = tempSelectedInvoices.any(
                      (inv) => inv['_id'] == invoice['_id'],
                    );

                    return CheckboxListTile(
                      activeColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      title: Text(
                        '${invoice['invoiceNumber']} - ${invoice['supplier']['name']}',
                        style: TextStyle(color: colorScheme.textPrimary),
                      ),
                      subtitle: Text(
                        'Amount: ₹${invoice['balanceAmount']} | Date: ${DateFormat('dd MMM yyyy').format(DateTime.parse(invoice['date']))}',
                        style: TextStyle(color: colorScheme.textSecondary),
                      ),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            tempSelectedInvoices.add(invoice);
                          } else {
                            tempSelectedInvoices.removeWhere(
                              (inv) => inv['_id'] == invoice['_id'],
                            );
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: colorScheme.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedInvoices = List.from(tempSelectedInvoices);
                      _isApplyingToInvoices = _selectedInvoices.isNotEmpty;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Submit payment
  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSupplierId == null) {
      _showSnackBar('Please select a supplier', isError: true);
      return;
    }

    if (_selectedBankAccountId == null) {
      _showSnackBar('Please select a bank account', isError: true);
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      _showSnackBar('Please enter a valid amount', isError: true);
      return;
    }

    final formattedDate = _selectedDate.toIso8601String();

    List<String>? invoicesPayload;
    if (_isApplyingToInvoices && _selectedInvoices.isNotEmpty) {
      invoicesPayload = _selectedInvoices
          .map((invoice) => invoice['_id'] as String)
          .toList();
    } else {
      invoicesPayload = [];
    }

    final success = await ref
        .read(paymentOutProvider.notifier)
        .createPayment(
          paymentTo: _selectedSupplierId!,
          paymentDate: formattedDate,
          amount: amount,
          paymentMode: _selectedPaymentMode,
          fromBankAccount: _selectedBankAccountId!,
          instrumentId: _instrumentIdController.text.isNotEmpty
              ? _instrumentIdController.text
              : null,
          ref1: _ref1Controller.text.isNotEmpty ? _ref1Controller.text : null,
          ref2: _ref2Controller.text.isNotEmpty ? _ref2Controller.text : null,
          remark: _remarkController.text.isNotEmpty
              ? _remarkController.text
              : null,
          invoices: invoicesPayload,
        );

    if (success) {
      _showSnackBar('Payment to supplier created successfully');
      Future.delayed(const Duration(seconds: 2), () {
        context.go('/payments'); 
      });
    } else {
      final paymentState = ref.read(paymentOutProvider);
      if (paymentState.error != null) {
        _showSnackBar(paymentState.error!, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentOutProvider);
    final colorScheme = ref.watch(colorProvider);

    if (paymentState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar(paymentState.error!, isError: true);
        ref.read(paymentOutProvider.notifier).clearError();
      });
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showSupplierDropdown = false;
          _showBankAccountDropdown = false;
          _showPaymentModeDropdown = false;
        });
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: colorScheme.background,
        appBar: AppBar(
          title: Text(
            'Record Payment Out',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.textPrimary,
            ),
          ),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.textPrimary,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: colorScheme.textPrimary,
            ),
            onPressed: () =>
                context.go('/payments'), 
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Supplier selection
                _buildSectionHeader('Payment To'),
                _buildSupplierDropdown(),

                // Payment date and amount in row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Payment Date'),
                          TextFormField(
                            controller: _paymentDateController,
                            readOnly: true,
                            decoration: _getInputDecoration(
                              hintText: 'Select Date',
                              suffixIcon: Icon(
                                Icons.calendar_today_rounded,
                                color: colorScheme.textSecondary,
                              ),
                            ),
                            onTap: () => _selectDate(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Enter Amount'),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: _getInputDecoration(
                              hintText: 'Amount',
                              prefixText: '₹ ',
                              prefixIcon: Icon(
                                Icons.currency_rupee_rounded,
                                color: colorScheme.textSecondary,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(value) == null ||
                                  double.tryParse(value)! <= 0) {
                                return 'Invalid amount';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Bank account
                _buildSectionHeader('Pay From'),
                _buildBankAccountDropdown(),

                // Payment mode
                _buildSectionHeader('Payment Mode'),
                _buildPaymentModeDropdown(),

                // Instrument ID for non-cash payments
                if (_selectedPaymentMode != 'CASH') ...[
                  _buildSectionHeader(
                    _selectedPaymentMode == 'CHEQUE'
                        ? 'Cheque Number'
                        : _selectedPaymentMode == 'UPI'
                        ? 'UPI Transaction ID'
                        : 'Transaction ID',
                  ),
                  TextFormField(
                    controller: _instrumentIdController,
                    decoration: _getInputDecoration(
                      hintText: _selectedPaymentMode == 'CHEQUE'
                          ? 'Enter Cheque Number'
                          : 'Enter Transaction ID',
                      prefixIcon: Icon(
                        Icons.receipt_rounded,
                        color: colorScheme.textSecondary,
                      ),
                    ),
                    validator: (value) {
                      if (_selectedPaymentMode != 'CASH' &&
                          (value == null || value.isEmpty)) {
                        return 'This field is required';
                      }
                      return null;
                    },
                  ),
                ],

                // Invoice Selection Section
                if (_selectedSupplierId != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildSectionHeader(
                          'Apply to Invoices',
                          icon: Icons.receipt_long_rounded,
                        ),
                      ),
                      paymentState.isLoadingInvoices
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.primary,
                                ),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () {
                                if (paymentState.invoices.isEmpty) {
                                  _showSnackBar(
                                    'Invoice not available for this supplier',
                                    isError: true,
                                  );
                                } else {
                                  _showInvoiceSelectionDialog();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text(
                                'Select Invoices',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                    ],
                  ),

                  // Invoice availability status
                  if (!paymentState.isLoadingInvoices &&
                      paymentState.invoices.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.warning.withOpacity(0.1),
                        border: Border.all(
                          color: colorScheme.warning.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: colorScheme.warning,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No pending invoices available for this supplier',
                              style: TextStyle(
                                color: colorScheme.warning,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Selected invoices display
                  if (_selectedInvoices.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.success.withOpacity(0.1),
                        border: Border.all(
                          color: colorScheme.success.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: colorScheme.success,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Selected Invoices (${_selectedInvoices.length})',
                                style: TextStyle(
                                  color: colorScheme.success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(
                            _selectedInvoices.length > 2
                                ? 2
                                : _selectedInvoices.length,
                            (index) {
                              final invoice = _selectedInvoices[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${invoice['invoiceNumber']} - ₹${invoice['balanceAmount']}',
                                        style: TextStyle(
                                          color: colorScheme.success,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.remove_circle_rounded,
                                        color: colorScheme.error,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _selectedInvoices.removeAt(index);
                                          _isApplyingToInvoices =
                                              _selectedInvoices.isNotEmpty;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          if (_selectedInvoices.length > 2)
                            Text(
                              '... and ${_selectedInvoices.length - 2} more',
                              style: TextStyle(
                                color: colorScheme.success,
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],

                // Additional Information Section
                _buildSectionHeader(
                  'Additional Information',
                  icon: Icons.notes_rounded,
                ),

                // Reference fields in a row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ref Note 1',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _ref1Controller,
                            decoration: _getInputDecoration(
                              hintText: 'Reference 1',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ref Note 2',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _ref2Controller,
                            decoration: _getInputDecoration(
                              hintText: 'Reference 2',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Remark field
                Text(
                  'Remark',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _remarkController,
                  decoration: _getInputDecoration(
                    hintText: 'Add any additional notes',
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 40),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go(
                          '/payments',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: colorScheme.border,
                          foregroundColor: colorScheme.textSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: paymentState.isLoading
                            ? null
                            : _submitPayment,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: paymentState.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Record Payment',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                // Bottom padding
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
