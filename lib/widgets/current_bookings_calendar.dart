import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/blackout_window.dart';
import 'package:room_booker/entities/request.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:room_booker/widgets/org_state_provider.dart';
import 'package:room_booker/widgets/request_editor_panel.dart';
import 'package:room_booker/widgets/room_selector.dart';
import 'package:room_booker/widgets/stateful_calendar.dart';
import 'package:rxdart/rxdart.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

extension on Request {
  Appointment toAppointment(RoomState roomState, {String? subject}) {
    var alphaLevel = status == RequestStatus.pending ? 128 : 255;
    var color = roomState.color(roomName).withAlpha(alphaLevel);
    return Appointment(
      subject: subject ??
          (status == RequestStatus.confirmed ? "Booked" : "Requested"),
      color: color,
      startTime: eventStartTime,
      endTime: eventEndTime,
    );
  }
}

class CurrentBookingsCalendar extends StatelessWidget {
  final String orgID;
  final CalendarView view;
  final Function(CalendarTapDetails) onTap;
  final Function(Request) onTapRequest;

  const CurrentBookingsCalendar(
      {super.key,
      required this.view,
      required this.orgID,
      required this.onTap,
      required this.onTapRequest});

  @override
  Widget build(BuildContext context) {
    return Consumer4<OrgRepo, OrgState, RoomState, CalendarState>(
      builder: (context, repo, orgState, roomState, calendarState, _) =>
          StreamBuilder(
        stream:
            RemoteState.createStream(repo, roomState, calendarState, orgState),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print(snapshot.error);
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
          var remoteState = snapshot.data as RemoteState;
          return Consumer<RequestEditorState>(
            builder: (context, requestEditorState, child) {
              var newApointmentColor =
                  roomState.color(roomState.enabledValue().id!);
              var newAppointment =
                  requestEditorState.getAppointment(newApointmentColor);
              Map<Appointment, Request> appointments = {};
              for (var request in remoteState.existingRequests) {
                String? subject;
                var details = remoteState.privateRequestDetails(request.id!);
                if (details != null) {
                  subject = details.eventName;
                }
                var appointment =
                    request.toAppointment(roomState, subject: subject);
                appointments[appointment] = request;
                for (var repeat in request.expand(
                    calendarState.windowStartDate, calendarState.windowEndDate,
                    includeRequestDate: false)) {
                  appointment =
                      repeat.toAppointment(roomState, subject: subject);
                  appointments[appointment] = repeat;
                }
              }
              var request = requestEditorState.getRequest(roomState);
              if (request != null &&
                  request.status != RequestStatus.confirmed) {
                var requests = request.expand(
                    calendarState.windowStartDate, calendarState.windowEndDate,
                    includeRequestDate: false);
                for (var request in requests) {
                  appointments[request.toAppointment(roomState,
                      subject: "Another occurance")] = request;
                }
              }
              return StatefulCalendar(
                view: view,
                showNavigationArrow: true,
                showDatePickerButton: true,
                showTodayButton: true,
                onTap: onTap,
                allowAppointmentResize: true,
                onAppointmentResizeEnd: (details) => requestEditorState
                    .updateTimes(details.startTime, details.endTime),
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

  static Stream<RemoteState> createStream(OrgRepo repo, RoomState roomState,
      CalendarState calendarState, OrgState orgState) {
    return repo.listRequests(
        orgID: orgState.org.id!,
        startTime: calendarState.windowStartDate,
        endTime: calendarState.windowEndDate,
        includeRoomIDs: {
          roomState.enabledValue().id!
        },
        includeStatuses: {
          RequestStatus.pending,
          RequestStatus.confirmed
        }).startWith([]).switchMap((requests) {
      return Rx.combineLatest2(
          _privateDetailsStream(orgState, repo, requests).startWith([]),
          repo.listBlackoutWindows(orgState.org.id!).startWith([]),
          (privateRequestDetails, blackoutWindows) => RemoteState(
              existingRequests: requests,
              privateRequestDetails: privateRequestDetails,
              blackoutWindows: blackoutWindows));
    });
  }

  static Stream<List<PrivateRequestDetails>> _privateDetailsStream(
      OrgState orgState, OrgRepo repo, List<Request> requests) {
    if (!orgState.currentUserIsAdmin()) {
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
