import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:room_booker/ui/widgets/simple_text_form_field.dart';

final timeFormat = DateFormat("h:mm a");

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

  TimeOfDay parseTime(String timeString) {
    return TimeOfDay.fromDateTime(timeFormat.parse(timeString));
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
          parsedTime = parseTime(value);
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
