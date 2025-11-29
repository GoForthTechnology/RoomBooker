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
      content: RadioGroup<RecurringBookingEditChoice>(
        groupValue: choice,
        onChanged: (value) {
          setState(() {
            choice = value!;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            RadioListTile<RecurringBookingEditChoice>(
              title: Text('This instance only'),
              value: RecurringBookingEditChoice.thisInstance,
            ),
            RadioListTile<RecurringBookingEditChoice>(
              title: Text('This and future instances'),
              value: RecurringBookingEditChoice.thisAndFuture,
            ),
            RadioListTile<RecurringBookingEditChoice>(
              title: Text('All instances'),
              value: RecurringBookingEditChoice.all,
            ),
          ],
        ),
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
