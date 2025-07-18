// lib/payments/invoice_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../theme_provider.dart';

class InvoiceDetailsScreen extends HookConsumerWidget {
  final Map<String, dynamic> payment;

  const InvoiceDetailsScreen({Key? key, required this.payment})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(colorProvider);
    final isDark = ref.watch(isDarkModeProvider);

    // Get invoices from payment data
    final invoices = (payment['invoices'] as List<dynamic>?) ?? [];

    // State for managing invoice applications
    final appliedInvoices = useState<List<Map<String, dynamic>>>(
      List<Map<String, dynamic>>.from(invoices),
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(context, colors),
      body: Column(
        children: [
          // Payment Summary Header
          _buildPaymentSummaryHeader(colors),

          const Divider(height: 1),

          // Applied Invoices Section
          _buildAppliedInvoicesHeader(appliedInvoices.value.length, colors),

          // Invoices List
          Expanded(child: _buildInvoicesList(appliedInvoices, colors)),
        ],
      ),
      // Apply to Another Invoice Button
      floatingActionButton: _buildApplyToInvoiceButton(
        context,
        colors,
        appliedInvoices,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WareozeColorScheme colors,
  ) {
    return AppBar(
      backgroundColor: colors.surface,
      foregroundColor: colors.textPrimary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Payment Details',
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showMoreOptions(context, colors),
        ),
      ],
    );
  }

  Widget _buildPaymentSummaryHeader(WareozeColorScheme colors) {
    final txnId = payment['txnId'] ?? 0;
    final amount = payment['amount'] ?? 0;
    final paymentDate = payment['paymentDate'] ?? '';
    final buyerName = payment['paymentFrom']?['name'] ?? '';
    final paymentMode = payment['paymentMode'] ?? '';
    final status = payment['applyStatus'] ?? '';

    return Container(
      color: colors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transaction ID and Status
          Row(
            children: [
              Text(
                'Transaction No. \n $txnId',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              _buildStatusChip(status, colors),
            ],
          ),

          const SizedBox(height: 12),

          // Payment Amount
          Text(
            '₹ ${_formatAmount(amount)}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),

          const SizedBox(height: 8),

          // Payment Details Grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border, width: 0.5),
            ),
            child: Column(
              children: [
                _buildPaymentDetailRow('Buyer Name', buyerName, colors),
                const SizedBox(height: 8),
                _buildPaymentDetailRow(
                  'Payment Date',
                  _formatDate(paymentDate),
                  colors,
                ),
                const SizedBox(height: 8),
                _buildPaymentDetailRow('Payment Mode', paymentMode, colors),
                const SizedBox(height: 8),
                _buildPaymentDetailRow(
                  'Total Applied',
                  '₹ ${_formatAmount(payment['paymentApplied'])}',
                  colors,
                ),
                const SizedBox(height: 8),
                _buildPaymentDetailRow(
                  'Total Unapplied',
                  '₹ ${_formatAmount(payment['paymentUnapplied'])}',
                  colors,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailRow(
    String label,
    String value,
    WareozeColorScheme colors,
  ) {
    return Row(
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildAppliedInvoicesHeader(
    int invoiceCount,
    WareozeColorScheme colors,
  ) {
    return Container(
      color: colors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            'Applied Invoices ($invoiceCount)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          if (invoiceCount > 1) ...[
            TextButton(
              onPressed: () => _sortInvoices(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sort, size: 16, color: colors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Sort',
                    style: TextStyle(color: colors.primary, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoicesList(
    ValueNotifier<List<Map<String, dynamic>>> appliedInvoices,
    WareozeColorScheme colors,
  ) {
    if (appliedInvoices.value.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: colors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No invoices applied yet',
              style: TextStyle(
                fontSize: 16,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to apply this payment to an invoice',
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appliedInvoices.value.length,
      itemBuilder: (context, index) {
        final invoiceData = appliedInvoices.value[index];
        final invoice = invoiceData['invoice'] as Map<String, dynamic>? ?? {};

        return _buildInvoiceCard(
          invoiceData,
          invoice,
          index,
          colors,
          appliedInvoices,
        );
      },
    );
  }

  Widget _buildInvoiceCard(
    Map<String, dynamic> invoiceData,
    Map<String, dynamic> invoice,
    int index,
    WareozeColorScheme colors,
    ValueNotifier<List<Map<String, dynamic>>> appliedInvoices,
  ) {
    final invoiceNumber = invoice['invoiceNumber'] ?? '';
    final invoiceDate = invoice['date'] ?? '';
    final invoiceAmount = invoice['amount'] ?? 0;
    final appliedAmountTotal = invoiceData['appliedAmountTotal'] ?? 0;
    final appliedAmountBase = invoiceData['appliedAmountBase'] ?? 0;
    final appliedAmountTax = invoiceData['appliedAmountTax'] ?? 0;
    final appliedAmountTDS = invoiceData['appliedAmountTDS'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: colors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invoice Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoice #$invoiceNumber',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(invoiceDate),
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: colors.textSecondary),
                  onSelected: (value) => _handleInvoiceAction(
                    value,
                    index,
                    appliedInvoices,
                    colors,
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16, color: colors.textPrimary),
                          const SizedBox(width: 8),
                          Text('Edit Application'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(
                            Icons.remove_circle,
                            size: 16,
                            color: colors.error,
                          ),
                          const SizedBox(width: 8),
                          Text('Remove Application'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 16,
                            color: colors.textPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text('View Invoice'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Amount Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border, width: 0.5),
              ),
              child: Column(
                children: [
                  // Invoice Amount vs Applied Amount
                  Row(
                    children: [
                      Expanded(
                        child: _buildAmountInfo(
                          'Invoice Amount',
                          '₹ ${_formatAmount(invoiceAmount)}',
                          colors.textSecondary,
                          colors.textPrimary,
                          colors,
                        ),
                      ),
                      Container(width: 1, height: 40, color: colors.border),
                      Expanded(
                        child: _buildAmountInfo(
                          'Applied Amount',
                          '₹ ${_formatAmount(appliedAmountTotal)}',
                          colors.textSecondary,
                          colors.primary,
                          colors,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Applied Amount Breakdown
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Applied Amount Breakdown',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildBreakdownItem(
                                'Base',
                                '₹ ${_formatAmount(appliedAmountBase)}',
                                colors,
                              ),
                            ),
                            Expanded(
                              child: _buildBreakdownItem(
                                'Tax',
                                '₹ ${_formatAmount(appliedAmountTax)}',
                                colors,
                              ),
                            ),
                            Expanded(
                              child: _buildBreakdownItem(
                                'TDS',
                                '₹ ${_formatAmount(appliedAmountTDS)}',
                                colors,
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
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInfo(
    String label,
    String amount,
    Color labelColor,
    Color amountColor,
    WareozeColorScheme colors,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: amountColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBreakdownItem(
    String label,
    String amount,
    WareozeColorScheme colors,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildApplyToInvoiceButton(
    BuildContext context,
    WareozeColorScheme colors,
    ValueNotifier<List<Map<String, dynamic>>> appliedInvoices,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () =>
            _showApplyToInvoiceBottomSheet(context, colors, appliedInvoices),
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Apply to another invoice',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: colors.primary.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, WareozeColorScheme colors) {
    Color backgroundColor;
    Color textColor = Colors.white;

    switch (status.toUpperCase()) {
      case 'FULLY_APPLIED':
        backgroundColor = colors.success;
        break;
      case 'PARTIALLY_APPLIED':
        backgroundColor = colors.warning;
        break;
      case 'UNAPPLIED':
        backgroundColor = colors.error;
        break;
      default:
        backgroundColor = colors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return date.toString();
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    if (amount is int) return amount.toString();
    if (amount is double) {
      if (amount == amount.toInt()) {
        return amount.toInt().toString();
      } else {
        return amount.toStringAsFixed(2);
      }
    }
    return amount.toString();
  }

  void _handleInvoiceAction(
    String action,
    int index,
    ValueNotifier<List<Map<String, dynamic>>> appliedInvoices,
    WareozeColorScheme colors,
  ) {
    switch (action) {
      case 'edit':
        _editInvoiceApplication(index, appliedInvoices, colors);
        break;
      case 'remove':
        _removeInvoiceApplication(index, appliedInvoices);
        break;
      case 'view':
        _viewInvoiceDetails(appliedInvoices.value[index]);
        break;
    }
  }

  void _editInvoiceApplication(
    int index,
    ValueNotifier<List<Map<String, dynamic>>> appliedInvoices,
    WareozeColorScheme colors,
  ) {
    // Implementation for editing invoice application
    print('Edit invoice application at index $index');
  }

  void _removeInvoiceApplication(
    int index,
    ValueNotifier<List<Map<String, dynamic>>> appliedInvoices,
  ) {
    final newList = List<Map<String, dynamic>>.from(appliedInvoices.value);
    newList.removeAt(index);
    appliedInvoices.value = newList;
  }

  void _viewInvoiceDetails(Map<String, dynamic> invoiceData) {
    // Implementation for viewing invoice details
    print('View invoice details: $invoiceData');
  }

  void _showApplyToInvoiceBottomSheet(
    BuildContext context,
    WareozeColorScheme colors,
    ValueNotifier<List<Map<String, dynamic>>> appliedInvoices,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 150,
          child: Center(
            child: Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context, WareozeColorScheme colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: colors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.share, color: colors.textPrimary),
            title: Text('Share Payment Details'),
            onTap: () {
              Navigator.pop(context);
              // Implement share functionality
            },
          ),
          ListTile(
            leading: Icon(Icons.download, color: colors.textPrimary),
            title: Text('Download Receipt'),
            onTap: () {
              Navigator.pop(context);
              // Implement download functionality
            },
          ),
          ListTile(
            leading: Icon(Icons.edit, color: colors.textPrimary),
            title: Text('Edit Payment'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to edit payment screen
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _sortInvoices() {
    print('Sort invoices');
    // Implement sorting functionality
  }
}
