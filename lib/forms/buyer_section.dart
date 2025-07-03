import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test_22/apis/providers/customer_provider.dart';

// Updated Buyer Selection Section Component - Now focused only on client selection
class BuyerSelectionSection extends ConsumerStatefulWidget {
  final Map<String, dynamic>? selectedClient;
  final Function(Map<String, dynamic>) onClientSelected;
  final String? validationError;
  final String? accountId;
  final bool showHeader;

  const BuyerSelectionSection({
    super.key,
    required this.selectedClient,
    required this.onClientSelected,
    this.validationError,
    this.accountId,
    this.showHeader = true,
  });

  @override
  ConsumerState<BuyerSelectionSection> createState() =>
      _BuyerSelectionSectionState();
}

class _BuyerSelectionSectionState extends ConsumerState<BuyerSelectionSection> {
  @override
  void initState() {
    super.initState();
    // Load customers when component initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomers();
    });
  }

  void _loadCustomers() {
    ref
        .read(customerListProvider.notifier)
        .loadCustomers(page: 0, refresh: true, accountId: widget.accountId);
  }

  void _showClientSelection(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => ClientSelectionSheet(
        onClientSelected: (client) {
          widget.onClientSelected(client);
        },
        selectedClientId: widget.selectedClient?['_id'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection(
      header: widget.showHeader
          ? Transform.translate(
              offset: const Offset(-4, 0),
              child: const Text(
                'BUYER',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.25,
                ),
              ),
            )
          : null,
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      margin: EdgeInsets.zero,
      topMargin: widget.showHeader ? 10 : 0,
      children: [
        if (widget.selectedClient == null)
          _buildSelectClientTile(context)
        else
          _buildSelectedClientTile(context),

        if (widget.validationError != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              widget.validationError!,
              style: const TextStyle(
                color: CupertinoColors.destructiveRed,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectClientTile(BuildContext context) {
    return CupertinoListTile(
      title: const Text('Select Client'),
      subtitle: const Text('Tap to choose a client'),
      leading: const Icon(CupertinoIcons.person_circle, size: 30),
      trailing: const Icon(CupertinoIcons.chevron_right),
      onTap: () => _showClientSelection(context),
    );
  }

  Widget _buildSelectedClientTile(BuildContext context) {
    final client = widget.selectedClient!;

    // Handle different possible field names for client data
    final clientName =
        client['name'] ??
        client['firstName'] ??
        client['fullName'] ??
        'Unknown Client';

    final clientEmail = client['email'] ?? client['emailAddress'] ?? 'No email';

    final clientPhone =
        client['phone'] ??
        client['whatsAppNumber'] ??
        client['mobile'] ??
        'No phone';

    final addressCount = client['addresses']?.length ?? 0;

    return CupertinoListTile(
      leadingSize: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      title: Text(
        clientName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // const SizedBox(height: 4),
          // Text(
          //   clientEmail,
          //   style: TextStyle(
          //     fontSize: 14,
          //     color: CupertinoColors.secondaryLabel.resolveFrom(context),
          //   ),
          // ),
          const SizedBox(height: 2),
          Text(
            clientPhone,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          if (addressCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$addressCount address${addressCount > 1 ? 'es' : ''} available',
                style: const TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.person_solid,
          color: CupertinoColors.systemBlue,
          size: 20,
        ),
      ),
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _showClientSelection(context),
        child: const Text('Change', style: TextStyle(fontSize: 14)),
      ),
    );
  }
}

// Enhanced Client Selection Sheet
class ClientSelectionSheet extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onClientSelected;
  final String? selectedClientId;

  const ClientSelectionSheet({
    super.key,
    required this.onClientSelected,
    this.selectedClientId,
  });

  @override
  ConsumerState<ClientSelectionSheet> createState() =>
      _ClientSelectionSheetState();
}

class _ClientSelectionSheetState extends ConsumerState<ClientSelectionSheet> {
  String searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreCustomers();
    }
  }

  void _loadMoreCustomers() {
    final customerState = ref.read(customerListProvider);
    customerState.whenData((data) {
      if (data.hasMore && !data.isLoadingMore) {
        ref
            .read(customerListProvider.notifier)
            .loadCustomers(
              page: data.currentPage + 1,
              searchQuery: searchQuery.isEmpty ? null : searchQuery,
            );
      }
    });
  }

  void _performSearch(String query) {
    setState(() {
      searchQuery = query;
    });

    // Debounce search to avoid too many API calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (searchQuery == query) {
        ref
            .read(customerListProvider.notifier)
            .loadCustomers(
              page: 0,
              refresh: true,
              searchQuery: query.isEmpty ? null : query,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final customerState = ref.watch(customerListProvider);

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
                    'Select Client',
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
              placeholder: 'Search clients...',
              onChanged: _performSearch,
            ),
          ),

          // Client List
          Expanded(
            child: customerState.when(
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 48,
                      color: CupertinoColors.destructiveRed,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading clients',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: CupertinoColors.secondaryLabel,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton.filled(
                      onPressed: () {
                        ref
                            .read(customerListProvider.notifier)
                            .loadCustomers(page: 0, refresh: true);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (customerData) {
                if (customerData.customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.person_2,
                          size: 55,
                          color: CupertinoColors.secondaryLabel,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty
                              ? 'No clients found'
                              : 'No matching clients',
                          style: const TextStyle(
                            color: CupertinoColors.secondaryLabel,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      CupertinoListSection(
                        backgroundColor: CupertinoColors.systemBackground
                            .resolveFrom(context),
                        margin: EdgeInsets.zero,
                        topMargin: 0,
                        children: customerData.customers.map((client) {
                          final isSelected =
                              client['_id'] == widget.selectedClientId;
                          final clientName = client['name'];
                          final clientEmail =
                              client['email'] ??
                              client['emailAddress'] ??
                              'No email';
                          final clientPhone =
                              client['phone'] ??
                              client['whatsAppNumber'] ??
                              client['mobile'] ??
                              'No phone';
                          final addressCount = client['addresses']?.length ?? 0;

                          return CupertinoListTile(
                            onTap: () {
                              widget.onClientSelected(client);
                              Navigator.pop(context);
                            },
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? CupertinoColors.systemBlue.withOpacity(
                                        0.2,
                                      )
                                    : CupertinoColors.systemGrey6.resolveFrom(
                                        context,
                                      ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isSelected
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : CupertinoIcons.person_solid,
                                color: isSelected
                                    ? CupertinoColors.systemBlue
                                    : CupertinoColors.secondaryLabel
                                          .resolveFrom(context),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              clientName,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? CupertinoColors.activeBlue
                                    : CupertinoColors.label,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$clientEmail • $clientPhone',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                                  ),
                                ),
                                if (addressCount > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.systemBlue
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '$addressCount address${addressCount > 1 ? 'es' : ''}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: CupertinoColors.systemBlue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      // Loading more indicator
                      if (customerData.isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: CupertinoActivityIndicator(),
                        ),
                    ],
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
