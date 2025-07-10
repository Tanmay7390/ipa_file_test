import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../apis/providers/employee_provider.dart';
import '../apis/providers/countries_states_currency_provider.dart';
import '../../theme_provider.dart';
import '../components/form_fields.dart';

// Employee form sections enum
enum EmployeeFormSection {
  personal,
  contact,
  addresses,
  family,
  education,
  employment,
  salary,
  compliance,
  attachments,
}

// Extension to get section display names
extension EmployeeFormSectionExtension on EmployeeFormSection {
  String get displayName {
    switch (this) {
      case EmployeeFormSection.personal:
        return 'Personal Information';
      case EmployeeFormSection.contact:
        return 'Contact Information';
      case EmployeeFormSection.addresses:
        return 'Addresses';
      case EmployeeFormSection.family:
        return 'Family & Dependents';
      case EmployeeFormSection.education:
        return 'Education';
      case EmployeeFormSection.employment:
        return 'Employment History';
      case EmployeeFormSection.salary:
        return 'Salary Information';
      case EmployeeFormSection.compliance:
        return 'Compliance Information';
      case EmployeeFormSection.attachments:
        return 'Attachments';
    }
  }

  IconData get icon {
    switch (this) {
      case EmployeeFormSection.personal:
        return CupertinoIcons.person;
      case EmployeeFormSection.contact:
        return CupertinoIcons.phone;
      case EmployeeFormSection.addresses:
        return CupertinoIcons.location;
      case EmployeeFormSection.family:
        return CupertinoIcons.group;
      case EmployeeFormSection.education:
        return CupertinoIcons.book;
      case EmployeeFormSection.employment:
        return CupertinoIcons.briefcase;
      case EmployeeFormSection.salary:
        return CupertinoIcons.money_dollar;
      case EmployeeFormSection.compliance:
        return CupertinoIcons.checkmark_shield;
      case EmployeeFormSection.attachments:
        return CupertinoIcons.doc;
    }
  }
}

class EmployeeSectionedFormPage extends ConsumerStatefulWidget {
  final String employeeId; // Required for updates only
  final EmployeeFormSection initialSection;

  const EmployeeSectionedFormPage({
    super.key,
    required this.employeeId,
    this.initialSection = EmployeeFormSection.personal,
  });

  @override
  ConsumerState<EmployeeSectionedFormPage> createState() =>
      _EmployeeSectionedFormPageState();
}

