import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/services/booking_service.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/ui/widgets/booking_list/booking_lists.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class ConflictingBookings extends StatelessWidget {
  final BookingService service;
  final String orgID;

  const ConflictingBookings({
    super.key,
    required this.orgID,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: service.findOverlappingBookings(
        orgID: orgID,
        startTime: DateTime.now(),
        endTime: DateTime.now().add(Duration(days: 365)),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          log(snapshot.error.toString(), error: snapshot.error);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: ${snapshot.error}')));
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
          orgID: orgID,
          backgroundColorFn: (r) {
            if (r.eventStartTime.isBefore(
              DateTime.now().add(Duration(days: 7)),
            )) {
              return Color.fromRGBO(238, 205, 205, 1.0);
            }
            return null;
          },
          emptyText: "No conflicting bookings",
          statusList: const [],
          overrideRequests: conflictingRequests.sorted(
            (l, r) => l.eventStartTime.compareTo(r.eventStartTime),
          ),
          actions: [],
          actionBuilder: (request) {
            bool canIgnore = !request.isRepeating();
            return [
              RequestAction(
                icon: Icons.visibility,
                text: "View",
                onClick: (request) => AutoRouter.of(context).push(
                  ViewBookingsRoute(
                    orgID: orgID,
                    requestID: request.id!,
                    view: CalendarView.day.name,
                    targetDateStr: DateFormat(
                      "yyyy-MM-dd",
                    ).format(request.eventStartTime),
                  ),
                ),
              ),
              RequestAction(
                icon: Icons.report_off,
                text: "Ignore",
                disableText: canIgnore ? "" : "This booking is recurring",
                onClick: !canIgnore
                    ? null
                    : (request) async {
                        bool shouldIgnore = await _confirmIgnore(
                          context,
                          request,
                        );
                        if (!shouldIgnore) {
                          return Future.value();
                        }
                        await service.ignoreOverlaps(orgID, request.id!);
                      },
              ),
            ];
          },
        );
      },
    );
  }
}

Future<bool> _confirmIgnore(BuildContext context, Request request) async {
  return await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Ignore Conflict?"),
      content: const Text(
        "Are you sure you want to ignore this conflict? This can potentially lead to a double booking.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("Confirm"),
        ),
      ],
    ),
  );
}
