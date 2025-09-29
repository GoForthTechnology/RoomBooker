import 'package:flutter/material.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/ui/widgets/booking_lists.dart';

class ConfirmedOneOffBookings extends StatelessWidget {
  final BookingRepo repo;
  final String orgID;

  const ConfirmedOneOffBookings(
      {super.key, required this.orgID, required this.repo});

  @override
  Widget build(BuildContext context) {
    return BookingList(
      orgID: orgID,
      emptyText: "No confirmed bookings",
      requestFilter: (r) => !r.isRepeating(),
      statusList: const [
        RequestStatus.confirmed,
      ],
      actions: [
        RequestAction(
            text: "Revisit",
            onClick: (request) => repo.revisitBookingRequest(orgID, request))
      ],
    );
  }
}

class ConfirmedRepeatingBookings extends StatelessWidget {
  final BookingRepo repo;
  final String orgID;

  const ConfirmedRepeatingBookings(
      {super.key, required this.orgID, required this.repo});

  @override
  Widget build(BuildContext context) {
    return BookingList(
      orgID: orgID,
      emptyText: "No recurring bookings",
      requestFilter: (r) => r.isRepeating() && !r.hasEndDate(),
      statusList: const [
        RequestStatus.confirmed,
      ],
      actions: [
        RequestAction(
          text: "End",
          onClick: (request) => _confirmEndBooking(context, orgID, request),
        ),
        RequestAction(
          text: "Revisit",
          onClick: (request) => repo.revisitBookingRequest(orgID, request),
        ),
      ],
    );
  }

  void _confirmEndBooking(
      BuildContext context, String orgID, Request request) async {
    bool shouldEnd = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("End Booking"),
              content: const Text("Are you sure you want to end this booking?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text("End"),
                ),
              ],
            ));
    if (!shouldEnd || !context.mounted) {
      return;
    }
    DateTime? endDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (endDate == null) {
      return;
    }
    await repo.endBooking(orgID, request.id!, endDate);
  }
}
