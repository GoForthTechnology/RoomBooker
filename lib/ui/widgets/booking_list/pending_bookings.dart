import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/ui/widgets/booking_list/booking_lists.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class PendingBookings extends StatelessWidget {
  final BookingRepo repo;
  final String orgID;

  const PendingBookings({super.key, required this.orgID, required this.repo});

  @override
  Widget build(BuildContext context) {
    return BookingList(
      orgID: orgID,
      statusList: const [RequestStatus.pending],
      emptyText: "No Pending Requests",
      actions: [
        RequestAction(
          icon: Icons.visibility,
          text: "View",
          onClick: (request) => AutoRouter.of(context).push(
            ViewBookingsRoute(
              orgID: orgID,
              requestID: request.id!,
              view: CalendarView.day.name,
              targetDate: request.eventStartTime,
            ),
          ),
        ),
        RequestAction(
          icon: Icons.check_circle,
          text: "Approve",
          onClick: (request) => repo.confirmRequest(orgID, request.id!),
        ),
        RequestAction(
          icon: Icons.block,
          text: "Deny",
          onClick: (request) => repo.denyRequest(orgID, request.id!),
        ),
      ],
    );
  }
}
