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
  Request? request;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
              flex: 2,
              child: Column(children: [
                const Heading("Pending"),
                PendingBookings(
                  onFocusBooking: focusBooking,
                  orgID: widget.orgID,
                ),
                const Heading("Resolved"),
                ResolvedBookings(
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
    return Consumer<OrgRepo>(
      builder: (context, repo, child) => StreamingCalendar(
        displayDate: request.eventStartTime,
        stateStream: Rx.combineLatest3(
            repo.listRequests(orgID, includeRoomIDs: {request.roomID}),
            repo.getRequestDetails(orgID, request.id!),
            repo.listBlackoutWindows(orgID),
            (requests, requestDetails, blackoutWindows) {
          return CalendarState(
            [request],
            (_) => requestDetails?.eventName ?? "Some Event",
            (_) => Colors.blue,
            blackoutWindows: blackoutWindows +
                requests.map((r) => BlackoutWindow.fromRequest(r)).toList(),
          );
        }),
        view: CalendarView.day,
      ),
    );
  }
}
