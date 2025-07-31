import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SimpleTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? validationMessage;
  final GestureTapCallback? onTap;
  final bool readOnly;
  final bool clearable;
  final Function(String)? onChanged;
  final RegExp? validationRegex;
  final String? Function(String)? customValidator;

  const SimpleTextFormField({
    super.key,
    required this.controller,
    required this.readOnly,
    required this.labelText,
    this.validationMessage,
    this.onTap,
    this.onChanged,
    this.clearable = false,
    this.validationRegex,
    this.customValidator,
  });

  @override
  Widget build(BuildContext context) {
    Widget? suffixIcon = !clearable
        ? null
        : IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              controller.clear();
              if (onChanged != null) {
                onChanged!("");
              }
            },
          );
    Widget field = TextFormField(
      controller: controller,
      readOnly: readOnly,
      enabled: !readOnly,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon,
      ),
      onChanged: (value) {
        if (onChanged != null) {
          onChanged!(value);
        }
      },
      validator: (value) {
        if (customValidator != null) {
          var customValidationResult = customValidator!(value ?? "");
          if (customValidationResult != null) {
            return customValidationResult;
          }
          return null;
        }
        if (validationMessage == null) {
          return null;
        }
        var hasValue = value != null && value.isNotEmpty;

        if (validationRegex != null) {
          if (hasValue && !validationRegex!.hasMatch(value)) {
            return validationMessage;
          }
        } else if (!hasValue) {
          return validationMessage;
        }
        return null;
      },
    );
    if (readOnly) {
      field = GestureDetector(
        onTap: () async {
          var messenger = ScaffoldMessenger.of(context);
          if (readOnly) {
            await Clipboard.setData(ClipboardData(text: controller.text));
            messenger.showSnackBar(
              const SnackBar(content: Text('Copied to clipboard')),
            );
          }
          if (onTap != null) {
            onTap!();
          }
        },
        child: field,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: field,
    );
  }
}
