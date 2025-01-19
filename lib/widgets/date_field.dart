import 'package:flutter/material.dart';
import 'package:room_booker/widgets/simple_text_form_field.dart';

class DateField extends StatelessWidget {
  final String labelText;
  final String? validationMessage;
  final DateTime initialValue;
  final bool readOnly;
  final Function(DateTime) onChanged;
  final TextEditingController controller = TextEditingController();

  DateField(
      {super.key,
      required this.initialValue,
      required this.labelText,
      this.validationMessage,
      required this.onChanged,
      required this.readOnly}) {
    controller.text = dateToString(initialValue);
  }

  @override
  Widget build(BuildContext context) {
    return SimpleTextFormField(
        controller: controller,
        labelText: labelText,
        validationMessage: validationMessage,
        readOnly: readOnly,
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
              });
  }
}

String dateToString(DateTime date) {
  return "${date.toLocal()}".split(' ')[0];
}
