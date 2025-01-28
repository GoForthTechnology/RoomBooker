import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/request.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:room_booker/widgets/heading.dart';
import 'package:room_booker/widgets/booking_lists.dart';
import 'package:room_booker/widgets/stateful_calendar.dart';
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
  Request? request;

  @override
  Widget build(BuildContext context) {
    var repo = Provider.of<OrgRepo>(context, listen: false);
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
              flex: 2,
              child: Column(children: [
                const Heading("Pending"),
                PendingBookings(
                  repo: repo,
                  onFocusBooking: focusBooking,
                  orgID: widget.orgID,
                ),
                const Heading("Resolved"),
                ResolvedBookings(
                  repo: repo,
                  onFocusBooking: focusBooking,
                  orgID: widget.orgID,
                )
              ])),
          if (request != null)
            Flexible(
                flex: 1,
                child: SizedBox(
                    height: 600,
                    child: Calendar(
                      request: request!,
                      orgID: widget.orgID,
                    ))),
        ],
      ),
    );
  }

  void focusBooking(Request booking) {
    setState(() {
      if (request != null) {
        request = null;
      } else {
        request = booking;
      }
    });
  }
}

class Calendar extends StatelessWidget {
  final String orgID;
  final Request request;

  const Calendar({super.key, required this.request, required this.orgID});

  @override
  Widget build(BuildContext context) {
    return CalendarStateProvider(
        child: Consumer2<OrgRepo, CalendarState>(
      builder: (context, repo, calendarState, child) => StreamBuilder(
        stream: Rx.combineLatest3(
            repo.listRequests(
                orgID: orgID,
                startTime: stripTime(request.eventStartTime),
                endTime:
                    stripTime(request.eventStartTime).add(Duration(days: 1)),
                includeRoomIDs: {request.roomID},
                includeStatuses: {RequestStatus.confirmed}),
            repo.getRequestDetails(orgID, request.id!),
            repo.listBlackoutWindows(orgID),
            (requests, requestDetails, blackoutWindows) => CalendarData(
                existingRequests: requests,
                blackoutWindows: blackoutWindows,
                privateDetails: [requestDetails!])),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print(snapshot.error);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${snapshot.error}')),
              );
            });
            return const Placeholder();
          }
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }
          var calendarData = snapshot.data as CalendarData;
          return StatefulCalendar(
            view: CalendarView.day,
            showNavigationArrow: true,
            showDatePickerButton: true,
            showTodayButton: true,
            onAppointmentResizeEnd: (details) {},
            newAppointment: Appointment(
              subject: calendarData.privateDetails![0].eventName,
              color: Colors.blue,
              startTime: request.eventStartTime,
              endTime: request.eventEndTime,
            ),
            blackoutWindows: calendarData.blackoutWindows,
            appointments: {
              for (var request in calendarData.existingRequests)
                Appointment(
                  subject: "Some Request",
                  color: Colors.grey,
                  startTime: request.eventStartTime,
                  endTime: request.eventEndTime,
                ): request
            },
          );
        },
      ),
    ));
  }
}

DateTime stripTime(DateTime time) {
  return DateTime(time.year, time.month, time.day);
}
