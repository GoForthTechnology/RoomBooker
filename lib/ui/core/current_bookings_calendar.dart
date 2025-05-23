import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/blackout_window.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/ui/core/org_state_provider.dart';
import 'package:room_booker/ui/view_bookings/request_editor_panel.dart';
import 'package:room_booker/ui/core/room_selector.dart';
import 'package:room_booker/ui/core/stateful_calendar.dart';
import 'package:rxdart/rxdart.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

extension on Request {
  Appointment toAppointment(RoomState roomState,
      {String? subject, bool diminish = false}) {
    var alphaLevel = diminish || status == RequestStatus.pending ? 128 : 255;
    var color = roomState.color(roomID).withAlpha(alphaLevel);
    return Appointment(
      subject: subject ??
          (status == RequestStatus.confirmed ? "Booked" : "Requested"),
      color: color,
      startTime: eventStartTime,
      endTime: eventEndTime,
      resourceIds: [id!],
    );
  }
}

class CurrentBookingsCalendar extends StatelessWidget {
  final String orgID;
  final Function(CalendarTapDetails)? onTap;
  final Function(Request)? onTapRequest;
  final Request? existingRequest;
  final bool showDatePickerButton;
  final bool includePrivateBookings;

  const CurrentBookingsCalendar(
      {super.key,
      required this.orgID,
      required this.onTap,
      required this.onTapRequest,
      required this.showDatePickerButton,
      this.includePrivateBookings = true,
      this.existingRequest});

  @override
  Widget build(BuildContext context) {
    var repo = Provider.of<BookingRepo>(context, listen: false);
    return Consumer3<OrgState, RoomState, CalendarState>(
      builder: (context, orgState, roomState, calendarState, _) =>
          StreamBuilder(
        stream:
            RemoteState.createStream(repo, roomState, calendarState, orgState),
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
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          var remoteState = snapshot.data as RemoteState;
          return Consumer<RequestEditorState>(
            builder: (context, requestEditorState, child) {
              var enabledRoom = roomState.enabledValue();
              if (requestEditorState.roomID != "") {
                enabledRoom = roomState.getRoom(requestEditorState.roomID!);
              }
              var newApointmentColor = enabledRoom == null
                  ? Colors.blue
                  : roomState.color(enabledRoom.id!);
              var newAppointment =
                  requestEditorState.getAppointment(newApointmentColor);
              if (newAppointment == null) {
                var request = requestEditorState.getRequest(roomState);
                var details = requestEditorState.getPrivateDetails();
                newAppointment = request?.toAppointment(roomState,
                    subject: details.eventName);
              }
              Map<Appointment, Request> appointments = {};
              for (var request in remoteState.existingRequests) {
                String? subject = request.publicName;
                var details = remoteState.privateRequestDetails(request.id!);
                if (details != null) {
                  subject = details.eventName;
                }
                var isPrivateBooking = (subject ?? "") == "";
                if (isPrivateBooking && !includePrivateBookings) {
                  continue;
                }
                /*var appointment =
                    request.toAppointment(roomState, subject: subject);
                appointments[appointment] = request;*/
                var start = calendarState.startOfView();
                var end = calendarState.endOfView();
                for (var repeat
                    in request.expand(start, end, includeRequestDate: true)) {
                  if (_isSameRequest(
                      requestEditorState.existingRequest, repeat)) {
                    // Skip the current request
                    continue;
                  }
                  var appointment = repeat.toAppointment(roomState,
                      subject: subject, diminish: newAppointment != null);
                  appointments[appointment] = repeat;
                }
              }
              // TODO: reenable this at some point
              /*var request = requestEditorState.getRequest(roomState);
              if (request != null &&
                  request.status != RequestStatus.confirmed) {
                var requests = request.expand(
                    calendarState.startOfView(), calendarState.endOfView(),
                    includeRequestDate: false);
                for (var request in requests) {
                  appointments[request.toAppointment(roomState,
                      subject: "Another occurance")] = request;
                }
              }*/
              return StatefulCalendar(
                view: calendarState.controller.view,
                showNavigationArrow: true,
                showDatePickerButton: showDatePickerButton,
                showTodayButton: true,
                onTap: onTap,
                allowAppointmentResize: true,
                onAppointmentResizeEnd: (details) => requestEditorState
                    .updateTimes(details.startTime, details.endTime),
                allowDragAndDrop: true,
                onAppointmentDragEnd: (details) {
                  log("Drag and drop request ${details.request.id}");
                  if (requestEditorState.requestID() != details.request.id) {
                    log("Not the active request!");
                    return;
                  }
                  var start = details.dropTime;
                  var end = start.add(details.request.eventDuration());
                  requestEditorState.updateTimes(start, end);
                },
                onTapBooking: onTapRequest,
                newAppointment: newAppointment,
                blackoutWindows: remoteState.blackoutWindows,
                appointments: appointments,
              );
            },
          );
        },
      ),
    );
  }
}

bool _isSameRequest(Request? request, Request repeat) {
  if (request == null) {
    return false;
  }
  if (request.id != repeat.id) {
    return false;
  }
  var requestDate = DateTime(
    request.eventStartTime.year,
    request.eventStartTime.month,
    request.eventStartTime.day,
  );
  var repeatDate = DateTime(
    repeat.eventStartTime.year,
    repeat.eventStartTime.month,
    repeat.eventStartTime.day,
  );
  return requestDate == repeatDate;
}

class RemoteState {
  final List<Request> existingRequests;
  final Map<String, PrivateRequestDetails> _privateRequestDetails;
  final List<BlackoutWindow> blackoutWindows;

  RemoteState(
      {required this.existingRequests,
      required this.blackoutWindows,
      List<PrivateRequestDetails> privateRequestDetails = const []})
      : _privateRequestDetails = {
          for (var d in privateRequestDetails) d.id!: d
        };

  PrivateRequestDetails? privateRequestDetails(String requestID) {
    return _privateRequestDetails[requestID];
  }

  static Stream<RemoteState> createStream(BookingRepo repo, RoomState roomState,
      CalendarState calendarState, OrgState orgState) {
    var startTime = calendarState.startOfView();
    var endTime = calendarState.endOfView();
    var roomIDs = roomState.enabledValues().map((r) => r.id!).toSet();
    return repo.listRequests(
        orgID: orgState.org.id!,
        startTime: startTime,
        endTime: endTime,
        includeRoomIDs: roomIDs,
        includeStatuses: {
          RequestStatus.pending,
          RequestStatus.confirmed
        }).switchMap((requests) {
      return Rx.combineLatest2(
          _privateDetailsStream(orgState, repo, requests),
          repo.listBlackoutWindows(orgState.org.id!),
          (privateRequestDetails, blackoutWindows) => RemoteState(
              existingRequests: requests,
              privateRequestDetails: privateRequestDetails,
              blackoutWindows: blackoutWindows));
    });
  }

  static Stream<List<PrivateRequestDetails>> _privateDetailsStream(
      OrgState orgState, BookingRepo repo, List<Request> requests) {
    if (!orgState.currentUserIsAdmin() || requests.isEmpty) {
      return Stream.value([]);
    }
    var orgID = orgState.org.id!;
    var streams =
        requests.map((r) => repo.getRequestDetails(orgID, r.id!)).toList();
    return Rx.combineLatestList(streams).map((details) {
      var out = <PrivateRequestDetails>[];
      for (var d in details) {
        if (d != null) {
          out.add(d);
        }
      }
      return out;
    });
  }
}
