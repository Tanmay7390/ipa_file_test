import 'package:flutter/cupertino.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cupertino_calendar_picker/cupertino_calendar_picker.dart';
import 'dart:io';

/// A collection of reusable form field widgets with Cupertino design
class FormFieldWidgets {
  // Static controller storage to persist controllers across rebuilds
  static final Map<String, TextEditingController> _controllers = {};

  /// Get or create a controller for a specific field
  static TextEditingController _getController(
    String key, {
    String? initialValue,
  }) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: initialValue ?? '');
    }
    return _controllers[key]!;
  }

  /// Clean up controllers (call this when disposing forms)
  static void disposeController(String key) {
    if (_controllers.containsKey(key)) {
      _controllers[key]!.dispose();
      _controllers.remove(key);
    }
  }

  /// Clean up all controllers
  static void disposeAllControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

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
                  fontSize: 16,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.25,
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
                  itemTheme: PullDownMenuItemTheme(
                    textStyle: TextStyle(
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.25,
                    ),
                  ),
                  icon: CupertinoIcons.camera,
                  onTap: () =>
                      _pickImage(context, key, onChanged, ImageSource.camera),
                ),
                PullDownMenuItem(
                  title: 'Open Gallery',
                  itemTheme: PullDownMenuItemTheme(
                    textStyle: TextStyle(
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.25,
                    ),
                  ),
                  icon: CupertinoIcons.photo,
                  onTap: () =>
                      _pickImage(context, key, onChanged, ImageSource.gallery),
                ),
                PullDownMenuItem(
                  title: 'Choose from Files',
                  icon: CupertinoIcons.folder,
                  itemTheme: PullDownMenuItemTheme(
                    textStyle: TextStyle(
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.25,
                    ),
                  ),
                  onTap: () => _pickImageFromFiles(context, key, onChanged),
                ),
                if (formData[key] != null)
                  PullDownMenuItem(
                    title: 'Remove Photo',
                    itemTheme: PullDownMenuItemTheme(
                      textStyle: TextStyle(
                        fontFamily: 'SF Pro Display',
                        letterSpacing: 0.25,
                      ),
                    ),
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
                                  fontFamily: 'SF Pro Display',
                                  letterSpacing: 0.25,
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
                                    fontFamily: 'SF Pro Display',
                                    letterSpacing: 0.25,
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
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.25,
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

  /// Builds a multiple photos selection field with horizontal scrollable display
  static Widget buildMultiplePhotosField(
    String key,
    String label, {
    required Function(String, dynamic) onChanged,
    required Map<String, dynamic> formData,
    required Map<String, String> validationErrors,
    required BuildContext context,
    double photoSize = 80,
    bool isRequired = false,
  }) {
    bool hasError = validationErrors.containsKey(key);
    String required = isRequired ? '*' : '';
    List<File> photos = List<File>.from(formData[key] ?? []);

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
                  '$label $required',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.25,
                    color: hasError
                        ? CupertinoColors.systemRed
                        : CupertinoColors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: photoSize + 20,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Add Photo Button
                        GestureDetector(
                          onTap: () => _showMultiplePhotoOptions(
                            context,
                            key,
                            onChanged,
                            photos,
                          ),
                          child: Container(
                            width: photoSize,
                            height: photoSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: hasError
                                  ? CupertinoColors.systemRed.withOpacity(0.1)
                                  : CupertinoColors.systemGrey6,
                              border: hasError
                                  ? Border.all(
                                      color: CupertinoColors.systemRed,
                                      width: 2,
                                    )
                                  : Border.all(
                                      color: CupertinoColors.systemGrey4,
                                    ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.plus,
                                  size: photoSize * 0.3,
                                  color: CupertinoColors.systemGrey,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    fontFamily: 'SF Pro Display',
                                    letterSpacing: 0.25,
                                    color: CupertinoColors.systemGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Display selected photos
                        ...photos.asMap().entries.map((entry) {
                          int index = entry.key;
                          File photo = entry.value;
                          return Container(
                            margin: EdgeInsets.only(left: 12),
                            child: Stack(
                              children: [
                                Container(
                                  width: photoSize,
                                  height: photoSize,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(photo),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -8,
                                  right: -8,
                                  child: GestureDetector(
                                    onTap: () => _removePhotoAt(
                                      index,
                                      key,
                                      onChanged,
                                      photos,
                                    ),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.systemRed,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        CupertinoIcons.xmark,
                                        size: 16,
                                        color: CupertinoColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
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
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.25,
                  color: CupertinoColors.systemRed,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Shows photo selection options for multiple photos
  static void _showMultiplePhotoOptions(
    BuildContext context,
    String key,
    Function(String, dynamic) onChanged,
    List<File> currentPhotos,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Add Photos'),
        actions: [
          CupertinoActionSheetAction(
            child: Text('Camera'),
            onPressed: () {
              Navigator.pop(context);
              _pickMultipleImages(
                context,
                key,
                onChanged,
                currentPhotos,
                ImageSource.camera,
              );
            },
          ),
          CupertinoActionSheetAction(
            child: Text('Gallery'),
            onPressed: () {
              Navigator.pop(context);
              _pickMultipleImages(
                context,
                key,
                onChanged,
                currentPhotos,
                ImageSource.gallery,
              );
            },
          ),
          CupertinoActionSheetAction(
            child: Text('Files'),
            onPressed: () {
              Navigator.pop(context);
              _pickMultipleImagesFromFiles(
                context,
                key,
                onChanged,
                currentPhotos,
              );
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  /// Private helper method to pick multiple images from camera or gallery
  static Future<void> _pickMultipleImages(
    BuildContext context,
    String key,
    Function(String, dynamic) onChanged,
    List<File> currentPhotos,
    ImageSource source,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();

      if (source == ImageSource.camera) {
        // Camera can only pick one image at a time
        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );

        if (image != null) {
          List<File> updatedPhotos = List<File>.from(currentPhotos);
          updatedPhotos.add(File(image.path));
          onChanged(key, updatedPhotos);
        }
      } else {
        // Gallery can pick multiple images
        final List<XFile> images = await picker.pickMultiImage(
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );

        if (images.isNotEmpty) {
          List<File> updatedPhotos = List<File>.from(currentPhotos);
          for (XFile image in images) {
            updatedPhotos.add(File(image.path));
          }
          onChanged(key, updatedPhotos);
        }
      }
    } catch (e) {
      _showErrorDialog(context, 'Failed to pick images');
    }
  }

  /// Private helper method to pick multiple images from files
  static Future<void> _pickMultipleImagesFromFiles(
    BuildContext context,
    String key,
    Function(String, dynamic) onChanged,
    List<File> currentPhotos,
  ) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        List<File> updatedPhotos = List<File>.from(currentPhotos);
        for (PlatformFile file in result.files) {
          if (file.path != null) {
            updatedPhotos.add(File(file.path!));
          }
        }
        onChanged(key, updatedPhotos);
      }
    } catch (e) {
      _showErrorDialog(context, 'Failed to pick images from files');
    }
  }

  /// Remove photo at specific index
  static void _removePhotoAt(
    int index,
    String key,
    Function(String, dynamic) onChanged,
    List<File> currentPhotos,
  ) {
    List<File> updatedPhotos = List<File>.from(currentPhotos);
    updatedPhotos.removeAt(index);
    onChanged(key, updatedPhotos);
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
    String type,
    BuildContext context, {
    required Function(String, dynamic) onChanged,
    required Map<String, dynamic> formData,
    required Map<String, String> validationErrors,
    bool isRequired = false,
    bool compact = false,
    bool compactFull = false,
    bool enabled = true,
    TextEditingController? controller,
  }) {
    bool hasError = validationErrors.containsKey(key);
    String required = isRequired ? '*' : '';

    // Use provided controller or get/create a persistent one
    final textController =
        controller ??
        _getController(key, initialValue: formData[key]?.toString() ?? '');

    // Sync controller with formData only if they differ (avoid cursor jumping)
    final currentFormValue = formData[key]?.toString() ?? '';
    if (controller == null && textController.text != currentFormValue) {
      // Preserve cursor position when updating
      final selection = textController.selection;
      textController.text = currentFormValue;
      if (selection.isValid && selection.end <= currentFormValue.length) {
        textController.selection = selection;
      }
    }

    return Container(
      padding: compact
          ? EdgeInsets.symmetric(horizontal: 2, vertical: 16)
          : EdgeInsets.all(16),
      color: CupertinoColors.systemBackground.resolveFrom(context),
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
                      fontSize: 16,
                      fontFamily: 'SF Pro Display',
                      letterSpacing: 0.25,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                ),
              if (!compact) SizedBox(width: 16),
              Expanded(
                child: CupertinoTextField(
                  controller: textController,
                  onChanged: (value) => onChanged(key, value),
                  placeholder: 'Enter $label $required',
                  placeholderStyle: TextStyle(
                    fontSize: 16,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.25,
                    color: hasError
                        ? CupertinoColors.systemRed
                        : CupertinoColors.systemGrey,
                  ),
                  decoration: BoxDecoration(),
                  prefix: type == 'phone'
                      ? Text(
                          '+91  ',
                          style: TextStyle(
                            fontFamily: 'SF Pro Display',
                            letterSpacing: 0.25,
                            fontSize: 16,
                          ),
                        )
                      : null,
                  // suffix: type == 'email'
                  //     ? Text(
                  //         '@gmail.com',
                  //         style: TextStyle(
                  //           fontFamily: 'SF Pro Display',
                  //           letterSpacing: 0.25,
                  //           fontSize: 16,
                  //         ),
                  //       )
                  //     : null,
                  padding: EdgeInsets.zero,
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.black,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.25,
                  ),
                  keyboardType: type == 'phone'
                      ? TextInputType.phone
                      : type == 'email'
                      ? TextInputType.emailAddress
                      : type == 'number'
                      ? TextInputType.number
                      : TextInputType.text,
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
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.25,
                  fontSize: 14,
                ),
              ),
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
    TextEditingController? controller,
    bool compactFull = false,
  }) {
    bool hasError = validationErrors.containsKey(key);
    String required = isRequired ? '*' : '';

    // Use provided controller or get/create a persistent one
    final textController =
        controller ??
        _getController(key, initialValue: formData[key]?.toString() ?? '');

    // Sync controller with formData only if they differ (avoid cursor jumping)
    final currentFormValue = formData[key]?.toString() ?? '';
    if (controller == null && textController.text != currentFormValue) {
      // Preserve cursor position when updating
      final selection = textController.selection;
      textController.text = currentFormValue;
      if (selection.isValid && selection.end <= currentFormValue.length) {
        textController.selection = selection;
      }
    }

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
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.25,
                    color: CupertinoColors.black,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: CupertinoTextField(
                  controller: textController,
                  onChanged: (value) => onChanged(key, value),
                  placeholder: 'Enter $label $required',
                  placeholderStyle: TextStyle(
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.25,
                    color: hasError
                        ? CupertinoColors.systemRed
                        : CupertinoColors.systemGrey,
                  ),
                  decoration: BoxDecoration(),
                  padding: EdgeInsets.zero,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.25,
                    color: CupertinoColors.black,
                  ),
                  maxLines: maxLines,
                  minLines: minLines,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
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
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.25,
                  fontSize: 14,
                ),
              ),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.25,
                    color: CupertinoColors.black,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: PullDownButton(
                  itemBuilder: (context) => options
                      .map(
                        (option) => PullDownMenuItem.selectable(
                          title: option,
                          itemTheme: PullDownMenuItemTheme(
                            textStyle: TextStyle(
                              fontFamily: 'SF Pro Display',
                              letterSpacing: 0.25,
                            ),
                          ),
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
                            formData[key]?.toString() ??
                                'Select $label $required',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'SF Pro Display',
                              letterSpacing: 0.25,
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
          if (hasError && validationErrors[key] != null)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                validationErrors[key]!,
                style: TextStyle(
                  color: CupertinoColors.systemRed,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.25,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

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
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.25,
                    color: CupertinoColors.black,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: PullDownButton(
                  itemBuilder: (context) => options
                      .map(
                        (option) => PullDownMenuItem.selectable(
                          title: option,
                          itemTheme: PullDownMenuItemTheme(
                            textStyle: TextStyle(
                              fontFamily: 'SF Pro Display',
                              letterSpacing: 0.25,
                            ),
                          ),
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
                                      fontSize: 16,
                                      fontFamily: 'SF Pro Display',
                                      letterSpacing: 0.25,
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
                                                fontFamily: 'SF Pro Display',
                                                letterSpacing: 0.25,
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
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: 0.25,
                    color: CupertinoColors.black,
                  ),
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
                                fontSize: 16,
                                fontFamily: 'SF Pro Display',
                                letterSpacing: 0.25,
                                color: selectedDate != null
                                    ? CupertinoColors.black
                                    : hasError
                                    ? CupertinoColors.systemRed
                                    : CupertinoColors.systemGrey,
                              ),
                            ),
                            Icon(CupertinoIcons.calendar, size: 19),
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
                  fontFamily: 'SF Pro Display',
                  letterSpacing: 0.25,
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

    TextStyle applyFontFamily(BuildContext context, TextStyle? baseStyle) {
      final resolved = baseStyle ?? const TextStyle();
      return resolved.copyWith(
        fontFamily: 'SF Pro Display',
        letterSpacing: 0.25,
      );
    }

    final DateTime? selectedDate = await showCupertinoCalendarPicker(
      context,
      widgetRenderBox: renderBox,
      initialDateTime: initialDate,
      minimumDateTime: minDate,
      maximumDateTime: maxDate,
      mode: CupertinoCalendarMode.date,
      dismissBehavior: CalendarDismissBehavior.onOusideTapOrDateSelect,

      weekdayDecoration: CalendarWeekdayDecoration(
        textStyle: applyFontFamily(
          context,
          CalendarWeekdayDecoration().textStyle,
        ),
      ),

      headerDecoration: CalendarHeaderDecoration(
        monthDateStyle: applyFontFamily(
          context,
          CalendarHeaderDecoration().monthDateStyle,
        ),
      ),

      monthPickerDecoration: CalendarMonthPickerDecoration(
        disabledDayStyle: CalendarMonthPickerDisabledDayStyle(
          textStyle: applyFontFamily(
            context,
            CalendarMonthPickerDisabledDayStyle().textStyle,
          ),
        ),
        selectedCurrentDayStyle: CalendarMonthPickerSelectedCurrentDayStyle(
          textStyle: applyFontFamily(
            context,
            CalendarMonthPickerSelectedCurrentDayStyle().textStyle,
          ),
        ),
        selectedDayStyle: CalendarMonthPickerSelectedDayStyle(
          textStyle: applyFontFamily(
            context,
            CalendarMonthPickerSelectedDayStyle().textStyle,
          ),
        ),
        currentDayStyle: CalendarMonthPickerCurrentDayStyle(
          textStyle: applyFontFamily(
            context,
            CalendarMonthPickerCurrentDayStyle().textStyle,
          ),
        ),
        defaultDayStyle: CalendarMonthPickerDefaultDayStyle(
          textStyle: applyFontFamily(
            context,
            CalendarMonthPickerDefaultDayStyle().textStyle,
          ),
        ),
      ),
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
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'SF Pro Display',
                letterSpacing: 0.25,
                color: CupertinoColors.black,
              ),
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
class CollapsibleSection extends StatefulWidget {
  final List<Widget> fields;
  final String title;
  final bool compact;
  final bool initiallyExpanded;

  const CollapsibleSection({
    super.key,
    required this.fields,
    this.title = '',
    this.compact = false,
    this.initiallyExpanded = true,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _iconAnimation;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title.isNotEmpty)
          GestureDetector(
            onTap: _toggleExpansion,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: CupertinoColors.systemGrey6,
              padding: const EdgeInsets.only(
                left: 20,
                right: 16,
                bottom: 10,
                top: 10,
              ),
              child: Transform.translate(
                offset: const Offset(-4, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'SF Pro Display',
                          letterSpacing: 0.25,
                          fontSize: 14,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _iconAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _iconAnimation.value * 3.14159,
                          child: const Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: CupertinoColors.systemGrey2,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1.0,
          child: CupertinoListSection(
            backgroundColor: CupertinoColors.systemBackground.resolveFrom(
              context,
            ),
            dividerMargin: widget.compact ? 0 : 110,
            margin: EdgeInsets.zero,
            topMargin: 0,
            additionalDividerMargin: widget.compact ? 0 : 30,
            children: widget.fields,
          ),
        ),
      ],
    );
  }
}

Widget BuildSection(
  List<Widget> fields, {
  String title = '',
  bool compact = false,
  bool initiallyExpanded = true,
}) {
  return CollapsibleSection(
    fields: fields,
    title: title,
    compact: compact,
    initiallyExpanded: initiallyExpanded,
  );
}