// lib/payments/payment_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../apis/providers/payment_provider.dart';
import '../theme_provider.dart';
import 'invoice_details_screen.dart';

class PaymentListScreen extends HookConsumerWidget {
  const PaymentListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch both payment providers
    final paymentState = ref.watch(paymentProvider);
    final paymentOutState = ref.watch(paymentOutProvider);
    final colors = ref.watch(colorProvider);
    final isDark = ref.watch(isDarkModeProvider);

    // State for filters
    final expandedRows = useState<Set<int>>({});
    final selectedTab = useState<int>(0); // 0 = Payment In, 1 = Payment Out

    // Get current data based on selected tab
    final currentPayments = selectedTab.value == 0
        ? paymentState.payments
        : paymentOutState.payments;
    final currentIsLoading = selectedTab.value == 0
        ? paymentState.isLoading
        : paymentOutState.isLoading;
    final currentError = selectedTab.value == 0
        ? paymentState.error
        : paymentOutState.error;

    // Initialize and fetch data
    useEffect(() {
      Future.microtask(() {
        // Fetch Payment In data
        ref.read(paymentProvider.notifier).fetchPayments();
        ref.read(paymentProvider.notifier).fetchFilterOptions();

        // Fetch Payment Out data
        ref.read(paymentOutProvider.notifier).fetchPayments();
        ref.read(paymentOutProvider.notifier).fetchFilterOptions();
      });
      return null;
    }, []);

