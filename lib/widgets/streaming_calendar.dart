import 'package:flutter/material.dart';
import 'package:room_booker/entities/blackout_window.dart';
import 'package:room_booker/entities/booking.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarState {
  List<Booking> bookings = [];
  List<BlackoutWindow> blackoutWindows = [];
}

class StreamingCalendar extends StatefulWidget {
  final Stream<CalendarState> stateStream;
  final bool showNavigationArrow;
  final bool showDatePickerButton;
  final bool showTodayButton;
  final CalendarView view;
  final Function(CalendarTapDetails) onTap;
  final Function(Booking) onTapBooking;
  final CalendarController controller = CalendarController();

  StreamingCalendar(
      {super.key,
      required this.stateStream,
      required this.showNavigationArrow,
      required this.showDatePickerButton,
      required this.showTodayButton,
      required this.view,
      required this.onTap,
      required this.onTapBooking}); // Added controller parameter

  @override
  _StreamingCalendarState createState() => _StreamingCalendarState();
}

class _StreamingCalendarState extends State<StreamingCalendar> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.stateStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        return calendarWidget(snapshot.data!);
      },
    );
  }

  Widget calendarWidget(CalendarState state) {
    List<Appointment> appointments = [];
    appointments.addAll(state.bookings.map(fromBooking).toList());

    List<TimeRegion> blackoutWindows =
        state.blackoutWindows.map(toTimeRegion).toList();

    return SfCalendar(
      view: widget.view,
      onTap: (details) {
        var appointments = details.appointments ?? [];
        if (appointments.isEmpty) {
          widget.onTap(details);
          return;
        }
        for (var appointment in details.appointments ?? []) {
          widget.onTapBooking(fromAppointment(appointment));
        }
      },
      controller: widget.controller,
      dataSource: DataSource(appointments),
      showNavigationArrow: widget.showNavigationArrow,
      showDatePickerButton: widget.showDatePickerButton,
      showTodayButton: widget.showTodayButton,
      specialRegions: blackoutWindows,
    );
  }
}

TimeRegion toTimeRegion(BlackoutWindow blackoutWindow) {
  return TimeRegion(
    startTime: blackoutWindow.start,
    endTime: blackoutWindow.end,
    enablePointerInteraction: false,
    text: blackoutWindow.reason,
    recurrenceRule: blackoutWindow.recurrenceRule,
    color: Colors.grey.withOpacity(0.2),
  );
}

class DataSource extends CalendarDataSource {
  DataSource(List<Appointment> source) {
    appointments = source;
  }
}

Appointment fromBooking(Booking booking) {
  return Appointment(
    startTime: booking.eventStartTime,
    endTime: booking.eventEndTime,
    subject: booking.eventName,
    color: booking.confirmation != null ? Colors.blue : Colors.red,
    location: booking.selectedRoom,
  );
}

Booking fromAppointment(Appointment appointment) {
  return Booking(
    eventName: appointment.subject,
    eventStartTime: appointment.startTime,
    eventEndTime: appointment.endTime,
    selectedRoom: appointment.location ?? "",
    name: '',
    email: '',
    message: '',
    phone: '',
    attendance: 0,
    doorUnlockTime: appointment.startTime,
    doorLockTime: appointment.endTime,
  );
}
