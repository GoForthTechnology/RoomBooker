import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/ui/core/stateful_calendar.dart';
import 'package:rxdart/rxdart.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class ConfirmedOneOffBookings extends StatelessWidget {
  final BookingRepo repo;
  final String orgID;
  final Function(Request) onFocusBooking;

  const ConfirmedOneOffBookings(
      {super.key,
      required this.orgID,
      required this.onFocusBooking,
      required this.repo});

  @override
  Widget build(BuildContext context) {
    return BookingList(
      onFocusBooking: onFocusBooking,
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
  final Function(Request) onFocusBooking;

  const ConfirmedRepeatingBookings(
      {super.key,
      required this.orgID,
      required this.onFocusBooking,
      required this.repo});

  @override
  Widget build(BuildContext context) {
    return BookingList(
      onFocusBooking: onFocusBooking,
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

class RejectedBookings extends StatelessWidget {
  final BookingRepo repo;
  final String orgID;
  final Function(Request) onFocusBooking;

  const RejectedBookings(
      {super.key,
      required this.orgID,
      required this.onFocusBooking,
      required this.repo});

  @override
  Widget build(BuildContext context) {
    return BookingList(
      onFocusBooking: onFocusBooking,
      orgID: orgID,
      emptyText: "No confirmed bookings",
      statusList: const [
        RequestStatus.denied,
      ],
      actions: [
        RequestAction(
            text: "Revisit",
            onClick: (request) => repo.revisitBookingRequest(orgID, request))
      ],
    );
  }
}

class PendingBookings extends StatelessWidget {
  final BookingRepo repo;
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
          text: "View",
          onClick: (request) => AutoRouter.of(context).push(ViewBookingsRoute(
              orgID: orgID,
              requestID: request.id!,
              view: CalendarView.day.name,
              targetDate: request.eventStartTime)),
        ),
        RequestAction(
            text: "Approve",
            onClick: (request) => repo.confirmRequest(orgID, request.id!)),
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
  final bool Function(Request)? requestFilter;
  final List<RequestAction> actions;

  const BookingList(
      {super.key,
      required this.onFocusBooking,
      required this.orgID,
      required this.actions,
      required this.statusList,
      required this.emptyText,
      this.requestFilter});

  @override
  Widget build(BuildContext context) {
    var bookingRepo = Provider.of<BookingRepo>(context, listen: false);
    return StreamBuilder(
      stream: bookingRepo
          .listRequests(
              orgID: orgID,
              startTime: DateTime.now(),
              endTime: DateTime.now().add(const Duration(days: 365)),
              includeStatuses: Set.from(statusList))
          .map((requests) =>
              requests.where(requestFilter ?? (r) => true).toList()),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          log(snapshot.error.toString(), error: snapshot.error);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${snapshot.error}')),
            );
          });
          return const Placeholder();
        }
        List<Request> requests = snapshot.data ?? [];
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
              stream: bookingRepo.getRequestDetails(orgID, request.id!),
              builder: (context, detailsSnapshot) {
                if (!detailsSnapshot.hasData) {
                  return Container();
                }
                var details = detailsSnapshot.data!;
                return BookingTile(
                  orgID: orgID,
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
    );
  }
}

class RequestAction {
  final String text;
  final Function(Request) onClick;

  RequestAction({required this.text, required this.onClick});
}

class BookingTile extends StatelessWidget {
  final String orgID;
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
    required this.orgID,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 1,
        child: ExpansionTile(
          title: Text("${details.eventName} for ${details.name}"),
          subtitle: _subtitle(context),
          leading: _leading(),
          trailing: _trailing(),
          expandedAlignment: Alignment.topLeft,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
        ));
  }

  Widget? _trailing() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions
          .map(
            (a) => ElevatedButton(
                onPressed: () => a.onClick(request), child: Text(a.text)),
          )
          .toList(),
    );
  }

  Widget? _leading() {
    if (request.status == RequestStatus.pending) {
      return null;
    }
    return Icon(
      Icons.event,
      /*color: request.status == RequestStatus.confirmed
            ? const Color.fromRGBO(120, 166, 90, 1.0)
            : const Color.fromRGBO(187, 39, 26, 1.0),*/
    );
  }

  Widget _subtitle(BuildContext context) {
    var startTimeStr =
        TimeOfDay.fromDateTime(request.eventStartTime).format(context);
    var endTimeStr =
        TimeOfDay.fromDateTime(request.eventEndTime).format(context);
    var subtitle =
        '${request.roomName} on ${formatDate(request.eventStartTime)} from $startTimeStr to $endTimeStr';
    if (request.isRepeating()) {
      subtitle += ' (recurring ${request.recurrancePattern})';
    }
    return Text(subtitle);
  }
}

Widget detailTable(Request booking, PrivateRequestDetails details) {
  return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Table(
        defaultColumnWidth: const FixedColumnWidth(200),
        children: [
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

String formatDate(DateTime dateTime) {
  return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
}

class Calendar extends StatelessWidget {
  final String orgID;
  final Request request;

  const Calendar({super.key, required this.request, required this.orgID});

  @override
  Widget build(BuildContext context) {
    var bookingRepo = Provider.of<BookingRepo>(context, listen: false);
    return CalendarStateProvider(
        initialView: CalendarView.day,
        focusDate: request.eventStartTime,
        child: Consumer<CalendarState>(
          builder: (context, calendarState, child) => StreamBuilder(
            stream: Rx.combineLatest3(
                bookingRepo.listRequests(
                    orgID: orgID,
                    startTime: stripTime(request.eventStartTime),
                    endTime: stripTime(request.eventStartTime)
                        .add(const Duration(days: 1)),
                    includeRoomIDs: {request.roomID},
                    includeStatuses: {RequestStatus.confirmed}),
                bookingRepo.getRequestDetails(orgID, request.id!),
                bookingRepo.listBlackoutWindows(orgID),
                (requests, requestDetails, blackoutWindows) => CalendarData(
                    existingRequests: requests,
                    blackoutWindows: blackoutWindows,
                    privateDetails: [requestDetails!])),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                log(snapshot.error.toString(), error: snapshot.error);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${snapshot.error}')),
                  );
                });
                return const Placeholder();
              }
              if (!snapshot.hasData) {
                return Container();
              }
              var calendarData = snapshot.data as CalendarData;
              var filteredRequests = calendarData.existingRequests
                  .where((r) => r.id != request.id)
                  .toList();
              return StatefulCalendar(
                view: CalendarView.day,
                showNavigationArrow: false,
                showDatePickerButton: false,
                showTodayButton: false,
                onAppointmentResizeEnd: (details) {},
                newAppointment: Appointment(
                  subject: calendarData.privateDetails![0].eventName,
                  color: Colors.blue,
                  startTime: request.eventStartTime,
                  endTime: request.eventEndTime,
                ),
                blackoutWindows: calendarData.blackoutWindows,
                appointments: {
                  for (var request in filteredRequests)
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