class _EmployeeSectionedFormPageState
    extends ConsumerState<EmployeeSectionedFormPage> {
  EmployeeFormSection currentSection = EmployeeFormSection.personal;
  Map<String, dynamic> formData = {};
  Map<String, String> validationErrors = {};
  bool isLoading = false;
  bool isInitialized = false;

  // Section-specific data lists
  List<Map<String, dynamic>> addresses = [];
  List<Map<String, dynamic>> emergencyPhones = [];
  List<Map<String, dynamic>> dependents = [];
  List<Map<String, dynamic>> education = [];
  List<Map<String, dynamic>> prevEmployment = [];
  List<Map<String, dynamic>> uniform = [];
  List<File> attachments = [];

  // Helper method to clean up nested objects to only include IDs
  Map<String, dynamic> _cleanDataForUpdate(Map<String, dynamic> data) {
    final cleanedData = Map<String, dynamic>.from(data);

    // Extract only IDs from nested objects
    if (cleanedData['account'] is Map) {
      cleanedData['account'] = cleanedData['account']['_id'];
    }

    if (cleanedData['client'] is Map) {
      cleanedData['client'] = cleanedData['client']['_id'];
    }

    if (cleanedData['createdBy'] is Map) {
      cleanedData['createdBy'] = cleanedData['createdBy']['_id'];
    }

    if (cleanedData['updatedBy'] is Map) {
      cleanedData['updatedBy'] = cleanedData['updatedBy']['_id'];
    }

    if (cleanedData['baseLocation'] is Map) {
      cleanedData['baseLocation'] = cleanedData['baseLocation']['_id'];
    }

    // Clean up addresses array
    if (cleanedData['addresses'] is List) {
      cleanedData['addresses'] = (cleanedData['addresses'] as List)
          .where(
            (addr) => addr['_id'] != null,
          ) // Only include existing addresses
          .map((addr) => addr['_id']) // Extract only the ObjectId
          .toList();
    }

    // Remove MongoDB-specific fields
    cleanedData.remove('createdAt');
    cleanedData.remove('updatedAt');
    cleanedData.remove('__v');

    return cleanedData;
  }

  // Store original employee data to preserve other sections
  Map<String, dynamic> originalEmployeeData = {};

  @override
  void initState() {
    super.initState();
    currentSection = widget.initialSection;
    _initializeForm();
  }

  @override
  void dispose() {
    FormFieldWidgets.disposeAllControllers();
    super.dispose();
  }

  Future<void> _initializeForm() async {
    await _loadEmployeeData();
    setState(() {
      isInitialized = true;
    });
  }

  Future<void> _loadEmployeeData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await ref
          .read(employeeActionsProvider)
          .getEmployee(widget.employeeId);

      if (response.success && response.data != null) {
        final employee = response.data!;

        // Store original data to preserve other sections
        originalEmployeeData = Map<String, dynamic>.from(employee);

        // Map employee data to form data
        formData = {
          'name': employee['name'] ?? '',
          'empId': employee['empId'] ?? '',
          'gender': employee['gender'] ?? '',
          'dob': employee['dob'] != null
              ? DateTime.parse(employee['dob'])
              : null,
          'personalEmail': employee['personalEmail'] ?? '',
          'businessEmail': employee['businessEmail'] ?? '',
          'primaryPhone': employee['primaryPhone'] ?? '',
          'alternatePhone': employee['alternatePhone'] ?? '',
          'alternatePhoneRelation': employee['alternatePhoneRelation'] ?? '',
          'fatherName': employee['fatherName'] ?? '',
          'motherName': employee['motherName'] ?? '',
          'isMarried': employee['isMarried'] ?? false,
          'marriageDate': employee['marriageDate'] != null
              ? DateTime.parse(employee['marriageDate'])
              : null,
          'spouseName': employee['spouseName'] ?? '',
          'spousePhone': employee['spousePhone'] ?? '',
          'languages': List<String>.from(employee['languages'] ?? []),
          'isPrevEmployment': employee['isPrevEmployment'] ?? false,
          'isCompliance': employee['isCompliance'] ?? false,
          'nomineeName': employee['nomineeName'] ?? '',
          'nomineeRelation': employee['nomineeRelation'] ?? '',
          'bankLinkPhone': employee['bankLinkPhone'] ?? '',
          'grossSalary': employee['salary']?.isNotEmpty == true
              ? employee['salary'][0]['grossSalary'] ?? ''
              : '',
          'ctc': employee['salary']?.isNotEmpty == true
              ? employee['salary'][0]['ctc'] ?? ''
              : '',
          'assessmentYear': employee['salary']?.isNotEmpty == true
              ? employee['salary'][0]['assessmentYear'] ?? ''
              : '',
          'dateOfJoining': employee['dateOfJoining'] != null
              ? DateTime.parse(employee['dateOfJoining'])
              : null,
          'dateofResign': employee['dateofResign'] != null
              ? DateTime.parse(employee['dateofResign'])
              : null,
          'reasonOfResign': employee['reasonOfResign'] ?? '',
          'isActive': employee['isActive'] ?? true,
          'photo': null,
          'signature': null,
        };

        // Handle photo URL if it exists and is a valid string URL
        if (employee['photo'] != null &&
            employee['photo'] is String &&
            employee['photo'].toString().isNotEmpty &&
            (employee['photo'].toString().startsWith('http://') ||
                employee['photo'].toString().startsWith('https://'))) {
          formData['photoUrl'] = employee['photo'];
        }

        // Remove any invalid photo data that might cause issues
        if (formData['photo'] != null && formData['photo'] is! File) {
          formData.remove('photo');
        }

        // Load addresses
        addresses = List<Map<String, dynamic>>.from(
          employee['addresses']?.map(
                (addr) => {
                  'id': addr['_id'],
                  'type': addr['type'],
                  'line1': addr['line1'] ?? '',
                  'line2': addr['line2'] ?? '',
                  'city': addr['city'] ?? '',
                  'state': addr['state'],
                  'country': addr['country'],
                  'code': addr['code'] ?? '',
                },
              ) ??
              [],
        );

        // Ensure we have at least present and permanent address entries
        if (addresses.isEmpty ||
            !addresses.any((a) => a['type'] == 'Present Address')) {
          addresses.add({
            'type': 'Present Address',
            'line1': '',
            'line2': '',
            'city': '',
            'state': null,
            'country': null,
            'code': '',
          });
        }
        if (!addresses.any((a) => a['type'] == 'Permanent Address')) {
          addresses.add({
            'type': 'Permanent Address',
            'line1': '',
            'line2': '',
            'city': '',
            'state': null,
            'country': null,
            'code': '',
          });
        }

        // Load other arrays
        emergencyPhones = List<Map<String, dynamic>>.from(
          employee['emergencyPhones'] ?? [],
        );
        dependents = List<Map<String, dynamic>>.from(
          employee['dependents'] ?? [],
        );
        education = List<Map<String, dynamic>>.from(
          employee['education'] ?? [],
        );
        prevEmployment = List<Map<String, dynamic>>.from(
          employee['prevEmployment'] ?? [],
        );
        uniform = List<Map<String, dynamic>>.from(employee['uniform'] ?? []);
      }
    } catch (e) {
      print('Error loading employee data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onFieldChanged(String key, dynamic value) {
    setState(() {
      formData[key] = value;
      // Clear validation error when field is modified
      validationErrors.remove(key);
    });
  }

  bool _validateCurrentSection() {
    validationErrors.clear();

    switch (currentSection) {
      case EmployeeFormSection.personal:
        if (formData['name']?.isEmpty ?? true) {
          validationErrors['name'] = 'Name is required';
        }
        if (formData['empId']?.isEmpty ?? true) {
          validationErrors['empId'] = 'Employee ID is required';
        }
        if (formData['gender']?.isEmpty ?? true) {
          validationErrors['gender'] = 'Gender is required';
        }
        if (formData['dob'] == null) {
          validationErrors['dob'] = 'Date of birth is required';
        }
        break;

      case EmployeeFormSection.contact:
        if (formData['primaryPhone']?.isEmpty ?? true) {
          validationErrors['primaryPhone'] = 'Primary phone is required';
        }
        if (formData['personalEmail']?.isEmpty ?? true) {
          validationErrors['personalEmail'] = 'Personal email is required';
        }
        break;

      case EmployeeFormSection.addresses:
        // Validate present address
        final presentAddr = addresses.firstWhere(
          (addr) => addr['type'] == 'Present Address',
          orElse: () => {},
        );
        if (presentAddr['line1']?.isEmpty ?? true) {
          validationErrors['presentAddressLine1'] =
              'Present address line 1 is required';
        }
        break;

      default:
        break;
    }

    return validationErrors.isEmpty;
  }

  Future<void> _updateSection() async {
    if (!_validateCurrentSection()) {
      setState(() {});
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      // Start with original employee data to preserve other sections
      final submitData = _cleanDataForUpdate(originalEmployeeData);

      // Update only the current section's data
      switch (currentSection) {
        case EmployeeFormSection.personal:
          submitData.addAll({
            'name': formData['name'],
            'empId': formData['empId'],
            'gender': formData['gender'],
            'dob': formData['dob']?.toIso8601String(),
            'fatherName': formData['fatherName'],
            'motherName': formData['motherName'],
            'languages': formData['languages'],
          });

          if (formData['photo'] != null && formData['photo'] is File) {
            submitData['photo'] = await MultipartFile.fromFile(
              (formData['photo'] as File).path,
              filename: 'photo.jpg',
            );
          }
          break;

        case EmployeeFormSection.contact:
          submitData.addAll({
            'personalEmail': formData['personalEmail'],
            'businessEmail': formData['businessEmail'],
            'primaryPhone': formData['primaryPhone'],
            'alternatePhone': formData['alternatePhone'],
            'alternatePhoneRelation': formData['alternatePhoneRelation'],
          });
          submitData['emergencyPhones'] = emergencyPhones;
          break;

        case EmployeeFormSection.addresses:
          // Only include addresses that have existing IDs
          final existingAddressIds = addresses
              .where((addr) => addr['id'] != null)
              .map((addr) => addr['id'])
              .toList();

          // Don't add addresses to submitData for FormData processing
          // Instead, handle addresses separately or use a different approach
          // For now, skip updating addresses until address API is implemented

          // TODO: Implement separate address update calls here
          // You should call address update API for each modified address
          break;

        case EmployeeFormSection.family:
          submitData.addAll({
            'isMarried': formData['isMarried'],
            'marriageDate': formData['marriageDate']?.toIso8601String(),
            'spouseName': formData['spouseName'],
            'spousePhone': formData['spousePhone'],
          });
          submitData['dependents'] = dependents;
          break;

        case EmployeeFormSection.education:
          submitData['education'] = education;
          break;

        case EmployeeFormSection.employment:
          submitData.addAll({'isPrevEmployment': formData['isPrevEmployment']});
          submitData['prevEmployment'] = prevEmployment;
          break;

        case EmployeeFormSection.salary:
          submitData['salary'] = [
            {
              'grossSalary': formData['grossSalary'] ?? '',
              'ctc': formData['ctc'] ?? '',
              'assessmentYear': formData['assessmentYear'] ?? '',
              'startDate': formData['dateOfJoining']?.toIso8601String(),
              'endDate': formData['dateofResign']?.toIso8601String(),
              'active': true,
            },
          ];
          submitData.addAll({
            'dateOfJoining': formData['dateOfJoining']?.toIso8601String(),
            'dateofResign': formData['dateofResign']?.toIso8601String(),
            'reasonOfResign': formData['reasonOfResign'],
          });
          break;

        case EmployeeFormSection.compliance:
          submitData.addAll({
            'isCompliance': formData['isCompliance'],
            'nomineeName': formData['nomineeName'],
            'nomineeRelation': formData['nomineeRelation'],
            'bankLinkPhone': formData['bankLinkPhone'],
            'isActive': formData['isActive'],
          });
          submitData['uniform'] = uniform;
          break;

        case EmployeeFormSection.attachments:
          if (formData['signature'] != null && formData['signature'] is File) {
            submitData['signature'] = await MultipartFile.fromFile(
              (formData['signature'] as File).path,
              filename: 'signature.jpg',
            );
          }
          break;
      }

      // Update employee
      final response = await ref
          .read(employeeActionsProvider)
          .updateEmployee(widget.employeeId, submitData);

      if (response.success) {
        // Refresh employee list
        ref.read(employeeListProvider.notifier).refresh();

        // Show success message and go back
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: Text('${currentSection.displayName} updated successfully'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pop(); // Go back to profile page
                },
              ),
            ],
          ),
        );
      } else {
        // Show error message
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(response.error ?? 'Failed to update employee'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error updating employee: $e');
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: const Text('An unexpected error occurred'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildSectionContent() {
    switch (currentSection) {
      case EmployeeFormSection.personal:
        return _buildPersonalSection();
      case EmployeeFormSection.contact:
        return _buildContactSection();
      case EmployeeFormSection.addresses:
        return _buildAddressesSection();
      case EmployeeFormSection.family:
        return _buildFamilySection();
      case EmployeeFormSection.education:
        return _buildEducationSection();
      case EmployeeFormSection.employment:
        return _buildEmploymentSection();
      case EmployeeFormSection.salary:
        return _buildSalarySection();
      case EmployeeFormSection.compliance:
        return _buildComplianceSection();
      case EmployeeFormSection.attachments:
        return _buildAttachmentsSection();
    }
  }

  Widget _buildPersonalSection() {
    return Column(
      children: [
        FormFieldWidgets.buildAvatarField(
          'photo',
          'Profile Photo',
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
          context: context,
          initials: formData['name']?.isNotEmpty == true
              ? formData['name'].toString().substring(0, 1).toUpperCase()
              : null,
          existingImageUrl: formData['photoUrl'],
        ),

        FormFieldWidgets.buildTextField(
          'name',
          'Full Name',
          'text',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
          isRequired: true,
        ),

        FormFieldWidgets.buildTextField(
          'empId',
          'Employee ID',
          'text',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
          isRequired: true,
        ),

        FormFieldWidgets.buildSelectField(
          'gender',
          'Gender',
          ['Male', 'Female', 'Other'],
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
          isRequired: true,
        ),

        FormFieldWidgets.buildDateField(
          'dob',
          'Date of Birth',
          context: context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
          isRequired: true,
          maximumDate: DateTime.now(),
        ),

        FormFieldWidgets.buildTextField(
          'fatherName',
          'Father\'s Name',
          'text',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        FormFieldWidgets.buildTextField(
          'motherName',
          'Mother\'s Name',
          'text',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        FormFieldWidgets.buildMultiSelectField(
          'languages',
          'Languages',
          [
            'English',
            'Hindi',
            'Marathi',
            'Tamil',
            'Telugu',
            'Gujarati',
            'Bengali',
            'Kannada',
            'Malayalam',
            'Punjabi',
          ],
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      children: [
        FormFieldWidgets.buildTextField(
          'personalEmail',
          'Personal Email',
          'email',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
          isRequired: true,
        ),

        FormFieldWidgets.buildTextField(
          'businessEmail',
          'Business Email',
          'email',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        FormFieldWidgets.buildTextField(
          'primaryPhone',
          'Primary Phone',
          'phone',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
          isRequired: true,
        ),

        FormFieldWidgets.buildTextField(
          'alternatePhone',
          'Alternate Phone',
          'phone',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        if (formData['alternatePhone']?.isNotEmpty == true)
          FormFieldWidgets.buildTextField(
            'alternatePhoneRelation',
            'Alternate Phone Relation',
            'text',
            context,
            onChanged: _onFieldChanged,
            formData: formData,
            validationErrors: validationErrors,
          ),

        _buildEmergencyContactsSection(),
      ],
    );
  }

  Widget _buildEmergencyContactsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Emergency Contacts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _addEmergencyContact,
                child: const Icon(CupertinoIcons.add, size: 20),
              ),
            ],
          ),

          ...emergencyPhones.asMap().entries.map((entry) {
            final index = entry.key;
            final contact = entry.value;

            return Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Contact ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _removeEmergencyContact(index),
                        child: const Icon(
                          CupertinoIcons.xmark,
                          size: 16,
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                    ],
                  ),

                  FormFieldWidgets.buildTextField(
                    'emergencyName_$index',
                    'Name',
                    'text',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        emergencyPhones[index]['name'] = value;
                      });
                    },
                    formData: {'emergencyName_$index': contact['name'] ?? ''},
                    validationErrors: {},
                    compact: true,
                  ),

                  FormFieldWidgets.buildTextField(
                    'emergencyPhone_$index',
                    'Phone',
                    'phone',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        emergencyPhones[index]['phone'] = value;
                      });
                    },
                    formData: {'emergencyPhone_$index': contact['phone'] ?? ''},
                    validationErrors: {},
                    compact: true,
                  ),

                  FormFieldWidgets.buildTextField(
                    'emergencyRelation_$index',
                    'Relation',
                    'text',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        emergencyPhones[index]['relation'] = value;
                      });
                    },
                    formData: {
                      'emergencyRelation_$index': contact['relation'] ?? '',
                    },
                    validationErrors: {},
                    compact: true,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _addEmergencyContact() {
    setState(() {
      emergencyPhones.add({'name': '', 'phone': '', 'relation': ''});
    });
  }

  void _removeEmergencyContact(int index) {
    setState(() {
      emergencyPhones.removeAt(index);
    });
  }

  Widget _buildAddressesSection() {
    return Column(
      children: addresses.map((address) {
        final index = addresses.indexOf(address);
        final type = address['type'];
        final prefix = type.toLowerCase().replaceAll(' ', '');

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemGrey4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              FormFieldWidgets.buildTextField(
                '${prefix}Line1',
                'Address Line 1',
                'text',
                context,
                onChanged: (key, value) {
                  setState(() {
                    address['line1'] = value;
                  });
                },
                formData: {'${prefix}Line1': address['line1'] ?? ''},
                validationErrors: type == 'Present Address'
                    ? {
                        'presentAddressLine1':
                            validationErrors['presentAddressLine1'] ?? '',
                      }
                    : {},
                isRequired: type == 'Present Address',
                compact: true,
              ),

              FormFieldWidgets.buildTextField(
                '${prefix}Line2',
                'Address Line 2',
                'text',
                context,
                onChanged: (key, value) {
                  setState(() {
                    address['line2'] = value;
                  });
                },
                formData: {'${prefix}Line2': address['line2'] ?? ''},
                validationErrors: {},
                compact: true,
              ),

              FormFieldWidgets.buildTextField(
                '${prefix}City',
                'City',
                'text',
                context,
                onChanged: (key, value) {
                  setState(() {
                    address['city'] = value;
                  });
                },
                formData: {'${prefix}City': address['city'] ?? ''},
                validationErrors: {},
                compact: true,
              ),

              // State and Country dropdowns would go here
              // You'll need to implement these using your countries_states_provider
              FormFieldWidgets.buildTextField(
                '${prefix}PinCode',
                'Pin Code',
                'number',
                context,
                onChanged: (key, value) {
                  setState(() {
                    address['code'] = value;
                  });
                },
                formData: {'${prefix}PinCode': address['code'] ?? ''},
                validationErrors: {},
                compact: true,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFamilySection() {
    return Column(
      children: [
        FormFieldWidgets.buildSwitchField(
          'isMarried',
          'Married',
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        if (formData['isMarried'] == true) ...[
          FormFieldWidgets.buildDateField(
            'marriageDate',
            'Marriage Date',
            context: context,
            onChanged: _onFieldChanged,
            formData: formData,
            validationErrors: validationErrors,
            maximumDate: DateTime.now(),
          ),

          FormFieldWidgets.buildTextField(
            'spouseName',
            'Spouse Name',
            'text',
            context,
            onChanged: _onFieldChanged,
            formData: formData,
            validationErrors: validationErrors,
          ),

          FormFieldWidgets.buildTextField(
            'spousePhone',
            'Spouse Phone',
            'phone',
            context,
            onChanged: _onFieldChanged,
            formData: formData,
            validationErrors: validationErrors,
          ),
        ],

        _buildDependentsSection(),
      ],
    );
  }

  Widget _buildDependentsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dependents',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _addDependent,
                child: const Icon(CupertinoIcons.add, size: 20),
              ),
            ],
          ),

          ...dependents.asMap().entries.map((entry) {
            final index = entry.key;
            final dependent = entry.value;

            return Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dependent ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _removeDependent(index),
                        child: const Icon(
                          CupertinoIcons.xmark,
                          size: 16,
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                    ],
                  ),

                  FormFieldWidgets.buildTextField(
                    'dependentName_$index',
                    'Name',
                    'text',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        dependents[index]['name'] = value;
                      });
                    },
                    formData: {'dependentName_$index': dependent['name'] ?? ''},
                    validationErrors: {},
                    compact: true,
                  ),

                  FormFieldWidgets.buildSelectField(
                    'dependentRelation_$index',
                    'Relation',
                    [
                      'Son',
                      'Daughter',
                      'Father',
                      'Mother',
                      'Brother',
                      'Sister',
                      'Other',
                    ],
                    onChanged: (key, value) {
                      setState(() {
                        dependents[index]['relation'] = value;
                      });
                    },
                    formData: {
                      'dependentRelation_$index': dependent['relation'] ?? '',
                    },
                    validationErrors: {},
                  ),

                  FormFieldWidgets.buildTextField(
                    'dependentAge_$index',
                    'Age',
                    'number',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        dependents[index]['age'] = value;
                      });
                    },
                    formData: {
                      'dependentAge_$index': dependent['age']?.toString() ?? '',
                    },
                    validationErrors: {},
                    compact: true,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _addDependent() {
    setState(() {
      dependents.add({'name': '', 'relation': '', 'age': ''});
    });
  }

  void _removeDependent(int index) {
    setState(() {
      dependents.removeAt(index);
    });
  }

  Widget _buildEducationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Education',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _addEducation,
                child: const Icon(CupertinoIcons.add, size: 20),
              ),
            ],
          ),

          ...education.asMap().entries.map((entry) {
            final index = entry.key;
            final edu = entry.value;

            return Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Education ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _removeEducation(index),
                        child: const Icon(
                          CupertinoIcons.xmark,
                          size: 16,
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                    ],
                  ),

                  FormFieldWidgets.buildTextField(
                    'educationCourse_$index',
                    'Course',
                    'text',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        education[index]['course'] = value;
                      });
                    },
                    formData: {'educationCourse_$index': edu['course'] ?? ''},
                    validationErrors: {},
                    compact: true,
                  ),

                  FormFieldWidgets.buildTextField(
                    'educationCollege_$index',
                    'College/Institute',
                    'text',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        education[index]['college'] = value;
                      });
                    },
                    formData: {'educationCollege_$index': edu['college'] ?? ''},
                    validationErrors: {},
                    compact: true,
                  ),

                  FormFieldWidgets.buildTextField(
                    'educationUniversity_$index',
                    'University',
                    'text',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        education[index]['university'] = value;
                      });
                    },
                    formData: {
                      'educationUniversity_$index': edu['university'] ?? '',
                    },
                    validationErrors: {},
                    compact: true,
                  ),

                  FormFieldWidgets.buildTextField(
                    'educationPercentage_$index',
                    'Percentage',
                    'number',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        education[index]['percentage'] = value;
                      });
                    },
                    formData: {
                      'educationPercentage_$index':
                          edu['percentage']?.toString() ?? '',
                    },
                    validationErrors: {},
                    compact: true,
                  ),

                  FormFieldWidgets.buildTextField(
                    'educationPassingYear_$index',
                    'Passing Year',
                    'number',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        education[index]['passing_year'] = value;
                      });
                    },
                    formData: {
                      'educationPassingYear_$index':
                          edu['passing_year']?.toString() ?? '',
                    },
                    validationErrors: {},
                    compact: true,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _addEducation() {
    setState(() {
      education.add({
        'course': '',
        'college': '',
        'university': '',
        'percentage': '',
        'passing_year': '',
      });
    });
  }

  void _removeEducation(int index) {
    setState(() {
      education.removeAt(index);
    });
  }

  Widget _buildEmploymentSection() {
    return Column(
      children: [
        FormFieldWidgets.buildSwitchField(
          'isPrevEmployment',
          'Has Previous Employment',
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        if (formData['isPrevEmployment'] == true)
          _buildPreviousEmploymentSection(),
      ],
    );
  }

  Widget _buildPreviousEmploymentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Previous Employment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _addPreviousEmployment,
                child: const Icon(CupertinoIcons.add, size: 20),
              ),
            ],
          ),

          ...prevEmployment.asMap().entries.map((entry) {
            final index = entry.key;
            final emp = entry.value;

            return Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Employment ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _removePreviousEmployment(index),
                        child: const Icon(
                          CupertinoIcons.xmark,
                          size: 16,
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                    ],
                  ),

                  FormFieldWidgets.buildTextField(
                    'empCompanyName_$index',
                    'Company Name',
                    'text',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        prevEmployment[index]['companyName'] = value;
                      });
                    },
                    formData: {
                      'empCompanyName_$index': emp['companyName'] ?? '',
                    },
                    validationErrors: {},
                    compact: true,
                  ),

                  FormFieldWidgets.buildTextField(
                    'empDesignation_$index',
                    'Designation',
                    'text',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        prevEmployment[index]['designation'] = value;
                      });
                    },
                    formData: {
                      'empDesignation_$index': emp['designation'] ?? '',
                    },
                    validationErrors: {},
                    compact: true,
                  ),

                  FormFieldWidgets.buildDateField(
                    'empStartDate_$index',
                    'Start Date',
                    context: context,
                    onChanged: (key, value) {
                      setState(() {
                        prevEmployment[index]['startDate'] = value
                            ?.toIso8601String();
                      });
                    },
                    formData: {
                      'empStartDate_$index': emp['startDate'] != null
                          ? DateTime.parse(emp['startDate'])
                          : null,
                    },
                    validationErrors: {},
                  ),

                  FormFieldWidgets.buildDateField(
                    'empEndDate_$index',
                    'End Date',
                    context: context,
                    onChanged: (key, value) {
                      setState(() {
                        prevEmployment[index]['endDate'] = value
                            ?.toIso8601String();
                      });
                    },
                    formData: {
                      'empEndDate_$index': emp['endDate'] != null
                          ? DateTime.parse(emp['endDate'])
                          : null,
                    },
                    validationErrors: {},
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _addPreviousEmployment() {
    setState(() {
      prevEmployment.add({
        'companyName': '',
        'designation': '',
        'startDate': null,
        'endDate': null,
      });
    });
  }

  void _removePreviousEmployment(int index) {
    setState(() {
      prevEmployment.removeAt(index);
    });
  }

  Widget _buildSalarySection() {
    return Column(
      children: [
        FormFieldWidgets.buildTextField(
          'grossSalary',
          'Gross Salary',
          'number',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        FormFieldWidgets.buildTextField(
          'ctc',
          'CTC',
          'number',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        FormFieldWidgets.buildTextField(
          'assessmentYear',
          'Assessment Year',
          'text',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        FormFieldWidgets.buildDateField(
          'dateOfJoining',
          'Date of Joining',
          context: context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        FormFieldWidgets.buildDateField(
          'dateofResign',
          'Date of Resignation',
          context: context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        if (formData['dateofResign'] != null)
          FormFieldWidgets.buildTextAreaField(
            'reasonOfResign',
            'Reason for Resignation',
            onChanged: _onFieldChanged,
            formData: formData,
            validationErrors: validationErrors,
          ),
      ],
    );
  }

  Widget _buildComplianceSection() {
    return Column(
      children: [
        FormFieldWidgets.buildSwitchField(
          'isCompliance',
          'Compliance Required',
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        FormFieldWidgets.buildTextField(
          'nomineeName',
          'Nominee Name',
          'text',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        FormFieldWidgets.buildTextField(
          'nomineeRelation',
          'Nominee Relation',
          'text',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        FormFieldWidgets.buildTextField(
          'bankLinkPhone',
          'Bank Linked Phone',
          'phone',
          context,
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        FormFieldWidgets.buildSwitchField(
          'isActive',
          'Active Employee',
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
        ),

        _buildUniformSection(),
      ],
    );
  }

  Widget _buildUniformSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Uniform',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _addUniform,
                child: const Icon(CupertinoIcons.add, size: 20),
              ),
            ],
          ),

          ...uniform.asMap().entries.map((entry) {
            final index = entry.key;
            final uniformItem = entry.value;

            return Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Uniform ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _removeUniform(index),
                        child: const Icon(
                          CupertinoIcons.xmark,
                          size: 16,
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                    ],
                  ),

                  FormFieldWidgets.buildTextField(
                    'uniformItem_$index',
                    'Item',
                    'text',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        uniform[index]['item'] = value;
                      });
                    },
                    formData: {'uniformItem_$index': uniformItem['item'] ?? ''},
                    validationErrors: {},
                    compact: true,
                  ),

                  FormFieldWidgets.buildTextField(
                    'uniformQuantity_$index',
                    'Quantity',
                    'number',
                    context,
                    onChanged: (key, value) {
                      setState(() {
                        uniform[index]['quantity'] = value;
                      });
                    },
                    formData: {
                      'uniformQuantity_$index':
                          uniformItem['quantity']?.toString() ?? '',
                    },
                    validationErrors: {},
                    compact: true,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _addUniform() {
    setState(() {
      uniform.add({'item': '', 'quantity': ''});
    });
  }

  void _removeUniform(int index) {
    setState(() {
      uniform.removeAt(index);
    });
  }

  Widget _buildAttachmentsSection() {
    return Column(
      children: [
        FormFieldWidgets.buildAvatarField(
          'signature',
          'Signature',
          onChanged: _onFieldChanged,
          formData: formData,
          validationErrors: validationErrors,
          context: context,
          size: 120,
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          child: const Text(
            'Additional document uploads can be handled here. You can extend this section to include specific document types like Aadhar, PAN, etc.',
            style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorProvider);

    if (!isInitialized || isLoading) {
      return CupertinoPageScaffold(
        backgroundColor: colors.background,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: colors.surface,
          middle: Text(
            'Update ${currentSection.displayName}',
            style: TextStyle(color: colors.textPrimary),
          ),
        ),
        child: Center(child: CupertinoActivityIndicator(color: colors.primary)),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surface,
        middle: Text(
          'Update ${currentSection.displayName}',
          style: TextStyle(color: colors.textPrimary),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: Icon(CupertinoIcons.back, color: colors.primary),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Section icon and title
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      currentSection.icon,
                      color: colors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSection.displayName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Update your ${currentSection.displayName.toLowerCase()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Section content
            Expanded(
              child: SingleChildScrollView(child: _buildSectionContent()),
            ),

            // Update button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  onPressed: isLoading ? null : _updateSection,
                  color: colors.primary,
                  child: isLoading
                      ? CupertinoActivityIndicator(color: CupertinoColors.white)
                      : Text(
                          'Update ${currentSection.displayName}',
                          style: const TextStyle(color: CupertinoColors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
