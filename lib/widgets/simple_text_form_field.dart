import 'package:flutter/material.dart';

class SimpleTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? validationMessage;
  final GestureTapCallback? onTap;
  final bool readOnly;
  final bool clearable;
  final Function(String)? onChanged;

  const SimpleTextFormField({
    super.key,
    required this.controller,
    required this.readOnly,
    required this.labelText,
    this.validationMessage,
    this.onTap,
    this.onChanged,
    this.clearable = false,
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
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextFormField(
          controller: controller,
          onTap: onTap,
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
            if (value == null || value.isEmpty) {
              return validationMessage;
            }
            return null;
          },
        ));
  }
}
