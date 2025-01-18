import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/request.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:room_booker/widgets/request_editor_panel.dart';
import 'package:room_booker/widgets/room_selector.dart';
import 'package:room_booker/widgets/streaming_calendar.dart';
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
    return Consumer3<OrgRepo, RoomState, RequestEditorState>(
      builder: (context, repo, roomState, requestEditorState, child) =>
          StreamingCalendar(
        view: CalendarView.week,
        showNavigationArrow: true,
        showDatePickerButton: true,
        showTodayButton: true,
        onTap: onTap,
        allowAppointmentResize: true,
        onAppointmentResizeEnd: (details) =>
            requestEditorState.updateTimes(details.startTime, details.endTime),
        onTapBooking: onTapRequest,
        stateStream: Rx.combineLatest2(
            repo.listRequests(orgID,
                includeRooms: roomState.enabledValues(),
                includeStatuses: [
                  RequestStatus.pending,
                  RequestStatus.confirmed
                ]).startWith([]).onErrorReturn([]),
            repo.listBlackoutWindows(orgID).startWith([]),
            (requests, blackoutWindows) => CalendarState(
                requests,
                (r) => r.status == RequestStatus.confirmed
                    ? "Booked"
                    : "Requested",
                (r) => roomState
                    .color(r.selectedRoom)
                    .withAlpha(r.status == RequestStatus.pending ? 128 : 255),
                blackoutWindows: blackoutWindows)),
      ),
    );
  }
}
