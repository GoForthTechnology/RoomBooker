import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/booking.dart';
import 'package:room_booker/repos/booking_repo.dart';
import 'package:room_booker/widgets/heading.dart';
import 'package:room_booker/widgets/booking_lists.dart';
import 'package:room_booker/widgets/streaming_calendar.dart';
import 'package:rxdart/rxdart.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

@RoutePage()
class ReviewBookingsScreen extends StatelessWidget {
  const ReviewBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Booking Requests'),
        ),
        body: const ReviewPanel());
  }
}

class ReviewPanel extends StatefulWidget {
  const ReviewPanel({super.key});

  @override
  State<ReviewPanel> createState() => _ReviewPanelState();
}

class _ReviewPanelState extends State<ReviewPanel> {
  Appointment? appointment;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
              flex: 2,
              child: Column(children: [
                const Heading(text: "Pending"),
                PendingBookings(onFocusBooking: focusBooking),
                const Heading(text: "Resolved"),
                ResolvedBookings(onFocusBooking: focusBooking)
              ])),
          if (appointment != null)
            Flexible(
                flex: 1,
                child: SizedBox(
                    height: 600, child: Calendar(appointment: appointment!))),
        ],
      ),
    );
  }

  void focusBooking(Booking booking) {
    setState(() {
      if (appointment != null) {
        appointment = null;
      } else {
        appointment = Appointment(
            startTime: booking.eventStartTime,
            endTime: booking.eventEndTime,
            subject: booking.eventName,
            notes: booking.message);
      }
    });
  }
}

class Calendar extends StatelessWidget {
  final Appointment appointment;

  const Calendar({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingRepo>(
      builder: (context, repo, child) => StreamingCalendar(
        displayDate: appointment.startTime,
        stateStream:
            Rx.combineLatest2(repo.bookings(), repo.blackoutWindows.asStream(),
                (bookings, blackoutWindows) {
          var booking = Booking(
            name: 'Default Name',
            email: 'default@example.com',
            phone: '123-456-7890',
            eventName: appointment.subject,
            eventStartTime: appointment.startTime,
            eventEndTime: appointment.endTime,
            attendance: 0,
            selectedRoom: 'Default Room',
            message: appointment.notes ?? "",
            doorUnlockTime: appointment.startTime,
            doorLockTime: appointment.endTime,
            status: BookingStatus.pending,
          );
          return CalendarState(
            bookings: [booking],
            blackoutWindows: blackoutWindows +
                bookings.map((b) => b.toBlackoutWindow()).toList(),
          );
        }),
        view: CalendarView.day,
      ),
    );
  }
}
