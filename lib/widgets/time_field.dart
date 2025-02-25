import 'package:flutter/material.dart';
import 'package:room_booker/widgets/simple_text_form_field.dart';

class TimeField extends StatelessWidget {
  final bool readOnly;
  final TimeOfDay initialValue;
  final Function(TimeOfDay) onChanged;
  final String labelText;
  final String? validationMessage;
  final controller = TextEditingController();

  TimeField(
      {super.key,
      required this.initialValue,
      required this.onChanged,
      required this.labelText,
      this.validationMessage,
      required this.readOnly}) {
    controller.text = formatTimeOfDay(initialValue);
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
              var minimumTime = TimeOfDay.now();
              var messenger = ScaffoldMessenger.of(context);
              var minimumTimeStr = minimumTime.format(context);
              TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: initialValue,
              );
              if (pickedTime == null) {
                return;
              }
              if (minimumTime.isAfter(pickedTime!)) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Time must be after $minimumTimeStr'),
                  ),
                );
                return;
              }
              var roundedTime = roundToNearest30Minutes(pickedTime);
              controller.text = formatTimeOfDay(roundedTime);
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

String formatTimeOfDay(TimeOfDay time) {
  var hourStr = time.hour.toString().padLeft(2, '0');
  var minuteStr = time.minute.toString().padLeft(2, '0');
  return "$hourStr:$minuteStr";
}
