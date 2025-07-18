import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Wareozo/apis/providers/sales_provider.dart';
import '../theme_provider.dart';
import '../share/share_bottom_sheet.dart';

class SalesListingPage extends ConsumerStatefulWidget {
  const SalesListingPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SalesListingPage> createState() => _SalesListingPageState();
}

class _SalesListingPageState extends ConsumerState<SalesListingPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Initialize data on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salesProvider.notifier).fetchSales();
      ref.read(salesProvider.notifier).fetchFilterOptions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper method to check if receipt PDF exists
  bool _hasReceiptPdf(Map<String, dynamic> invoice) {
    final invoiceNumber = invoice['invoiceNumber'] ?? 'Unknown';
    
    // Check if receiptPdfUrlLocation exists and has a valid Location
    final receiptPdfLocation = invoice['receiptPdfUrlLocation'];
    if (receiptPdfLocation != null && 
        receiptPdfLocation['Location'] != null && 
        receiptPdfLocation['Location'].toString().trim().isNotEmpty) {
      print('✅ Receipt PDF found for $invoiceNumber via receiptPdfUrlLocation');
      return true;
    }
    
    // Check if receiptTemplates array exists and has items
    final receiptTemplates = invoice['receiptTemplates'] as List?;
    if (receiptTemplates != null && receiptTemplates.isNotEmpty) {
      // Check if the last receipt template has a valid Location
      final lastTemplate = receiptTemplates.last;
      if (lastTemplate['Location'] != null && 
          lastTemplate['Location'].toString().trim().isNotEmpty) {
        print('✅ Receipt PDF found for $invoiceNumber via receiptTemplates');
        return true;
      }
    }
    
    print('❌ No receipt PDF found for $invoiceNumber');
    return false;
  }

  // Helper method to check if receipt sharing is actually possible
  bool _canShareReceipt(Map<String, dynamic> invoice) {
    final invoiceNumber = invoice['invoiceNumber'] ?? 'Unknown';
    
    // Must have PDF available
    if (!_hasReceiptPdf(invoice)) {
      print('❌ Cannot share receipt for $invoiceNumber - No PDF available');
      return false;
    }
    
    // Must have template configured
    final templateId = invoice['receiptPdfTemplate'] ??
                      invoice['receiptTemplateId'] ??
                      invoice['receiptTemplate']?['_id'];
    
    if (templateId == null || templateId.toString().trim().isEmpty) {
      print('❌ Cannot share receipt for $invoiceNumber - No template configured');
      return false;
    }
    
    // Must have payment information (received amount > 0)
    final receivedAmount = invoice['receivedAmount'] ?? 0.0;
    if (receivedAmount <= 0) {
      print('❌ Cannot share receipt for $invoiceNumber - No payments received (receivedAmount: $receivedAmount)');
      return false;
    }
    
    print('✅ Can share receipt for $invoiceNumber - All conditions met');
    return true;
  }

  // Helper method to check if invoice PDF exists
  bool _hasInvoicePdf(Map<String, dynamic> invoice) {
    final invoiceNumber = invoice['invoiceNumber'] ?? 'Unknown';
    
    // Check if pdfUrlLocation exists and has a valid Location
    final pdfLocation = invoice['pdfUrlLocation'];
    if (pdfLocation != null && 
        pdfLocation['Location'] != null && 
        pdfLocation['Location'].toString().trim().isNotEmpty) {
      print('✅ Invoice PDF found for $invoiceNumber via pdfUrlLocation');
      return true;
    }
    
    // Check if draftTemplates array exists and has items
    final draftTemplates = invoice['draftTemplates'] as List?;
    if (draftTemplates != null && draftTemplates.isNotEmpty) {
      // Check if the last draft template has a valid Location
      final lastTemplate = draftTemplates.last;
      if (lastTemplate['Location'] != null && 
          lastTemplate['Location'].toString().trim().isNotEmpty) {
        print('✅ Invoice PDF found for $invoiceNumber via draftTemplates');
        return true;
      }
    }
    
    print('❌ No invoice PDF found for $invoiceNumber');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorProvider);
    final salesState = ref.watch(salesProvider);
    final dashboardNumbers = ref.watch(salesDashboardProvider);
    final isLoading = ref.watch(salesLoadingProvider);
    final error = ref.watch(salesErrorProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'Sales',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: colors.textPrimary),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(salesProvider.notifier).fetchSales();
        },
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              )
            : error != null
            ? _buildErrorWidget(error, colors)
            : CustomScrollView(
                slivers: [
                  // Search and Filter Section
                  SliverToBoxAdapter(child: _buildSearchAndFilterRow(colors)),

                  // Dashboard Cards Section
                  SliverToBoxAdapter(
                    child: Container(
                      color: colors.surface,
                      child: Column(
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                _buildDashboardCard(
                                  'Total Sales',
                                  '₹ ${NumberFormat('#,##,###.##').format(dashboardNumbers.totalInvoicesAmount)}',
                                  colors.primary,
                                  Icons.receipt_long,
                                  colors,
                                ),
                                const SizedBox(width: 12),
                                _buildDashboardCard(
                                  'Total Received',
                                  '₹ ${NumberFormat('#,##,###.##').format(dashboardNumbers.totalReceivedOrPaid)}',
                                  colors.success,
                                  Icons.payments,
                                  colors,
                                ),
                                const SizedBox(width: 12),
                                _buildDashboardCard(
                                  'Total Unpaid',
                                  '₹ ${NumberFormat('#,##,###.##').format(dashboardNumbers.totalUnpaid)}',
                                  colors.error,
                                  Icons.money_off,
                                  colors,
                                ),
                                const SizedBox(width: 12),
                                _buildDashboardCard(
                                  'Quotations',
                                  '₹ ${NumberFormat('#,##,###.##').format(dashboardNumbers.totalQuotationOrPOAmount)}',
                                  colors.warning,
                                  Icons.description,
                                  colors,
                                ),
                                const SizedBox(width: 12),
                                _buildDashboardCard(
                                  'Delivery Notes',
                                  '₹ ${NumberFormat('#,##,###.##').format(dashboardNumbers.totalDeliveryNoteAmount)}',
                                  Color(0xFF9C27B0),
                                  Icons.local_shipping,
                                  colors,
                                ),
                              ],
                            ),
                          ),

                          // Divider for visual separation
                          Container(
                            height: 1,
                            color: colors.border.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Sales List Section
                  SliverToBoxAdapter(
                    child: Container(
                      color: colors.background,
                      child: _buildSalesListContent(
                        salesState.invoices,
                        colors,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSalesListContent(
    List<Map<String, dynamic>> invoices,
    WareozeColorScheme colors,
  ) {
    // Apply search filter
    final searchFilteredInvoices = _searchQuery.isEmpty
        ? invoices
        : invoices.where((invoice) {
            final invoiceNumber =
                invoice['invoiceNumber']?.toString().toLowerCase() ?? '';
            final buyerName =
                invoice['buyer']?['name']?.toString().toLowerCase() ?? '';
            final query = _searchQuery.toLowerCase();
            return invoiceNumber.contains(query) || buyerName.contains(query);
          }).toList();

    // Debug: Print current filter state
    final currentFilter = ref.watch(salesCurrentFilterProvider);
    print(
      'Current Filter - Status: ${currentFilter.status}, VoucherType: ${currentFilter.voucherType}, Buyer: ${currentFilter.buyer}',
    );
    print(
      'Total invoices: ${invoices.length}, After search: ${searchFilteredInvoices.length}',
    );

    if (searchFilteredInvoices.isEmpty) {
      return Container(
        // Add minimum height to ensure scrollability even when empty
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 300,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 64, color: colors.textSecondary),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No sales records found for "$_searchQuery"'
                    : 'No sales records found',
                style: TextStyle(fontSize: 16, color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (_searchQuery.isNotEmpty ||
                  currentFilter.status != 'all' ||
                  currentFilter.voucherType != 'all' ||
                  currentFilter.buyer != 'all') ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    ref.read(salesProvider.notifier).resetFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Clear Filters'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: searchFilteredInvoices.map((invoice) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildInvoiceCard(invoice, colors),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDashboardCard(
    String title,
    String value,
    Color color,
    IconData icon,
    WareozeColorScheme colors,
  ) {
    return Container(
      width: 160, // Optimized width
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Better spacing
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // Fixed spacing
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterRow(WareozeColorScheme colors) {
    return Container(
      color: colors.surface,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.refresh, color: colors.primary),
            onPressed: () => ref.read(salesProvider.notifier).resetFilters(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Type here to search party...',
                hintStyle: TextStyle(color: colors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: colors.surface,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: colors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(
    Map<String, dynamic> invoice,
    WareozeColorScheme colors,
  ) {
    final voucherType = invoice['voucherType'] ?? 'Invoice';
    final invoiceNumber = invoice['invoiceNumber'] ?? '';
    final date = invoice['date'] ?? '';
    final buyerName =
        invoice['buyer']?['name'] ?? invoice['client']?['name'] ?? 'Unknown';
    final amount = invoice['amount'] ?? 0.0;
    final balanceAmount = invoice['balanceAmount'] ?? 0.0;

    // Handle status properly - check both status and displayStatus
    final status =
        invoice['status']?.toString() ??
        invoice['displayStatus']?.toString() ??
        'Unknown';

    final dueDate = invoice['payBydate'] ?? invoice['invoiceExpiryDate'] ?? '';
    final tax = invoice['finalTax'] ?? 0.0;

    return Card(
      elevation: 2,
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showInvoiceDetails(invoice, colors),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getVoucherTypeColor(
                                  voucherType,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                voucherType,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getVoucherTypeColor(voucherType),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              invoiceNumber,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          buyerName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Date: ${_formatDate(date)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge (moved to top right)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getDisplayStatus(status),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Amount Details Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tax',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                        Text(
                          '₹ ${NumberFormat('#,##,###.##').format(tax)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Due In',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                        Text(
                          _formatDueDate(dueDate),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _getDueDateColor(dueDate),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                        Text(
                          '₹ ${NumberFormat('#,##,###.##').format(amount)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (balanceAmount > 0)
                          Text(
                            '₹ ${NumberFormat('#,##,###.##').format(balanceAmount)} (Unpaid)',
                            style: TextStyle(fontSize: 12, color: colors.error),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Divider
              Container(height: 1, color: colors.border.withOpacity(0.3)),

              const SizedBox(height: 12),

              // Action Buttons Row
              _buildActionButtons(invoice, voucherType, status, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    Map<String, dynamic> invoice,
    String voucherType,
    String status,
    WareozeColorScheme colors,
  ) {
    List<Map<String, dynamic>> actions = [];

    if (voucherType == 'Invoice') {
      // Edit action
      actions.add({
        'icon': Icons.edit,
        'label': 'Edit',
        'color': colors.primary,
        'onTap': () => _navigateToEditInvoice(invoice),
      });

      // Share Invoice action - only show if invoice PDF exists
      if (_hasInvoicePdf(invoice)) {
        actions.add({
          'icon': Icons.picture_as_pdf,
          'label': 'Share Invoice',
          'color': colors.success,
          'onTap': () => _shareInvoice(invoice),
        });
      }

      // Share Receipts action - only show if receipt PDF exists
      if (_hasReceiptPdf(invoice)) {
        actions.add({
          'icon': Icons.receipt,
          'label': 'Share Receipts',
          'color': Colors.purple,
          'onTap': () => _shareReceipts(invoice),
        });
      }

      // View action
      actions.add({
        'icon': Icons.visibility,
        'label': 'View',
        'color': colors.warning,
        'onTap': () => _navigateToViewInvoice(invoice),
      });

      // Payment action (only if not paid)
      if (status != 'PAID') {
        actions.add({
          'icon': Icons.payment,
          'label': 'Payment In',
          'color': Colors.blue,
          'onTap': () => _navigateToRecordPayment(invoice),
        });
      }

      // Delete receipts (only if paid and has receipts)
      if (status == 'PAID' && _hasReceiptPdf(invoice)) {
        actions.add({
          'icon': Icons.delete,
          'label': 'Delete Receipts',
          'color': colors.error,
          'onTap': () => _deleteReceipts(invoice),
        });
      }

      // Copy action
      actions.add({
        'icon': Icons.copy,
        'label': 'Copy',
        'color': colors.textSecondary,
        'onTap': () => _makeCopy(invoice),
      });
    } else if (voucherType == 'Quotation') {
      // Edit action
      actions.add({
        'icon': Icons.edit,
        'label': 'Edit',
        'color': colors.primary,
        'onTap': () => _navigateToEditQuotation(invoice),
      });

      // Share action - only show if quotation PDF exists
      if (_hasInvoicePdf(invoice)) {
        actions.add({
          'icon': Icons.share,
          'label': 'Share',
          'color': colors.success,
          'onTap': () => _shareQuotation(invoice),
        });
      }

      // View action
      actions.add({
        'icon': Icons.visibility,
        'label': 'View',
        'color': colors.warning,
        'onTap': () => _navigateToViewQuotation(invoice),
      });

      // Create Invoice action
      actions.add({
        'icon': Icons.receipt_long,
        'label': 'Invoice',
        'color': Colors.purple,
        'onTap': () => _createInvoiceFromQuotation(invoice),
      });

      // Copy action
      actions.add({
        'icon': Icons.copy,
        'label': 'Copy',
        'color': colors.textSecondary,
        'onTap': () => _makeCopy(invoice),
      });
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: actions.take(5).map((action) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildActionButton(
              icon: action['icon'],
              label: action['label'],
              color: action['color'],
              onTap: action['onTap'],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Rest of the methods remain the same...
  void _showInvoiceDetails(
    Map<String, dynamic> invoice,
    WareozeColorScheme colors,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildInvoiceDetailsModal(invoice, colors),
    );
  }

  Widget _buildInvoiceDetailsModal(
    Map<String, dynamic> invoice,
    WareozeColorScheme colors,
  ) {
    final voucherType = invoice['voucherType'] ?? 'Invoice';
    final invoiceNumber = invoice['invoiceNumber'] ?? '';
    final date = invoice['date'] ?? '';
    final buyerName =
        invoice['buyer']?['name'] ?? invoice['client']?['name'] ?? 'Unknown';
    final amount = invoice['amount'] ?? 0.0;
    final balanceAmount = invoice['balanceAmount'] ?? 0.0;
    final status =
        invoice['status']?.toString() ??
        invoice['displayStatus']?.toString() ??
        'Unknown';
    final dueDate = invoice['payBydate'] ?? invoice['invoiceExpiryDate'] ?? '';
    final tax = invoice['finalTax'] ?? 0.0;
    final discountAmount = invoice['discountAmount'] ?? 0.0;
    final subTotal = invoice['subTotal'] ?? 0.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.border.withOpacity(0.5)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getVoucherTypeColor(voucherType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getVoucherTypeIcon(voucherType),
                    color: _getVoucherTypeColor(voucherType),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$voucherType Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        invoiceNumber,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getDisplayStatus(status),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.close, color: colors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Party Information
                  _buildDetailSection('Party Information', [
                    _buildDetailItem('Party Name', buyerName, colors),
                    _buildDetailItem('Invoice Number', invoiceNumber, colors),
                    _buildDetailItem('Date', _formatDate(date), colors),
                    if (dueDate.isNotEmpty)
                      _buildDetailItem(
                        'Due Date',
                        _formatDate(dueDate),
                        colors,
                      ),
                  ], colors),

                  const SizedBox(height: 24),

                  // Amount Details
                  _buildDetailSection('Amount Details', [
                    _buildDetailItem(
                      'Subtotal',
                      '₹ ${NumberFormat('#,##,###.##').format(subTotal)}',
                      colors,
                    ),
                    if (discountAmount > 0)
                      _buildDetailItem(
                        'Discount',
                        '- ₹ ${NumberFormat('#,##,###.##').format(discountAmount)}',
                        colors,
                        valueColor: colors.warning,
                      ),
                    _buildDetailItem(
                      'Tax Amount',
                      '₹ ${NumberFormat('#,##,###.##').format(tax)}',
                      colors,
                    ),
                    const Divider(),
                    _buildDetailItem(
                      'Total Amount',
                      '₹ ${NumberFormat('#,##,###.##').format(amount)}',
                      colors,
                      isHighlighted: true,
                    ),
                    if (balanceAmount > 0)
                      _buildDetailItem(
                        'Balance Amount',
                        '₹ ${NumberFormat('#,##,###.##').format(balanceAmount)}',
                        colors,
                        valueColor: colors.error,
                        isHighlighted: true,
                      ),
                  ], colors),

                  const SizedBox(height: 24),

                  // Payment Status
                  if (status != 'DRAFT')
                    _buildDetailSection('Payment Information', [
                      _buildDetailItem(
                        'Status',
                        _getDisplayStatus(status),
                        colors,
                        valueColor: _getStatusColor(status),
                      ),
                      if (dueDate.isNotEmpty)
                        _buildDetailItem(
                          'Due In',
                          _formatDueDate(dueDate),
                          colors,
                          valueColor: _getDueDateColor(dueDate),
                        ),
                      if (balanceAmount == 0 && amount > 0)
                        _buildDetailItem(
                          'Paid Amount',
                          '₹ ${NumberFormat('#,##,###.##').format(amount)}',
                          colors,
                          valueColor: colors.success,
                        ),
                    ], colors),
                ],
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.background,
              border: Border(
                top: BorderSide(color: colors.border.withOpacity(0.5)),
              ),
            ),
            child: _buildInvoiceDetailsModalActionButtons(context, invoice, colors),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceDetailsModalActionButtons(
    BuildContext context,
    Map<String, dynamic> invoice,
    WareozeColorScheme colors,
  ) {
    List<Widget> actionButtons = [];

    // Share Invoice button (only if invoice PDF exists)
    if (_hasInvoicePdf(invoice)) {
      actionButtons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _shareInvoice(invoice);
            },
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('Share Invoice'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.success,
              side: BorderSide(color: colors.success),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      );
    }

    // Share Receipts button (only if receipt can be shared)
    if (_canShareReceipt(invoice)) {
      if (actionButtons.isNotEmpty) {
        actionButtons.add(const SizedBox(width: 12));
      }
      actionButtons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _shareReceipts(invoice);
            },
            icon: const Icon(Icons.receipt, size: 18),
            label: const Text('Share Receipts'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.purple,
              side: BorderSide(color: Colors.purple),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      );
    }

    // View button (always show)
    if (actionButtons.isNotEmpty) {
      actionButtons.add(const SizedBox(width: 12));
    }
    actionButtons.add(
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            _navigateToViewInvoice(invoice);
          },
          icon: const Icon(Icons.visibility, size: 18),
          label: const Text('View'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );

    return Row(children: actionButtons);
  }

  Widget _buildDetailSection(
    String title,
    List<Widget> children,
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border.withOpacity(0.3)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    WareozeColorScheme colors, {
    Color? valueColor,
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isHighlighted ? 15 : 14,
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: isHighlighted ? 15 : 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isHighlighted ? 16 : 14,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getVoucherTypeIcon(String voucherType) {
    switch (voucherType.toLowerCase()) {
      case 'invoice':
        return Icons.receipt_long;
      case 'quotation':
        return Icons.description;
      case 'credit note':
        return Icons.note;
      case 'delivery note':
        return Icons.local_shipping;
      default:
        return Icons.receipt;
    }
  }

  String _getDisplayStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return 'PAID';
      case 'PENDING':
        return 'PENDING';
      case 'PARTIALLY_PAID':
        return 'PARTIALLY PAID';
      case 'DRAFT':
        return 'DRAFT';
      case 'OVERDUE':
        return 'OVERDUE';
      case 'INVOICE SENT':
        return 'INVOICE SENT';
      case 'INVOICED':
        return 'INVOICED';
      default:
        return status;
    }
  }

  List<PopupMenuEntry<String>> _buildActionMenu(Map<String, dynamic> invoice) {
    final voucherType = invoice['voucherType'] ?? 'Invoice';
    final status = invoice['status'] ?? invoice['displayStatus'] ?? '';

    List<PopupMenuEntry<String>> items = [];

    if (voucherType == 'Invoice') {
      items.addAll([
        const PopupMenuItem(
          value: 'edit_invoice',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('Edit Invoice'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'view_invoice',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 20),
              SizedBox(width: 8),
              Text('View Invoice'),
            ],
          ),
        ),
        
        // Only show Share Invoice if PDF exists
        if (_hasInvoicePdf(invoice))
          const PopupMenuItem(
            value: 'share_invoice',
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf, size: 20),
                SizedBox(width: 8),
                Text('Share Invoice'),
              ],
            ),
          ),
        
        // Only show Share Receipts if receipt PDF exists
        if (_hasReceiptPdf(invoice))
          const PopupMenuItem(
            value: 'share_receipts',
            child: Row(
              children: [
                Icon(Icons.receipt, size: 20),
                SizedBox(width: 8),
                Text('Share Receipts'),
              ],
            ),
          ),
        
        if (status != 'PAID')
          const PopupMenuItem(
            value: 'record_payment',
            child: Row(
              children: [
                Icon(Icons.payment, size: 20),
                SizedBox(width: 8),
                Text('Record Payment In'),
              ],
            ),
          ),
        
        if (status == 'PAID')
          const PopupMenuItem(
            value: 'view_receipts',
            child: Row(
              children: [
                Icon(Icons.receipt, size: 20),
                SizedBox(width: 8),
                Text('View Receipts'),
              ],
            ),
          ),
        
        if (status == 'PAID' && _canShareReceipt(invoice))
          const PopupMenuItem(
            value: 'delete_receipts',
            child: Row(
              children: [
                Icon(Icons.delete, size: 20, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Delete All Receipts',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
      ]);
    } else if (voucherType == 'Quotation') {
      items.addAll([
        const PopupMenuItem(
          value: 'edit_quotation',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('Edit Quotation'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'view_quotation',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 20),
              SizedBox(width: 8),
              Text('View Quotation'),
            ],
          ),
        ),
        
        // Only show Share Quotation if PDF exists
        if (_hasInvoicePdf(invoice))
          const PopupMenuItem(
            value: 'share_quotation',
            child: Row(
              children: [
                Icon(Icons.share, size: 20),
                SizedBox(width: 8),
                Text('Share Quotation'),
              ],
            ),
          ),
        
        const PopupMenuItem(
          value: 'create_invoice',
          child: Row(
            children: [
              Icon(Icons.receipt_long, size: 20),
              SizedBox(width: 8),
              Text('Create Invoice'),
            ],
          ),
        ),
      ]);
    }

    items.add(
      const PopupMenuItem(
        value: 'make_copy',
        child: Row(
          children: [
            Icon(Icons.copy, size: 20),
            SizedBox(width: 8),
            Text('Make a copy'),
          ],
        ),
      ),
    );

    return items;
  }

  void _handleAction(String action, Map<String, dynamic> invoice) {
    switch (action) {
      case 'edit_invoice':
        _navigateToEditInvoice(invoice);
        break;
      case 'view_invoice':
        _navigateToViewInvoice(invoice);
        break;
      case 'share_invoice':
        _shareInvoice(invoice);
        break;
      case 'share_receipts':
        _shareReceipts(invoice);
        break;
      case 'record_payment':
        _navigateToRecordPayment(invoice);
        break;
      case 'view_receipts':
        _navigateToViewReceipts(invoice);
        break;
      case 'delete_receipts':
        _deleteReceipts(invoice);
        break;
      case 'edit_quotation':
        _navigateToEditQuotation(invoice);
        break;
      case 'view_quotation':
        _navigateToViewQuotation(invoice);
        break;
      case 'share_quotation':
        _shareQuotation(invoice);
        break;
      case 'create_invoice':
        _createInvoiceFromQuotation(invoice);
        break;
      case 'make_copy':
        _makeCopy(invoice);
        break;
    }
  }

  // Action methods (keeping the same implementations)
  void _navigateToEditInvoice(Map<String, dynamic> invoice) {
    print('Edit Invoice: ${invoice['invoiceNumber']}');
  }

  void _navigateToViewInvoice(Map<String, dynamic> invoice) {
    print('View Invoice: ${invoice['invoiceNumber']}');
  }

  void _shareInvoice(Map<String, dynamic> invoice) {
    final buyerEmails = List<String>.from(
      invoice['buyer']?['email'] ?? invoice['client']?['email'] ?? [],
    );

    // Get template ID dynamically from invoice data only
    final templateId = invoice['pdfTemplate'] ?? 
                     invoice['templateId'] ??
                     invoice['template']?['_id'];

    // Only proceed if we have a valid template ID
    if (templateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No template configured for this invoice'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(
        invoiceId: invoice['_id'] ?? '',
        voucherType: 'Invoice',
        defaultEmails: buyerEmails,
        title: 'Share Invoice',
        invoiceData: invoice, // Pass the invoice data for preview
        templateId: templateId, // Pass the dynamic template ID
      ),
    );
  }

  void _navigateToRecordPayment(Map<String, dynamic> invoice) {
    print('Record Payment: ${invoice['invoiceNumber']}');
  }

  void _navigateToViewReceipts(Map<String, dynamic> invoice) {
    print('View Receipts: ${invoice['invoiceNumber']}');
  }

  void _shareReceipts(Map<String, dynamic> invoice) {
    final invoiceNumber = invoice['invoiceNumber'] ?? 'Unknown';
    print('🔄 Attempting to share receipts for $invoiceNumber');
    
    final buyerEmails = List<String>.from(
      invoice['buyer']?['email'] ?? invoice['client']?['email'] ?? [],
    );
    print('📧 Buyer emails: $buyerEmails');

    // Get template ID dynamically from invoice data only
    final templateId = invoice['receiptPdfTemplate'] ??
                      invoice['receiptTemplateId'] ??
                      invoice['receiptTemplate']?['_id'];
    print('🏷️ Template ID: $templateId');

    // Debug: Print key payment data
    print('💰 Payment data:');
    print('  - receivedAmount: ${invoice['receivedAmount']}');
    print('  - paymentMode: ${invoice['paymentMode']}');
    print('  - payment: ${invoice['payment']}');
    print('  - account: ${invoice['account']}');

    // Only proceed if we have a valid template ID
    if (templateId == null) {
      print('❌ No template ID found for $invoiceNumber');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No receipt template configured for this invoice'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Double-check if receipt can be shared
    if (!_canShareReceipt(invoice)) {
      print('❌ Receipt sharing conditions not met for $invoiceNumber');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Receipt cannot be shared for this invoice'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('✅ All conditions met, opening share dialog for $invoiceNumber');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(
        invoiceId: invoice['_id'] ?? '',
        voucherType: 'PaymentReceipt',
        defaultEmails: buyerEmails,
        title: 'Share Payment Receipt',
        invoiceData: invoice, // Pass the full invoice data for payment context
        templateId: templateId, // Pass the dynamic template ID
      ),
    );
  }

  void _deleteReceipts(Map<String, dynamic> invoice) {
    _showDeleteConfirmation(invoice);
  }

  void _navigateToEditQuotation(Map<String, dynamic> invoice) {
    print('Edit Quotation: ${invoice['invoiceNumber']}');
  }

  void _navigateToViewQuotation(Map<String, dynamic> invoice) {
    print('View Quotation: ${invoice['invoiceNumber']}');
  }

  void _shareQuotation(Map<String, dynamic> invoice) {
    final buyerEmails = List<String>.from(
      invoice['buyer']?['email'] ?? invoice['client']?['email'] ?? [],
    );

    // Get template ID dynamically from invoice data only
    final templateId = invoice['pdfTemplate'] ??
                      invoice['templateId'] ??
                      invoice['template']?['_id'];

    // Only proceed if we have a valid template ID
    if (templateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No template configured for this quotation'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(
        invoiceId: invoice['_id'] ?? '',
        voucherType: 'Quotation',
        defaultEmails: buyerEmails,
        title: 'Share Quotation',
        invoiceData: invoice, // Pass the quotation data for preview
        templateId: templateId, // Pass the dynamic template ID
      ),
    );
  }

  void _createInvoiceFromQuotation(Map<String, dynamic> invoice) {
    print('Create Invoice from Quotation: ${invoice['invoiceNumber']}');
  }

  void _makeCopy(Map<String, dynamic> invoice) {
    print('Make a copy: ${invoice['invoiceNumber']}');
  }

  void _showDeleteConfirmation(Map<String, dynamic> invoice) {
    final colors = ref.watch(colorProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'Delete Receipts',
          style: TextStyle(color: colors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete all receipts for ${invoice['invoiceNumber']}?',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              print('Delete receipts confirmed');
            },
            child: Text('Delete', style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error, WareozeColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colors.error),
          const SizedBox(height: 16),
          Text(
            'Error: $error',
            style: TextStyle(fontSize: 16, color: colors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(salesProvider.notifier).fetchSales();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.surface,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SalesFilterBottomSheet(),
    );
  }

  Color _getVoucherTypeColor(String voucherType) {
    switch (voucherType.toLowerCase()) {
      case 'invoice':
        return Colors.blue;
      case 'quotation':
        return Colors.orange;
      case 'credit note':
        return Colors.purple;
      case 'delivery note':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'PARTIALLY_PAID':
        return Colors.blue;
      case 'DRAFT':
        return Colors.grey;
      case 'OVERDUE':
        return Colors.red;
      case 'INVOICE SENT':
        return Colors.purple;
      case 'INVOICED':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Color _getDueDateColor(String dueDate) {
    try {
      final due = DateTime.parse(dueDate);
      final now = DateTime.now();
      if (due.isBefore(now)) {
        return Colors.red;
      } else if (due.difference(now).inDays <= 7) {
        return Colors.orange;
      } else {
        return Colors.green;
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatDueDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = date.difference(now).inDays;

      if (difference < 0) {
        return 'Overdue by ${-difference} days';
      } else if (difference == 0) {
        return 'Due today';
      } else {
        return 'Due in $difference days';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }
}

// Filter Bottom Sheet Widget remains the same...
class SalesFilterBottomSheet extends ConsumerStatefulWidget {
  const SalesFilterBottomSheet({Key? key}) : super(key: key);

  @override
  ConsumerState<SalesFilterBottomSheet> createState() =>
      _SalesFilterBottomSheetState();
}

class _SalesFilterBottomSheetState
    extends ConsumerState<SalesFilterBottomSheet> {
  String selectedStatus = 'all';
  String selectedVoucherType = 'all';
  String selectedBuyer = 'all';
  DateRangePreset selectedDateRange = DateRangePreset.thisFYYear;
  DateTime? customStartDate;
  DateTime? customEndDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentFilter = ref.read(salesCurrentFilterProvider);
      setState(() {
        selectedStatus = currentFilter.status;
        selectedVoucherType = currentFilter.voucherType;
        selectedBuyer = currentFilter.buyer;
        selectedDateRange = currentFilter.dateRangePreset;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorProvider);
    final statusOptions = ref.watch(salesStatusOptionsProvider);
    final voucherTypeOptions = ref.watch(salesVoucherTypeOptionsProvider);
    final buyerOptions = ref.watch(salesBuyerOptionsProvider);
    final dateRangeOptions = ref.watch(salesDateRangeOptionsProvider);

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
                  'Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _resetFilters(),
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
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
                  // Status Filter
                  _buildFilterSection(
                    'Status',
                    _buildDropdown(
                      'All',
                      selectedStatus,
                      statusOptions
                          .map((e) => {'id': e.value, 'name': e.label})
                          .toList(),
                      (value) =>
                          setState(() => selectedStatus = value ?? 'all'),
                      colors,
                    ),
                    colors,
                  ),

                  const SizedBox(height: 20),

                  // Date Range Filter
                  _buildFilterSection(
                    'Date Range',
                    _buildDropdown(
                      'This FY Year (Apr - Mar)',
                      selectedDateRange.toString(),
                      dateRangeOptions
                          .map(
                            (e) => {'id': e.value.toString(), 'name': e.label},
                          )
                          .toList(),
                      (value) => setState(() {
                        selectedDateRange = DateRangePreset.values.firstWhere(
                          (preset) => preset.toString() == value,
                          orElse: () => DateRangePreset.thisFYYear,
                        );
                      }),
                      colors,
                    ),
                    colors,
                  ),

                  // Custom Date Range (if selected)
                  if (selectedDateRange == DateRangePreset.custom) ...[
                    const SizedBox(height: 20),
                    _buildFilterSection(
                      'Custom Date Range',
                      Column(
                        children: [
                          _buildDatePicker(
                            'Start Date',
                            customStartDate,
                            (date) => setState(() => customStartDate = date),
                            colors,
                          ),
                          const SizedBox(height: 12),
                          _buildDatePicker(
                            'End Date',
                            customEndDate,
                            (date) => setState(() => customEndDate = date),
                            colors,
                          ),
                        ],
                      ),
                      colors,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Voucher Type Filter
                  _buildFilterSection(
                    'Voucher Type',
                    _buildDropdown(
                      'Select Voucher',
                      selectedVoucherType,
                      voucherTypeOptions
                          .map((e) => {'id': e.value, 'name': e.label})
                          .toList(),
                      (value) =>
                          setState(() => selectedVoucherType = value ?? 'all'),
                      colors,
                    ),
                    colors,
                  ),

                  const SizedBox(height: 20),

                  // Party Filter
                  _buildFilterSection(
                    'Party',
                    _buildDropdown(
                      'All',
                      selectedBuyer,
                      buyerOptions,
                      (value) => setState(() => selectedBuyer = value ?? 'all'),
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
                    onPressed: () => _resetFilters(),
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
                    onPressed: () => _applyFilters(),
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

  Widget _buildDropdown(
    String hint,
    String? value,
    List<Map<String, String>> items,
    ValueChanged<String?> onChanged,
    WareozeColorScheme colors,
  ) {
    // Ensure the value exists in the items list
    final validValue = items.any((item) => item['id'] == value) ? value : null;

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
          value: validValue,
          hint: Text(hint, style: TextStyle(color: colors.textSecondary)),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: colors.textSecondary),
          style: TextStyle(color: colors.textPrimary, fontSize: 16),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item['id'],
              child: Text(
                item['name'] ?? '',
                style: TextStyle(color: colors.textPrimary),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? selectedDate,
    void Function(DateTime?) onDateSelected,
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
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
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
              onDateSelected(date);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(12),
              color: colors.surface,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? DateFormat('dd/MM/yyyy').format(selectedDate)
                        : 'Select $label',
                    style: TextStyle(
                      color: selectedDate != null
                          ? colors.textPrimary
                          : colors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _resetFilters() {
    setState(() {
      selectedStatus = 'all';
      selectedVoucherType = 'all';
      selectedBuyer = 'all';
      selectedDateRange = DateRangePreset.thisFYYear;
      customStartDate = null;
      customEndDate = null;
    });
  }

  void _applyFilters() {
    // Apply date range filter first
    if (selectedDateRange == DateRangePreset.custom) {
      if (customStartDate != null && customEndDate != null) {
        ref
            .read(salesProvider.notifier)
            .filterByDateRange(customStartDate!, customEndDate!);
      }
    } else {
      ref
          .read(salesProvider.notifier)
          .filterByDateRangePreset(selectedDateRange);
    }

    // Create a comprehensive filter with all selected options
    final fyDates = FinancialYearUtils.getFinancialYearDates();
    final startDate = selectedDateRange == DateRangePreset.custom
        ? (customStartDate ?? fyDates['startDateFY']!)
        : FinancialYearUtils.getDateRangeForPreset(
            selectedDateRange,
          )['startDate']!;
    final endDate = selectedDateRange == DateRangePreset.custom
        ? (customEndDate ?? fyDates['endDateFY']!)
        : FinancialYearUtils.getDateRangeForPreset(
            selectedDateRange,
          )['endDate']!;

    final newFilter = SalesFilter(
      buyer: selectedBuyer,
      status: selectedStatus,
      voucherType: selectedVoucherType,
      startDate: startDate,
      endDate: endDate,
      dateRangePreset: selectedDateRange,
    );

    ref.read(salesProvider.notifier).updateFilter(newFilter);
    Navigator.of(context).pop();
  }
}