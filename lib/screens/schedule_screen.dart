import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/widgets/current_bookings_calendar.dart';
import 'package:room_booker/widgets/org_state_provider.dart';
import 'package:room_booker/widgets/request_editor_panel.dart';
import 'package:room_booker/widgets/stateful_calendar.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

@RoutePage()
class ScheduleScreen extends StatelessWidget {
  final String orgID;

  const ScheduleScreen({super.key, @PathParam('orgID') required this.orgID});

  @override
  Widget build(BuildContext context) {
    return OrgStateProvider(
      orgID: orgID,
      child: Consumer<OrgState>(
        builder: (context, orgState, child) => Scaffold(
          appBar: AppBar(
            title: Text("Schedule for ${orgState.org.name}"),
            actions: [],
          ),
          body: CalendarStateProvider(
            child: RequestStateProvider(
              enableAllRooms: true,
              orgID: orgID,
              child: CurrentBookingsCalendar(
                view: CalendarView.schedule,
                showAllRooms: true,
                orgID: orgID,
                onTap: (details) {},
                onTapRequest: (r) {},
              ),
            ),
          ),
        ),
      ),
    );
  }
}
