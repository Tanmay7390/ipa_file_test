import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:Wareozo/components/common.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:Wareozo/components/form_fields.dart';

void showInvoiceFormSheet(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    CupertinoModalSheetRoute(
      swipeDismissible: true,
      builder: (context) => const InvoiceFormSheet(),
    ),
  );
}

class InvoiceFormSheet extends StatefulWidget {
  const InvoiceFormSheet({super.key});

  @override
  State<InvoiceFormSheet> createState() => _InvoiceFormSheetState();
}

class _InvoiceFormSheetState extends State<InvoiceFormSheet> {
  final Map<String, dynamic> formData = {};
  final Map<String, String> validationErrors = {};

  final emailPattern = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
  final phonePattern = RegExp(r'^[6-9]\d{9}$');

  final genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final languageOptions = [
    'English',
    'Hindi',
    'Marathi',
    'Tamil',
    'Telugu',
    'Kannada',
    'Malayalam',
    'Bengali',
    'Gujarati',
    'Punjabi',
    'Odia',
    'Assamese',
  ];

  String _getInitials() {
    final f = formData['firstName']?.trim() ?? '';
    final l = formData['lastName']?.trim() ?? '';
    return (f.isNotEmpty ? f[0] : '') + (l.isNotEmpty ? l[0] : '');
  }

  void _updateFormData(String key, dynamic value) {
    setState(() {
      formData[key] = value;
      validationErrors.remove(key);
    });
  }

  bool _validateForm() {
    validationErrors.clear();
    void checkRequired(String key, String label) {
      if (formData[key]?.toString().trim().isEmpty ?? true) {
        validationErrors[key] = '$label is required';
      }
    }

    checkRequired('firstName', 'First name');
    checkRequired('lastName', 'Last name');
    checkRequired('gender', 'Gender');
    checkRequired('dateOfBirth', 'Date of birth');
    checkRequired('email', 'Email');
    checkRequired('phone', 'Phone number');
    checkRequired('address', 'Address');

    if (formData['email'] != null &&
        !emailPattern.hasMatch(formData['email'].toString().trim())) {
      validationErrors['email'] = 'Enter a valid email';
    }

    if (formData['phone'] != null &&
        !phonePattern.hasMatch(formData['phone'].toString().trim())) {
      validationErrors['phone'] = 'Enter a valid 10-digit phone number';
    }

    return validationErrors.isEmpty;
  }

