import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/booking.dart';
import 'package:room_booker/repos/booking_repo.dart';
import 'package:room_booker/utils/appointment_extensions.dart';
import 'package:room_booker/widgets/streaming_calendar.dart';
import 'package:rxdart/rxdart.dart';
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
  final DateTime? initialStartTime;
  final DateTime? initialEndTime;
  final String roomID;

  final Function(Appointment) onAppointmentChanged;

  const NewBookingCalendar(
      {super.key,
      required this.onAppointmentChanged,
      this.initialStartTime,
      this.initialEndTime,
      required this.roomID});

  @override
  State<StatefulWidget> createState() => _NewBookingCalendarState();
}

class _NewBookingCalendarState extends State<NewBookingCalendar> {
  final PublishSubject<Appointment?> _appointmentSubject = PublishSubject();

  @override
  void initState() {
    if (widget.initialEndTime != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        var appointment = Appointment(
          startTime: widget.initialStartTime!,
          endTime: widget.initialEndTime!,
          subject: 'New Appointment',
          color: Colors.blue,
        );
        _updateAppointment(appointment);
      });
    }
    super.initState();
  }

  void _updateAppointment(Appointment appointment) {
    _appointmentSubject.add(appointment);
    widget.onAppointmentChanged(appointment);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingRepo>(
        builder: (context, repo, child) => StreamingCalendar(
              view: CalendarView.week,
              showNavigationArrow: true,
              showDatePickerButton: true,
              showTodayButton: true,
              allowAppointmentResize: true,
              stateStream: Rx.combineLatest3(
                  _appointmentSubject.stream.startWith(null),
                  repo.bookings(roomID: widget.roomID),
                  repo.blackoutWindows.asStream(),
                  (appointment, bookings, blackoutWindows) {
                var windows = blackoutWindows;
                windows.addAll(
                    bookings.map((booking) => booking.toBlackoutWindow()));

                return CalendarState(
                    bookings: appointment == null
                        ? []
                        : [appointment.toBooking(BookingStatus.pending)],
                    blackoutWindows: windows);
              }),
              onAppointmentResizeEnd: (details) async {
                var startTime = roundToNearest30Minutes(details.startTime);
                var endTime = roundToNearest30Minutes(details.endTime);
                _updateAppointment(Appointment(
                  startTime: startTime,
                  endTime: endTime,
                  subject: details.appointment.subject,
                  color: details.appointment.color,
                ));
              },
              onTap: (detail) {
                if (detail.targetElement == CalendarElement.calendarCell) {
                  _updateAppointment(Appointment(
                    startTime: detail.date!,
                    endTime: detail.date!.add(const Duration(hours: 1)),
                    subject: 'New Appointment',
                    color: Colors.blue,
                  ));
                }
              },
            ));
  }
}

DateTime roundToNearest30Minutes(DateTime dateTime) {
  final int minute = dateTime.minute;
  final int mod = minute % 30;
  final int roundedMinute = mod < 15 ? minute - mod : minute + (30 - mod);
  return DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour,
      roundedMinute);
}
