import 'dart:developer';

import 'package:room_booker/data/services/print_service.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/data/services/auth_service.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/room_repo.dart';
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
  final RoomRepo _roomRepo;
  final OrgState _orgState;

  final CalendarViewModel _calendarViewModel;
  final RequestEditorViewModel _requestEditorViewModel;

  final Size Function() sizeProvider;
  final Function(Request) showRequestDialog;
  final Function() showEditorAsDialog;
  final Future<DateTime?> Function(DateTime, DateTime, DateTime) pickDate;
  final Future<TimeOfDay?> Function(DateTime) pickTime;
  final PrintService? printService;

  static final dateFormat = DateFormat('yyyy-MM-dd');

  final _showRoomSelectorSubject = BehaviorSubject<bool>.seeded(false);

  ViewBookingsViewModel({
    required BookingRepo bookingRepo,
    required RoomRepo roomRepo,
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
    this.printService,
  }) : _bookingRepo = bookingRepo,
       _roomRepo = roomRepo,
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
    if (readOnlyMode || !_orgState.currentUserIsAdmin) {
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

    actions.add(
      Action(
        name: "Print",
        icon: Icons.print,
        onPressed: () => _onPrint(context),
      ),
    );

    return actions;
  }

  void _onPrint(BuildContext context) async {
    try {
      final service = printService ?? PrintService();

      var targetDate =
          _calendarViewModel.controller.displayDate ?? DateTime.now();
      var view = _calendarViewModel.controller.view ?? CalendarView.week;

      DateTime start;
      DateTime end;
      if (view == CalendarView.day) {
        start = DateTime(targetDate.year, targetDate.month, targetDate.day);
        end = start.add(const Duration(days: 1));
      } else if (view == CalendarView.week) {
        start = targetDate.subtract(const Duration(days: 7));
        end = targetDate.add(const Duration(days: 7));
      } else {
        start = DateTime(
          targetDate.year,
          targetDate.month,
          1,
        ).subtract(const Duration(days: 7));
        end = DateTime(
          targetDate.year,
          targetDate.month + 1,
          1,
        ).add(const Duration(days: 7));
      }

      // Wait for the stream to settle to get the latest data
      final requestsStream = _bookingRepo.listRequests(
        orgID: orgID,
        startTime: start,
        endTime: end,
        includeStatuses: {RequestStatus.confirmed},
      );
      List<Request> requests = [];
      final subscription = requestsStream.listen((event) {
        requests = event;
      });

      // Wait for 500ms for data to fetch (skipping potential initial empty/cache states)
      await Future.delayed(const Duration(milliseconds: 500));
      await subscription.cancel();

      // If user is admin, fetch private details to show real names instead of "Private"
      if (_orgState.currentUserIsAdmin) {
        requests = await Future.wait(
          requests.map((r) async {
            if (r.id == null) return r;
            try {
              final details = await _bookingRepo
                  .getRequestDetails(orgID, r.id!)
                  .first;
              if (details != null && details.eventName.isNotEmpty) {
                return r.copyWith(publicName: details.eventName);
              }
            } catch (e) {
              log("Error fetching details for print: $e");
            }
            return r;
          }),
        );
      }

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
    }
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
