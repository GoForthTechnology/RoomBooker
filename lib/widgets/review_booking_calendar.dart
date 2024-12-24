import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/booking.dart';
import 'package:room_booker/repos/booking_repo.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class ReviewBookingsCalendar extends StatefulWidget {
  const ReviewBookingsCalendar({super.key});

  @override
  _ReviewBookingsCalendarState createState() => _ReviewBookingsCalendarState();
}

class _ReviewBookingsCalendarState extends State<ReviewBookingsCalendar> {
  final CalendarController _calendarController = CalendarController();
  final List<Appointment> _appointments = [];
  Appointment? _newAppointment;

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingRepo>(
        builder: (context, repo, child) => StreamBuilder(
              stream: repo.requests,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasData) {
                  _appointments.clear();
                  if (_newAppointment != null) {
                    _appointments.add(_newAppointment!);
                  }
                  _appointments.addAll(snapshot.data!.map(toAppointment));
                }
                return SizedBox(
                  height: 1100,
                  child: Card(
                      child: SfCalendar(
                    view: CalendarView.week,
                    showNavigationArrow: true,
                    showDatePickerButton: true,
                    showTodayButton: true,
                    controller: _calendarController,
                    dataSource: AppointmentDataSource(_appointments),
                    specialRegions: _getTimeRegions(),
                    onTap: (CalendarTapDetails details) {
                      // TODO
                    },
                  )),
                );
              },
            ));
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

Appointment toAppointment(Booking booking) {
  return Appointment(
    startTime: booking.eventStartTime,
    endTime: booking.eventEndTime,
    subject: booking.eventName,
    color: Colors.blue,
  );
}
