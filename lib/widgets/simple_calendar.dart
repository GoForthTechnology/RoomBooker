import 'package:flutter/material.dart';
import 'package:room_booker/entities/blackout_window.dart';
import 'package:room_booker/entities/request.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarState {
  final Appointment? newAppointment;
  final Map<Appointment, Request> appointments;
  final List<BlackoutWindow> blackoutWindows;

  CalendarState(List<Request> requests, String Function(Request) name,
      Color Function(Request) color,
      {required this.blackoutWindows, this.newAppointment})
      : appointments = {
          for (var r in requests)
            Appointment(
              subject: name(r),
              color: color(r),
              startTime: r.eventStartTime,
              endTime: r.eventEndTime,
            ): r
        } {
    blackoutWindows.sort((a, b) => a.start.compareTo(b.start));
  }
}

class ResizeDetails {
  final Appointment appointment;
  final DateTime startTime;
  final DateTime endTime;

  ResizeDetails({
    required this.appointment,
    required this.startTime,
    required this.endTime,
  });
}

class SimpleCalendar extends StatefulWidget {
  final CalendarState state;
  final bool showNavigationArrow;
  final bool showDatePickerButton;
  final bool showTodayButton;
  final CalendarView view;
  final DateTime? selectedDate;
  final DateTime? displayDate;
  final Function(CalendarTapDetails)? onTap;
  final Function(Request)? onTapBooking;

  final bool allowAppointmentResize;
  final Function(ResizeDetails)? onAppointmentResizeEnd;

  const SimpleCalendar(
      {super.key,
      required this.state,
      required this.view,
      this.onTap,
      this.onTapBooking,
      this.showNavigationArrow = false,
      this.showDatePickerButton = false,
      this.showTodayButton = false,
      this.onAppointmentResizeEnd,
      this.selectedDate,
      this.displayDate,
      this.allowAppointmentResize = false}); // Added controller parameter

  @override
  StreamingCalendarState createState() => StreamingCalendarState();
}

class StreamingCalendarState extends State<SimpleCalendar> {
  final CalendarController controller = CalendarController();

  @override
  void initState() {
    controller.selectedDate = widget.selectedDate;
    controller.displayDate = widget.displayDate;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Appointment> appointments = List.from(widget.state.appointments.keys);
    List<TimeRegion> blackoutWindows =
        widget.state.blackoutWindows.map(toTimeRegion).toList();

    Function(AppointmentResizeEndDetails)? onResizeEnd;
    if (widget.onAppointmentResizeEnd != null) {
      onResizeEnd = (details) {
        widget.onAppointmentResizeEnd!(ResizeDetails(
            appointment: details.appointment,
            startTime: details.startTime!,
            endTime: details.endTime!));
      };
    }
    return SfCalendar(
      view: widget.view,
      onTap: (details) {
        controller.selectedDate = null; // Clear the selected date
        var appointments = details.appointments ?? [];
        if (appointments.isEmpty && widget.onTap != null) {
          widget.onTap!(details);
          return;
        }
        if (widget.onTapBooking != null) {
          for (var appointment in details.appointments ?? []) {
            var request = widget.state.appointments[appointment];
            if (request == null) {
              throw Exception("Appointment not found in state");
            }
            widget.onTapBooking!(request);
          }
        }
      },
      minDate: nowRoundedUpToNearestHour(),
      controller: controller,
      dataSource: DataSource(appointments +
          [
            if (widget.state.newAppointment != null)
              widget.state.newAppointment!
          ]),
      showNavigationArrow: widget.showNavigationArrow,
      showDatePickerButton: widget.showDatePickerButton,
      showTodayButton: widget.showTodayButton,
      specialRegions: blackoutWindows,
      allowAppointmentResize: widget.allowAppointmentResize,
      onAppointmentResizeEnd: onResizeEnd,
    );
  }
}

DateTime nowRoundedUpToNearestHour() {
  var now = DateTime.now();
  return DateTime(now.year, now.month, now.day, now.hour + 1);
}

TimeRegion toTimeRegion(BlackoutWindow blackoutWindow) {
  return TimeRegion(
    startTime: blackoutWindow.start,
    endTime: blackoutWindow.end,
    enablePointerInteraction: false,
    text: blackoutWindow.reason,
    recurrenceRule: blackoutWindow.recurrenceRule,
    color: Colors.grey.withValues(alpha: 0.2),
  );
}

class DataSource extends CalendarDataSource {
  DataSource(List<Appointment> source) {
    appointments = source;
  }
}

Request fromAppointment(Appointment appointment, RequestStatus status) {
  return Request(
    eventStartTime: appointment.startTime,
    eventEndTime: appointment.endTime,
    selectedRoom: appointment.location ?? "",
    status: status,
  );
}
