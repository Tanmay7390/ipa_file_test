// lib/forms/subcategory_form.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Wareozo/components/form_fields.dart';
import 'package:Wareozo/apis/providers/category_provider.dart';

class SubCategoryForm extends ConsumerStatefulWidget {
  final String categoryId;
  final Map<String, dynamic>? subCategory;

  const SubCategoryForm({
    super.key,
    required this.categoryId,
    this.subCategory,
  });

  @override
  ConsumerState<SubCategoryForm> createState() => _SubCategoryFormState();
}

class _SubCategoryFormState extends ConsumerState<SubCategoryForm> {
  final Map<String, dynamic> _formData = {};
  final Map<String, String> _validationErrors = {};
  bool _isSubmitting = false;

  bool get _isEditing => widget.subCategory != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    // Clean up controllers
    FormFieldWidgets.disposeController('subcategory_name');
    FormFieldWidgets.disposeController('subcategory_alias');
    super.dispose();
  }

  void _initializeForm() {
    if (_isEditing) {
      _formData['name'] = widget.subCategory!['name']?.toString() ?? '';
      _formData['alias'] = widget.subCategory!['alias']?.toString() ?? '';
    } else {
      _formData['name'] = '';
      _formData['alias'] = '';
    }
  }

  void _onChanged(String key, dynamic value) {
    setState(() {
      _formData[key] = value;
      // Clear validation error when user starts typing
      if (_validationErrors.containsKey(key)) {
        _validationErrors.remove(key);
      }
    });
  }

  bool _validateForm() {
    _validationErrors.clear();

    // Validate name
    final name = _formData['name']?.toString().trim() ?? '';
    if (name.isEmpty) {
      _validationErrors['name'] = 'Sub-category name is required';
    } else if (name.length < 2) {
      _validationErrors['name'] =
          'Sub-category name must be at least 2 characters';
    } else if (name.length > 50) {
      _validationErrors['name'] =
          'Sub-category name must be less than 50 characters';
    }

    // Validate alias (optional)
    final alias = _formData['alias']?.toString().trim() ?? '';
    if (alias.isNotEmpty && alias.length > 30) {
      _validationErrors['alias'] = 'Alias must be less than 30 characters';
    }

    return _validationErrors.isEmpty;
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) {
      setState(() {});
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final name = _formData['name']?.toString().trim() ?? '';
      final alias = _formData['alias']?.toString().trim();

      bool success;
      if (_isEditing) {
        success = await ref
            .read(categoryProvider.notifier)
            .updateSubCategory(
              subCategoryId: widget.subCategory!['_id'],
              name: name,
              categoryId: widget.categoryId,
              alias: alias?.isNotEmpty == true ? alias : null,
            );
      } else {
        success = await ref
            .read(categoryProvider.notifier)
            .createSubCategory(
              name: name,
              categoryId: widget.categoryId,
              alias: alias?.isNotEmpty == true ? alias : null,
            );
      }

      if (success && mounted) {
        Navigator.of(context).pop();
        _showSuccessMessage();
      } else {
        setState(() {
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showErrorMessage('An unexpected error occurred');
    }
  }

  void _showSuccessMessage() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          _isEditing ? 'Sub-Category Updated' : 'Sub-Category Created',
        ),
        content: Text(
          _isEditing
              ? 'Sub-category has been updated successfully'
              : 'Sub-category has been created successfully',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getParentCategoryName() {
    final categories = ref.read(categoryProvider).categories;
    final parentCategory = categories.firstWhere(
      (cat) => cat['_id'] == widget.categoryId,
      orElse: () => {'name': 'Unknown Category'},
    );
    return parentCategory['name']?.toString() ?? 'Unknown Category';
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.systemGrey5,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: _isSubmitting
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemBlue,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.25,
                    ),
                  ),
                ),
                Text(
                  _isEditing ? 'Edit Sub-Category' : 'Add Sub-Category',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.25,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting
                      ? const CupertinoActivityIndicator()
                      : Text(
                          _isEditing ? 'Update' : 'Create',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SF Pro Display',
                            letterSpacing: 0.25,
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Form content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Parent category info
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            CupertinoIcons.folder_fill,
                            color: CupertinoColors.systemBlue,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Parent Category',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.systemGrey,
                                  fontFamily: 'SF Pro Display',
                                  letterSpacing: 0.25,
                                ),
                              ),
                              Text(
                                _getParentCategoryName(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'SF Pro Display',
                                  letterSpacing: 0.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Error display
                  if (categoryState.error != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: CupertinoColors.systemRed.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.exclamationmark_circle,
                            color: CupertinoColors.systemRed,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              categoryState.error!,
                              style: const TextStyle(
                                color: CupertinoColors.systemRed,
                                fontSize: 14,
                                fontFamily: 'SF Pro Display',
                                letterSpacing: 0.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (categoryState.error != null) const SizedBox(height: 20),

                  // Form fields
                  CupertinoListSection(
                    backgroundColor: CupertinoColors.systemBackground,
                    margin: EdgeInsets.zero,
                    topMargin: 0,
                    additionalDividerMargin: 30,
                    children: [
                      // Sub-category name field
                      FormFieldWidgets.buildTextField(
                        'name',
                        'Sub-Category Name',
                        'text',
                        context,
                        onChanged: _onChanged,
                        formData: _formData,
                        validationErrors: _validationErrors,
                        isRequired: true,
                      ),

                      // Sub-category alias field
                      FormFieldWidgets.buildTextField(
                        'alias',
                        'Alias (Optional)',
                        'text',
                        context,
                        onChanged: _onChanged,
                        formData: _formData,
                        validationErrors: _validationErrors,
                        isRequired: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Form instructions
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.info_circle,
                              color: CupertinoColors.systemOrange,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sub-Category Information',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.systemOrange,
                                fontFamily: 'SF Pro Display',
                                letterSpacing: 0.25,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Sub-category name is required and will be used to further categorize items\n'
                          '• Alias is optional and can be used as a short code or abbreviation\n'
                          '• Sub-categories help organize inventory within the parent category',
                          style: TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.systemOrange.withOpacity(
                              0.8,
                            ),
                            fontFamily: 'SF Pro Display',
                            letterSpacing: 0.25,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
