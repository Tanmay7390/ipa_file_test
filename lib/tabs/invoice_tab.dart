import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colors.textSecondary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Expense analysis',
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
              const SizedBox(height: 16),
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
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatCurrency(totalAmount),
                    style: TextStyle(
                      fontSize: 28,
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
              const SizedBox(height: 16),
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
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
    final invoicePrefix = '[$invoiceNumber] ';

    // Simple logic: if buyer name is longer than 25 characters, split it
    if (buyerName.length > 25) {
      final words = buyerName.split(' ');
      if (words.length > 1) {
        final halfIndex = (words.length / 2).ceil();
        final firstHalf = words.take(halfIndex).join(' ');
        final secondHalf = words.skip(halfIndex).join(' ');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$invoicePrefix$firstHalf',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              secondHalf.length > 20
                  ? '${secondHalf.substring(0, 20)}...'
                  : secondHalf,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      }
    }

    // Default: show in single line with ellipsis if needed
    return Text(
      '$invoicePrefix$buyerName',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      maxLines: 2,
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
        heading: 'Invoices',
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
              // Navigate to add form based on selected segment
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

            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final invoice = invoices[index];
                final String invoiceNumber =
                    invoice['invoiceNumber']?.toString() ?? '';
                final String buyerName =
                    invoice['buyer']?['name']?.toString() ?? 'Unknown Buyer';
                final String date = _formatDate(invoice['date']?.toString());
                final double amount =
                    double.tryParse(invoice['amount']?.toString() ?? '0') ??
                    0.0;
                final String status = invoice['status']?.toString() ?? 'DRAFT';

                // Determine amount color based on status or amount
                Color amountColor = colors.error;
                String amountPrefix = '- ';

                if (status == 'PAID' || amount > 0) {
                  amountColor = colors.success;
                  amountPrefix = '+ ';
                }

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border, width: 0.5),
                  ),
                  child: CupertinoListTile(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
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
                      // Navigate to invoice details using GoRouter
                      final invoiceId = invoice['_id']?.toString();
                      if (invoiceId != null) {
                        context.push('/invoices/$invoiceId');
                      }
                    },
                  ),
                );
              }, childCount: invoices.length),
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
