import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/blackout_window.dart';
import 'package:room_booker/entities/request.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:room_booker/widgets/request_editor_panel.dart';
import 'package:room_booker/widgets/room_selector.dart';
import 'package:room_booker/widgets/simple_calendar.dart';
import 'package:rxdart/rxdart.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

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
    return Consumer2<OrgRepo, RoomState>(
      builder: (context, repo, roomState, _) => StreamBuilder(
        stream: RemoteState.createStream(orgID, repo, roomState),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }
          var remoteState = snapshot.data as RemoteState;
          return Consumer<RequestEditorState>(
            builder: (context, requestEditorState, child) => SimpleCalendar(
              state: _createCalendarState(
                  requestEditorState, remoteState, roomState),
              view: CalendarView.week,
              showNavigationArrow: true,
              showDatePickerButton: true,
              showTodayButton: true,
              onTap: onTap,
              allowAppointmentResize: true,
              onAppointmentResizeEnd: (details) => requestEditorState
                  .updateTimes(details.startTime, details.endTime),
              onTapBooking: onTapRequest,
            ),
          );
        },
      ),
    );
  }

  CalendarState _createCalendarState(
    RequestEditorState requestEditorState,
    RemoteState remoteState,
    RoomState roomState,
  ) {
    var newAppointmentColor = roomState.color(requestEditorState.roomID!);
    return CalendarState(
        newAppointment: requestEditorState.getAppointment(newAppointmentColor),
        remoteState.existingRequests,
        (r) => r.status == RequestStatus.confirmed ? "Booked" : "Requested",
        (r) => roomState
            .color(r.roomName)
            .withAlpha(r.status == RequestStatus.pending ? 128 : 255),
        blackoutWindows: remoteState.blackoutWindows);
  }
}

class RemoteState {
  final List<Request> existingRequests;
  final List<BlackoutWindow> blackoutWindows;

  RemoteState({required this.existingRequests, required this.blackoutWindows});

  static Stream<RemoteState> createStream(
      String orgID, OrgRepo repo, RoomState roomState) {
    return Rx.combineLatest2(
        repo.listRequests(orgID, includeRoomIDs: {
          roomState.enabledValue().id!
        }, includeStatuses: {
          RequestStatus.pending,
          RequestStatus.confirmed
        }).startWith([]).onErrorReturn([]),
        repo.listBlackoutWindows(orgID).startWith([]),
        (existingRequests, blackoutWindows) => RemoteState(
            existingRequests: existingRequests,
            blackoutWindows: blackoutWindows));
  }
}
