import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:room_booker/widgets/calendar_widget.dart';

class NewBookingForm extends StatefulWidget {
  const NewBookingForm({super.key});

  @override
  NewBookingFormState createState() => NewBookingFormState();
}

class NewBookingFormState extends State<NewBookingForm> {
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final attendanceController = TextEditingController();
  final messageController = TextEditingController();
  final eventNameController = TextEditingController();
  final eventStartTimeController = TextEditingController();
  final eventEndTimeController = TextEditingController();
  final eventDateController = TextEditingController();
  final doorsLockTimeController = TextEditingController();
  final doorsUnlockTimeController = TextEditingController();
  String selectedRoom = 'Stewardship Hall'; // Default value for dropdown

  @override
  Widget build(BuildContext context) {
    eventStartTimeController.addListener(() {
      if (eventStartTimeController.text.isEmpty) {
        return;
      }
      if (eventEndTimeController.text.isEmpty) {
        var startTime = parseTimeOfDay(eventStartTimeController.text)!;
        eventEndTimeController.text =
            TimeOfDay(hour: startTime.hour + 1, minute: startTime.minute)
                .format(context);
      }
    });
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Heading(text: "Requester Information"),
            MyTextFormField(
              controller: nameController,
              labelText: 'Your Name',
              validationMessage: 'Please enter your name',
            ),
            MyTextFormField(
              controller: emailController,
              labelText: 'Your Email',
              validationMessage: 'Please enter your email',
            ),
            MyTextFormField(
              controller: phoneController,
              labelText: 'Your Phone #',
              validationMessage: 'Please enter your phone number',
            ),
            const Heading(text: "Event Information"),
            RoomField(
                selectedRoom: selectedRoom,
                onChanged: (newValue) {
                  setState(() {
                    selectedRoom = newValue!;
                  });
                }),
            MyTextFormField(
              controller: eventNameController,
              labelText: "Event Name",
              validationMessage: "Please enter the event name",
            ),
            TextFormField(
              controller: attendanceController,
              decoration: const InputDecoration(
                labelText: 'Event Attendance',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                FilteringTextInputFormatter.allow(RegExp(r'^[1-9]\d*|0$')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the event attendance';
                }
                return null;
              },
            ),
            const Instructions(
              text:
                  "Please select a time slot on the calendar to set the event date and time",
            ),
            SizedBox(
              height: 1100,
              child: Card(child: CalendarWidget(
                onAppointmentChanged: (a) {
                  eventDateController.text = dateToString(a.startTime);
                  eventStartTimeController.text =
                      TimeOfDay.fromDateTime(a.startTime).format(context);
                  eventEndTimeController.text =
                      TimeOfDay.fromDateTime(a.endTime).format(context);
                },
              )),
            ),
            DateField(
              controller: eventDateController,
              labelText: "Event Date",
              validationMessage: "Please enter the event date",
            ),
            TimeField(
              controller: eventStartTimeController,
              labelText: 'Event Start Time',
              validationMessage: 'Please enter the event start time',
            ),
            TimeField(
              controller: eventEndTimeController,
              labelText: 'Event End Time',
              validationMessage: 'Please enter the event end time',
              minimumTime: parseTimeOfDay(eventStartTimeController.text),
            ),
            const Instructions(
              text:
                  "Please select when you would like the doors to be unlocked and locked",
            ),
            TimeField(
              controller: doorsUnlockTimeController,
              labelText: 'Doors Unlock Time',
              validationMessage:
                  'When would you like the doors to be unlocked?',
            ),
            TimeField(
              controller: doorsLockTimeController,
              labelText: 'Doors Lock Time',
              validationMessage: 'When would you like the doors to be locked?',
              minimumTime: parseTimeOfDay(eventStartTimeController.text),
            ),
            const Instructions(
              text: "Additional information",
            ),
            TextFormField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: null, // not required
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final booking = Booking(
                    name: nameController.text,
                    email: emailController.text,
                    phone: phoneController.text,
                    attendance: int.parse(attendanceController.text),
                    message: messageController.text,
                    eventName: eventNameController.text,
                    eventStartTime: eventStartTimeController.text,
                    eventEndTime: eventEndTimeController.text,
                    eventDate: eventDateController.text,
                    selectedRoom: selectedRoom,
                  );
                  _showBookingSummaryDialog(context, booking);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingSummaryDialog(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Booking Summary'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Name: ${booking.name}'),
                Text('Email: ${booking.email}'),
                Text('Phone: ${booking.phone}'),
                Text('Event Name: ${booking.eventName}'),
                Text('Event Date: ${booking.eventDate}'),
                Text('Event Start Time: ${booking.eventStartTime}'),
                Text('Event End Time: ${booking.eventEndTime}'),
                Text('Event Attendance: ${booking.attendance}'),
                Text('Event Location: ${booking.selectedRoom}'),
                Text('Notes: ${booking.message}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Return to home page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request has been submitted')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class MyTextFormField extends StatelessWidget {
  final String labelText;
  final String? validationMessage;
  final GestureTapCallback? onTap;
  final TextEditingController controller;
  final bool? readOnly;

  const MyTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.validationMessage,
    this.onTap,
    this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextFormField(
          controller: controller,
          onTap: onTap,
          readOnly: readOnly ?? false,
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

class TimeField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? validationMessage;
  final TimeOfDay? minimumTime;

  const TimeField(
      {super.key,
      required this.controller,
      required this.labelText,
      this.validationMessage,
      this.minimumTime});

  @override
  Widget build(BuildContext context) {
    return MyTextFormField(
      controller: controller,
      labelText: labelText,
      validationMessage: validationMessage,
      readOnly: true,
      onTap: () async {
        var initialTime = roundToNearest30Minutes(TimeOfDay.now());
        if (controller.text.isNotEmpty) {
          initialTime = parseTimeOfDay(controller.text)!;
        }
        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: initialTime,
        );
        if (minimumTime != null && minimumTime!.isAfter(pickedTime!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Time must be after ${minimumTime!.format(context)}'),
            ),
          );
          return;
        }
        if (pickedTime != null) {
          final roundedTime = roundToNearest30Minutes(pickedTime);
          controller.text = roundedTime.format(context);
        }
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

// Parse a string in the format "HH:MM AM/PM" to a TimeOfDay object
TimeOfDay? parseTimeOfDay(String time) {
  if (time.isEmpty) {
    return null;
  }
  var parts = time.split(":");
  return TimeOfDay(
    hour: int.parse(parts[0]),
    minute: int.parse(parts[1].split(" ")[0]),
  );
}

class DateField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? validationMessage;

  const DateField(
      {super.key,
      required this.controller,
      required this.labelText,
      this.validationMessage});

  @override
  Widget build(BuildContext context) {
    return MyTextFormField(
        controller: controller,
        labelText: labelText,
        validationMessage: validationMessage,
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
          );
          if (pickedDate != null) {
            controller.text = dateToString(pickedDate);
          }
        });
  }
}

String dateToString(DateTime date) {
  return "${date.toLocal()}".split(' ')[0];
}

class RoomField extends StatelessWidget {
  final String selectedRoom;
  final Function(String?) onChanged;

  const RoomField(
      {super.key, required this.selectedRoom, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedRoom,
      decoration: const InputDecoration(
        labelText: 'Event Location',
        border: OutlineInputBorder(),
      ),
      items: <String>[
        'Stewardship Hall',
        'St. John\'s Room',
        'Magdalen Room',
        'Gym'
      ].map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a room';
        }
        return null;
      },
    );
  }
}

class Heading extends StatelessWidget {
  final String text;

  const Heading({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.headlineMedium,
        ));
  }
}

class Instructions extends StatelessWidget {
  final String text;

  const Instructions({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.headlineSmall,
        ));
  }
}

class Booking {
  final String name;
  final String email;
  final String phone;
  final int attendance;
  final String message;
  final String eventName;
  final String eventStartTime;
  final String eventEndTime;
  final String eventDate;
  final String selectedRoom;

  Booking({
    required this.name,
    required this.email,
    required this.phone,
    required this.attendance,
    required this.message,
    required this.eventName,
    required this.eventStartTime,
    required this.eventEndTime,
    required this.eventDate,
    required this.selectedRoom,
  });
}
