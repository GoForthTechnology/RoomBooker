import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

extension AppointmentCopyWith on Appointment {
  Appointment copyWith({
    DateTime? startTime,
    DateTime? endTime,
    String? subject,
    Color? color,
  }) {
    return Appointment(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      subject: subject ?? this.subject,
      color: color ?? this.color,
    );
  }
}

class NewBookingCalendar extends StatefulWidget {
  final Function(Appointment) onAppointmentChanged;

  const NewBookingCalendar({super.key, required this.onAppointmentChanged});

  @override
  _NewBookingCalendarState createState() => _NewBookingCalendarState();
}

class _NewBookingCalendarState extends State<NewBookingCalendar> {
  final CalendarController _calendarController = CalendarController();
  final List<Appointment> _appointments = [];

  @override
  Widget build(BuildContext context) {
    return SfCalendar(
      view: CalendarView.week,
      showNavigationArrow: true,
      showDatePickerButton: true,
      showTodayButton: true,
      controller: _calendarController,
      dataSource: AppointmentDataSource(_appointments),
      specialRegions: _getTimeRegions(),
      onTap: (CalendarTapDetails details) {
        if (details.targetElement == CalendarElement.calendarCell) {
          setState(() {
            var appointment = Appointment(
              startTime: details.date!,
              endTime: details.date!.add(const Duration(hours: 1)),
              subject: 'New Appointment',
              color: Colors.blue,
            );
            if (_appointments.isEmpty) {
              _appointments.add(appointment);
            } else {
              _appointments[0] = appointment;
            }
            widget.onAppointmentChanged(appointment);
          });
        }
      },
      allowAppointmentResize: true, // Enable appointment resizing
      onAppointmentResizeEnd: (AppointmentResizeEndDetails details) {
        setState(() {
          final Appointment appointment = details.appointment;
          final int index = _appointments.indexOf(appointment);
          var appoinment = appointment.copyWith(
            startTime: roundToNearest30Minutes(details.startTime!),
            endTime: roundToNearest30Minutes(details.endTime!),
          );
          _appointments[index] = appoinment;
          widget.onAppointmentChanged(appoinment);
        });
      },
    );
  }

  List<TimeRegion> _getTimeRegions() {
    return [
      TimeRegion(
        startTime: DateTime(2023, 1, 1, 0, 0),
        endTime: DateTime(2023, 1, 1, 5, 59),
        enablePointerInteraction: false,
        recurrenceRule: 'FREQ=DAILY',
        color: Colors.grey.withOpacity(0.2),
        text: "Too Early",
      ),
      TimeRegion(
        startTime: DateTime(2023, 1, 1, 22, 0),
        endTime: DateTime(2023, 1, 1, 23, 59),
        enablePointerInteraction: false,
        recurrenceRule: 'FREQ=DAILY',
        text: "Too Late",
      ),
      TimeRegion(
        startTime: DateTime(2024, 12, 24, 6, 0),
        endTime: DateTime(2024, 12, 24, 21, 59),
        text: "Christmas Eve",
        enablePointerInteraction: false,
      ),
      TimeRegion(
        startTime: DateTime(2024, 12, 25, 6, 0),
        endTime: DateTime(2024, 12, 25, 21, 59),
        text: "Christmas Day",
        enablePointerInteraction: false,
      ),
      TimeRegion(
        startTime: DateTime(2025, 1, 1, 6, 0),
        endTime: DateTime(2025, 1, 1, 21, 59),
        text: "New Year's Day",
        enablePointerInteraction: false,
      )
    ];
  }
}

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}

DateTime roundToNearest30Minutes(DateTime dateTime) {
  final int minute = dateTime.minute;
  final int mod = minute % 30;
  final int roundedMinute = mod < 15 ? minute - mod : minute + (30 - mod);
  return DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour,
      roundedMinute);
}
