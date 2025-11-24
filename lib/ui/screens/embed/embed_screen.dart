import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/ui/widgets/booking_calendar/booking_calendar.dart';
import 'package:room_booker/ui/widgets/booking_calendar/view_model.dart';
import 'package:room_booker/ui/widgets/org_state_provider.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';
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
    var bookingRepo = Provider.of<BookingRepo>(context, listen: false);

    var defaultView = CalendarView.values.firstWhere(
      (element) => element.name == (view ?? 'week'),
    );

    return OrgStateProvider(
      orgID: orgID,
      child: Consumer<OrgState>(
        builder: (context, orgState, child) => RoomStateProvider(
          org: orgState.org,
          builder: (context, _) => Consumer<RoomState>(
            builder: (context, roomState, child) => BookingCalendar(
              createViewModel: () => CalendarViewModel(
                orgState: orgState,
                defaultView: defaultView,
                bookingRepo: bookingRepo,
                roomState: roomState,
                showDatePickerButton: false,
                includePrivateBookings: false,
                showNavigationArrow: false,
                showTodayButton: true,
                appendRoomName: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
