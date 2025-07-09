import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../apis/providers/inventory_provider.dart';
import '../theme_provider.dart';
import '../components/form_fields.dart';

class AdjustStockPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> inventory;

  const AdjustStockPage({Key? key, required this.inventory}) : super(key: key);

  @override
  ConsumerState<AdjustStockPage> createState() => _AdjustStockPageState();
}

class _AdjustStockPageState extends ConsumerState<AdjustStockPage> {
  final Map<String, dynamic> _formData = {};
  final Map<String, String> _validationErrors = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final currentStock = InventoryHelper.getCurrentStock(widget.inventory);
    _formData['itemName'] = InventoryHelper.getInventoryName(widget.inventory);
    _formData['currentStock'] = currentStock;
    _formData['finalStock'] = currentStock;
    _formData['isAdd'] = true; // Default to Add Stock
    _formData['quantity'] = '';
    _formData['remarks'] = '';
  }

  void _onChanged(String key, dynamic value) {
    setState(() {
      _formData[key] = value;
      _validationErrors.remove(key);

      // Calculate final stock when quantity changes
      if (key == 'quantity' || key == 'isAdd') {
        _calculateFinalStock();
      }
    });
  }

  void _calculateFinalStock() {
    final currentStock = _formData['currentStock'] as int;
    final quantity =
        int.tryParse(_formData['quantity']?.toString() ?? '0') ?? 0;
    final isAdd = _formData['isAdd'] as bool;

    if (isAdd) {
      _formData['finalStock'] = currentStock + quantity;
    } else {
      _formData['finalStock'] = currentStock - quantity;
    }
  }

  bool _validateForm() {
    _validationErrors.clear();

    if (_formData['quantity'] == null ||
        _formData['quantity'].toString().isEmpty) {
      _validationErrors['quantity'] = 'Quantity is required';
    } else {
      final quantity = int.tryParse(_formData['quantity'].toString());
      if (quantity == null || quantity <= 0) {
        _validationErrors['quantity'] = 'Please enter a valid quantity';
      }
    }

    return _validationErrors.isEmpty;
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) {
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);

    try {
      final inventoryId = widget.inventory['_id']?.toString();
      if (inventoryId == null) {
        throw Exception('Inventory ID not found');
      }

      final quantity = int.parse(_formData['quantity'].toString());
      final isAdd = _formData['isAdd'] as bool;
      final remarks = _formData['remarks']?.toString() ?? '';

      final result = await ref
          .read(inventoryProvider.notifier)
          .adjustInventoryStock(
            inventoryId: inventoryId,
            quantity: quantity,
            isAdd: isAdd,
            remarks: remarks,
          );

      if (result.isSuccess) {
        if (mounted) {
          // Show success dialog instead of SnackBar
          showDialog(
            context: context,
            barrierDismissible: false, // Prevent dismissing by tapping outside
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: Text('Success'),
                content: Text(
                  result.successMessage ?? 'Stock adjusted successfully',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(); // Close dialog
                      // Use a post-frame callback to avoid navigation conflicts
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          Navigator.of(
                            context,
                          ).pop(true); // Return to previous page with success
                        }
                      });
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        if (mounted) {
          // Show error dialog instead of SnackBar
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Error'),
                content: Text(result.errorMessage ?? 'Failed to adjust stock'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Show error dialog instead of SnackBar
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Error: ${e.toString()}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back, color: colors.textPrimary),
        ),
        title: Text(
          'Adjust Stock',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(CupertinoIcons.xmark, color: colors.textSecondary),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Item Name (Read-only)
                  FormFieldWidgets.buildTextField(
                    'itemName',
                    'Item Name',
                    'text',
                    context,
                    onChanged: _onChanged,
                    formData: _formData,
                    validationErrors: _validationErrors,
                    enabled: false,
                  ),

                  // Current Stock (Read-only)
                  FormFieldWidgets.buildTextField(
                    'currentStock',
                    'Current Stock',
                    'text',
                    context,
                    onChanged: _onChanged,
                    formData: _formData,
                    validationErrors: _validationErrors,
                    enabled: false,
                  ),

                  // Final Stock (Read-only)
                  FormFieldWidgets.buildTextField(
                    'finalStock',
                    'Final Stock',
                    'text',
                    context,
                    onChanged: _onChanged,
                    formData: _formData,
                    validationErrors: _validationErrors,
                    enabled: false,
                  ),

                  // Add/Reduce Stock Radio Buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () => _onChanged('isAdd', true),
                          child: Row(
                            children: [
                              Icon(
                                _formData['isAdd'] == true
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : CupertinoIcons.circle,
                                color: _formData['isAdd'] == true
                                    ? Colors.green
                                    : colors.textSecondary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Add Stock',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _onChanged('isAdd', false),
                          child: Row(
                            children: [
                              Icon(
                                _formData['isAdd'] == false
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : CupertinoIcons.circle,
                                color: _formData['isAdd'] == false
                                    ? Colors.green
                                    : colors.textSecondary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Reduce Stock',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quantity Input
                  FormFieldWidgets.buildTextField(
                    'quantity',
                    'Add Or Reduce Stock',
                    'number',
                    context,
                    onChanged: _onChanged,
                    formData: _formData,
                    validationErrors: _validationErrors,
                    isRequired: true,
                  ),

                  // Remarks Input
                  FormFieldWidgets.buildTextAreaField(
                    'remarks',
                    'Remarks(Optional)',
                    onChanged: _onChanged,
                    formData: _formData,
                    validationErrors: _validationErrors,
                    maxLines: 3,
                    minLines: 2,
                  ),
                ],
              ),
            ),
          ),

          // Save Button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
