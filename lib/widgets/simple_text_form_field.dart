import 'package:flutter/material.dart';

class SimpleTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? validationMessage;
  final GestureTapCallback? onTap;
  final bool readOnly;
  final Function(String)? onChanged;

  SimpleTextFormField({
    super.key,
    required this.controller,
    required this.readOnly,
    required this.labelText,
    this.validationMessage,
    this.onTap,
    this.onChanged,
  }) {
    if (onChanged != null) {
      controller.addListener(() {
        onChanged!(controller.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return validationMessage;
            }
            return null;
          },
        ));
  }
}
