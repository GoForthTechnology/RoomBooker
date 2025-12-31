import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:room_booker/ui/widgets/booking_calendar/booking_calendar.dart';
import 'package:room_booker/ui/widgets/booking_calendar/view_model.dart';
import 'package:room_booker/ui/widgets/org_state_provider.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

@RoutePage(name: 'EmbedWidgetRoute')
class EmbedWidget extends StatelessWidget {
  final String orgID;
  final String? view;

  const EmbedWidget({
    super.key,
    @QueryParam('v') this.view,
    @PathParam('orgID') required this.orgID,
  });

  @override
  Widget build(BuildContext context) {
    final span = Sentry.getSpan()?.startChild('ui.embed_widget.build');
    try {
      var defaultView = CalendarView.values.firstWhere(
        (element) => element.name == (view ?? 'week'),
      );

      span?.status = const SpanStatus.ok();
      return Scaffold(
        body: OrgStateProvider(
          orgID: orgID,
          child: Consumer<OrgState>(
            builder: (context, orgState, child) => RoomStateProvider(
              org: orgState.org,
              enableAllRooms: true,
              builder: (context, _) => Consumer<RoomState>(
                builder: (context, roomState, child) => BookingCalendar(
                  createViewModel: () => CalendarViewModel(
                    orgState: orgState,
                    loggingService: context.read(),
                    defaultView: defaultView,

                    roomState: roomState,
                    bookingService: context.read(),
                    showDatePickerButton: false,
                    includePrivateBookings: false,
                    showNavigationArrow: false,
                    showTodayButton: false,
                    appendRoomName: true,
                    allowedViews: [defaultView],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      span?.status = const SpanStatus.internalError();
      rethrow;
    } finally {
      span?.finish();
    }
  }
}
