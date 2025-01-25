import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/request.dart';
import 'package:room_booker/repos/org_repo.dart';

class ResolvedBookings extends StatelessWidget {
  final OrgRepo repo;
  final String orgID;
  final Function(Request) onFocusBooking;

  const ResolvedBookings(
      {super.key,
      required this.orgID,
      required this.onFocusBooking,
      required this.repo});

  @override
  Widget build(BuildContext context) {
    return BookingList(
      onFocusBooking: onFocusBooking,
      orgID: orgID,
      emptyText: "No Resolved Requests",
      statusList: const [
        RequestStatus.confirmed,
        RequestStatus.denied,
      ],
      actions: [
        RequestAction(
            text: "Revisit",
            onClick: (request) =>
                repo.revisitBookingRequest(orgID, request.id!))
      ],
    );
  }
}

class PendingBookings extends StatelessWidget {
  final OrgRepo repo;
  final String orgID;
  final Function(Request) onFocusBooking;

  const PendingBookings(
      {super.key,
      required this.orgID,
      required this.onFocusBooking,
      required this.repo});

  @override
  Widget build(BuildContext context) {
    return BookingList(
      onFocusBooking: onFocusBooking,
      orgID: orgID,
      statusList: const [RequestStatus.pending],
      emptyText: "No Pending Requests",
      actions: [
        RequestAction(
            text: "Approve",
            onClick: (request) => repo.confirmRequest(orgID, request)),
        RequestAction(
            text: "Deny",
            onClick: (request) => repo.denyRequest(orgID, request.id!)),
      ],
    );
  }
}

class BookingList extends StatelessWidget {
  final String orgID;
  final String emptyText;
  final Function(Request) onFocusBooking;
  final List<RequestStatus> statusList;
  final List<RequestAction> actions;

  const BookingList(
      {super.key,
      required this.onFocusBooking,
      required this.orgID,
      required this.actions,
      required this.statusList,
      required this.emptyText});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrgRepo>(
      builder: (context, repo, child) => StreamBuilder(
        stream: repo.listRequests(orgID, includeStatuses: statusList),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }
          List<Request> requests = snapshot.data!;
          if (requests.isEmpty) {
            return Text(emptyText);
          }
          requests.sort((a, b) => a.eventStartTime.compareTo(b.eventStartTime));
          return ListView.builder(
            shrinkWrap: true,
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var request = requests[index];
              return StreamBuilder(
                stream: repo.getRequestDetails(orgID, request.id!),
                builder: (context, detailsSnapshot) {
                  if (!detailsSnapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  var details = detailsSnapshot.data!;
                  return BookingTile(
                    request: request,
                    details: details,
                    onFocusBooking: onFocusBooking,
                    actions: actions,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class RequestAction {
  final String text;
  final Function(Request) onClick;

  RequestAction({required this.text, required this.onClick});
}

class BookingTile extends StatelessWidget {
  final List<RequestAction> actions;
  final Function(Request) onFocusBooking;
  final Request request;
  final PrivateRequestDetails details;

  const BookingTile({
    super.key,
    required this.onFocusBooking,
    required this.request,
    required this.actions,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    bool resolved = request.status != RequestStatus.pending;
    bool confirmed = request.status == RequestStatus.confirmed;
    return Card(
        elevation: 1,
        color: resolved
            ? confirmed
                ? const Color.fromRGBO(220, 233, 213, 1.0)
                : const Color.fromRGBO(238, 205, 205, 1.0)
            : null,
        child: ExpansionTile(
          title: Text("${details.eventName} for ${details.name}"),
          subtitle: _subtitle(),
          leading: _leading(),
          trailing: _trailing(),
          expandedAlignment: Alignment.topLeft,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                detailTable(request, details),
                Column(
                  children: [
                    ElevatedButton(
                        onPressed: () => onFocusBooking(request),
                        child: const Text("Toggle Calendar")),
                    ...actions.map(
                      (a) => ElevatedButton(
                          onPressed: () => a.onClick(request),
                          child: Text(a.text)),
                    )
                  ],
                )
              ],
            )
          ],
        ));
  }

  Widget? _trailing() {
    if (request.status == RequestStatus.pending) {
      return null;
    }
    if (request.status == RequestStatus.confirmed) {
      return const Text('CONFIRMED');
    }
    if (request.status == RequestStatus.denied) {
      return const Text('DENIED');
    }
    throw ("Invalid status!");
  }

  Widget? _leading() {
    if (request.status == RequestStatus.pending) {
      return null;
    }
    return Icon(Icons.event,
        color: request.status == RequestStatus.confirmed
            ? const Color.fromRGBO(120, 166, 90, 1.0)
            : const Color.fromRGBO(187, 39, 26, 1.0));
  }

  Widget _subtitle() {
    return Text(
        '${request.roomName} on ${formatDate(request.eventStartTime)} from ${formatTime(request.eventStartTime)} to ${formatTime(request.eventEndTime)}');
  }
}

Widget detailTable(Request booking, PrivateRequestDetails details) {
  return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Table(
        defaultColumnWidth: const FixedColumnWidth(200),
        children: [
          bookingField('Start Time',
              "${formatDate(booking.eventStartTime)} ${formatTime(booking.eventStartTime)}"),
          bookingField('End Time',
              "${formatDate(booking.eventEndTime)} ${formatTime(booking.eventEndTime)}"),
          bookingField('Phone', details.phone),
          bookingField('Email', details.email),
          bookingField('Message', details.message),
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

String formatDate(DateTime dateTime) {
  return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
}

String formatTime(DateTime dateTime) {
  var hourStr = dateTime.hour.toString().padLeft(2, '0');
  var minuteStr = dateTime.minute.toString().padLeft(2, '0');
  return "$hourStr:$minuteStr";
}
