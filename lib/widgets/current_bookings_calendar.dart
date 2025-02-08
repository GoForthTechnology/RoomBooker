import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/blackout_window.dart';
import 'package:room_booker/entities/request.dart';
import 'package:room_booker/repos/org_repo.dart';
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
  final Function(CalendarTapDetails) onTap;
  final Function(Request) onTapRequest;

  const CurrentBookingsCalendar(
      {super.key,
      required this.orgID,
      required this.onTap,
      required this.onTapRequest});

  @override
  Widget build(BuildContext context) {
    return Consumer3<OrgRepo, RoomState, CalendarState>(
      builder: (context, repo, roomState, calendarState, _) => StreamBuilder(
        stream: RemoteState.createStream(orgID, repo, roomState, calendarState),
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
            return const CircularProgressIndicator();
          }
          var remoteState = snapshot.data as RemoteState;
          print("Remote state: ${remoteState.existingRequests.length}");
          return Consumer<RequestEditorState>(
            builder: (context, requestEditorState, child) {
              var newApointmentColor =
                  roomState.color(requestEditorState.roomID!);
              var newAppointment =
                  requestEditorState.getAppointment(newApointmentColor);
              var appointments = {
                for (var request in remoteState.existingRequests)
                  request.toAppointment(roomState): request
              };
              var series = requestEditorState.getSeries();
              if (series != null) {
                var requests = series.expand(
                    calendarState.windowStartDate, calendarState.windowEndDate,
                    includeRequestDate: false);
                for (var request in requests) {
                  appointments[request.toAppointment(roomState,
                      subject: "Another occurance")] = request;
                }
              }
              return StatefulCalendar(
                view: CalendarView.week,
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
  final List<BlackoutWindow> blackoutWindows;

  RemoteState({required this.existingRequests, required this.blackoutWindows});

  static Stream<RemoteState> createStream(String orgID, OrgRepo repo,
      RoomState roomState, CalendarState calendarState) {
    return Rx.combineLatest2(
        repo.listRequests(
            orgID: orgID,
            startTime: calendarState.windowStartDate,
            endTime: calendarState.windowEndDate,
            includeRoomIDs: {
              roomState.enabledValue().id!
            },
            includeStatuses: {
              RequestStatus.pending,
              RequestStatus.confirmed
            }).startWith([]),
        repo.listBlackoutWindows(orgID).startWith([]),
        (existingRequests, blackoutWindows) => RemoteState(
            existingRequests: existingRequests,
            blackoutWindows: blackoutWindows));
  }
}
