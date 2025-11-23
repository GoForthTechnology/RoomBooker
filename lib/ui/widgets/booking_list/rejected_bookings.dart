import 'package:flutter/material.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/ui/widgets/booking_list/booking_lists.dart';

class RejectedBookings extends StatelessWidget {
  final BookingRepo repo;
  final String orgID;

  const RejectedBookings({super.key, required this.orgID, required this.repo});

  @override
  Widget build(BuildContext context) {
    return BookingList(
      orgID: orgID,
      emptyText: "No confirmed bookings",
      statusList: const [RequestStatus.denied],
      actions: [
        RequestAction(
          icon: Icons.assignment_return,
          text: "Revisit",
          onClick: (request) => repo.revisitBookingRequest(orgID, request),
        ),
      ],
    );
  }
}
