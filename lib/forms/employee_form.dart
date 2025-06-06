import 'package:flutter/cupertino.dart';
import 'package:flutter_test_22/components/form_fields.dart';
import 'package:smooth_sheets/smooth_sheets.dart';
import 'package:flutter/material.dart';

void showEmployeeAddSheet(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    CupertinoModalSheetRoute(
      swipeDismissible: true,
      builder: (context) => const EmployeeAddSheet(),
    ),
  );
}

class EmployeeAddSheet extends StatefulWidget {
  const EmployeeAddSheet({super.key});

  @override
  State<EmployeeAddSheet> createState() => _EmployeeAddSheetState();
}

class _EmployeeAddSheetState extends State<EmployeeAddSheet> {
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
          title: Text('Success'),
          content: Text('Profile updated successfully!'),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
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
    return SheetKeyboardDismissible(
      dismissBehavior: const SheetKeyboardDismissBehavior.onDragDown(),
      child: Sheet(
        decoration: SheetDecorationBuilder(
          size: SheetSize.stretch,
          builder: (context, child) => ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColoredBox(
              color: CupertinoColors.systemGroupedBackground,
              child: child,
            ),
          ),
        ),
        child: SheetContentScaffold(
          backgroundColor: Colors.white,
          topBar: CupertinoNavigationBar(
            middle: const Text('New Employee'),
            backgroundColor: CupertinoColors.systemBackground,
            border: const Border(
              bottom: BorderSide(
                color: CupertinoColors.systemGrey4,
                width: 0.5,
              ),
            ),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _saveForm,
              child: const Text('Add'),
            ),
          ),
          body: SizedBox.expand(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsetsGeometry.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text('Code : #1024', style: TextStyle(fontSize: 15)),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
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
                    _buildSection(title: 'GENERAL DETAILS', [
                      FormFieldWidgets.buildSelectField(
                        'gender',
                        'Gender',
                        genderOptions,
                        isRequired: true,
                        onChanged: _updateFormData,
                        formData: formData,
                        validationErrors: validationErrors,
                      ),
                      FormFieldWidgets.buildDateField(
                        'dateOfBirth',
                        'Date of Birth',
                        isRequired: true,
                        context: context,
                        minimumDate: DateTime(1920),
                        maximumDate: DateTime.now().subtract(
                          Duration(days: 365 * 16),
                        ),
                        dateFormat: 'dd/MM/yyyy',
                        onChanged: _updateFormData,
                        formData: formData,
                        validationErrors: validationErrors,
                      ),
                      FormFieldWidgets.buildMultiSelectField(
                        'languages',
                        'Languages',
                        languageOptions,
                        onChanged: _updateFormData,
                        formData: formData,
                        validationErrors: validationErrors,
                        // context: context,
                      ),
                    ]),
                    _buildSection(title: 'CONTACT DETAILS', [
                      FormFieldWidgets.buildTextField(
                        'email',
                        'Email',
                        'email',
                        isRequired: true,
                        onChanged: _updateFormData,
                        formData: formData,
                        validationErrors: validationErrors,
                      ),
                      FormFieldWidgets.buildTextField(
                        'phone',
                        'Phone',
                        'phone',
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
                    SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    List<Widget> fields, {
    String title = '',
    bool compact = false,
  }) {
    return CupertinoListSection(
      header: title.isNotEmpty
          ? Transform.translate(
              offset: Offset(-4, 0), // Shifts text 20 pixels to the left
              child: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
      backgroundColor: CupertinoColors.systemGroupedBackground,
      dividerMargin: compact ? 0 : 100,
      margin: EdgeInsets.zero,
      topMargin: title.isNotEmpty ? 10 : 0,
      additionalDividerMargin: compact ? 0 : 30,
      children: fields,
    );
  }
}
