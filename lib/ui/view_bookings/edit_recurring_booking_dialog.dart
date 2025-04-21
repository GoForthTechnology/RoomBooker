import 'package:flutter/material.dart';
import 'package:room_booker/data/repos/org_repo.dart';

class EditRecurringBookingDialog extends StatefulWidget {
  const EditRecurringBookingDialog({super.key});

  @override
  _EditRecurringBookingDialogState createState() =>
      _EditRecurringBookingDialogState();
}

class _EditRecurringBookingDialogState
    extends State<EditRecurringBookingDialog> {
  RecurringBookingEditChoice choice = RecurringBookingEditChoice.thisInstance;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Recurring Booking'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<RecurringBookingEditChoice>(
            title: const Text('This instance only'),
            value: RecurringBookingEditChoice.thisInstance,
            groupValue: choice,
            onChanged: (value) {
              setState(() {
                choice = value!;
              });
            },
          ),
          RadioListTile<RecurringBookingEditChoice>(
            title: const Text('This and future instances'),
            value: RecurringBookingEditChoice.thisAndFuture,
            groupValue: choice,
            onChanged: (value) {
              setState(() {
                choice = value!;
              });
            },
          ),
          RadioListTile<RecurringBookingEditChoice>(
            title: const Text('All instances'),
            value: RecurringBookingEditChoice.all,
            groupValue: choice,
            onChanged: (value) {
              setState(() {
                choice = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(choice);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
