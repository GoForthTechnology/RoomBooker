import 'package:flutter/material.dart';
import 'package:room_booker/ui/core/simple_text_form_field.dart';

class TimeField extends StatelessWidget {
  final bool readOnly;
  final TimeOfDay initialValue;
  final Function(TimeOfDay) onChanged;
  final String labelText;
  final String? validationMessage;
  final controller = TextEditingController();
  final MaterialLocalizations localizations;

  TimeField(
      {super.key,
      required this.initialValue,
      required this.onChanged,
      required this.labelText,
      this.validationMessage,
      required this.readOnly,
      required this.localizations}) {
    controller.text = localizations.formatTimeOfDay(initialValue);
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
              TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: initialValue,
              );
              if (pickedTime == null) {
                return;
              }
              var roundedTime = roundToNearest30Minutes(pickedTime);
              controller.text = localizations.formatTimeOfDay(roundedTime);
              onChanged(roundedTime);
            },
    );
  }

  TimeOfDay roundToNearest30Minutes(TimeOfDay time) {
    final int minute = time.minute;
    final int mod = minute % 30;
    final int roundedMinute = mod < 15 ? minute - mod : minute + (30 - mod);
    return TimeOfDay(hour: time.hour, minute: roundedMinute);
  }
}
