import 'dart:developer';
import 'package:flutter/services.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide Badge, Action;
import 'package:provider/provider.dart';
import 'package:room_booker/data/services/analytics_service.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/services/logging_service.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/data/repos/prefs_repo.dart';
import 'package:room_booker/ui/screens/view_bookings/view_bookings_view_model.dart';
import 'package:room_booker/ui/utils/traced_stream_builder.dart';
import 'package:room_booker/ui/widgets/booking_calendar/booking_calendar.dart';
import 'package:room_booker/ui/widgets/booking_calendar/view_model.dart';
import 'package:room_booker/ui/widgets/edit_recurring_booking_dialog.dart';
import 'package:room_booker/ui/widgets/navigation_drawer.dart';
import 'package:room_booker/ui/widgets/org_state_provider.dart';
import 'package:room_booker/ui/widgets/request_editor/request_editor.dart';
import 'package:room_booker/ui/widgets/request_editor/request_editor_view_model.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:badges/badges.dart';
import 'package:room_booker/ui/utils/date_formatting.dart';

@RoutePage()
class ViewBookingsScreen extends StatelessWidget {
  final String orgID;
  final String? view;
  final bool createRequest;
  final bool readOnlyMode;
  final String? targetDateStr;
  final String? requestID;
  final bool showPrivateBookings;
  final DateTime? targetDate;

  final ViewBookingsViewModel Function(BuildContext)? createViewModel;
  final CalendarViewModel Function(BuildContext, DateTime?)?
  createCalendarViewModel;
  final RequestEditorViewModel Function(BuildContext)?
  createRequestEditorViewModel;

  ViewBookingsScreen({
    super.key,
    @PathParam('orgID') required this.orgID,
    @QueryParam('rid') this.requestID,
    @QueryParam('spb') this.showPrivateBookings = true,
    @QueryParam('ro') this.readOnlyMode = false,
    this.createRequest = false,
    @QueryParam('td') this.targetDateStr,
    @QueryParam('v') this.view,
    this.createViewModel,
    this.createCalendarViewModel,
    this.createRequestEditorViewModel,
  }) : targetDate = targetDateStr != null
           ? DateTime.tryParse(targetDateStr)
           : null;

  @override
  Widget build(BuildContext context) {
    var analytics = Provider.of<AnalyticsService>(context, listen: false);
    var logging = Provider.of<LoggingService>(context, listen: false);
    return analytics.logView(
      viewName: "View Bookings",
      builder: () => OrgStateProvider(
        orgID: orgID,
        child: Consumer<OrgState>(
          builder: (context, orgState, child) => RoomStateProvider(
            enableAllRooms: true,
            org: orgState.org,
            builder: (context, _) => ChangeNotifierProvider.value(
              value: createCalendarViewModel != null
                  ? createCalendarViewModel!(context, targetDate)
                  : _createCalendarViewModel(targetDate, context),
              builder: (context, child) => ChangeNotifierProvider.value(
                value: createRequestEditorViewModel != null
                    ? createRequestEditorViewModel!(context)
                    : _createRequestEditorViewModel(context),
                builder: (context, child) => ChangeNotifierProvider.value(
                  value: createViewModel != null
                      ? createViewModel!(context)
                      : _createViewModel(context),
                  child: _content(orgState, logging),
                ),
              ),
            ),
          ),
        ),
      ),
      parameters: {
        "orgID": orgID,
        "rid": requestID ?? "",
        "spb": showPrivateBookings.toString(),
        "ro": readOnlyMode.toString(),
        "td": targetDateStr ?? "",
        "v": view ?? "",
      },
    );
  }

  ViewBookingsViewModel _createViewModel(BuildContext context) {
    return ViewBookingsViewModel(
      readOnlyMode: readOnlyMode,
      router: AutoRouter.of(context),
      bookingRepo: context.read(),
      roomRepo: context.read(),
      authService: context.read(),
      sizeProvider: () => MediaQuery.sizeOf(context),
      orgState: context.read(),
      requestEditorViewModel: context.read(),
      calendarViewModel: context.read(),
      createRequest: createRequest,
      showPrivateBookings: showPrivateBookings,
      existingRequestID: requestID,
      showRoomSelector: true,
      showRequestDialog: (request) => _showRequestDialog(request, context),
      showEditorAsDialog: () => _showPannelAsDialog(context, context.read()),
      updateUri: (uri) async {
        await SystemNavigator.routeInformationUpdated(uri: uri);
      },
      pickDate: (initialDate, firstDate, lastDate) => showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
      pickTime: (targetDate) => showTimePicker(
        context: context,
        helpText: "Select start time",
        initialTime: TimeOfDay.fromDateTime(targetDate),
      ),
    );
  }

