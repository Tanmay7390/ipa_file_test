// update_payment_info_form.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test_22/apis/providers/business_commonprofile_provider.dart';
import 'package:flutter_test_22/theme_provider.dart';
import 'package:flutter_test_22/components/form_fields.dart';
import 'dart:io';

class UpdatePaymentInfoForm extends ConsumerStatefulWidget {
  const UpdatePaymentInfoForm({Key? key}) : super(key: key);

  @override
  ConsumerState<UpdatePaymentInfoForm> createState() =>
      _UpdatePaymentInfoFormState();
}

class _UpdatePaymentInfoFormState extends ConsumerState<UpdatePaymentInfoForm> {
  Map<String, dynamic> formData = {};
  Map<String, String> validationErrors = {};
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    final businessProfile = ref.read(businessProfileProvider);
    final profile = businessProfile.profile;

    if (profile != null) {
      formData = {
        'gPayPhone': profile['gPayPhone'] ?? '',
        'gPayPhoneVerifiedFlag': profile['gPayPhoneVerifiedFlag'] ?? false,
        'upiId': profile['upiId'] ?? '',
        'qrCodeUrl': profile['qrCodeUrl'] ?? '',
        'qrCodeFile': null, // For new QR code file uploads
      };
    }
  }

  void _onFieldChanged(String key, dynamic value) {
    setState(() {
      formData[key] = value;
      // Clear validation error for this field when user starts typing
      if (validationErrors.containsKey(key)) {
        validationErrors.remove(key);
      }
    });
  }

  bool _validateForm() {
    validationErrors.clear();

    // Phone number validation
    if (formData['gPayPhone']?.isNotEmpty == true &&
        !_isValidPhoneNumber(formData['gPayPhone'])) {
      validationErrors['gPayPhone'] = 'Please enter a valid 10-digit phone number';
    }

    // UPI ID validation
    if (formData['upiId']?.isNotEmpty == true &&
        !_isValidUPIId(formData['upiId'])) {
      validationErrors['upiId'] = 'Please enter a valid UPI ID (e.g., name@upi)';
    }

    // At least one payment method should be provided
    if ((formData['gPayPhone']?.isEmpty ?? true) &&
        (formData['upiId']?.isEmpty ?? true) &&
        (formData['qrCodeUrl']?.isEmpty ?? true) &&
        formData['qrCodeFile'] == null) {
      validationErrors['general'] = 'Please provide at least one payment method';
    }

    setState(() {});
    return validationErrors.isEmpty;
  }

  bool _isValidPhoneNumber(String phone) {
    // Remove any non-digit characters and check if it's 10 digits
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    return RegExp(r'^\d{10}$').hasMatch(cleanPhone);
  }

  bool _isValidUPIId(String upiId) {
    // Basic UPI ID validation pattern
    return RegExp(r'^[\w\.-]+@[\w\.-]+$').hasMatch(upiId);
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final businessProfileHelper = ref.read(businessProfileHelperProvider);
      
      // Prepare payment data
      Map<String, dynamic> paymentData = {};
      
      if (formData['gPayPhone']?.isNotEmpty == true) {
        paymentData['gPayPhone'] = formData['gPayPhone'];
      }
      
      if (formData['gPayPhoneVerifiedFlag'] != null) {
        paymentData['gPayPhoneVerifiedFlag'] = formData['gPayPhoneVerifiedFlag'];
      }
      
      if (formData['upiId']?.isNotEmpty == true) {
        paymentData['upiId'] = formData['upiId'];
      }
      
      // For QR code file upload, you would typically need to:
      // 1. Upload the file to your server/cloud storage
      // 2. Get the URL back
      // 3. Include the URL in the payment data
      // For now, we'll just include the existing URL if no new file is selected
      if (formData['qrCodeFile'] != null) {
        // TODO: Implement file upload logic here
        // paymentData['qrCodeUrl'] = await uploadQRCodeFile(formData['qrCodeFile']);
        _showErrorDialog('QR Code file upload is not implemented yet. Please use the existing QR code or contact support.');
        setState(() {
          isSubmitting = false;
        });
        return;
      } else if (formData['qrCodeUrl']?.isNotEmpty == true) {
        paymentData['qrCodeUrl'] = formData['qrCodeUrl'];
      }

      final success = await businessProfileHelper.updatePaymentInfo(paymentData);

      if (success) {
        _showSuccessDialog();
      } else {
        final error = businessProfileHelper.error;
        _showErrorDialog(error ?? 'Failed to update payment information');
      }
    } catch (e) {
      _showErrorDialog('An unexpected error occurred: $e');
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: const Text('Payment information updated successfully!'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _verifyPhoneNumber() {
    if (formData['gPayPhone']?.isEmpty ?? true) {
      _showErrorDialog('Please enter a phone number first');
      return;
    }

    if (!_isValidPhoneNumber(formData['gPayPhone'])) {
      _showErrorDialog('Please enter a valid 10-digit phone number');
      return;
    }

    // TODO: Implement phone verification logic here
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Phone Verification'),
        content: const Text('Phone verification feature is not implemented yet. Please contact support for manual verification.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodePreview() {
    final colors = ref.watch(colorProvider);
    
    if (formData['qrCodeFile'] != null) {
      return Container(
        height: 150,
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            formData['qrCodeFile'],
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (formData['qrCodeUrl']?.isNotEmpty == true) {
      return Container(
        height: 150,
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            formData['qrCodeUrl'],
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CupertinoActivityIndicator(),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: colors.error.withOpacity(0.1),
                child: Center(
                  child: Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    color: colors.error,
                    size: 32,
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      return Container(
        height: 150,
        width: 150,
        decoration: BoxDecoration(
          color: colors.border.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.qrcode,
                color: colors.textSecondary,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'No QR Code',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.25,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(colorProvider);
    final businessProfile = ref.watch(businessProfileProvider);

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: colors.surface,
        middle: Text(
          'Update Payment Info',
          style: TextStyle(
            color: colors.textPrimary,
            fontFamily: 'SF Pro Display',
            letterSpacing: 0.25,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(
            CupertinoIcons.back,
            color: colors.primary,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: isSubmitting || businessProfile.isUpdating ? null : _submitForm,
          child: isSubmitting || businessProfile.isUpdating
              ? CupertinoActivityIndicator()
              : Text(
                  'Save',
                  style: TextStyle(
                    color: colors.primary,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // General validation error
              if (validationErrors.containsKey('general'))
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.error.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        color: colors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          validationErrors['general']!,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.error,
                            fontFamily: 'SF Pro Display',
                            letterSpacing: 0.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Google Pay Section
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colors.border.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'GOOGLE PAY',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                          letterSpacing: 0.5,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ),
                    FormFieldWidgets.buildTextField(
                      'gPayPhone',
                      'Phone Number',
                      'phone',
                      context,
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                    ),
                    Container(
                      height: 0.5,
                      color: colors.border,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6.5, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'SF Pro Display',
                                    letterSpacing: 0.25,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                formData['gPayPhoneVerifiedFlag'] == true
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : CupertinoIcons.xmark_circle,
                                color: formData['gPayPhoneVerifiedFlag'] == true
                                    ? CupertinoColors.systemGreen
                                    : colors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formData['gPayPhoneVerifiedFlag'] == true ? 'Verified' : 'Not Verified',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'SF Pro Display',
                                  letterSpacing: 0.25,
                                  color: formData['gPayPhoneVerifiedFlag'] == true
                                      ? CupertinoColors.systemGreen
                                      : colors.error,
                                ),
                              ),
                            ],
                          ),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(8),
                            onPressed: _verifyPhoneNumber,
                            child: Text(
                              'Verify',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'SF Pro Display',
                                letterSpacing: 0.25,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // UPI Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colors.border.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'UPI PAYMENT',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                          letterSpacing: 0.5,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ),
                    FormFieldWidgets.buildTextField(
                      'upiId',
                      'UPI ID',
                      'text',
                      context,
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                    ),
                  ],
                ),
              ),

              // QR Code Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colors.border.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'QR CODE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                          letterSpacing: 0.5,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ),
                    FormFieldWidgets.buildAvatarField(
                      'qrCodeFile',
                      'QR Code Image',
                      onChanged: _onFieldChanged,
                      formData: formData,
                      validationErrors: validationErrors,
                      context: context,
                      size: 150,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Current QR Code:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                          fontFamily: 'SF Pro Display',
                          letterSpacing: 0.25,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildQRCodePreview(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Information Note
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      CupertinoIcons.info_circle,
                      color: colors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                              fontFamily: 'SF Pro Display',
                              letterSpacing: 0.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This payment information will be used for receiving payments from customers. Please ensure all details are accurate and up-to-date.',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.textSecondary,
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

              const SizedBox(height: 100), // Extra space for better scrolling
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    FormFieldWidgets.disposeAllControllers();
    super.dispose();
  }
}