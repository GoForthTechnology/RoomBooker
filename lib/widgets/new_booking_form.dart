import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/organization.dart';
import 'package:room_booker/entities/request.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:room_booker/widgets/heading.dart';
import 'package:room_booker/widgets/new_booking_calendar.dart';

class NewBookingForm extends StatefulWidget {
  final String orgID;
  final DateTime? startTime;
  final String roomID;

  const NewBookingForm(
      {super.key, this.startTime, required this.roomID, required this.orgID});

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
  String? selectedRoom;

  @override
  void initState() {
    if (widget.startTime != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        eventDateController.text = dateToString(widget.startTime!);
        eventStartTimeController.text =
            TimeOfDay.fromDateTime(widget.startTime!).format(context);
        eventEndTimeController.text = TimeOfDay.fromDateTime(
                widget.startTime!.add(const Duration(hours: 1)))
            .format(context);
        doorsUnlockTimeController.text = eventStartTimeController.text;
        selectedRoom = widget.roomID;
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    eventStartTimeController.addListener(() {
      if (eventStartTimeController.text.isEmpty) {
        return;
      }
      if (eventEndTimeController.text.isEmpty) {
        var startTime = parseTimeOfDay(eventStartTimeController.text)!;
        eventEndTimeController.text = formatTimeOfDay(
            TimeOfDay(hour: startTime.hour + 1, minute: startTime.minute));
      }
      if (doorsUnlockTimeController.text.isEmpty) {
        doorsUnlockTimeController.text = eventStartTimeController.text;
      }
    });
    eventEndTimeController.addListener(() {
      if (eventEndTimeController.text.isEmpty) {
        return;
      }
      if (doorsLockTimeController.text.isEmpty) {
        doorsLockTimeController.text = eventEndTimeController.text;
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
                orgID: widget.orgID,
                selectedRoom: selectedRoom ?? widget.roomID,
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
              child: Card(
                  child: NewBookingCalendar(
                orgID: widget.orgID,
                roomID: selectedRoom ?? widget.roomID,
                initialStartTime: widget.startTime,
                initialEndTime: widget.startTime?.add(const Duration(hours: 1)),
                onAppointmentChanged: (a) {
                  eventDateController.text = dateToString(a.startTime);
                  eventStartTimeController.text =
                      formatTimeOfDay(TimeOfDay.fromDateTime(a.startTime));
                  eventEndTimeController.text =
                      formatTimeOfDay(TimeOfDay.fromDateTime(a.endTime));
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
              //validationMessage: 'When would you like the doors to be unlocked?',
            ),
            TimeField(
              controller: doorsLockTimeController,
              labelText: 'Doors Lock Time',
              //validationMessage: 'When would you like the doors to be locked?',
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
            Consumer<OrgRepo>(
                builder: (context, repo, child) => ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          var date = DateTime.parse(eventDateController.text);
                          var startToD =
                              parseTimeOfDay(eventStartTimeController.text);
                          var endToD =
                              parseTimeOfDay(eventEndTimeController.text);
                          var unlockToD =
                              parseTimeOfDay(doorsUnlockTimeController.text);
                          var lockToD =
                              parseTimeOfDay(doorsLockTimeController.text);
                          final booking = Request(
                            name: nameController.text,
                            email: emailController.text,
                            phone: phoneController.text,
                            attendance: int.parse(attendanceController.text),
                            message: messageController.text,
                            eventName: eventNameController.text,
                            eventStartTime: DateTime(date.year, date.month,
                                date.day, startToD!.hour, startToD.minute),
                            eventEndTime: DateTime(date.year, date.month,
                                date.day, endToD!.hour, endToD.minute),
                            doorUnlockTime: DateTime(date.year, date.month,
                                date.day, unlockToD!.hour, unlockToD.minute),
                            doorLockTime: DateTime(date.year, date.month,
                                date.day, lockToD!.hour, lockToD.minute),
                            selectedRoom: selectedRoom ?? widget.roomID,
                            status: RequestStatus.pending,
                          );
                          _showBookingSummaryDialog(context, booking, repo);
                        }
                      },
                      child: const Text('Submit'),
                    )),
          ],
        ),
      ),
    );
  }

  void _showBookingSummaryDialog(
      BuildContext context, Request booking, OrgRepo repo) {
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
              onPressed: () async {
                var navigator = Navigator.of(context);
                var messenger = ScaffoldMessenger.of(context);
                await repo.addBookingRequest(widget.orgID, booking);
                navigator.pop();
                navigator.pop();
                messenger.showSnackBar(
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
        var messenger = ScaffoldMessenger.of(context);
        var initialTime = roundToNearest30Minutes(TimeOfDay.now());
        var minimumTimeStr = minimumTime!.format(context);
        if (controller.text.isNotEmpty) {
          initialTime = parseTimeOfDay(controller.text)!;
        }
        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: initialTime,
        );
        if (minimumTime != null && minimumTime!.isAfter(pickedTime!)) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Time must be after $minimumTimeStr'),
            ),
          );
          return;
        }
        if (pickedTime != null) {
          final roundedTime = roundToNearest30Minutes(pickedTime);
          controller.text = formatTimeOfDay(roundedTime);
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

String formatTimeOfDay(TimeOfDay time) {
  var hourStr = time.hour.toString().padLeft(2, '0');
  var minuteStr = time.minute.toString().padLeft(2, '0');
  return "$hourStr:$minuteStr";
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
  final String orgID;
  final String selectedRoom;
  final Function(String?) onChanged;

  const RoomField(
      {super.key,
      required this.selectedRoom,
      required this.onChanged,
      required this.orgID});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrgRepo>(
        builder: (context, repo, child) => StreamBuilder(
              stream: repo.listRooms(orgID),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                List<Room> rooms = snapshot.data!;
                return DropdownButtonFormField<String>(
                  value: selectedRoom,
                  decoration: const InputDecoration(
                    labelText: 'Event Location',
                    border: OutlineInputBorder(),
                  ),
                  items: rooms.map<DropdownMenuItem<String>>((Room value) {
                    return DropdownMenuItem<String>(
                      value: value.name,
                      child: Text(value.name),
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
              },
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
