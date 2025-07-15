import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/prefs_repo.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/ui/core/current_bookings_calendar.dart';
import 'package:room_booker/ui/core/org_state_provider.dart';
import 'package:room_booker/ui/view_bookings/request_editor_panel.dart';
import 'package:room_booker/ui/core/room_selector.dart';
import 'package:room_booker/ui/core/stateful_calendar.dart';
import 'package:rxdart/rxdart.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

@RoutePage()
class ViewBookingsScreen extends StatelessWidget {
  final String orgID;
  final String? view;
  final bool createRequest;
  final bool readOnlyMode;
  final DateTime? targetDate;
  final String? requestID;
  final bool showPrivateBookings;

  ViewBookingsScreen(
      {super.key,
      @PathParam('orgID') required this.orgID,
      @QueryParam('rid') this.requestID,
      @QueryParam('spb') this.showPrivateBookings = true,
      @QueryParam('ro') this.readOnlyMode = false,
      this.createRequest = false,
      this.targetDate,
      @QueryParam('v') String? view})
      : view = (targetDate != null || requestID != null
            ? CalendarView.day.name
            : view);

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.logScreenView(
        screenName: "View Bookings", parameters: {"orgID": orgID});
    var bookingRepo = Provider.of<BookingRepo>(context, listen: false);
    if (requestID == null) {
      return _content(context, null, null);
    }
    return StreamBuilder(
      stream: Rx.combineLatest2(
        bookingRepo.getRequestDetails(orgID, requestID!),
        bookingRepo.getRequest(orgID, requestID!),
        (details, request) => (details, request),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          log("Error fetching request details: ${snapshot.error}",
              error: snapshot.error);
          return const Placeholder();
        }
        if (!snapshot.hasData) {
          log("No data for request ID: $requestID");
          return const Placeholder();
        }
        var data = snapshot.data!;
        return _content(context, data.$2, data.$1);
      },
    );
  }

  Widget _content(
      BuildContext context, Request? request, PrivateRequestDetails? details) {
    Widget? leading = FirebaseAuth.instance.currentUser == null
        ? null
        : BackButton(
            onPressed: () {
              var router = AutoRouter.of(context);
              if (router.canPop()) {
                router.pop();
              } else {
                router.replace(LandingRoute());
              }
            },
          );
    var defaultView = view;
    if (defaultView == null) {
      var prefRepo = Provider.of<PreferencesRepo>(context, listen: false);
      defaultView = prefRepo.defaultCalendarView.name;
    }
    return OrgStateProvider(
      orgID: orgID,
      child: Consumer<OrgState>(
        builder: (context, orgState, child) => RequestStateProvider(
          enableAllRooms: true,
          org: orgState.org,
          initialRequest: request,
          initialDetails: details,
          requestStartTime: createRequest ? targetDate : null,
          child: CalendarStateProvider(
            initialView: CalendarView.values
                .firstWhere((element) => element.name == defaultView),
            focusDate: targetDate ?? request?.eventEndTime ?? DateTime.now(),
            builder: (context, child) {
              var calendarState = Provider.of<CalendarState>(context);
              bool showFab = calendarState.controller.view != CalendarView.day;
              return Consumer<RequestPanelSate>(
                builder: (context, requestPanelState, child) => Scaffold(
                  appBar: AppBar(
                    title: Text(orgState.org.name),
                    leading: leading,
                    actions: _actions(context, orgState),
                  ),
                  floatingActionButton: showFab
                      ? FloatingActionButton(
                          onPressed: () => _onFabPressed(context),
                          child: const Icon(Icons.add),
                        )
                      : null,
                  body: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        flex: 3,
                        child: Column(
                          children: [
                            RoomCardSelector(),
                            Expanded(child: _buildCalendar(context, request)),
                          ],
                        ),
                      ),
                      if (requestPanelState.active)
                        Flexible(
                          flex: 1,
                          child: SingleChildScrollView(
                              child: NewRequestPanel(
                            orgID: orgID,
                          )),
                        )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onFabPressed(BuildContext context) async {
    var router = AutoRouter.of(context);
    var calendarState = Provider.of<CalendarState>(context, listen: false);

    var focusDate = calendarState.controller.displayDate;
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
        initialTime: TimeOfDay.fromDateTime(targetDate));
    if (eventTime == null) {
      return;
    }

    var startTime = DateTime(targetDate.year, targetDate.month, targetDate.day,
        eventTime.hour, eventTime.minute);
    router.push(ViewBookingsRoute(
        orgID: orgID,
        view: CalendarView.day.name,
        targetDate: startTime,
        createRequest: true));
  }

  bool _isSmallView(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 600;
  }

  Widget _buildCalendar(BuildContext context, Request? existingRequest) {
    var requestEditorState =
        Provider.of<RequestEditorState>(context, listen: false);
    var requestPanelState =
        Provider.of<RequestPanelSate>(context, listen: false);
    var calendarState = Provider.of<CalendarState>(context, listen: false);
    var roomState = Provider.of<RoomState>(context, listen: false);
    return CurrentBookingsCalendar(
      includePrivateBookings: showPrivateBookings,
      orgID: orgID,
      onTap: readOnlyMode
          ? null
          : (details) {
              var targetDate = details.date!;
              var currentView = calendarState.controller.view;
              if (currentView == CalendarView.month) {
                AutoRouter.of(context).push(ViewBookingsRoute(
                  orgID: orgID,
                  view: CalendarView.day.name,
                  targetDate: targetDate,
                ));
                return;
              }
              requestEditorState.clearAppointment();
              requestEditorState.createRequest(
                  details.date!,
                  details.date!.add(const Duration(hours: 1)),
                  roomState.enabledValue()!);
              if (_isSmallView(context)) {
                _showPannelAsDialog(context);
              } else {
                requestPanelState.showPanel();
              }
            },
      onTapRequest: readOnlyMode
          ? null
          : (request) async {
              if (FirebaseAuth.instance.currentUser == null) {
                return;
              }
              var isSmallView = _isSmallView(context);
              var details =
                  await Provider.of<BookingRepo>(context, listen: false)
                      .getRequestDetails(orgID, request.id!)
                      .first;
              if (details == null) {
                return;
              }
              requestEditorState.showRequest(request, details);
              if (isSmallView && context.mounted) {
                _showPannelAsDialog(context);
              } else {
                requestPanelState.showPanel();
              }
              SystemNavigator.routeInformationUpdated(
                  uri: Uri(path: "/view/$orgID?requestID=${request.id}"));
              FirebaseAnalytics.instance
                  .logEvent(name: "Start creating request");
            },
      showDatePickerButton: true,
    );
  }

  void _showPannelAsDialog(BuildContext context) {
    var requestEditorState =
        Provider.of<RequestEditorState>(context, listen: false);
    var requestPanelState =
        Provider.of<RequestPanelSate>(context, listen: false);
    var roomState = Provider.of<RoomState>(context, listen: false);
    var orgState = Provider.of<OrgState>(context, listen: false);
    showDialog(
        context: context,
        builder: (context) => MultiProvider(
                providers: [
                  ChangeNotifierProvider.value(value: requestEditorState),
                  ChangeNotifierProvider.value(value: roomState),
                  ChangeNotifierProvider.value(value: requestPanelState),
                  ChangeNotifierProvider.value(value: orgState),
                ],
                builder: (context, child) =>
                    Dialog.fullscreen(child: NewRequestPanel(orgID: orgID))));
  }

  List<Widget> _actions(BuildContext context, OrgState orgState) {
    if (FirebaseAuth.instance.currentUser != null) {
      var privilegedActions = <Widget>[];
      if (orgState.currentUserIsAdmin()) {
        privilegedActions.add(Tooltip(
          message: "View Agenda",
          child: IconButton(
            icon: const Icon(Icons.view_agenda),
            onPressed: () =>
                AutoRouter.of(context).push(ScheduleRoute(orgID: orgID)),
          ),
        ));
        privilegedActions.add(Tooltip(
          message: "Review Bookings",
          child: IconButton(
            icon: const Icon(Icons.approval_rounded),
            onPressed: () =>
                AutoRouter.of(context).push(ReviewBookingsRoute(orgID: orgID)),
          ),
        ));
        privilegedActions.add(Tooltip(
          message: "Settings",
          child: IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () =>
                AutoRouter.of(context).push(OrgSettingsRoute(orgID: orgID)),
          ),
        ));
      }
      return [
        ...privilegedActions,
        Tooltip(
          message: "Logout",
          child: IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              var router = AutoRouter.of(context);
              await FirebaseAuth.instance.signOut();
              router.replace(ViewBookingsRoute(orgID: orgID));
            },
          ),
        ),
      ];
    }
    return [
      Tooltip(
        message: "Login",
        child: IconButton(
          icon: const Icon(Icons.login),
          onPressed: () =>
              AutoRouter.of(context).push(LoginRoute(orgID: orgID)),
        ),
      )
    ];
  }
}
