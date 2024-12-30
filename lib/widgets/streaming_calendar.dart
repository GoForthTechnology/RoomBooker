import 'package:flutter/material.dart';
import 'package:room_booker/entities/blackout_window.dart';
import 'package:room_booker/entities/booking.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarState {
  final List<Booking> bookings;
  final List<BlackoutWindow> blackoutWindows;

  CalendarState({required this.bookings, required this.blackoutWindows}) {
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

class StreamingCalendar extends StatefulWidget {
  final Stream<CalendarState> stateStream;
  final bool showNavigationArrow;
  final bool showDatePickerButton;
  final bool showTodayButton;
  final CalendarView view;
  final DateTime? selectedDate;
  final DateTime? displayDate;
  final Function(CalendarTapDetails)? onTap;
  final Function(Booking)? onTapBooking;

  final bool allowAppointmentResize;
  final Function(ResizeDetails)? onAppointmentResizeEnd;

  const StreamingCalendar(
      {super.key,
      required this.stateStream,
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

class StreamingCalendarState extends State<StreamingCalendar> {
  final CalendarController controller = CalendarController();

  @override
  void initState() {
    controller.selectedDate = widget.selectedDate;
    controller.displayDate = widget.displayDate;
    super.initState();
  }

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
        var appointments = details.appointments ?? [];
        if (appointments.isEmpty && widget.onTap != null) {
          widget.onTap!(details);
          return;
        }
        if (widget.onTapBooking != null) {
          for (var appointment in details.appointments ?? []) {
            widget.onTapBooking!(
                fromAppointment(appointment, BookingStatus.unknown));
          }
        }
      },
      controller: controller,
      dataSource: DataSource(appointments),
      showNavigationArrow: widget.showNavigationArrow,
      showDatePickerButton: widget.showDatePickerButton,
      showTodayButton: widget.showTodayButton,
      specialRegions: blackoutWindows,
      allowAppointmentResize: widget.allowAppointmentResize,
      onAppointmentResizeEnd: onResizeEnd,
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
    color: Colors.grey.withValues(alpha: 0.2),
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
    color: booking.status == BookingStatus.confirmed ? Colors.blue : Colors.red,
    location: booking.selectedRoom,
  );
}

Booking fromAppointment(Appointment appointment, BookingStatus status) {
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
    status: status,
  );
}
