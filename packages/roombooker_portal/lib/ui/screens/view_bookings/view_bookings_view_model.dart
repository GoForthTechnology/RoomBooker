import 'dart:async';
import 'dart:developer';

import 'package:roombooker_core/data/services/print_service.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:roombooker_core/data/services/auth_service.dart';
import 'package:roombooker_core/data/entities/request.dart';
import 'package:roombooker_core/data/services/booking_service.dart';
import 'package:roombooker_core/data/repos/room_repo.dart';
import 'package:roombooker_portal/router.dart';
import 'package:roombooker_portal/ui/widgets/booking_calendar/view_model.dart';
import 'package:roombooker_portal/ui/widgets/org_state_provider.dart';
import 'package:roombooker_portal/ui/widgets/request_editor/request_editor_view_model.dart';

import 'package:rxdart/rxdart.dart';
import 'package:roombooker_core/utils/calendar_utils.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import 'package:roombooker_portal/ui/utils/booking_date_helper.dart';

class ViewBookingsViewModel extends ChangeNotifier {
  final String? _existingRequestID;
  final bool readOnlyMode;
  final bool createRequest;
  final bool showPrivateBookings;

  final StackRouter _router;
  final AuthService _authService;

  final RoomRepo _roomRepo;
  final OrgState _orgState;
  final BookingService _bookingService;

  final CalendarViewModel _calendarViewModel;
  final RequestEditorViewModel _requestEditorViewModel;

  final Size Function() sizeProvider;
  final Function(Request) showRequestDialog;
  final Function() showEditorAsDialog;
  final Function(String) showSnackBar;
  final Future<DateTime?> Function(DateTime, DateTime, DateTime) pickDate;
  final Future<TimeOfDay?> Function(DateTime) pickTime;
  final PrintService? printService;

  static final dateFormat = DateFormat('yyyy-MM-dd');

  final _showRoomSelectorSubject = BehaviorSubject<bool>.seeded(false);
  final _subscriptions = <StreamSubscription>[];

  ViewBookingsViewModel({
    required RoomRepo roomRepo,
    required AuthService authService,
    required OrgState orgState,
    required BookingService bookingService,
    required StackRouter router,
    required this.sizeProvider,
    required CalendarViewModel calendarViewModel,
    required RequestEditorViewModel requestEditorViewModel,
    required String? existingRequestID,
    required bool showRoomSelector,
    required this.createRequest,
    required this.readOnlyMode,
    required this.showPrivateBookings,
    required this.showRequestDialog,
    required this.showEditorAsDialog,
    required this.showSnackBar,
    required Function(Uri) updateUri,
    required this.pickDate,
    required this.pickTime,
    this.printService,
  }) : _roomRepo = roomRepo,
       _authService = authService,
       _bookingService = bookingService,
       _router = router,
       _calendarViewModel = calendarViewModel,
       _requestEditorViewModel = requestEditorViewModel,
       _orgState = orgState,
       _existingRequestID = existingRequestID {
    _showRoomSelectorSubject.add(showRoomSelector);
    _calendarViewModel.registerNewAppointmentStream(
      _requestEditorViewModel.currentDataStream(),
    );
    _calendarViewModel.registerInitialRequestStream(
      _requestEditorViewModel.initialRequestStream,
    );
    _subscriptions.add(_calendarViewModel.dateTapStream.listen(_onTapDate));
    _subscriptions.add(
      _calendarViewModel.requestTapStream.listen(_onTapBooking),
    );
    _subscriptions.add(
      _calendarViewModel.dragEndStream.listen(_onDragEnd),
    );
    _subscriptions.add(
      _calendarViewModel.resizeEndStream.listen(_onResizeEnd),
    );
    _subscriptions.add(_currentUriStream().listen(updateUri));

    if (_existingRequestID != null) {
      loadExistingRequest(_existingRequestID);
    }
  }

