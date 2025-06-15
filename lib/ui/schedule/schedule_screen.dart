import 'package:auto_route/auto_route.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/ui/core/current_bookings_calendar.dart';
import 'package:room_booker/ui/core/org_state_provider.dart';
import 'package:room_booker/ui/view_bookings/request_editor_panel.dart';
import 'package:room_booker/ui/core/room_selector.dart';
import 'package:room_booker/ui/core/stateful_calendar.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

@RoutePage()
class ScheduleScreen extends StatelessWidget {
  final String orgID;

  const ScheduleScreen({super.key, @PathParam('orgID') required this.orgID});

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance
        .logScreenView(screenName: "Schedule", parameters: {"orgID": orgID});
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
              org: orgState.org,
              child: Column(
                children: [
                  RoomCardSelector(),
                  Expanded(
                      child: CurrentBookingsCalendar(
                    showDatePickerButton: false,
                    orgID: orgID,
                    onTap: (details) {},
                    onTapRequest: (r) {
                      AutoRouter.of(context).push(ViewBookingsRoute(
                          orgID: orgID,
                          requestID: r.id,
                          view: CalendarView.day.name));
                    },
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
