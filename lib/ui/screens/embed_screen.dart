import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/ui/widgets/current_bookings_calendar.dart';
import 'package:room_booker/ui/widgets/org_state_provider.dart';
import 'package:room_booker/ui/widgets/stateful_calendar.dart';
import 'package:room_booker/ui/widgets/request_editor_panel.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

@RoutePage()
class EmbedScreen extends StatelessWidget {
  final String orgID;
  final String? view;

  const EmbedScreen({
    super.key,
    @QueryParam('v') this.view,
    @PathParam('orgID') required this.orgID,
  });

  @override
  Widget build(BuildContext context) {
    String defaultView = view ?? 'week';
    return OrgStateProvider(
        orgID: orgID,
        child: Consumer<OrgState>(
          builder: (context, orgState, child) => RequestStateProvider(
            orgState: orgState,
            enableAllRooms: true,
            child: CalendarStateProvider(
              initialView: CalendarView.values
                  .firstWhere((element) => element.name == defaultView),
              focusDate: DateTime.now(),
              builder: (context, child) {
                return CurrentBookingsCalendar(
                  orgID: orgID,
                  onTap: (details) {},
                  onTapRequest: (request) {},
                  showDatePickerButton: false,
                  includePrivateBookings: false,
                  showNavigationArrow: false,
                  showTodayButton: false,
                  appendRoomName: true,
                  allowedViews: [],
                );
              },
            ),
          ),
        ));
  }
}
