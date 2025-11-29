import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide Badge, Action;
import 'package:provider/provider.dart';
import 'package:room_booker/data/analytics_service.dart';
import 'package:room_booker/data/auth_service.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/data/repos/prefs_repo.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/ui/screens/view_bookings/view_bookings_view_model.dart';
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

@RoutePage()
class ViewBookingsScreen extends StatelessWidget {
  final String orgID;
  final String? view;
  final bool createRequest;
  final bool readOnlyMode;
  final DateTime? targetDate;
  final String? requestID;
  final bool showPrivateBookings;

  ViewBookingsScreen({
    super.key,
    @PathParam('orgID') required this.orgID,
    @QueryParam('rid') this.requestID,
    @QueryParam('spb') this.showPrivateBookings = true,
    @QueryParam('ro') this.readOnlyMode = false,
    this.createRequest = false,
    @QueryParam('td') this.targetDate,
    @QueryParam('v') String? view,
  }) : view = (targetDate != null || requestID != null
           ? CalendarView.day.name
           : view);

  @override
  Widget build(BuildContext context) {
    var analytics = Provider.of<FirebaseAnalyticsService>(
      context,
      listen: false,
    );
    analytics.logScreenView(
      screenName: "View Bookings",
      parameters: {"orgID": orgID},
    );
    return OrgStateProvider(
      orgID: orgID,
      child: Consumer<OrgState>(
        builder: (context, orgState, child) => RoomStateProvider(
          enableAllRooms: true,
          org: orgState.org,
          builder: (context, _) => ChangeNotifierProvider.value(
            value: _createCalendarViewModel(targetDate, context),
            builder: (context, child) => ChangeNotifierProvider.value(
              value: _createRequestEditorViewModel(context),
              builder: (context, child) => ChangeNotifierProvider.value(
                value: _createViewModel(context),
                child: _content(orgState),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ViewBookingsViewModel _createViewModel(BuildContext context) {
    return ViewBookingsViewModel(
      readOnlyMode: readOnlyMode,
      router: AutoRouter.of(context),
      bookingRepo: context.read<BookingRepo>(),
      authService: context.read<FirebaseAuthService>(),
      sizeProvider: () => MediaQuery.sizeOf(context),
      orgState: context.read<OrgState>(),
      requestEditorViewModel: context.read<RequestEditorViewModel>(),
      calendarViewModel: context.read<CalendarViewModel>(),
      createRequest: createRequest,
      showPrivateBookings: showPrivateBookings,
      existingRequestID: requestID,
      showRoomSelector: true,
      showRequestDialog: (request) => _showRequestDialog(request, context),
      showEditorAsDialog: () =>
          _showPannelAsDialog(context, context.read<RequestEditorViewModel>()),
      updateUri: (uri) async {
        await SystemNavigator.routeInformationUpdated(uri: uri);
      },
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
      allowViewNavigation: true,
    );
  }

  Widget _content(OrgState orgState) {
    return Consumer3<ViewBookingsViewModel, OrgState, CalendarViewModel>(
      builder: (context, viewModel, orgState, calendarViewModel, _) =>
          StreamBuilder(
            stream: viewModel.viewStateStream,
            builder: (context, snapshot) {
              log('ViewBookingsScreen: Building with snapshot: $snapshot');
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
              onPressed: () => _onFabPressed(context, calendarViewModel),
              child: const Icon(Icons.add),
            )
          : null,
      drawer: viewModel.isSmallView() ? MyDrawer(org: orgState.org) : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!viewModel.isSmallView() &&
              viewState.showRoomSelector &&
              !viewState.showEditor)
            Flexible(flex: 1, child: MyDrawer(org: orgState.org)),
          Flexible(flex: 3, child: BookingCalendarView()),
          if (viewState.showEditor && !viewModel.isSmallView())
            Flexible(
              flex: 1,
              child: SingleChildScrollView(child: RequestEditor()),
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

  void _onFabPressed(BuildContext context, CalendarViewModel viewModel) async {
    var router = AutoRouter.of(context);

    var focusDate = viewModel.controller.displayDate;
    var firstDate = DateTime(focusDate!.year, focusDate.month);
    var lastDate = firstDate.add(Duration(days: 365));

    var targetDate = await showDatePicker(
      context: context,
      initialDate: focusDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (targetDate == null || !context.mounted) {
      return;
    }

    var eventTime = await showTimePicker(
      context: context,
      helpText: "Select start time",
      initialTime: TimeOfDay.fromDateTime(targetDate),
    );
    if (eventTime == null) {
      return;
    }

    var startTime = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      eventTime.hour,
      eventTime.minute,
    );
    router.push(
      ViewBookingsRoute(
        orgID: orgID,
        view: CalendarView.day.name,
        targetDate: startTime,
        createRequest: true,
      ),
    );
  }

  RequestEditorViewModel _createRequestEditorViewModel(BuildContext context) {
    return RequestEditorViewModel(
      editorTitle: "Request Editor",
      analyticsService: context.read<FirebaseAnalyticsService>(),
      authService: context.read<FirebaseAuthService>(),
      bookingRepo: context.read<BookingRepo>(),
      orgState: context.read<OrgState>(),
      roomState: context.read<RoomState>(),
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
              child: Text(_getFormattedBookingRange(request)),
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

  String _getFormattedBookingRange(Request request) {
    final start = request.eventStartTime.toLocal();
    final end = request.eventEndTime.toLocal();
    final isSameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    if (isSameDay) {
      return '${DateFormat.yMMMMEEEEd().format(start)} ⋅ ${DateFormat.jm().format(start)} - ${DateFormat.jm().format(end)}';
    }
    return '${DateFormat.yMd().add_jm().format(start)} - ${DateFormat.yMd().add_jm().format(end)}';
  }
}
