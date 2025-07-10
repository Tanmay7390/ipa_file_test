import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';
import '../../../../components/page_scaffold.dart';
import '../../../../components/swipable_row.dart';
import '../../../../theme_provider.dart';
import '../apis/providers/invoice_provider.dart';

class InvoiceTab extends ConsumerStatefulWidget {
  const InvoiceTab({super.key});

  @override
  ConsumerState<InvoiceTab> createState() => _InvoiceTabState();
}

class _InvoiceTabState extends ConsumerState<InvoiceTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchField = false;

  @override
  void initState() {
    super.initState();
    // Load invoices when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(invoiceListProvider.notifier).loadInvoices();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '₹0.00';
    final double value = double.tryParse(amount.toString()) ?? 0.0;
    return '₹${value.toStringAsFixed(2)}';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('dd MMM yy, hh:mm a').format(date);
    } catch (e) {
      return '';
    }
  }

  Widget _buildExpenseInsightCard(
    AsyncValue<List<Map<String, dynamic>>> invoicesAsync,
    WareozeColorScheme colors,
  ) {
    return invoicesAsync.when(
      data: (invoices) {
        // Calculate total amounts
        double totalAmount = 0.0;
        double todayAmount = 0.0;
        final DateTime today = DateTime.now();

        for (final invoice in invoices) {
          final double amount =
              double.tryParse(invoice['amount']?.toString() ?? '0') ?? 0.0;
          totalAmount += amount;

          // Check if invoice is from today
          final String? dateString = invoice['date']?.toString();
          if (dateString != null) {
            try {
              final DateTime invoiceDate = DateTime.parse(dateString);
              if (invoiceDate.year == today.year &&
                  invoiceDate.month == today.month &&
                  invoiceDate.day == today.day) {
                todayAmount += amount;
              }
            } catch (e) {
              // Ignore date parsing errors
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              bottom: BorderSide(
                color: colors.border.withOpacity(0.3),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expense analysis section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Expence analysis',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'August - Week 3',
                style: TextStyle(fontSize: 15, color: colors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Expenses insight section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Expenses insight',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatCurrency(totalAmount),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    _formatCurrency(658.01),
                    style: TextStyle(fontSize: 18, color: colors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent expenses section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Recent expenses',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: colors.textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 15,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatCurrency(todayAmount),
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
        );
      },
      loading: () => Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        child: Center(child: CupertinoActivityIndicator(color: colors.primary)),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildInvoiceTitle(
    String invoiceNumber,
    String buyerName,
    WareozeColorScheme colors,
  ) {
    return Text(
      '[$invoiceNumber] $buyerName',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoiceListProvider);
    final invoiceNotifier = ref.read(invoiceListProvider.notifier);
    final colors = ref.watch(colorProvider);

    return CupertinoPageScaffold(
      child: CustomPageScaffold(
        colorScheme: colors,
        heading: 'Sales',
        searchController: _searchController,
        showSearchField: _showSearchField,
        isLoading: invoicesAsync.isLoading,
        onSearchToggle: (isVisible) {
          setState(() {
            _showSearchField = isVisible;
          });
        },
        onSearchChange: (query) {
          invoiceNotifier.searchInvoices(query);
        },
        onRefresh: () async {
          await invoiceNotifier.loadInvoices();
        },
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            // Check if we can pop, otherwise go to home
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          child: Icon(
            CupertinoIcons.chevron_left,
            color: colors.primary,
            size: 28,
          ),
        ),
        floatingActionButton: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Color(0xFF4C9656),
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
              context.go('/invoice/add');
            },
            child: Icon(
              CupertinoIcons.add,
              color: CupertinoColors.white,
              size: 24,
            ),
          ),
        ),
        customHeaderWidget: _buildExpenseInsightCard(invoicesAsync, colors),

        sliverList: invoicesAsync.when(
          data: (invoices) {
            if (invoices.isEmpty && !invoicesAsync.isLoading) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.doc_text,
                        size: 64,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No invoices found',
                        style: TextStyle(
                          fontSize: 17,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first invoice to get started',
                        style: TextStyle(
                          fontSize: 15,
                          color: colors.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Create list items with separators
            final listItems = invoices.map((invoice) {
              final String invoiceNumber =
                  invoice['invoiceNumber']?.toString() ?? '';
              final String buyerName =
                  invoice['buyer']?['name']?.toString() ?? 'Unknown Buyer';
              final String date = _formatDate(invoice['date']?.toString());
              final double amount =
                  double.tryParse(invoice['amount']?.toString() ?? '0') ?? 0.0;
              final String status = invoice['status']?.toString() ?? 'DRAFT';

              // Determine amount color based on status
              Color amountColor = colors.error;
              String amountPrefix = '- ';

              if (status == 'PAID') {
                amountColor = colors.success;
                amountPrefix = '+ ';
              }

              return SwipeActionCell(
                key: ObjectKey(invoice),
                trailingActions: <SwipeAction>[
                  SwipeAction(
                    title: "Delete",
                    performsFirstActionWithFullSwipe: true,
                    onTap: (handler) async {
                      await handler(true);
                      // Show confirmation dialog for delete
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: Text('Delete Invoice'),
                          content: Text(
                            'Are you sure you want to delete this invoice?',
                          ),
                          actions: [
                            CupertinoDialogAction(
                              child: Text('Cancel'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              child: Text('Delete'),
                              onPressed: () {
                                Navigator.of(context).pop();
                                final invoiceId = invoice['_id']?.toString();
                                if (invoiceId != null) {
                                  invoiceNotifier.deleteInvoice(invoiceId);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    color: CupertinoColors.systemRed,
                  ),
                  SwipeAction(
                    title: "Edit",
                    onTap: (handler) async {
                      final invoiceId = invoice['_id']?.toString();
                      if (invoiceId != null) {
                        context.push('/invoice/edit/$invoiceId');
                      }
                      await handler(false);
                    },
                    color: CupertinoColors.systemOrange,
                  ),
                  SwipeAction(
                    title: "Record Payment",
                    onTap: (handler) async {
                      final invoiceId = invoice['_id']?.toString();
                      if (invoiceId != null) {
                        context.push('/invoice/payment/$invoiceId');
                      }
                      await handler(false);
                    },
                    color: CupertinoColors.systemGreen,
                  ),
                ],
                child: CupertinoListTile(
                  backgroundColor: CupertinoColors.systemBackground.resolveFrom(
                    context,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      CupertinoIcons.doc_text,
                      color: colors.warning,
                      size: 20,
                    ),
                  ),
                  title: _buildInvoiceTitle(invoiceNumber, buyerName, colors),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      date,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  trailing: Text(
                    '$amountPrefix${_formatCurrency(amount).substring(1)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: amountColor,
                    ),
                  ),
                  onTap: () {
                    final invoiceId = invoice['_id']?.toString();
                    if (invoiceId != null) {
                      context.push('/invoices/$invoiceId');
                    }
                  },
                ),
              );
            }).toList();

            return SliverToBoxAdapter(
              child: CupertinoListSection(
                margin: EdgeInsets.zero,
                additionalDividerMargin: 60, // This creates the line separators
                backgroundColor: CupertinoColors.systemBackground,
                topMargin: 0,
                children: listItems,
              ),
            );
          },
          loading: () => const BuildShimmerTile(),
          error: (error, stack) => BuildErrorState(
            onRefresh: () => invoiceNotifier.loadInvoices(),
            error: error,
          ),
        ),
      ),
    );
  }
}