  @override
  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _showRoomSelectorSubject.close();
    super.dispose();
  }

  Stream<Uri> _currentUriStream() {
    return Rx.combineLatest2(
      _requestEditorViewModel.initialRequestStream,
      _calendarViewModel.calendarViewState(),
      (initialRequest, viewState) {
        final params = <String, String>{
          "td": DateFormat('yyyy-MM-dd').format(viewState.currentDate),
          "v": viewState.currentView.name,
        };
        if (readOnlyMode) {
          params["ro"] = "true";
        }
        if (!showPrivateBookings) {
          params["spb"] = "false";
        }
        if (createRequest) {
          params["createRequest"] = "true";
        }
        if (initialRequest?.id != null) {
          params["rid"] = initialRequest!.id!;
        }
        return Uri(path: "/view/${_orgState.org.id!}", queryParameters: params);
      },
    );
  }

  void _onTapBooking(Request request) async {
    if (readOnlyMode || !_orgState.currentUserIsAdmin) {
      showRequestDialog(request);
    } else {
      var details = await _bookingService
          .getRequestDetails(orgID, request.id!)
          .first;
      if (details == null) {
        throw Exception("Request details with ID ${request.id} not found");
      }
      _requestEditorViewModel.initializeFromExistingRequest(request, details);
      if (isSmallView()) {
        showEditorAsDialog();
      }
    }
  }

  void _onTapDate(DateTapDetails details) {
    log("Date tapped: ${details.date}");
    if (readOnlyMode) {
      return;
    }

    if (details.view == CalendarView.month) {
      if (_requestEditorViewModel.isRescheduling) {
        log("Ignoring month tap during reschedule");
        return;
      }
      log("Changing to day view for date ${details.date}");
      _calendarViewModel.focusDate(details.date);
      return;
    }

    if (_requestEditorViewModel.isRescheduling) {
      log("Teleporting event to ${details.date}");
      _requestEditorViewModel.moveEventTo(details.date);
    } else {
      log("Loading new request for date ${details.date}");
      loadNewRequest(details.date);
    }
  }

  void _onDragEnd(DragDetails details) {
    log("Event dragged: ${details.request.id} to ${details.dropTime}");
    final request = details.request;
    final duration = request.eventEndTime.difference(request.eventStartTime);
    final newStart = details.dropTime;
    final newEnd = newStart.add(duration);
    _rescheduleRequest(request, newStart, newEnd);
  }

  void _onResizeEnd(ResizeDetails details) {
    log("Event resized: ${details.request.id} to ${details.startTime} - ${details.endTime}");
    _rescheduleRequest(details.request, details.startTime, details.endTime);
  }

  Future<void> _rescheduleRequest(
    Request originalRequest,
    DateTime newStart,
    DateTime newEnd,
  ) async {
    try {
      final details = await _bookingService
          .getRequestDetails(orgID, originalRequest.id!)
          .first;
      if (details == null) {
        throw Exception("Request details with ID ${originalRequest.id} not found");
      }

      final updatedRequest = originalRequest.copyWith(
        eventStartTime: newStart,
        eventEndTime: newEnd,
      );

      await _bookingService.updateBooking(
        orgID,
        originalRequest,
        updatedRequest,
        details,
        originalRequest.status ?? RequestStatus.pending,
        _requestEditorViewModel.choiceProvider,
        originalStartTime: originalRequest.eventStartTime,
      );
    } catch (e) {
      log("Error rescheduling booking: $e");
      showSnackBar("Failed to reschedule: $e");
    }
  }

  Future<void> loadExistingRequest(String requestID) async {
    log("Loading existing request with ID $requestID");
    var request = await _bookingService.getRequest(orgID, requestID).first;
    if (request == null) {
      throw Exception("Request with ID $requestID not found");
    }
    var details = await _bookingService
        .getRequestDetails(orgID, requestID)
        .first;
    if (details == null) {
      throw Exception("Request details with ID $requestID not found");
    }
    _requestEditorViewModel.initializeFromExistingRequest(request, details);

    // Center the calendar on the event and open the editor on small screens
    _calendarViewModel.scrollToTime(request.eventStartTime);
    if (isSmallView()) {
      showEditorAsDialog();
    }
  }

  Future<void> loadNewRequest(DateTime targetDate) async {
    _requestEditorViewModel.initializeNewRequest(targetDate);
    if (isSmallView()) {
      showEditorAsDialog();
    }
  }

  Stream<ViewState> get viewStateStream =>
      Rx.combineLatest2<bool, Request?, ViewState>(
        _showRoomSelectorSubject.stream,
        _requestEditorViewModel.initialRequestStream,
        (showRoomSelector, request) => ViewState(
          showEditor: request != null,
          showRoomSelector: showRoomSelector,
        ),
      );

  List<Action> getActions(BuildContext context) {
    List<Action> actions = [];

    actions.add(
      Action(
        name: "Print",
        icon: Icons.print,
        onPressed: () => _onPrint(context),
      ),
    );

    if (_orgState.currentUserIsAdmin) {
      actions.add(
        Action(
          name: "Review Requests",
          icon: Icons.approval_rounded,
          onPressed: () {
            AutoRouter.of(context).push(ReviewBookingsRoute(orgID: orgID));
          },
          // TODO: populate notification count using OrgDetailsProvider
        ),
      );
      actions.add(
        Action(
          name: "Settings",
          icon: Icons.settings,
          onPressed: () {
            AutoRouter.of(context).push(OrgSettingsRoute(orgID: orgID));
          },
        ),
      );
    }
    if (_authService.getCurrentUserID() != null) {
      actions.add(
        Action(
          name: "Logout",
          icon: Icons.logout,
          onPressed: () async {
            var router = AutoRouter.of(context);
            _authService.logout();
            router.replace(ViewBookingsRoute(orgID: orgID));
          },
        ),
      );
    } else {
      actions.add(
        Action(
          name: "Login",
          icon: Icons.login,
          onPressed: () =>
              AutoRouter.of(context).push(LoginRoute(orgID: orgID)),
        ),
      );
    }

    return actions;
  }

  void _onPrint(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final service = printService ?? PrintService();

      var targetDate =
          _calendarViewModel.controller.displayDate ?? DateTime.now();
      var view = _calendarViewModel.controller.view ?? CalendarView.week;

      final range = CalendarUtils.getVisibleRange(targetDate, view);
      DateTime start = range.start;
      DateTime end = range.end;

      // Wait for the stream to settle to get the latest data
      final requestsStream = _bookingService.getRequestsStream(
        orgID: orgID,
        isAdmin: _orgState.currentUserIsAdmin,
        start: start,
        end: end,
        includeStatuses: {RequestStatus.confirmed},
      );
      List<Request> requests = [];
      final subscription = requestsStream.listen((event) {
        requests = event;
      });

      // Wait for 500ms for data to fetch (skipping potential initial empty/cache states)
      await Future.delayed(const Duration(milliseconds: 500));
      await subscription.cancel();

      // Fetch room colors
      final rooms = await _roomRepo.listRooms(orgID).first;
      final roomColors = {for (var r in rooms) r.id!: r.colorHex ?? ""};

      await service.printCalendar(
        requests: requests,
        targetDate: targetDate,
        view: view,
        orgName: _orgState.org.name,
        roomColors: roomColors,
      );
    } catch (e) {
      log("Failed to print calendar: $e");
    } finally {
      // Dismiss loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  bool isSmallView() {
    return sizeProvider().width < 650;
  }

  Future<Request?> get existingRequest {
    if (_existingRequestID == null) {
      return Future.value(null);
    }
    return _bookingService.getRequest(orgID, _existingRequestID).first;
  }

  Future<PrivateRequestDetails?> get existingRequestDetails {
    if (_existingRequestID == null) {
      return Future.value(null);
    }
    return _bookingService.getRequestDetails(orgID, _existingRequestID).first;
  }

  String get orgID => _orgState.org.id!;

  void toggleRoomSelector() {
    var current = _showRoomSelectorSubject.value;
    _showRoomSelectorSubject.add(!current);
  }

  void closeEditor() {
    _requestEditorViewModel.closeEditor();
  }

  void onAddNewBooking() async {
    final focusDate = _calendarViewModel.controller.displayDate ?? DateTime.now();
    final firstDate = BookingDateHelper.getFirstDate(focusDate);
    final lastDate = BookingDateHelper.getLastDate(firstDate);

    final targetDate = await pickDate(focusDate, firstDate, lastDate);
    if (targetDate == null) {
      return;
    }

    var eventTime = await pickTime(targetDate);
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
    _router.push(
      ViewBookingsRoute(
        orgID: orgID,
        view: CalendarView.day.name,
        targetDateStr: dateFormat.format(startTime),
        createRequest: true,
      ),
    );
  }
}

class Action {
  final String name;
  final IconData icon;
  final VoidCallback onPressed;
  final int notificationCount;

  Action({
    required this.name,
    required this.icon,
    required this.onPressed,
    this.notificationCount = 0,
  });
}

class ViewState {
  final bool showEditor;
  final bool showRoomSelector;

  ViewState({required this.showEditor, required this.showRoomSelector});
}
