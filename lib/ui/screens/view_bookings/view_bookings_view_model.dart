import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/data/auth_service.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/ui/widgets/booking_calendar/view_model.dart';
import 'package:room_booker/ui/widgets/org_state_provider.dart';
import 'package:room_booker/ui/widgets/request_editor/request_editor_view_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import 'package:room_booker/ui/utils/booking_date_helper.dart';

class ViewBookingsViewModel extends ChangeNotifier {
  final String? _existingRequestID;
  final bool readOnlyMode;
  final bool createRequest;
  final bool showPrivateBookings;

  final StackRouter _router;
  final AuthService _authService;
  final BookingRepo _bookingRepo;
  final OrgState _orgState;

  final CalendarViewModel _calendarViewModel;
  final RequestEditorViewModel _requestEditorViewModel;

  final Size Function() sizeProvider;
  final Function(Request) showRequestDialog;
  final Function() showEditorAsDialog;
  final Future<DateTime?> Function(DateTime, DateTime, DateTime) pickDate;
  final Future<TimeOfDay?> Function(DateTime) pickTime;

  static final dateFormat = DateFormat('yyyy-MM-dd');

  final _showRoomSelectorSubject = BehaviorSubject<bool>.seeded(false);

  ViewBookingsViewModel({
    required BookingRepo bookingRepo,
    required AuthService authService,
    required OrgState orgState,
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
    required Function(Uri) updateUri,
    required this.pickDate,
    required this.pickTime,
  }) : _bookingRepo = bookingRepo,
       _authService = authService,
       _router = router,
       _calendarViewModel = calendarViewModel,
       _requestEditorViewModel = requestEditorViewModel,
       _orgState = orgState,
       _existingRequestID = existingRequestID {
    _showRoomSelectorSubject.add(showRoomSelector);
    _calendarViewModel.registerNewAppointmentStream(
      _requestEditorViewModel.currentDataStream(),
    );
    _calendarViewModel.dateTapStream.listen(_onTapDate);
    _calendarViewModel.requestTapStream.listen(_onTapBooking);
    _currentUriStream().listen(updateUri);

    if (_existingRequestID != null) {
      loadExistingRequest(_existingRequestID);
    }
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
    if (readOnlyMode) {
      showRequestDialog(request);
    } else {
      var details = await _bookingRepo
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
      log("Changing to day view for date ${details.date}");
      _calendarViewModel.focusDate(details.date);
      return;
    }
    log("Loading new request for date ${details.date}");
    loadNewRequest(details.date);
  }

  Future<void> loadExistingRequest(String requestID) async {
    log("Loading existing request with ID $requestID");
    var request = await _bookingRepo.getRequest(orgID, requestID).first;
    if (request == null) {
      throw Exception("Request with ID $requestID not found");
    }
    var details = await _bookingRepo.getRequestDetails(orgID, requestID).first;
    if (details == null) {
      throw Exception("Request details with ID $requestID not found");
    }
    _requestEditorViewModel.initializeFromExistingRequest(request, details);
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

  bool isSmallView() {
    return sizeProvider().width < 650;
  }

  Future<Request?> get existingRequest {
    if (_existingRequestID == null) {
      return Future.value(null);
    }
    return _bookingRepo.getRequest(orgID, _existingRequestID).first;
  }

  Future<PrivateRequestDetails?> get existingRequestDetails {
    if (_existingRequestID == null) {
      return Future.value(null);
    }
    return _bookingRepo.getRequestDetails(orgID, _existingRequestID).first;
  }

  String get orgID => _orgState.org.id!;

  void toggleRoomSelector() {
    var current = _showRoomSelectorSubject.value;
    _showRoomSelectorSubject.add(!current);
  }

  void onAddNewBooking() async {
    var focusDate = _calendarViewModel.controller.displayDate!;
    var firstDate = BookingDateHelper.getFirstDate(focusDate);
    var lastDate = BookingDateHelper.getLastDate(firstDate);

    var targetDate = await pickDate(focusDate, firstDate, lastDate);
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
