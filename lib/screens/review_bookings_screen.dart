import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/blackout_window.dart';
import 'package:room_booker/entities/request.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:room_booker/widgets/heading.dart';
import 'package:room_booker/widgets/booking_lists.dart';
import 'package:room_booker/widgets/streaming_calendar.dart';
import 'package:rxdart/rxdart.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

@RoutePage()
class ReviewBookingsScreen extends StatelessWidget {
  final String orgID;

  const ReviewBookingsScreen(
      {super.key, @PathParam("orgID") required this.orgID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Booking Requests'),
        ),
        body: ReviewPanel(
          orgID: orgID,
        ));
  }
}

class ReviewPanel extends StatefulWidget {
  final String orgID;
  const ReviewPanel({super.key, required this.orgID});

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
                PendingBookings(
                  onFocusBooking: focusBooking,
                  orgID: widget.orgID,
                ),
                const Heading(text: "Resolved"),
                ResolvedBookings(
                  onFocusBooking: focusBooking,
                  orgID: widget.orgID,
                )
              ])),
          if (appointment != null)
            Flexible(
                flex: 1,
                child: SizedBox(
                    height: 600,
                    child: Calendar(
                      appointment: appointment!,
                      orgID: widget.orgID,
                    ))),
        ],
      ),
    );
  }

  void focusBooking(Request booking) {
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
  final String orgID;
  final Appointment appointment;

  const Calendar({super.key, required this.appointment, required this.orgID});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrgRepo>(
      builder: (context, repo, child) => StreamingCalendar(
        displayDate: appointment.startTime,
        stateStream: Rx.combineLatest2(
            repo.listBookings(orgID), repo.listBlackoutWindows(orgID),
            (bookings, blackoutWindows) {
          var booking = Request(
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
            status: RequestStatus.pending,
          );
          return CalendarState(
            appointments: [
              Appointment(
                endTime: booking.eventEndTime,
                startTime: booking.eventStartTime,
                subject: booking.eventName,
              ),
            ],
            blackoutWindows: blackoutWindows +
                bookings.map((b) => BlackoutWindow.fromBooking(b)).toList(),
          );
        }),
        view: CalendarView.day,
      ),
    );
  }
}
