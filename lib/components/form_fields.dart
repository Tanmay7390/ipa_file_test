import 'package:flutter/cupertino.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import 'dart:io';

/// A collection of reusable form field widgets with Cupertino design
class FormFieldWidgets {
  /// Builds an avatar photo selection field with profile picture display
  static Widget buildAvatarField(
    String key,
    String label, {
    required Function(String, dynamic) onChanged,
    required Map<String, dynamic> formData,
    required Map<String, String> validationErrors,
    required BuildContext context,
    String? initials,
    double size = 100,
    bool isRequired = false,
  }) {
    bool hasError = validationErrors.containsKey(key);
    String required = isRequired ? '*' : '';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                '$label $required',
                style: TextStyle(
                  fontSize: 17,
                  color: hasError
                      ? CupertinoColors.systemRed
                      : CupertinoColors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Center(
            child: PullDownButton(
              itemBuilder: (context) => [
                PullDownMenuItem(
                  title: 'Open Camera',
                  icon: CupertinoIcons.camera,
                  onTap: () =>
                      _pickImage(context, key, onChanged, ImageSource.camera),
                ),
                PullDownMenuItem(
                  title: 'Open Gallery',
                  icon: CupertinoIcons.photo,
                  onTap: () =>
                      _pickImage(context, key, onChanged, ImageSource.gallery),
                ),
                PullDownMenuItem(
                  title: 'Choose from Files',
                  icon: CupertinoIcons.folder,
                  onTap: () => _pickImageFromFiles(context, key, onChanged),
                ),
                if (formData[key] != null)
                  PullDownMenuItem(
                    title: 'Remove Photo',
                    icon: CupertinoIcons.trash,
                    isDestructive: true,
                    onTap: () => onChanged(key, null),
                  ),
              ],
              buttonBuilder: (context, showMenu) => GestureDetector(
                onTap: showMenu,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasError
                        ? CupertinoColors.systemRed.withOpacity(0.1)
                        : CupertinoColors.systemGrey6,
                    border: hasError
                        ? Border.all(color: CupertinoColors.systemRed, width: 2)
                        : null,
                    image: formData[key] != null
                        ? DecorationImage(
                            image: FileImage(formData[key]),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: formData[key] == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (initials != null && initials.isNotEmpty)
                              Text(
                                initials,
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: size * 0.24,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else
                              Icon(
                                CupertinoIcons.camera,
                                size: size * 0.3,
                                color: CupertinoColors.systemGrey,
                              ),
                            if (initials == null || initials.isEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'Add Photo',
                                  style: TextStyle(
                                    color: CupertinoColors.systemGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        )
                      : null,
                ),
              ),
            ),
          ),
          if (hasError && validationErrors[key] != null)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                validationErrors[key]!,
                style: TextStyle(
                  color: CupertinoColors.systemRed,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  /// Private helper method to pick image from camera or gallery
  static Future<void> _pickImage(
    BuildContext context,
    String key,
    Function(String, dynamic) onChanged,
    ImageSource source,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        onChanged(key, File(image.path));
      }
    } catch (e) {
      _showErrorDialog(context, 'Failed to pick image');
    }
  }

  /// Private helper method to pick image from files
  static Future<void> _pickImageFromFiles(
    BuildContext context,
    String key,
    Function(String, dynamic) onChanged,
  ) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        onChanged(key, File(result.files.single.path!));
      }
    } catch (e) {
      _showErrorDialog(context, 'Failed to pick image from files');
    }
  }

