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
  final TimeOfDay? maxTime;
  final TimeOfDay? minTime;

  TimeField(
      {super.key,
      required this.initialValue,
      required this.onChanged,
      required this.labelText,
      this.validationMessage,
      required this.readOnly,
      required this.localizations,
      this.maxTime,
      this.minTime}) {
    controller.text = localizations.formatTimeOfDay(initialValue);
  }

  @override
  Widget build(BuildContext context) {
    return SimpleTextFormField(
      controller: controller,
      labelText: labelText,
      validationMessage: validationMessage,
      readOnly: readOnly,
      customValidator: (value) {
        TimeOfDay? parsedTime;
        try {
          final timeParts = value.split(':');
          if (timeParts.length != 2) throw FormatException();
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1].split(' ')[0]);
          parsedTime = TimeOfDay(hour: hour, minute: minute);
        } catch (e) {
          return 'Invalid time format';
        }
        if (maxTime != null && parsedTime.isAfter(maxTime!)) {
          return 'Time cannot be after ${localizations.formatTimeOfDay(maxTime!)}';
        }
        if (minTime != null && parsedTime.isBefore(minTime!)) {
          return 'Time cannot be before ${localizations.formatTimeOfDay(minTime!)}';
        }
        return null;
      },
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
