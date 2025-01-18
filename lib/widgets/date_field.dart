import 'package:flutter/material.dart';
import 'package:room_booker/widgets/simple_text_form_field.dart';

class DateField extends StatefulWidget {
  final String labelText;
  final String? validationMessage;
  final DateTime initialValue;
  final bool readOnly;
  final Function(DateTime) onChanged;

  const DateField(
      {super.key,
      required this.initialValue,
      required this.labelText,
      this.validationMessage,
      required this.onChanged,
      required this.readOnly});

  @override
  State<StatefulWidget> createState() => DateFieldSate();
}

class DateFieldSate extends State<DateField> {
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      controller.text = dateToString(widget.initialValue);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleTextFormField(
        controller: controller,
        labelText: widget.labelText,
        validationMessage: widget.validationMessage,
        readOnly: widget.readOnly,
        onTap: widget.readOnly
            ? null
            : () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  widget.onChanged(pickedDate);
                  controller.text = dateToString(pickedDate);
                }
              });
  }
}

String dateToString(DateTime date) {
  return "${date.toLocal()}".split(' ')[0];
}