  CalendarViewModel _createCalendarViewModel(
    DateTime? targetDate,
    BuildContext context,
  ) {
    var targetDate = this.targetDate ?? DateTime.now();
    var defaultView = view;
    if (defaultView == null) {
      var prefRepo = Provider.of<PreferencesRepo>(context, listen: false);
      defaultView = prefRepo.defaultCalendarView.name;
    }
    return CalendarViewModel(
      orgState: context.read(),
      bookingRepo: context.read(),
      roomState: context.read(),
      targetDate: targetDate,
      loggingService: context.read(),
      defaultView: CalendarView.values.firstWhere(
        (element) => element.name == defaultView,
      ),
      allowedViews: [
        CalendarView.day,
        CalendarView.week,
        CalendarView.month,
        CalendarView.schedule,
      ],
      includePrivateBookings: showPrivateBookings,
      showIgnoringOverlaps: !readOnlyMode,
      showDatePickerButton: true,
      showNavigationArrow: true,
      allowViewNavigation:
          false, // This must be false for Month -> Day navigvation to work properly
    );
  }

  Widget _content(OrgState orgState, LoggingService logging) {
    return Consumer3<ViewBookingsViewModel, OrgState, CalendarViewModel>(
      builder: (context, viewModel, orgState, calendarViewModel, _) =>
          TracedStreamBuilder(
            "render_view_bookings_view_state",
            logging,
            stream: viewModel.viewStateStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                log("Error loading view state: ${snapshot.error}");
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              var viewState = snapshot.data!;
              return _scaffold(
                orgState,
                viewModel,
                calendarViewModel,
                viewState,
                context,
              );
            },
          ),
    );
  }

  Widget _scaffold(
    OrgState orgState,
    ViewBookingsViewModel viewModel,
    CalendarViewModel calendarViewModel,
    ViewState viewState,
    BuildContext context,
  ) {
    var isSmall = viewModel.isSmallView();
    var showDrawer =
        !isSmall && viewState.showRoomSelector && !viewState.showEditor;
    var showEditor = !isSmall && viewState.showEditor;
    var panelWidth = MediaQuery.sizeOf(context).width / 4;

    return Scaffold(
      appBar: AppBar(
        title: Text(orgState.org.name),
        actions: _renderActions(viewModel.getActions(context)),
        leading: viewModel.isSmallView()
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: viewModel.toggleRoomSelector,
              ),
      ),
      floatingActionButton:
          calendarViewModel.controller.view != CalendarView.day
          ? FloatingActionButton(
              onPressed: viewModel.onAddNewBooking,
              child: const Icon(Icons.add),
            )
          : null,
      drawer: viewModel.isSmallView() ? MyDrawer(org: orgState.org) : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: showDrawer ? panelWidth : 0,
            child: ClipRect(
              child: OverflowBox(
                minWidth: panelWidth,
                maxWidth: panelWidth,
                alignment: Alignment.centerRight,
                child: MyDrawer(org: orgState.org),
              ),
            ),
          ),
          Expanded(child: BookingCalendarView()),
          if (!isSmall)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: showEditor ? panelWidth : 0,
              child: ClipRect(
                child: OverflowBox(
                  minWidth: panelWidth,
                  maxWidth: panelWidth,
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(child: RequestEditor()),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _renderActions(List<Action> actions) {
    return actions.map((action) {
      Widget widget = IconButton(
        tooltip: action.name,
        icon: Icon(action.icon),
        onPressed: () => action.onPressed(),
      );
      if (action.notificationCount > 0) {
        widget = Badge(
          badgeContent: Text(
            "${action.notificationCount}",
            style: TextStyle(color: Colors.white),
          ),
          badgeAnimation: const BadgeAnimation.slide(), // Optional animation
          child: widget,
        );
      }
      return Tooltip(message: action.name, child: widget);
    }).toList();
  }

  RequestEditorViewModel _createRequestEditorViewModel(BuildContext context) {
    return RequestEditorViewModel(
      editorTitle: "Request Editor",
      analyticsService: context.read(),
      authService: context.read(),
      bookingRepo: context.read(),
      orgState: context.read(),
      roomState: context.read(),
      choiceProvider: () => showDialog<RecurringBookingEditChoice>(
        context: context,
        builder: (context) => EditRecurringBookingDialog(),
      ),
    );
  }

  void _showRequestDialog(Request request, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(request.publicName ?? "Private Event"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(getFormattedBookingRange(request)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text('Room: ${request.roomName}'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPannelAsDialog(
    BuildContext context,
    RequestEditorViewModel requestEditorViewModel,
  ) {
    var roomState = Provider.of<RoomState>(context, listen: false);
    var orgState = Provider.of<OrgState>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: roomState),
          ChangeNotifierProvider.value(value: requestEditorViewModel),
          ChangeNotifierProvider.value(value: orgState),
        ],
        builder: (context, child) => Dialog.fullscreen(
          child: RequestEditor(onClose: () => Navigator.pop(context)),
        ),
      ),
    );
  }
}
