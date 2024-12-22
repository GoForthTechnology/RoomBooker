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

class CalendarWidget extends StatefulWidget {
  CalendarWidget({super.key});

  @override
  _CalendarWidgetState createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  final CalendarController _calendarController = CalendarController();
  final List<Appointment> _appointments = [];

  @override
  Widget build(BuildContext context) {
    return SfCalendar(
      view: CalendarView.week,
      controller: _calendarController,
      dataSource: AppointmentDataSource(_appointments),
      onTap: (CalendarTapDetails details) {
        if (details.targetElement == CalendarElement.calendarCell) {
          final DateTime selectedDate = details.date!;
          setState(() {
            _appointments.add(Appointment(
              startTime: selectedDate,
              endTime: selectedDate.add(const Duration(hours: 1)),
              subject: 'New Appointment',
              color: Colors.blue,
            ));
          });
        }
      },
      allowAppointmentResize: true, // Enable appointment resizing
      onAppointmentResizeEnd: (AppointmentResizeEndDetails details) {
        setState(() {
          final Appointment appointment = details.appointment;
          final int index = _appointments.indexOf(appointment);
          _appointments[index] = appointment.copyWith(
            startTime: details.startTime,
            endTime: details.endTime,
          );
        });
      },
    );
  }
}

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}