  /// Private helper method to show error dialog
  static void _showErrorDialog(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Builds a standard text field with optional validation styling
  static Widget buildTextField(
    String key,
    String label,
    String type, {
    required Function(String, dynamic) onChanged,
    required Map<String, dynamic> formData,
    required Map<String, String> validationErrors,
    bool isRequired = false,
    bool compact = false,
  }) {
    bool hasError = validationErrors.containsKey(key);
    String required = isRequired ? '*' : '';

    return Container(
      padding: compact
          ? EdgeInsets.symmetric(horizontal: 2, vertical: 16)
          : EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!compact)
                SizedBox(
                  width: 100,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      color: CupertinoColors.black,
                    ),
                  ),
                ),
              if (!compact) SizedBox(width: 16),
              Expanded(
                child: CupertinoTextField(
                  onChanged: (value) => onChanged(key, value),
                  placeholder: 'Enter $label $required',
                  placeholderStyle: TextStyle(
                    color: hasError
                        ? CupertinoColors.systemRed
                        : CupertinoColors.systemGrey,
                  ),
                  decoration: BoxDecoration(),
                  prefix: type == 'phone' ? Text('+91  ') : null,
                  suffix: type == 'email' ? Text('@gmail.com') : null,
                  padding: EdgeInsets.zero,
                  style: TextStyle(fontSize: 17, color: CupertinoColors.black),
                  keyboardType: type == 'phone'
                      ? TextInputType.phone
                      : type == 'email'
                      ? TextInputType.emailAddress
                      : TextInputType.text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a multi-line text area field
  static Widget buildTextAreaField(
    String key,
    String label, {
    required Function(String, dynamic) onChanged,
    required Map<String, dynamic> formData,
    required Map<String, String> validationErrors,
    bool isRequired = false,
    int maxLines = 4,
    int minLines = 3,
  }) {
    bool hasError = validationErrors.containsKey(key);
    String required = isRequired ? '*' : '';

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 17, color: CupertinoColors.black),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: CupertinoTextField(
                  onChanged: (value) => onChanged(key, value),
                  placeholder: 'Enter $label $required',
                  placeholderStyle: TextStyle(
                    color: hasError
                        ? CupertinoColors.systemRed
                        : CupertinoColors.systemGrey,
                  ),
                  decoration: BoxDecoration(),
                  padding: EdgeInsets.zero,
                  style: TextStyle(fontSize: 17, color: CupertinoColors.black),
                  maxLines: maxLines,
                  minLines: minLines,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a single-select dropdown field
  static Widget buildSelectField(
    String key,
    String label,
    List<String> options, {
    required Function(String, dynamic) onChanged,
    required Map<String, dynamic> formData,
    required Map<String, String> validationErrors,
    bool isRequired = false,
  }) {
    bool hasError = validationErrors.containsKey(key);
    String required = isRequired ? '*' : '';

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 17, color: CupertinoColors.black),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: PullDownButton(
                  itemBuilder: (context) => options
                      .map(
                        (option) => PullDownMenuItem.selectable(
                          title: option,
                          selected: formData[key] == option,
                          onTap: () => onChanged(key, option),
                        ),
                      )
                      .toList(),
                  buttonBuilder: (context, showMenu) => CupertinoButton(
                    onPressed: showMenu,
                    padding: EdgeInsets.zero,
                    minimumSize: Size(0, 0),
                    child: Container(
                      decoration: BoxDecoration(),
                      padding: EdgeInsets.zero,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formData[key] ?? 'Select $label $required',
                            style: TextStyle(
                              fontSize: 17,
                              color: formData[key] != null
                                  ? CupertinoColors.black
                                  : hasError
                                  ? CupertinoColors.systemRed
                                  : CupertinoColors.systemGrey,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            CupertinoIcons.chevron_up_chevron_down,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a multi-select field using PullDownButton with persistent selection
  /// Builds a multi-select field with chip display
  static Widget buildMultiSelectField(
    String key,
    String label,
    List<String> options, {
    required Function(String, dynamic) onChanged,
    required Map<String, dynamic> formData,
    required Map<String, String> validationErrors,
    bool isRequired = false,
  }) {
    List<String> selectedValues = List<String>.from(formData[key] ?? []);
    String required = isRequired ? '*' : '';

    return Container(
      padding: selectedValues.isEmpty
          ? EdgeInsets.all(16)
          : EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 17, color: CupertinoColors.black),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: PullDownButton(
                  itemBuilder: (context) => options
                      .map(
                        (option) => PullDownMenuItem.selectable(
                          title: option,
                          selected: selectedValues.contains(option),
                          onTap: () {
                            List<String> newSelection = List<String>.from(
                              selectedValues,
                            );
                            if (newSelection.contains(option)) {
                              newSelection.remove(option);
                            } else {
                              newSelection.add(option);
                            }
                            onChanged(key, newSelection);
                          },
                        ),
                      )
                      .toList(),
                  buttonBuilder: (context, showMenu) => CupertinoButton(
                    onPressed: showMenu,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.fromHeight(0),
                    child: Container(
                      decoration: BoxDecoration(),
                      padding: EdgeInsets.zero,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: selectedValues.isEmpty
                                ? Text(
                                    'Select $label $required',
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: selectedValues.map((item) {
                                      return Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.systemGrey
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: CupertinoColors.systemGrey
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              item,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: CupertinoColors.black,
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            GestureDetector(
                                              onTap: () {
                                                List<String> newSelection =
                                                    List<String>.from(
                                                      selectedValues,
                                                    );
                                                newSelection.remove(item);
                                                onChanged(key, newSelection);
                                              },
                                              child: Icon(
                                                CupertinoIcons
                                                    .xmark_circle_fill,
                                                size: 18,
                                                color:
                                                    CupertinoColors.systemGrey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            CupertinoIcons.chevron_up_chevron_down,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a date picker field using cupertino_calendar_picker
  static Widget buildDateField(
    String key,
    String label, {
    required BuildContext context,
    required Function(String, dynamic) onChanged,
    required Map<String, dynamic> formData,
    required Map<String, String> validationErrors,
    bool isRequired = false,
    DateTime? minimumDate,
    DateTime? maximumDate,
    String dateFormat = 'dd/MM/yyyy',
  }) {
    bool hasError = validationErrors.containsKey(key);
    DateTime? selectedDate = formData[key];
    String required = isRequired ? '*' : '';

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 17, color: CupertinoColors.black),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Builder(
                  builder: (context) {
                    return CupertinoButton(
                      onPressed: () => _showCalendarPicker(
                        context,
                        key,
                        onChanged,
                        formData,
                        minimumDate: minimumDate,
                        maximumDate: maximumDate,
                      ),
                      padding: EdgeInsets.zero,
                      minimumSize: Size(0, 0),
                      child: Container(
                        decoration: BoxDecoration(),
                        padding: EdgeInsets.zero,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedDate != null
                                  ? _formatDate(selectedDate, dateFormat)
                                  : 'Select $label $required',
                              style: TextStyle(
                                fontSize: 17,
                                color: selectedDate != null
                                    ? CupertinoColors.black
                                    : hasError
                                    ? CupertinoColors.systemRed
                                    : CupertinoColors.systemGrey,
                              ),
                            ),
                            Icon(CupertinoIcons.calendar, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (hasError && validationErrors[key] != null)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                validationErrors[key]!,
                style: TextStyle(
                  color: CupertinoColors.systemRed,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Shows calendar picker centered on screen
  static Future<void> _showCalendarPicker(
    BuildContext context,
    String key,
    Function(String, dynamic) onChanged,
    Map<String, dynamic> formData, {
    DateTime? minimumDate,
    DateTime? maximumDate,
  }) async {
    final nowDate = DateTime.now();
    final DateTime minDate = DateTime(
      nowDate.year - 100,
      nowDate.month,
      nowDate.day,
    );
    final DateTime maxDate = DateTime(
      nowDate.year + 100,
      nowDate.month,
      nowDate.day,
    );
    final initialDate = formData[key] ?? nowDate;
    final renderBox = context.findRenderObject() as RenderBox?;

    final DateTime? selectedDate = await showCupertinoCalendarPicker(
      context,
      widgetRenderBox: renderBox,
      initialDateTime: initialDate,
      minimumDateTime: minDate,
      maximumDateTime: maxDate,
      mode: CupertinoCalendarMode.date,
      dismissBehavior: CalendarDismissBehavior.onOusideTapOrDateSelect,
    );

    if (selectedDate != null) {
      onChanged(key, selectedDate);
    }
  }

  /// Private helper method to format date
  static String _formatDate(DateTime date, String format) {
    switch (format) {
      case 'MM/dd/yyyy':
        return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
      case 'yyyy-MM-dd':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      default: // 'dd/MM/yyyy'
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  /// Builds a switch toggle field
  static Widget buildSwitchField(
    String key,
    String label, {
    required Function(String, dynamic) onChanged,
    required Map<String, dynamic> formData,
    required Map<String, String> validationErrors,
    bool isRequired = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6.5, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 17, color: CupertinoColors.black),
            ),
          ),
          SizedBox(width: 16),
          CupertinoSwitch(
            value: formData[key] ?? false,
            onChanged: (bool value) => onChanged(key, value),
            activeTrackColor: CupertinoColors.activeBlue,
          ),
        ],
      ),
    );
  }
}
