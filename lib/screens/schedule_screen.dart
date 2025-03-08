import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/widgets/current_bookings_calendar.dart';
import 'package:room_booker/widgets/org_state_provider.dart';
import 'package:room_booker/widgets/request_editor_panel.dart';
import 'package:room_booker/widgets/room_selector.dart';
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
            leading: BackButton(
              onPressed: () {
                var router = AutoRouter.of(context);
                if (router.canPop()) {
                  router.popForced();
                } else {
                  router.replace(LandingRoute());
                }
              },
            ),
            actions: [],
          ),
          body: CalendarStateProvider(
            initialView: CalendarView.schedule,
            focusDate: DateTime.now(),
            child: RequestStateProvider(
              enableAllRooms: true,
              orgID: orgID,
              child: Column(
                children: [
                  RoomCardSelector(),
                  Expanded(
                      child: CurrentBookingsCalendar(
                    //view: CalendarView.schedule,
                    orgID: orgID,
                    onTap: (details) {},
                    onTapRequest: (r) {},
                  ))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
