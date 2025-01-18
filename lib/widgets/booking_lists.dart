import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/request.dart';
import 'package:room_booker/repos/org_repo.dart';

class ResolvedBookings extends StatelessWidget {
  final String orgID;
  final Function(Request) onFocusBooking;

  const ResolvedBookings(
      {super.key, required this.onFocusBooking, required this.orgID});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrgRepo>(
      builder: (context, repo, child) => StreamBuilder(
        stream: repo.listRequests(orgID, includeStatuses: [
          RequestStatus.confirmed,
          RequestStatus.denied,
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }
          List<Request> bookings = snapshot.data!;
          bookings.sort((a, b) => a.eventStartTime.compareTo(b.eventStartTime));
          return ListView.builder(
            shrinkWrap: true,
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return ResolvedBookingTitle(
                booking: bookings[index],
                onFocusBooking: onFocusBooking,
                onRevisitBooking: (b) =>
                    repo.revisitBookingRequest(orgID, b.id!),
              );
            },
          );
        },
      ),
    );
  }
}

class ResolvedBookingTitle extends StatelessWidget {
  final Function(Request) onFocusBooking;
  final Function(Request) onRevisitBooking;
  final Request booking;

  const ResolvedBookingTitle(
      {super.key,
      required this.onFocusBooking,
      required this.booking,
      required this.onRevisitBooking});

  @override
  Widget build(BuildContext context) {
    bool confirmed = booking.status == RequestStatus.confirmed;
    String trailingText = confirmed ? 'CONFIRMED' : 'DENIED';
    return Card(
        elevation: 1,
        color: confirmed
            ? const Color.fromRGBO(220, 233, 213, 1.0)
            : const Color.fromRGBO(238, 205, 205, 1.0),
        child: ExpansionTile(
          title: Text(bookingTitle(booking)),
          leading: Icon(
            Icons.event,
            color: confirmed
                ? const Color.fromRGBO(120, 166, 90, 1.0)
                : const Color.fromRGBO(187, 39, 26, 1.0),
          ),
          subtitle: Text(bookingSubtitle(booking)),
          trailing: Text(trailingText),
          expandedAlignment: Alignment.topLeft,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                detailTable(booking),
                Column(
                  children: [
                    ElevatedButton(
                        onPressed: () => onFocusBooking(booking),
                        child: const Text("Toggle Calendar")),
                    ElevatedButton(
                        onPressed: () => onRevisitBooking(booking),
                        child: const Text("Revisit")),
                  ],
                )
              ],
            )
          ],
        ));
  }
}

class PendingBookings extends StatelessWidget {
  final String orgID;
  final Function(Request) onFocusBooking;

  const PendingBookings(
      {super.key, required this.onFocusBooking, required this.orgID});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrgRepo>(
      builder: (context, repo, child) => StreamBuilder(
        stream: repo.listRequests(orgID, includeStatuses: [
          RequestStatus.pending,
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }
          List<Request> bookings = snapshot.data!;
          if (bookings.isEmpty) {
            return const Text("No pending bookings.");
          }
          bookings.sort((a, b) => a.eventStartTime.compareTo(b.eventStartTime));
          return ListView.builder(
            shrinkWrap: true,
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return PendingBookingTile(
                orgID: orgID,
                request: bookings[index],
                onFocusBooking: onFocusBooking,
              );
            },
          );
        },
      ),
    );
  }
}

class PendingBookingTile extends StatelessWidget {
  final Function(Request) onFocusBooking;
  final Request request;
  final String orgID;

  const PendingBookingTile(
      {super.key,
      required this.onFocusBooking,
      required this.request,
      required this.orgID});

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 1,
        child: ExpansionTile(
          leading: const Icon(Icons.event),
          title: Text(bookingTitle(request)),
          subtitle: Text(bookingSubtitle(request)),
          trailing: Consumer<OrgRepo>(
              builder: (context, repo, child) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => repo.confirmRequest(orgID, request),
                        child: const Text('Approve'),
                      ),
                      ElevatedButton(
                        onPressed: () => repo.denyRequest(orgID, request.id!),
                        child: const Text('Reject'),
                      )
                    ],
                  )),
          expandedAlignment: Alignment.topLeft,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                detailTable(request),
                Column(
                  children: [
                    ElevatedButton(
                        onPressed: () => onFocusBooking(request),
                        child: const Text("Toggle Calendar")),
                  ],
                )
              ],
            )
          ],
        ));
  }
}

Widget detailTable(Request booking) {
  return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Table(
        defaultColumnWidth: const FixedColumnWidth(200),
        children: [
          // TODO: Add private fields
          /*bookingField('Phone', booking.phone),
          bookingField('Email', booking.email),*/
          bookingField('Start Time',
              "${formatDate(booking.eventStartTime)} ${formatTime(booking.eventStartTime)}"),
          bookingField('End Time',
              "${formatDate(booking.eventEndTime)} ${formatTime(booking.eventEndTime)}"),
        ],
      ));
}

TableRow bookingField(String label, String value) {
  return TableRow(children: [
    TableCell(
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    ),
    TableCell(
      child: Text(value),
    ),
  ]);
}

String bookingTitle(Request booking) {
  // TODO: replace with private fields
  // return '${booking.eventName} for ${booking.name}';
  return "Some title";
}

String bookingSubtitle(Request booking) {
  return '${booking.selectedRoom} on ${formatDate(booking.eventStartTime)} from ${formatTime(booking.eventStartTime)} to ${formatTime(booking.eventEndTime)}';
}

String formatDate(DateTime dateTime) {
  return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
}

String formatTime(DateTime dateTime) {
  var hourStr = dateTime.hour.toString().padLeft(2, '0');
  var minuteStr = dateTime.minute.toString().padLeft(2, '0');
  return "$hourStr:$minuteStr";
}