    // Refresh data when tab changes
    useEffect(() {
      Future.microtask(() {
        if (selectedTab.value == 0) {
          ref.read(paymentProvider.notifier).fetchPayments();
        } else {
          ref.read(paymentOutProvider.notifier).fetchPayments();
        }
      });
      return null;
    }, [selectedTab.value]);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(context, colors, ref, selectedTab.value),
      body: Column(
        children: [
          // Tab Bar
          _buildTabBar(selectedTab, colors),

          // Actions Section
          _buildActionsSection(
            currentPayments,
            colors,
            context,
            selectedTab.value,
          ),

          const Divider(height: 1),

          // Data Table
          Expanded(
            child: _buildDataSection(
              currentIsLoading,
              currentError,
              currentPayments,
              expandedRows,
              ref,
              colors,
              context,
              selectedTab.value,
            ),
          ),
        ],
      ),
      // Floating Action Button - Dynamic based on selected tab
      floatingActionButton: _buildFloatingActionButton(
        selectedTab.value,
        context,
        colors,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WareozeColorScheme colors,
    WidgetRef ref,
    int selectedTab,
  ) {
    return AppBar(
      backgroundColor: colors.surface,
      foregroundColor: colors.textPrimary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            context.go('/home');
          }
        },
      ),
      title: Text(
        'Payments',
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_alt_outlined),
          onPressed: () =>
              _showFilterBottomSheet(context, ref, colors, selectedTab),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(
    int selectedTab,
    BuildContext context,
    WareozeColorScheme colors,
  ) {
    final isPaymentIn = selectedTab == 0;
    final buttonText = isPaymentIn ? 'Payment In' : 'Payment Out';
    final buttonColor = Color(0xFF4C9656);
    final route = isPaymentIn
        ? '/payments/addPaymentIn'
        : '/payments/addPaymentOut';

    return Container(
      width: 156,
      height: 56,
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          context.go(route);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.add, color: CupertinoColors.white, size: 24),
            SizedBox(width: 8),
            Text(
              buttonText,
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(
    BuildContext context,
    WidgetRef ref,
    WareozeColorScheme colors,
    int selectedTab,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          FilterBottomSheet(colors: colors, selectedTab: selectedTab),
    );
  }

  Widget _buildTabBar(
    ValueNotifier<int> selectedTab,
    WareozeColorScheme colors,
  ) {
    return Container(
      color: colors.surface,
      child: Row(
        children: [
          _buildTab('Payment In', 0, selectedTab, colors),
          _buildTab('Payment Out', 1, selectedTab, colors),
        ],
      ),
    );
  }

  Widget _buildTab(
    String title,
    int index,
    ValueNotifier<int> selectedTab,
    WareozeColorScheme colors,
  ) {
    final isActive = selectedTab.value == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => selectedTab.value = index,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? colors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isActive ? colors.primary : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionsSection(
    List<Map<String, dynamic>> payments,
    WareozeColorScheme colors,
    BuildContext context,
    int selectedTab,
  ) {
    final isPaymentIn = selectedTab == 0;
    final summaryTitle = isPaymentIn
        ? 'Inflow Cash Summary'
        : 'Outflow Cash Summary';
    final checkboxText = isPaymentIn
        ? 'Show Attached Invoices'
        : 'Show Attached Purchase Orders';

    return Container(
      color: colors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  summaryTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              // Checkbox for mobile layout
              if (MediaQuery.of(context).size.width < 600) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: false,
                      onChanged: (value) {},
                      activeColor: colors.primary,
                    ),
                    Flexible(
                      child: Text(
                        checkboxText,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Action buttons
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return _buildDesktopActions(payments, colors, checkboxText);
              } else {
                return _buildMobileActions(payments, colors);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopActions(
    List<Map<String, dynamic>> payments,
    WareozeColorScheme colors,
    String checkboxText,
  ) {
    return Row(
      children: [
        Row(
          children: [
            Checkbox(
              value: false,
              onChanged: (value) {},
              activeColor: colors.primary,
            ),
            Text(
              '$checkboxText in pdf report',
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ),
        const Spacer(),
        _buildActionButton(
          'Export To Excel',
          Icons.file_download,
          () => _exportToExcel(payments),
          colors,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          'Download PDF',
          Icons.picture_as_pdf,
          () => _downloadPDF(payments),
          colors,
        ),
      ],
    );
  }

  Widget _buildMobileActions(
    List<Map<String, dynamic>> payments,
    WareozeColorScheme colors,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Export Excel',
            Icons.file_download,
            () => _exportToExcel(payments),
            colors,
            isCompact: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            'Download PDF',
            Icons.picture_as_pdf,
            () => _downloadPDF(payments),
            colors,
            isCompact: true,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
    WareozeColorScheme colors, {
    bool isCompact = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: isCompact ? 16 : 18),
      label: Text(label, style: TextStyle(fontSize: isCompact ? 12 : 14)),
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 8 : 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildDataSection(
    bool isLoading,
    String? error,
    List<Map<String, dynamic>> payments,
    ValueNotifier<Set<int>> expandedRows,
    WidgetRef ref,
    WareozeColorScheme colors,
    BuildContext context,
    int selectedTab,
  ) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.error),
            const SizedBox(height: 16),
            Text(
              'Error: $error',
              style: TextStyle(color: colors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (selectedTab == 0) {
                  ref.read(paymentProvider.notifier).fetchPayments();
                } else {
                  ref.read(paymentOutProvider.notifier).fetchPayments();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Container(
      color: colors.surface,
      child: _buildResponsiveTable(
        payments,
        expandedRows,
        colors,
        context,
        ref,
        selectedTab,
      ),
    );
  }

  Widget _buildResponsiveTable(
    List<Map<String, dynamic>> payments,
    ValueNotifier<Set<int>> expandedRows,
    WareozeColorScheme colors,
    BuildContext context,
    WidgetRef ref,
    int selectedTab,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return _buildDesktopTable(
            payments,
            expandedRows,
            colors,
            context,
            ref,
            selectedTab,
          );
        } else {
          return _buildMobileTable(
            payments,
            expandedRows,
            colors,
            context,
            ref,
            selectedTab,
          );
        }
      },
    );
  }

  Widget _buildDesktopTable(
    List<Map<String, dynamic>> payments,
    ValueNotifier<Set<int>> expandedRows,
    WareozeColorScheme colors,
    BuildContext context,
    WidgetRef ref,
    int selectedTab,
  ) {
    final isPaymentIn = selectedTab == 0;
    final entityColumnTitle = isPaymentIn ? 'BUYER NAME' : 'SUPPLIER NAME';

    return RefreshIndicator(
      color: colors.primary,
      onRefresh: () async {
        if (selectedTab == 0) {
          await ref.read(paymentProvider.notifier).fetchPayments();
        } else {
          await ref.read(paymentOutProvider.notifier).fetchPayments();
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(colors.background),
            columns: [
              DataColumn(
                label: Text(
                  'TRXN ID',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'PAYMENT DATE',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  entityColumnTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'PAYMENT AMT.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'TOTAL APPLIED',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'TOTAL UNAPP...',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'STATUS',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'PAYMENT MODE',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
            rows: payments.map((payment) {
              final txnId = payment['txnId'] ?? 0;
              final isExpanded = expandedRows.value.contains(txnId);

              // Get entity name based on payment type
              final entityName = isPaymentIn
                  ? (payment['paymentFrom']?['name'] ?? '')
                  : (payment['paymentTo']?['name'] ?? '');

              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: colors.textSecondary,
                          ),
                          onPressed: () {
                            final newSet = Set<int>.from(expandedRows.value);
                            if (isExpanded) {
                              newSet.remove(txnId);
                            } else {
                              newSet.add(txnId);
                            }
                            expandedRows.value = newSet;
                          },
                        ),
                        Text(
                          '$txnId',
                          style: TextStyle(color: colors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      _formatDate(payment['paymentDate']),
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ),
                  DataCell(
                    Text(
                      entityName,
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ),
                  DataCell(
                    Text(
                      '₹ ${_formatAmount(payment['amount'])}',
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ),
                  DataCell(
                    Text(
                      '₹ ${_formatAmount(payment['paymentApplied'])}',
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ),
                  DataCell(
                    Text(
                      '₹ ${_formatAmount(payment['paymentUnapplied'])}',
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ),
                  DataCell(
                    _buildStatusChip(payment['applyStatus'] ?? '', colors),
                  ),
                  DataCell(
                    Text(
                      payment['paymentMode'] ?? '',
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTable(
    List<Map<String, dynamic>> payments,
    ValueNotifier<Set<int>> expandedRows,
    WareozeColorScheme colors,
    BuildContext context,
    WidgetRef ref,
    int selectedTab,
  ) {
    final isPaymentIn = selectedTab == 0;

    return RefreshIndicator(
      color: colors.primary,
      onRefresh: () async {
        if (selectedTab == 0) {
          await ref.read(paymentProvider.notifier).fetchPayments();
        } else {
          await ref.read(paymentOutProvider.notifier).fetchPayments();
        }
      },
      child: payments.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Text(
                      'No payments found',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final payment = payments[index];
                final txnId = payment['txnId'] ?? 0;
                final isExpanded = expandedRows.value.contains(txnId);

                // Get entity name based on payment type
                final entityName = isPaymentIn
                    ? (payment['paymentFrom']?['name'] ?? '')
                    : (payment['paymentTo']?['name'] ?? '');

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: colors.surface,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colors.border, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: IconButton(
                          icon: Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: colors.textSecondary,
                          ),
                          onPressed: () {
                            final newSet = Set<int>.from(expandedRows.value);
                            if (isExpanded) {
                              newSet.remove(txnId);
                            } else {
                              newSet.add(txnId);
                            }
                            expandedRows.value = newSet;
                          },
                        ),
                        title: Row(
                          children: [
                            Text(
                              'TXN $txnId',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            _buildStatusChip(
                              payment['applyStatus'] ?? '',
                              colors,
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              entityName,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '₹ ${_formatAmount(payment['amount'])}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: colors.primary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatDate(payment['paymentDate']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isExpanded)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.background,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(
                                'Payment Mode',
                                payment['paymentMode'] ?? '',
                                colors,
                              ),
                              _buildDetailRow(
                                'Total Applied',
                                '₹ ${_formatAmount(payment['paymentApplied'])}',
                                colors,
                              ),
                              _buildDetailRow(
                                'Total Unapplied',
                                '₹ ${_formatAmount(payment['paymentUnapplied'])}',
                                colors,
                              ),
                              const SizedBox(height: 16),
                              // Invoice/Purchase Order Details Section with Navigation
                              _buildInvoiceDetailsSection(
                                payment,
                                colors,
                                context,
                                isPaymentIn,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    WareozeColorScheme colors,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceDetailsSection(
    Map<String, dynamic> payment,
    WareozeColorScheme colors,
    BuildContext context,
    bool isPaymentIn,
  ) {
    // Get invoice details from the nested structure
    final invoices = payment['invoices'] as List<dynamic>? ?? [];
    final documentType = isPaymentIn ? 'invoices' : 'purchase orders';
    final buttonText = isPaymentIn
        ? 'Apply to Invoice'
        : 'Apply to Purchase Order';

    if (invoices.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border, width: 0.5),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 32,
              color: colors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'No $documentType applied',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToInvoiceDetails(context, payment),
                icon: const Icon(Icons.add, size: 16),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Get the first invoice (or you could show all invoices)
    final invoiceData = invoices[0];
    final invoice = invoiceData['invoice'] as Map<String, dynamic>? ?? {};

    // Extract invoice details
    final invoiceNumber = invoice['invoiceNumber'] ?? '';
    final invoiceDate = invoice['date'] ?? '';
    final invoiceAmount = invoice['amount'] ?? 0;
    final appliedAmountTotal = invoiceData['appliedAmountTotal'] ?? 0;
    final appliedAmountBase = invoiceData['appliedAmountBase'] ?? 0;
    final appliedAmountTax = invoiceData['appliedAmountTax'] ?? 0;
    final appliedAmountTDS = invoiceData['appliedAmountTDS'] ?? 0;

    if (invoiceNumber.isEmpty) {
      return const SizedBox.shrink();
    }

    final documentLabel = isPaymentIn
        ? 'Invoice Details'
        : 'Purchase Order Details';
    final documentNumberLabel = isPaymentIn ? 'INVOICE' : 'PURCHASE ORDER';
    final documentDateLabel = isPaymentIn ? 'INVOICE DATE' : 'PO DATE';
    final documentAmountLabel = isPaymentIn ? 'INVOICE AMOUNT' : 'PO AMOUNT';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              documentLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const Spacer(),
            // View All Button - Navigate to Invoice Details Screen
            TextButton(
              onPressed: () => _navigateToInvoiceDetails(context, payment),
              child: Text(
                'View All (${invoices.length})',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Make the entire container tappable
        GestureDetector(
          onTap: () => _navigateToInvoiceDetails(context, payment),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border, width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // First row: Document number and date
                Row(
                  children: [
                    _buildInvoiceDetailChip(
                      documentNumberLabel,
                      invoiceNumber,
                      colors,
                    ),
                    const SizedBox(width: 8),
                    _buildInvoiceDetailChip(
                      documentDateLabel,
                      _formatDate(invoiceDate),
                      colors,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Second row: Document amount and applied amount
                Row(
                  children: [
                    _buildInvoiceDetailChip(
                      documentAmountLabel,
                      '₹ ${_formatAmount(invoiceAmount)}',
                      colors,
                    ),
                    const SizedBox(width: 8),
                    _buildInvoiceDetailChip(
                      'APPLIED AMOUNT',
                      '₹ ${_formatAmount(appliedAmountTotal)}',
                      colors,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Third row: Applied base/tax/TDS breakdown
                Row(
                  children: [
                    _buildInvoiceDetailChip(
                      'APPLIED BASE/TAX/TDS',
                      '₹ ${_formatAmount(appliedAmountBase)}/ ₹ ${_formatAmount(appliedAmountTax)}/ ₹ ${_formatAmount(appliedAmountTDS)}',
                      colors,
                    ),
                  ],
                ),

                // If there are multiple invoices, show a button to view all
                if (invoices.length > 1) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: colors.primary, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.visibility,
                                size: 14,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'View All ${invoices.length} ${isPaymentIn ? 'Invoices' : 'Purchase Orders'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: colors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceDetailChip(
    String label,
    String value,
    WareozeColorScheme colors,
  ) {
    return Flexible(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: colors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: colors.primary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
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

  // Helper method to format amounts consistently
  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    if (amount is int) return amount.toString();
    if (amount is double) {
      // Format to 2 decimal places if needed, otherwise show as integer
      if (amount == amount.toInt()) {
        return amount.toInt().toString();
      } else {
        return amount.toStringAsFixed(2);
      }
    }
    return amount.toString();
  }

  // Method to navigate to invoice details screen
  void _navigateToInvoiceDetails(
    BuildContext context,
    Map<String, dynamic> payment,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailsScreen(payment: payment),
      ),
    );
  }

  // Method to show all invoices in a dialog or bottom sheet
  void _showAllInvoices(List<dynamic> invoices, WareozeColorScheme colors) {
    // You can implement a dialog or bottom sheet to show all invoices
    // For now, just print the count
    print('Show all ${invoices.length} invoices');
  }

  void _exportToExcel(List<Map<String, dynamic>> payments) {
    print('Exporting to Excel...');
    // Implement Excel export functionality
  }

  void _downloadPDF(List<Map<String, dynamic>> payments) {
    print('Downloading PDF...');
    // Implement PDF download functionality
  }

  void _addNewPayment() {
    print('Add new payment...');
    // Navigate to add payment screen
  }
}

// Filter Bottom Sheet Widget
class FilterBottomSheet extends HookConsumerWidget {
  final WareozeColorScheme colors;
  final int selectedTab;

  const FilterBottomSheet({
    Key? key,
    required this.colors,
    required this.selectedTab,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPaymentIn = selectedTab == 0;

    // Watch appropriate providers based on selected tab
    final paymentState = ref.watch(paymentProvider);
    final paymentOutState = ref.watch(paymentOutProvider);

    // Create options with ALL option
    final List<Map<String, String>> entityOptions = [
      {'id': 'ALL', 'name': 'ALL'},
    ];

    // Handle filter options separately for each type
    if (isPaymentIn) {
      final filterOptions = paymentState.filterOptions;
      for (final buyer in filterOptions.buyers) {
        entityOptions.add({'id': buyer.id, 'name': buyer.name});
      }
    } else {
      final filterOutOptions = paymentOutState.filterOptions;
      for (final supplier in filterOutOptions.suppliers) {
        entityOptions.add({'id': supplier.id, 'name': supplier.name});
      }
    }

    // Controllers for date pickers
    final startDateController = useTextEditingController();
    final endDateController = useTextEditingController();

    // State for filters - handle separately for each type
    final selectedEntityId = useState<String>(
      isPaymentIn ? paymentState.filter.buyer : paymentOutState.filter.supplier,
    );
    final selectedStatus = useState<String>(
      isPaymentIn ? paymentState.filter.status : paymentOutState.filter.status,
    );
    final selectedAmountRange = useState<String>('Below 1 Lakh');

    // Initialize date controllers
    useEffect(() {
      final startDate = isPaymentIn
          ? paymentState.filter.startDate
          : paymentOutState.filter.startDate;
      final endDate = isPaymentIn
          ? paymentState.filter.endDate
          : paymentOutState.filter.endDate;

      startDateController.text = DateFormat(
        'dd/MM/yyyy',
      ).format(DateTime.fromMillisecondsSinceEpoch(startDate));
      endDateController.text = DateFormat(
        'dd/MM/yyyy',
      ).format(DateTime.fromMillisecondsSinceEpoch(endDate));
      return null;
    }, []);

    final entityLabel = isPaymentIn ? 'Buyer Name' : 'Supplier Name';
    final entitySelectText = isPaymentIn ? 'Select Buyer' : 'Select Supplier';

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: colors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Filter ${isPaymentIn ? 'Payment In' : 'Payment Out'}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: colors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Filter content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Entity Filter (Buyer/Supplier)
                  _buildFilterSection(
                    entityLabel,
                    _buildEntityDropdown(
                      entitySelectText,
                      selectedEntityId.value,
                      entityOptions,
                      (value) => selectedEntityId.value = value!,
                      colors,
                    ),
                    colors,
                  ),

                  const SizedBox(height: 20),

                  // Status Filter
                  _buildFilterSection(
                    'Status',
                    _buildFilterDropdown(
                      'Select Status',
                      selectedStatus.value,
                      [
                        'ALL',
                        'FULLY_APPLIED',
                        'PARTIALLY_APPLIED',
                        'UNAPPLIED',
                      ],
                      (value) => selectedStatus.value = value!,
                      colors,
                    ),
                    colors,
                  ),

                  const SizedBox(height: 20),

                  // Date Range
                  _buildFilterSection(
                    'Date Range',
                    Column(
                      children: [
                        _buildDatePicker(
                          'Start Date',
                          startDateController,
                          context,
                          colors,
                        ),
                        const SizedBox(height: 12),
                        _buildDatePicker(
                          'End Date',
                          endDateController,
                          context,
                          colors,
                        ),
                      ],
                    ),
                    colors,
                  ),

                  const SizedBox(height: 20),

                  // Amount Range
                  _buildFilterSection(
                    'Amount Range',
                    _buildFilterDropdown(
                      'Select Amount Range',
                      selectedAmountRange.value,
                      [
                        'Below 1 Lakh',
                        '1-5 Lakhs',
                        '5-10 Lakhs',
                        'Above 10 Lakhs',
                      ],
                      (value) => selectedAmountRange.value = value!,
                      colors,
                    ),
                    colors,
                  ),
                ],
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.background,
              border: Border(top: BorderSide(color: colors.border, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Reset filters
                      selectedEntityId.value = 'ALL';
                      selectedStatus.value = 'ALL';
                      selectedAmountRange.value = 'Below 1 Lakh';
                      final now = DateTime.now();
                      final startDate = DateTime(
                        now.year,
                        now.month - 1,
                        now.day,
                      );
                      startDateController.text = DateFormat(
                        'dd/MM/yyyy',
                      ).format(startDate);
                      endDateController.text = DateFormat(
                        'dd/MM/yyyy',
                      ).format(now);

                      if (isPaymentIn) {
                        ref.read(paymentProvider.notifier).resetFilters();
                      } else {
                        ref.read(paymentOutProvider.notifier).resetFilters();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.border),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      // Apply filters
                      final startDate = DateFormat(
                        'dd/MM/yyyy',
                      ).parse(startDateController.text);
                      final endDate = DateFormat(
                        'dd/MM/yyyy',
                      ).parse(endDateController.text);

                      // Get amount range values
                      double fromAmount = 0;
                      double toAmount = 99999;

                      switch (selectedAmountRange.value) {
                        case 'Below 1 Lakh':
                          fromAmount = 0;
                          toAmount = 100000;
                          break;
                        case '1-5 Lakhs':
                          fromAmount = 100000;
                          toAmount = 500000;
                          break;
                        case '5-10 Lakhs':
                          fromAmount = 500000;
                          toAmount = 1000000;
                          break;
                        case 'Above 10 Lakhs':
                          fromAmount = 1000000;
                          toAmount = 99999999;
                          break;
                      }

                      if (isPaymentIn) {
                        final newFilter = PaymentFilter(
                          buyer: selectedEntityId.value,
                          status: selectedStatus.value,
                          fromAmountRange: fromAmount,
                          toAmountRange: toAmount,
                          startDate: startDate.millisecondsSinceEpoch,
                          endDate: endDate.millisecondsSinceEpoch,
                        );
                        ref
                            .read(paymentProvider.notifier)
                            .updateFilter(newFilter);
                      } else {
                        final newFilter = PaymentOutFilter(
                          supplier: selectedEntityId.value,
                          status: selectedStatus.value,
                          fromAmountRange: fromAmount,
                          toAmountRange: toAmount,
                          startDate: startDate.millisecondsSinceEpoch,
                          endDate: endDate.millisecondsSinceEpoch,
                        );
                        ref
                            .read(paymentOutProvider.notifier)
                            .updateFilter(newFilter);
                      }

                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    Widget content,
    WareozeColorScheme colors,
  ) {
    return Column(
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
        content,
      ],
    );
  }

  Widget _buildEntityDropdown(
    String hint,
    String selectedEntityId,
    List<Map<String, String>> entityOptions,
    ValueChanged<String?> onChanged,
    WareozeColorScheme colors,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(12),
        color: colors.surface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedEntityId,
          hint: Text(hint, style: TextStyle(color: colors.textSecondary)),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: colors.textSecondary),
          style: TextStyle(color: colors.textPrimary, fontSize: 16),
          items: entityOptions.map((option) {
            return DropdownMenuItem(
              value: option['id'],
              child: Text(
                option['name'] ?? '',
                style: TextStyle(color: colors.textPrimary),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
    String hint,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
    WareozeColorScheme colors,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(12),
        color: colors.surface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: colors.textSecondary)),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: colors.textSecondary),
          style: TextStyle(color: colors.textPrimary, fontSize: 16),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, style: TextStyle(color: colors.textPrimary)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePicker(
    String label,
    TextEditingController controller,
    BuildContext context,
    WareozeColorScheme colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          style: TextStyle(color: colors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderSide: BorderSide(color: colors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: colors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: colors.primary),
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colors.surface,
            suffixIcon: Icon(Icons.calendar_today, color: colors.textSecondary),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: colors.primary,
                      brightness: Theme.of(context).brightness,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              controller.text = DateFormat('dd/MM/yyyy').format(date);
            }
          },
        ),
      ],
    );
  }
}
