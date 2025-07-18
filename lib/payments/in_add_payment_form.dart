import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'in_payment_provider.dart';
import '../theme_provider.dart';

class AddPaymentInScreen extends ConsumerStatefulWidget {
  const AddPaymentInScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddPaymentInScreen> createState() => _AddPaymentInScreenState();
}

class _AddPaymentInScreenState extends ConsumerState<AddPaymentInScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  final _amountController = TextEditingController();
  final _paymentDateController = TextEditingController();
  final _customerSearchController = TextEditingController();
  final _bankAccountSearchController = TextEditingController();
  final _paymentModeController = TextEditingController();
  final _instrumentIdController = TextEditingController();
  final _ref1Controller = TextEditingController();
  final _ref2Controller = TextEditingController();
  final _remarkController = TextEditingController();

  final _fromBankAccountSearchController = TextEditingController();

  String? _selectedFromBankAccountId;
  String? _selectedFromBankAccountDisplay;
  bool _showFromBankAccountDropdown = false;

  DateTime _selectedDate = DateTime.now();
  String _selectedPaymentMode = 'CASH';
  String? _selectedCustomerId;
  String? _selectedCustomerName;
  String? _selectedBankAccountId;
  String? _selectedBankAccountDisplay;

  List<Map<String, dynamic>> _selectedInvoices = [];
  Map<String, TDSRate?> _invoiceTDSRates = {}; // Track TDS rate per invoice
  Map<String, double> _invoiceTDSAmounts = {}; // Track TDS amount per invoice
  bool _isApplyingToInvoices = false;
  bool _showCustomerDropdown = false;
  bool _showBankAccountDropdown = false;
  bool _showPaymentModeDropdown = false;
  bool _showTDSDropdown = false;

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
    _customerSearchController.dispose();
    _bankAccountSearchController.dispose();
    _fromBankAccountSearchController.dispose();
    _paymentModeController.dispose();
    _instrumentIdController.dispose();
    _ref1Controller.dispose();
    _ref2Controller.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  // Calculate total invoice amount
  double get _totalInvoiceAmount {
    return _selectedInvoices.fold<double>(0.0, (double sum, invoice) {
      final balanceAmount = invoice['balanceAmount'];
      if (balanceAmount is num) {
        return sum + balanceAmount.toDouble();
      }
      return sum;
    });
  }

  // Calculate total TDS amount across all invoices
  double get _totalTDSAmount {
    return _invoiceTDSAmounts.values.fold<double>(0.0, (
      double sum,
      double amount,
    ) {
      return sum + amount;
    });
  }

  // Calculate net amount after TDS (total invoice amount - total TDS)
  double get _netAmountAfterTDS {
    return _totalInvoiceAmount - _totalTDSAmount;
  }

  // Calculate TDS for a specific invoice
  double _calculateInvoiceTDS(String invoiceId, double invoiceAmount) {
    final tdsRate = _invoiceTDSRates[invoiceId];
    if (tdsRate == null) return 0.0;
    return invoiceAmount * (tdsRate.taxRate / 100);
  }

  // Update TDS for a specific invoice
  void _updateInvoiceTDS(
    String invoiceId,
    double invoiceAmount,
    TDSRate? tdsRate,
  ) {
    setState(() {
      if (tdsRate != null) {
        _invoiceTDSRates[invoiceId] = tdsRate;
        _invoiceTDSAmounts[invoiceId] = _calculateInvoiceTDS(
          invoiceId,
          invoiceAmount,
        );
      } else {
        _invoiceTDSRates.remove(invoiceId);
        _invoiceTDSAmounts.remove(invoiceId);
      }
    });
  }

  // Check if payment amount is excess
  bool get _isExcessPayment {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    return amount > _netAmountAfterTDS && _selectedInvoices.isNotEmpty;
  }

  // Get excess amount
  double get _excessAmount {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    return amount - _netAmountAfterTDS;
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

  // Show excess payment dialog
  Future<bool> _showExcessPaymentDialog() async {
    final colorScheme = ref.read(colorProvider);

    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: colorScheme.warning,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Excess Payment Detected',
              style: TextStyle(
                color: colorScheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '₹${_excessAmount.toStringAsFixed(2)} remains after settling all eligible invoices',
              style: TextStyle(color: colorScheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              'All eligible invoices have been fully settled, but there\'s still an excess amount. How would you like to handle this remaining amount?',
              style: TextStyle(color: colorScheme.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Record as Advance Payment option
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.success.withOpacity(0.1),
                border: Border.all(color: colorScheme.success.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        color: colorScheme.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Record as Advance Payment',
                        style: TextStyle(
                          color: colorScheme.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The excess amount will be credited to the customer\'s account for future invoices',
                    style: TextStyle(color: colorScheme.success, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Record as Unassigned Balance option
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Record as Unassigned Balance',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The excess amount will be kept as unassigned balance for manual allocation',
                    style: TextStyle(color: colorScheme.primary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Unassigned Balance',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Advance Payment'),
          ),
        ],
      ),
    );

    return result ?? false;
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

  // Build customer dropdown with search
  Widget _buildCustomerDropdown() {
    final paymentState = ref.watch(paymentProvider);
    final colorScheme = ref.read(colorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _customerSearchController,
          decoration: _getInputDecoration(
            hintText: 'Search and select customer',
            suffixIcon: Icon(
              Icons.expand_more_rounded,
              color: colorScheme.textSecondary,
            ),
            prefixIcon: Icon(
              Icons.person_rounded,
              color: colorScheme.textSecondary,
            ),
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              ref.read(paymentProvider.notifier).searchCustomers(value);
            }
            setState(() {
              _showCustomerDropdown = value.isNotEmpty;
            });
          },
          onTap: () {
            setState(() {
              _showCustomerDropdown = true;
            });
            if (_customerSearchController.text.isEmpty) {
              ref.read(paymentProvider.notifier).fetchAllCustomers();
            }
          },
          validator: (value) {
            if (_selectedCustomerId == null) {
              return 'Please select a customer';
            }
            return null;
          },
        ),
        if (_showCustomerDropdown && paymentState.customers.isNotEmpty)
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
              itemCount: paymentState.customers.length,
              itemBuilder: (context, index) {
                final customer = paymentState.customers[index];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCustomerId = customer['_id'];
                      _selectedCustomerName = customer['name'];
                      _customerSearchController.text = customer['name'];
                      _showCustomerDropdown = false;
                    });
                    ref
                        .read(paymentProvider.notifier)
                        .fetchCustomerInvoices(_selectedCustomerId!);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: index < paymentState.customers.length - 1
                          ? Border(
                              bottom: BorderSide(color: colorScheme.border),
                            )
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.textPrimary,
                          ),
                        ),
                        if (customer['email']?.isNotEmpty == true)
                          Text(
                            customer['email'][0],
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
        if (_selectedCustomerId != null)
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
                    'Selected: $_selectedCustomerName',
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
                      _selectedCustomerId = null;
                      _selectedCustomerName = null;
                      _customerSearchController.clear();
                      _showCustomerDropdown = false;
                      _selectedInvoices.clear();
                      _invoiceTDSRates.clear();
                      _invoiceTDSAmounts.clear();
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

  // Build from bank account dropdown with empty list
  Widget _buildFromBankAccountDropdown() {
    final colorScheme = ref.read(colorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _fromBankAccountSearchController,
          decoration: _getInputDecoration(
            hintText: 'Search and select from bank account',
            suffixIcon: Icon(
              Icons.expand_more_rounded,
              color: colorScheme.textSecondary,
            ),
            prefixIcon: Icon(
              Icons.account_balance_wallet_rounded,
              color: colorScheme.textSecondary,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _showFromBankAccountDropdown = value.isNotEmpty;
            });
          },
          onTap: () {
            setState(() {
              _showFromBankAccountDropdown = true;
            });
          },
          readOnly: true,
        ),
        if (_showFromBankAccountDropdown)
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: colorScheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No bank accounts available',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Build bank account dropdown with search
  Widget _buildBankAccountDropdown() {
    final paymentState = ref.watch(paymentProvider);
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
              ref.read(paymentProvider.notifier).searchBankAccounts(value);
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
              ref.read(paymentProvider.notifier).fetchBankAccounts();
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

  // Build invoice amount calculation display
  Widget _buildInvoiceAmountDisplay() {
    final colorScheme = ref.read(colorProvider);

    if (_selectedInvoices.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Calculation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Individual invoice breakdown
          ...List.generate(_selectedInvoices.length, (index) {
            final invoice = _selectedInvoices[index];
            final invoiceId = invoice['_id'];
            final invoiceAmount =
                (invoice['balanceAmount'] as num?)?.toDouble() ?? 0.0;
            final tdsRate = _invoiceTDSRates[invoiceId];
            final tdsAmount = _invoiceTDSAmounts[invoiceId] ?? 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        invoice['invoiceNumber'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textPrimary,
                        ),
                      ),
                      Text(
                        '₹${invoiceAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (tdsRate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TDS ${tdsRate.taxRate}% (${tdsRate.taxSection})',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.textSecondary,
                          ),
                        ),
                        Text(
                          '- ₹${tdsAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Net Amount',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.success,
                          ),
                        ),
                        Text(
                          '₹${(invoiceAmount - tdsAmount).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),

          const Divider(),

          // Total summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Invoice Amount:',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.textSecondary,
                ),
              ),
              Text(
                '₹${_totalInvoiceAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.textPrimary,
                ),
              ),
            ],
          ),
          if (_totalTDSAmount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total TDS Amount:',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.textSecondary,
                  ),
                ),
                Text(
                  '- ₹${_totalTDSAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Net Amount to Pay:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.textPrimary,
                ),
              ),
              Text(
                '₹${_netAmountAfterTDS.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showInvoiceSelectionDialog() async {
    final paymentState = ref.watch(paymentProvider);
    final colorScheme = ref.read(colorProvider);

    if (paymentState.invoices.isEmpty) {
      _showSnackBar(
        'No pending invoices found for this customer',
        isError: true,
      );
      return;
    }

    List<Map<String, dynamic>> tempSelectedInvoices = List.from(
      _selectedInvoices,
    );
    Map<String, TDSRate?> tempInvoiceTDSRates = Map.from(_invoiceTDSRates);
    Map<String, double> tempInvoiceTDSAmounts = Map.from(_invoiceTDSAmounts);

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
                'Select Invoices & Apply TDS',
                style: TextStyle(color: colorScheme.textPrimary),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 500,
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              'Select',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Invoice',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Amount',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Apply TDS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Invoice list
                    Expanded(
                      child: ListView.builder(
                        itemCount: paymentState.invoices.length,
                        itemBuilder: (context, index) {
                          final invoice = paymentState.invoices[index];
                          final invoiceId = invoice['_id'];
                          final invoiceAmount =
                              (invoice['balanceAmount'] as num?)?.toDouble() ??
                              0.0;
                          final isSelected = tempSelectedInvoices.any(
                            (inv) => inv['_id'] == invoiceId,
                          );
                          final selectedTDS = tempInvoiceTDSRates[invoiceId];
                          final tdsAmount =
                              tempInvoiceTDSAmounts[invoiceId] ?? 0.0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary.withOpacity(0.05)
                                  : colorScheme.surface,
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary.withOpacity(0.3)
                                    : colorScheme.border,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // Checkbox
                                    SizedBox(
                                      width: 40,
                                      child: Checkbox(
                                        value: isSelected,
                                        activeColor: colorScheme.primary,
                                        onChanged: (bool? value) {
                                          setDialogState(() {
                                            if (value == true) {
                                              tempSelectedInvoices.add(invoice);
                                            } else {
                                              tempSelectedInvoices.removeWhere(
                                                (inv) =>
                                                    inv['_id'] == invoiceId,
                                              );
                                              tempInvoiceTDSRates.remove(
                                                invoiceId,
                                              );
                                              tempInvoiceTDSAmounts.remove(
                                                invoiceId,
                                              );
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    // Invoice info
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            invoice['invoiceNumber'] ?? 'N/A',
                                            style: TextStyle(
                                              color: colorScheme.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('dd MMM yyyy').format(
                                              DateTime.parse(invoice['date']),
                                            ),
                                            style: TextStyle(
                                              color: colorScheme.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Amount
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '₹${invoiceAmount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: colorScheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    // TDS Dropdown
                                    Expanded(
                                      flex: 2,
                                      child: isSelected
                                          ? Container(
                                              height: 40,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: colorScheme.border,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: DropdownButton<TDSRate?>(
                                                value: selectedTDS,
                                                hint: Text(
                                                  'Apply TDS',
                                                  style: TextStyle(
                                                    color: colorScheme
                                                        .textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                isExpanded: true,
                                                underline: const SizedBox(),
                                                items: [
                                                  DropdownMenuItem<TDSRate?>(
                                                    value: null,
                                                    child: Text(
                                                      'No TDS',
                                                      style: TextStyle(
                                                        color: colorScheme
                                                            .textSecondary,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  ...paymentState.tdsRates.map((
                                                    TDSRate rate,
                                                  ) {
                                                    return DropdownMenuItem<
                                                      TDSRate?
                                                    >(
                                                      value: rate,
                                                      child: Text(
                                                        '${rate.taxRate}% - ${rate.taxSection}',
                                                        style: TextStyle(
                                                          color: colorScheme
                                                              .textPrimary,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ],
                                                onChanged: (TDSRate? newValue) {
                                                  setDialogState(() {
                                                    if (newValue != null) {
                                                      tempInvoiceTDSRates[invoiceId] =
                                                          newValue;
                                                      tempInvoiceTDSAmounts[invoiceId] =
                                                          invoiceAmount *
                                                          (newValue.taxRate /
                                                              100);
                                                    } else {
                                                      tempInvoiceTDSRates
                                                          .remove(invoiceId);
                                                      tempInvoiceTDSAmounts
                                                          .remove(invoiceId);
                                                    }
                                                  });
                                                },
                                              ),
                                            )
                                          : Container(
                                              height: 40,
                                              alignment: Alignment.center,
                                              child: Text(
                                                'Select invoice first',
                                                style: TextStyle(
                                                  color:
                                                      colorScheme.textSecondary,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                                // TDS Amount display
                                if (isSelected &&
                                    selectedTDS != null &&
                                    tdsAmount > 0)
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'TDS ${selectedTDS.taxRate}%: ₹${tdsAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // Summary
                    if (tempSelectedInvoices.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.success.withOpacity(0.1),
                          border: Border.all(
                            color: colorScheme.success.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Invoice Amount:',
                                  style: TextStyle(
                                    color: colorScheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '₹${tempSelectedInvoices.fold<double>(0.0, (sum, inv) => sum + ((inv['balanceAmount'] as num?)?.toDouble() ?? 0.0)).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: colorScheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            if (tempInvoiceTDSAmounts.isNotEmpty)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total TDS Amount:',
                                    style: TextStyle(
                                      color: colorScheme.error,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '- ₹${tempInvoiceTDSAmounts.values.fold<double>(0.0, (sum, amount) => sum + amount).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: colorScheme.error,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Net Amount:',
                                  style: TextStyle(
                                    color: colorScheme.success,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '₹${(tempSelectedInvoices.fold<double>(0.0, (sum, inv) => sum + ((inv['balanceAmount'] as num?)?.toDouble() ?? 0.0)) - tempInvoiceTDSAmounts.values.fold<double>(0.0, (sum, amount) => sum + amount)).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: colorScheme.success,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
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
                      _invoiceTDSRates = Map.from(tempInvoiceTDSRates);
                      _invoiceTDSAmounts = Map.from(tempInvoiceTDSAmounts);
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

    if (_selectedCustomerId == null) {
      _showSnackBar('Please select a customer', isError: true);
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

    // Validate amount against selected invoices
    if (_selectedInvoices.isNotEmpty) {
      final minAmount = _netAmountAfterTDS;
      if (amount < minAmount) {
        _showSnackBar(
          'Payment amount cannot be less than net amount after TDS (₹${minAmount.toStringAsFixed(2)})',
          isError: true,
        );
        return;
      }
    }

    // Check for excess payment
    bool isAdvancePayment = false;
    if (_selectedInvoices.isNotEmpty && _isExcessPayment) {
      isAdvancePayment = await _showExcessPaymentDialog();
      if (!isAdvancePayment) {
        return; // User cancelled or chose unassigned balance
      }
    }

    final formattedDate = _selectedDate.toIso8601String();

    final success = await ref
        .read(paymentProvider.notifier)
        .createPayment(
          paymentFrom: _selectedCustomerId!,
          paymentDate: formattedDate,
          amount: amount,
          fromBankAccount: null,
          paymentMode: _selectedPaymentMode,
          toBankAccount: _selectedBankAccountId!,
          instrumentId: _instrumentIdController.text.isNotEmpty
              ? _instrumentIdController.text
              : null,
          ref1: _ref1Controller.text.isNotEmpty ? _ref1Controller.text : null,
          ref2: _ref2Controller.text.isNotEmpty ? _ref2Controller.text : null,
          remark: _remarkController.text.isNotEmpty
              ? _remarkController.text
              : null,
          invoices: _selectedInvoices
              .map((invoice) => invoice['_id'] as String)
              .toList(),
          tdsRate: null, // No longer using global TDS rate
          tdsAmount: _totalTDSAmount,
          isAdvancePayment: isAdvancePayment,
        );

    if (success) {
      _showSnackBar('Payment created successfully');
      Future.delayed(const Duration(seconds: 2), () {
        context.go('/payments');
      });
    } else {
      final paymentState = ref.read(paymentProvider);
      if (paymentState.error != null) {
        _showSnackBar(paymentState.error!, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final colorScheme = ref.watch(colorProvider);

    if (paymentState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar(paymentState.error!, isError: true);
        ref.read(paymentProvider.notifier).clearError();
      });
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showCustomerDropdown = false;
          _showBankAccountDropdown = false;
          _showFromBankAccountDropdown = false;
          _showPaymentModeDropdown = false;
        });
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: colorScheme.background,
        appBar: AppBar(
          title: Text(
            'Record Payment In',
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
            onPressed: () => context.go('/payments'),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer selection
                _buildSectionHeader('Payment From'),
                _buildCustomerDropdown(),

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
                            onChanged: (value) {
                              setState(
                                () {},
                              ); // Trigger rebuild for excess payment check
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) {
                                return 'Invalid amount';
                              }

                              // Validate against selected invoices
                              if (_selectedInvoices.isNotEmpty) {
                                final minAmount = _netAmountAfterTDS;
                                if (amount < minAmount) {
                                  return 'Minimum: ₹${minAmount.toStringAsFixed(2)}';
                                }
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Show excess payment warning
                if (_isExcessPayment && _selectedInvoices.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.success.withOpacity(0.1),
                      border: Border.all(
                        color: colorScheme.success.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_rounded,
                          color: colorScheme.success,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Excess payment of ₹${_excessAmount.toStringAsFixed(2)} will be recorded as advance payment.',
                            style: TextStyle(
                              color: colorScheme.success,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // From Bank Account
                _buildSectionHeader('From Bank Account'),
                _buildFromBankAccountDropdown(),

                // Bank account
                _buildSectionHeader('Deposit To'),
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
                if (_selectedCustomerId != null) ...[
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
                                    'Invoice not available for this customer',
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
                              'No pending invoices available for this customer',
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
                            _selectedInvoices.length > 3
                                ? 3
                                : _selectedInvoices.length,
                            (index) {
                              final invoice = _selectedInvoices[index];
                              final invoiceId = invoice['_id'];
                              final invoiceAmount =
                                  (invoice['balanceAmount'] as num?)
                                      ?.toDouble() ??
                                  0.0;
                              final tdsRate = _invoiceTDSRates[invoiceId];
                              final tdsAmount =
                                  _invoiceTDSAmounts[invoiceId] ?? 0.0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${invoice['invoiceNumber']} - ₹${invoiceAmount.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color:
                                                      colorScheme.textPrimary,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (tdsRate != null)
                                                Text(
                                                  'TDS ${tdsRate.taxRate}%: ₹${tdsAmount.toStringAsFixed(2)} | Net: ₹${(invoiceAmount - tdsAmount).toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    color: colorScheme.primary,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                            ],
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
                                              _invoiceTDSRates.remove(
                                                invoiceId,
                                              );
                                              _invoiceTDSAmounts.remove(
                                                invoiceId,
                                              );
                                              _isApplyingToInvoices =
                                                  _selectedInvoices.isNotEmpty;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          if (_selectedInvoices.length > 3)
                            Text(
                              '... and ${_selectedInvoices.length - 3} more',
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

                  // Invoice amount calculation display
                  _buildInvoiceAmountDisplay(),
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
                        onPressed: () => context.go('/payments'),
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
