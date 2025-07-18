// lib/widgets/share_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'share_provider.dart';
import '../theme_provider.dart';

class ShareBottomSheet extends ConsumerStatefulWidget {
  final String invoiceId;
  final String voucherType; // 'Invoice', 'Quotation', 'PaymentReceipt'
  final List<String> defaultEmails;
  final String title;
  final Map<String, dynamic>? invoiceData;
  final String? templateId; // Optional template ID - can be null

  const ShareBottomSheet({
    Key? key,
    required this.invoiceId,
    required this.voucherType,
    required this.defaultEmails,
    required this.title,
    this.invoiceData,
    this.templateId,
  }) : super(key: key);

  @override
  ConsumerState<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends ConsumerState<ShareBottomSheet> {
  final TextEditingController _emailController = TextEditingController();
  final List<String> _emailList = [];
  bool _email = true;
  bool _sms = false;
  bool _whatsapp = false;
  bool _showOptions = false;
  String? _pdfUrl;
  String? _pdfError;
  bool _isPdfLoading = true;
  late PdfViewerController _pdfViewerController;

  // Local message state to avoid ScaffoldMessenger issues
  String? _localMessage;
  bool _isLocalMessageError = false;

  @override
  void initState() {
    super.initState();
    _emailList.addAll(widget.defaultEmails);
    _emailController.text = widget.defaultEmails.join(', ');
    _pdfViewerController = PdfViewerController();

    // Initialize PDF URL
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePdfUrl();
    });
  }

  void _initializePdfUrl() {
    try {
      setState(() {
        _isPdfLoading = true;
        _pdfError = null;
      });

      // Extract the PDF URL from invoice data
      _pdfUrl = _extractExistingPdfUrl();

      if (_pdfUrl == null || _pdfUrl!.isEmpty) {
        // Try to get PDF URL using the provider method
        final pdfUrl = ref
            .read(shareProvider.notifier)
            .getPdfUrl(
              invoiceId: widget.invoiceId,
              invoiceData: widget.invoiceData ?? {},
              documentType: widget.voucherType,
            );

        if (pdfUrl != null && pdfUrl.isNotEmpty) {
          _pdfUrl = pdfUrl;
        }
      }

      if (_pdfUrl == null || _pdfUrl!.isEmpty) {
        setState(() {
          _isPdfLoading = false;
          _pdfError =
              'PDF not available for this ${widget.voucherType.toLowerCase()}';
        });
      } else {
        print('PDF URL found: $_pdfUrl');
        setState(() {
          _isPdfLoading = false;
        });
      }
    } catch (e) {
      print('PDF URL initialization error: $e');
      setState(() {
        _isPdfLoading = false;
        _pdfError = 'Error loading PDF: ${e.toString()}';
      });
    }
  }

  String? _extractExistingPdfUrl() {
    final invoiceData = widget.invoiceData;
    if (invoiceData == null) return null;

    String? pdfUrl;

    switch (widget.voucherType) {
      case 'PaymentReceipt':
        // For payment receipts, try receipt PDF first, then fall back to invoice PDF
        pdfUrl = invoiceData['receiptPdfUrlLocation']?['Location'];
        if (pdfUrl == null || pdfUrl.toString().isEmpty) {
          pdfUrl = invoiceData['pdfUrlLocation']?['Location'];
        }
        break;
      case 'Invoice':
      case 'Quotation':
      default:
        // For invoices and quotations, use the main PDF URL
        pdfUrl = invoiceData['pdfUrlLocation']?['Location'];
        break;
    }

    if (pdfUrl != null && pdfUrl.toString().isNotEmpty) {
      print('Found existing PDF URL: $pdfUrl for ${widget.voucherType}');
      return pdfUrl.toString();
    }

    print('No PDF URL found in invoice data for ${widget.voucherType}');
    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _parseEmails(String text) {
    final emails = text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    setState(() {
      _emailList.clear();
      _emailList.addAll(emails);
    });
  }

  void _removeEmail(String email) {
    setState(() {
      _emailList.remove(email);
    });
  }

  void _showLocalMessage(String message, {bool isError = false}) {
    setState(() {
      _localMessage = message;
      _isLocalMessageError = isError;
    });

    // Clear message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _localMessage = null;
        });
      }
    });

    // Also try to show SnackBar if ScaffoldMessenger is available
    try {
      final scaffold = ScaffoldMessenger.maybeOf(context);
      if (scaffold != null) {
        scaffold.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError ? Colors.red : Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      print('Could not show SnackBar: $e');
    }
  }

  Future<void> _shareDocument() async {
    if (_emailList.isEmpty) {
      _showLocalMessage('Please add at least one email', isError: true);
      return;
    }

    // Check if template ID is available
    if (widget.templateId == null || widget.templateId!.trim().isEmpty) {
      _showLocalMessage(
        'No template configured for this ${widget.voucherType.toLowerCase()}. Please contact support.',
        isError: true,
      );
      return;
    }

    // Clear any existing messages
    ref.read(shareProvider.notifier).clearMessages();

    bool success = false;

    try {
      switch (widget.voucherType) {
        case 'Invoice':
          success = await ref
              .read(shareProvider.notifier)
              .shareInvoice(
                invoiceId: widget.invoiceId,
                emailList: _emailList,
                email: _email,
                sms: _sms,
                whatsapp: _whatsapp,
                templateId: widget.templateId,
              );
          break;
        case 'Quotation':
          success = await ref
              .read(shareProvider.notifier)
              .shareQuotation(
                invoiceId: widget.invoiceId,
                emailList: _emailList,
                email: _email,
                sms: _sms,
                whatsapp: _whatsapp,
                templateId: widget.templateId,
              );
          break;
        case 'PaymentReceipt':
          success = await ref
              .read(shareProvider.notifier)
              .sharePaymentReceipt(
                invoiceId: widget.invoiceId,
                emailList: _emailList,
                email: _email,
                sms: _sms,
                whatsapp: _whatsapp,
                templateId: widget.templateId,
              );
          break;
      }

      if (success) {
        final successMessage =
            ref.read(shareSuccessProvider) ??
            '${widget.voucherType} shared successfully!';
        _showLocalMessage(successMessage);

        // Close the dialog after a short delay to show the success message
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } else {
        final error = ref.read(shareErrorProvider);
        _showLocalMessage(
          error ?? 'Failed to share ${widget.voucherType}',
          isError: true,
        );
      }
    } catch (e) {
      _showLocalMessage('Error: $e', isError: true);
    }
  }

  Future<void> _openPdfExternally() async {
    if (_pdfUrl != null && _pdfUrl!.isNotEmpty) {
      try {
        final uri = Uri.parse(_pdfUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showLocalMessage('Cannot open PDF', isError: true);
        }
      } catch (e) {
        _showLocalMessage('Error opening PDF: $e', isError: true);
      }
    }
  }

  Future<void> _retryPdfLoading() async {
    _initializePdfUrl();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorProvider);
    final isLoading = ref.watch(shareLoadingProvider);
    final error = ref.watch(shareErrorProvider);

    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.95,
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
                  bottom: BorderSide(color: colors.border.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf,
                      color: colors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          'Preview and share ${widget.voucherType.toLowerCase()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_pdfUrl != null && _pdfUrl!.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.open_in_new, color: colors.primary),
                      onPressed: _openPdfExternally,
                      tooltip: 'Open externally',
                    ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Template ID Warning (if null)
            if (widget.templateId == null || widget.templateId!.trim().isEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No template configured for this ${widget.voucherType.toLowerCase()}. Sharing may not work properly.',
                        style: TextStyle(color: Colors.orange, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

            // Local Message Display
            if (_localMessage != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isLocalMessageError
                      ? colors.error.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isLocalMessageError
                        ? colors.error.withOpacity(0.3)
                        : Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isLocalMessageError
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: _isLocalMessageError ? colors.error : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _localMessage!,
                        style: TextStyle(
                          color: _isLocalMessageError
                              ? colors.error
                              : Colors.green,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 16,
                        color: _isLocalMessageError
                            ? colors.error
                            : Colors.green,
                      ),
                      onPressed: () => setState(() => _localMessage = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

            // PDF Preview Section
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border.withOpacity(0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildPdfPreviewContent(colors),
                ),
              ),
            ),

            // Share Options Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Quick Share Button (when options are collapsed)
                  if (!_showOptions)
                    Container(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _showOptions = true),
                        icon: const Icon(Icons.share, size: 20),
                        label: const Text('Share Options'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  // Expanded Options Panel
                  if (_showOptions) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.border.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Icon(
                                Icons.email,
                                color: colors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Share Settings',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: colors.textSecondary,
                                ),
                                onPressed: () =>
                                    setState(() => _showOptions = false),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Email Recipients
                          Text(
                            'Email Recipients *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Email input
                          TextField(
                            controller: _emailController,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Enter email addresses (comma separated)',
                              hintStyle: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 14,
                              ),
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
                                horizontal: 12,
                                vertical: 12,
                              ),
                              isDense: true,
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: colors.textSecondary,
                                size: 20,
                              ),
                            ),
                            onChanged: _parseEmails,
                            maxLines: 2,
                            minLines: 1,
                          ),

                          // Email chips
                          if (_emailList.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _emailList.map((email) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: colors.primary.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        email,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => _removeEmail(email),
                                        child: Icon(
                                          Icons.close,
                                          size: 16,
                                          color: colors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Share Methods
                          Text(
                            'Share Methods',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _email
                                        ? colors.primary.withOpacity(0.1)
                                        : colors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _email
                                          ? colors.primary
                                          : colors.border.withOpacity(0.3),
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () =>
                                        setState(() => _email = !_email),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.email,
                                          size: 16,
                                          color: _email
                                              ? colors.primary
                                              : colors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Email',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _email
                                                ? colors.primary
                                                : colors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _sms
                                        ? colors.primary.withOpacity(0.1)
                                        : colors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _sms
                                          ? colors.primary
                                          : colors.border.withOpacity(0.3),
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () => setState(() => _sms = !_sms),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.sms,
                                          size: 16,
                                          color: _sms
                                              ? colors.primary
                                              : colors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'SMS',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _sms
                                                ? colors.primary
                                                : colors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _whatsapp
                                        ? colors.primary.withOpacity(0.1)
                                        : colors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _whatsapp
                                          ? colors.primary
                                          : colors.border.withOpacity(0.3),
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () =>
                                        setState(() => _whatsapp = !_whatsapp),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.message,
                                          size: 16,
                                          color: _whatsapp
                                              ? colors.primary
                                              : colors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'WhatsApp',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _whatsapp
                                                ? colors.primary
                                                : colors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Error Display
                  if (error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colors.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: colors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              error,
                              style: TextStyle(
                                color: colors.error,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.textPrimary,
                            side: BorderSide(color: colors.border),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed:
                              (isLoading ||
                                  widget.templateId == null ||
                                  widget.templateId!.trim().isEmpty)
                              ? null
                              : _shareDocument,
                          icon: isLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.share, size: 18),
                          label: Text(
                            isLoading
                                ? 'Sharing...'
                                : widget.templateId == null ||
                                      widget.templateId!.trim().isEmpty
                                ? 'No Template'
                                : 'Share ${widget.voucherType}',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom padding
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfPreviewContent(WareozeColorScheme colors) {
    if (_isPdfLoading) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading PDF Preview...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we prepare your document',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_pdfError != null) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(Icons.error_outline, size: 48, color: colors.error),
            ),
            const SizedBox(height: 24),
            Text(
              'Preview Not Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _pdfError!,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _retryPdfLoading,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    side: BorderSide(color: colors.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
                if (_pdfUrl != null && _pdfUrl!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _openPdfExternally,
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Open PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    if (_pdfUrl != null && _pdfUrl!.isNotEmpty) {
      return Container(
        child: SfPdfViewer.network(
          _pdfUrl!,
          controller: _pdfViewerController,
          onDocumentLoaded: (details) {
            setState(() {
              _isPdfLoading = false;
            });
          },
          onDocumentLoadFailed: (details) {
            setState(() {
              _isPdfLoading = false;
              _pdfError = 'Failed to load PDF: ${details.error}';
            });
          },
        ),
      );
    }

    // Fallback when no PDF is available
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.picture_as_pdf_outlined,
              size: 48,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No PDF Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Document preview is not available for this ${widget.voucherType.toLowerCase()}',
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _retryPdfLoading,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