  void _saveForm() {
    if (_validateForm()) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Success'),
          content: const Text('Invoice added successfully!'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context)
                ..pop()
                ..pop(),
            ),
          ],
        ),
      );
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text('New Invoice')),
      // SheetKeyboardDismissible(
      //   dismissBehavior: const SheetKeyboardDismissBehavior.onDragDown(),
      //   child: Sheet(
      //     decoration: SheetDecorationBuilder(
      //       size: SheetSize.stretch,
      //       builder: (context, child) {
      //         return ClipRRect(
      //           borderRadius: BorderRadius.circular(16),
      //           child: ColoredBox(
      //             color: CupertinoColors.systemGroupedBackground.resolveFrom(
      //               context,
      //             ),
      //             child: child,
      //           ),
      //         );
      //       },
      //     ),
      //     child: SheetContentScaffold(
      //       backgroundColor: Colors.transparent,
      //       topBar: CupertinoAppBar(
      //         title: const Text('New Invoice'),
      //         leading: CupertinoButton(
      //           onPressed: () => Navigator.pop(context),
      //           child: const Text('Cancel'),
      //         ),
      //         trailing: CupertinoButton(
      //           onPressed: _saveForm,
      //           child: const Text('Add'),
      //         ),
      //       ),
      //       body: SingleChildScrollView(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 120),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('Code : #1024', style: TextStyle(fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: FormFieldWidgets.buildAvatarField(
                    'profileImage',
                    '',
                    context: context,
                    onChanged: _updateFormData,
                    formData: formData,
                    validationErrors: validationErrors,
                    initials: _getInitials(),
                    size: 100,
                  ),
                ),
                Expanded(
                  child: _buildSection(compact: true, [
                    FormFieldWidgets.buildTextField(
                      'firstName',
                      'First Name',
                      'text',
                      context,
                      isRequired: true,
                      onChanged: _updateFormData,
                      formData: formData,
                      validationErrors: validationErrors,
                      compact: true,
                    ),
                    FormFieldWidgets.buildTextField(
                      'lastName',
                      'Last Name',
                      'text',
                      context,
                      isRequired: true,
                      onChanged: _updateFormData,
                      formData: formData,
                      validationErrors: validationErrors,
                      compact: true,
                    ),
                  ]),
                ),
              ],
            ),
            _buildSection([
              FormFieldWidgets.buildTextField(
                'invoiceNumber',
                'Invoice No',
                'text',
                context,
                isRequired: true,
                onChanged: _updateFormData,
                formData: formData,
                validationErrors: validationErrors,
              ),
              FormFieldWidgets.buildTextField(
                'paymentTerm',
                'Payment Term',
                'text',
                context,
                isRequired: true,
                onChanged: _updateFormData,
                formData: formData,
                validationErrors: validationErrors,
              ),
              FormFieldWidgets.buildDateField(
                'invoiceDate',
                'Date',
                isRequired: true,
                context: context,
                minimumDate: DateTime(1920),
                maximumDate: DateTime.now().subtract(
                  const Duration(days: 365 * 16),
                ),
                dateFormat: 'dd/MM/yyyy',
                onChanged: _updateFormData,
                formData: formData,
                validationErrors: validationErrors,
              ),
              FormFieldWidgets.buildDateField(
                'dueDate',
                'Due Date',
                isRequired: true,
                context: context,
                minimumDate: DateTime(1920),
                maximumDate: DateTime.now().subtract(
                  const Duration(days: 365 * 16),
                ),
                dateFormat: 'dd/MM/yyyy',
                onChanged: _updateFormData,
                formData: formData,
                validationErrors: validationErrors,
              ),
            ]),
            _buildSection(title: 'QUOTATION AND PO', [
              FormFieldWidgets.buildDateField(
                'quotationDate',
                'Quo. Date',
                isRequired: true,
                context: context,
                minimumDate: DateTime(1920),
                maximumDate: DateTime.now().subtract(
                  const Duration(days: 365 * 16),
                ),
                dateFormat: 'dd/MM/yyyy',
                onChanged: _updateFormData,
                formData: formData,
                validationErrors: validationErrors,
              ),
              FormFieldWidgets.buildTextField(
                'quotationNumber',
                'Quo. Number',
                'text',
                context,
                isRequired: true,
                onChanged: _updateFormData,
                formData: formData,
                validationErrors: validationErrors,
              ),
              FormFieldWidgets.buildDateField(
                'poDate',
                'PO Date',
                isRequired: true,
                context: context,
                minimumDate: DateTime(1920),
                maximumDate: DateTime.now().subtract(
                  const Duration(days: 365 * 16),
                ),
                dateFormat: 'dd/MM/yyyy',
                onChanged: _updateFormData,
                formData: formData,
                validationErrors: validationErrors,
              ),
              FormFieldWidgets.buildTextField(
                'poNumber',
                'PO Number',
                'text',
                context,
                isRequired: true,
                onChanged: _updateFormData,
                formData: formData,
                validationErrors: validationErrors,
              ),
            ]),
            _buildSection(title: 'CONTACT DETAILS', [
              FormFieldWidgets.buildTextField(
                'email',
                'Email',
                'email',
                context,
                isRequired: true,
                onChanged: _updateFormData,
                formData: formData,
                validationErrors: validationErrors,
              ),
              FormFieldWidgets.buildTextField(
                'phone',
                'Phone',
                'phone',
                context,
                isRequired: true,
                onChanged: _updateFormData,
                formData: formData,
                validationErrors: validationErrors,
              ),
              FormFieldWidgets.buildTextAreaField(
                'address',
                'Address',
                isRequired: true,
                onChanged: _updateFormData,
                formData: formData,
                validationErrors: validationErrors,
              ),
              FormFieldWidgets.buildSwitchField(
                'isActive',
                'Active',
                formData: formData,
                validationErrors: validationErrors,
                onChanged: _updateFormData,
              ),
            ]),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
    //   ),
    // );
  }

  Widget _buildSection(
    List<Widget> fields, {
    String title = '',
    bool compact = false,
  }) {
    return CupertinoListSection(
      header: title.isNotEmpty
          ? Transform.translate(
              offset: const Offset(-4, 0),
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.25,
                ),
              ),
            )
          : null,
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      dividerMargin: compact ? 0 : 100,
      margin: EdgeInsets.zero,
      topMargin: title.isNotEmpty ? 10 : 0,
      additionalDividerMargin: compact ? 0 : 30,
      children: fields,
    );
  }
}
