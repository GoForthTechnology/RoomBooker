import 'package:flutter/material.dart';
import 'package:room_booker/widgets/simple_text_form_field.dart';

class DateField extends StatelessWidget {
  final String labelText;
  final String? validationMessage;
  final String? emptyText;
  final DateTime? initialValue;
  final bool readOnly;
  final bool clearable;
  final Function(DateTime) onChanged;
  final TextEditingController controller = TextEditingController();

  DateField(
      {super.key,
      required this.initialValue,
      required this.labelText,
      this.validationMessage,
      this.clearable = false,
      this.emptyText,
      required this.onChanged,
      required this.readOnly}) {
    controller.text =
        initialValue != null ? dateToString(initialValue!) : emptyText ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return SimpleTextFormField(
      controller: controller,
      labelText: labelText,
      validationMessage: validationMessage,
      readOnly: readOnly,
      clearable: clearable,
      onTap: readOnly
          ? null
          : () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (pickedDate != null) {
                onChanged(pickedDate);
                controller.text = dateToString(pickedDate);
              }
            },
      onChanged: (value) {
        if (value == "") {
          controller.text = emptyText ?? "";
        }
      },
    );
  }
}

String dateToString(DateTime date) {
  return "${date.toLocal()}".split(' ')[0];
}
