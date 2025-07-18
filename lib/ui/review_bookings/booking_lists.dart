import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/ui/core/room_selector.dart';
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

class ConflictingBookings extends StatelessWidget {
  final BookingRepo repo;
  final String orgID;
  final Function(Request) onFocusBooking;

  const ConflictingBookings(
      {super.key,
      required this.orgID,
      required this.onFocusBooking,
      required this.repo});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: repo.findOverlappingBookings(
          orgID, DateTime.now(), DateTime.now().add(Duration(days: 365))),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          log(snapshot.error.toString(), error: snapshot.error);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${snapshot.error}')),
            );
          });
          return const CircularProgressIndicator();
        }
        if (!snapshot.hasData) {
          return Container();
        }
        var conflicts = snapshot.data!;
        Set<Request> conflictingRequests = {};
        for (var pair in conflicts) {
          conflictingRequests.add(pair.first);
          conflictingRequests.add(pair.second);
        }
        return BookingList(
          onFocusBooking: onFocusBooking,
          orgID: orgID,
          emptyText: "No conflicting bookings",
          requestFilter: (r) => conflictingRequests.contains(r),
          statusList: const [
            RequestStatus.confirmed,
          ],
          overrideRequests: conflictingRequests
              .sorted((a, b) => a.eventStartTime.compareTo(b.eventStartTime)),
          actions: [
            RequestAction(
                text: "View",
                onClick: (request) => AutoRouter.of(context).push(
                    ViewBookingsRoute(
                        orgID: orgID,
                        requestID: request.id!,
                        view: CalendarView.day.name,
                        targetDate: request.eventStartTime))),
          ],
        );
      },
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

class RenderedRequest {
  final Request request;
  final PrivateRequestDetails details;

  RenderedRequest({required this.request, required this.details});
}

class BookingList extends StatelessWidget {
  final String orgID;
  final String emptyText;
  final Function(Request) onFocusBooking;
  final List<RequestStatus> statusList;
  final bool Function(Request)? requestFilter;
  final List<RequestAction> actions;
  final List<Request> overrideRequests;

  const BookingList(
      {super.key,
      required this.onFocusBooking,
      required this.orgID,
      required this.actions,
      required this.statusList,
      required this.emptyText,
      this.requestFilter,
      this.overrideRequests = const []});

  Stream<List<RenderedRequest>> _renderedRequests(
      BookingRepo bookingRepo, String orgID, List<Request> requests) {
    return Rx.combineLatest(
        requests.map(
            (request) => bookingRepo.getRequestDetails(orgID, request.id!)),
        (detailsList) {
      return List<RenderedRequest>.generate(
        detailsList.length,
        (index) {
          var details = detailsList[index];
          if (details == null) {
            log("No details found for request ${requests[index].id}");
            details = PrivateRequestDetails(
              name: "Unknown",
              email: "Unknown",
              phone: "Unknown",
              eventName: "Unknown",
            );
          }
          return RenderedRequest(
            request: requests[index],
            details: details,
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    var bookingRepo = Provider.of<BookingRepo>(context, listen: false);
    return Consumer<RoomState>(builder: (context, roomState, child) {
      Stream<List<Request>> requestStream;
      if (overrideRequests.isNotEmpty) {
        requestStream = Stream.value(overrideRequests);
      } else {
        requestStream = bookingRepo
            .listRequests(
                orgID: orgID,
                startTime: DateTime.now(),
                endTime: DateTime.now().add(const Duration(days: 365)),
                includeRoomIDs:
                    roomState.enabledValues().map((r) => r.id!).toSet(),
                includeStatuses: Set.from(statusList))
            .map((requests) =>
                requests.where(requestFilter ?? (r) => true).toList());
      }
      return StreamBuilder(
        stream: requestStream,
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
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder(
            stream: _renderedRequests(bookingRepo, orgID, snapshot.data ?? []),
            builder: (context, detailsSnapshot) {
              if (detailsSnapshot.hasError) {
                log(detailsSnapshot.error.toString(),
                    error: detailsSnapshot.error);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${detailsSnapshot.error}')),
                  );
                });
                return const Placeholder();
              }
              var renderedRequests = detailsSnapshot.data ?? [];
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: renderedRequests.length,
                itemBuilder: (context, index) {
                  var renderedRequest = renderedRequests[index];
                  return BookingTile(
                    orgID: orgID,
                    request: renderedRequest.request,
                    details: renderedRequest.details,
                    onFocusBooking: onFocusBooking,
                    actions: actions,
                  );
                },
              );
            },
          );
        },
      );
    });
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
    var roomState = Provider.of<RoomState>(context, listen: false);
    return Card(
      elevation: 1,
      child: ExpansionTile(
        title: Text("${details.eventName} for ${details.name}"),
        subtitle: _subtitle(context),
        leading: _leading(roomState.color(request.roomID)),
        trailing: _trailing(),
        expandedAlignment: Alignment.topLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: request.id!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Request ID copied to clipboard'),
                    ),
                  );
                },
                child: Text(
                  "Request ID: ${request.id}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )),
          ),
          detailTable(request, details),
        ],
      ),
    );
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

  Widget? _leading(Color color) {
    if (request.status == RequestStatus.pending) {
      return null;
    }
    return Icon(
      Icons.event,
      color: color,
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
  final Organization org;
  final Request request;

  const Calendar({super.key, required this.request, required this.org});

  @override
  Widget build(BuildContext context) {
    var bookingRepo = Provider.of<BookingRepo>(context, listen: false);
    var startTime = stripTime(request.eventStartTime);
    var endTime = stripTime(request.eventEndTime).add(const Duration(days: 1));
    return CalendarStateProvider(
        initialView: CalendarView.day,
        focusDate: request.eventStartTime,
        child: Consumer<CalendarState>(
          builder: (context, calendarState, child) => StreamBuilder(
            stream: Rx.combineLatest3(
                bookingRepo.listRequests(
                    orgID: org.id!,
                    startTime: startTime,
                    endTime: endTime,
                    includeRoomIDs: {request.roomID},
                    includeStatuses: {RequestStatus.confirmed}),
                bookingRepo.getRequestDetails(org.id!, request.id!),
                bookingRepo.listBlackoutWindows(org, startTime, endTime),
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
