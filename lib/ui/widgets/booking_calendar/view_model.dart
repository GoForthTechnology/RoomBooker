import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:room_booker/data/entities/blackout_window.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/ui/widgets/org_state_provider.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';
import 'package:rxdart/rxdart.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarViewState {
  final bool allowAppointmentResize;
  final bool allowDragAndDrop;
  final CalendarDataSource dataSource;
  final List<TimeRegion> specialRegions;

  CalendarViewState({
    required this.allowAppointmentResize,
    required this.allowDragAndDrop,
    required this.specialRegions,
    required this.dataSource,
  });
}

class VisibleWindow {
  final DateTime start;
  final DateTime end;

  VisibleWindow({required this.start, required this.end});
}

class CalendarViewModel extends ChangeNotifier {
  final CalendarController controller = CalendarController();

  final BehaviorSubject<VisibleWindow> _visibleWindowController =
      BehaviorSubject();
  final BehaviorSubject<Map<String, Request>> _requestIndex = BehaviorSubject();

  final Function(Request)? onRequestTap;
  final Function(DateTapDetails)? onDateTap;
  final Function(DragDetails)? onDragEnd;
  final Function(ResizeDetails)? onResizeEnd;

  final bool appendRoomName;
  final bool includePrivateBookings;
  final bool _allowAppointmentResize;
  final bool _allowDragAndDrop;
  final bool showNavigationArrow;
  final bool showTodayButton;
  final bool showDatePickerButton;
  final bool showIgnoringOverlaps;
  final bool allowViewNavigation;
  final List<CalendarView> allowedViews;
  final Stream<Appointment?> _newAppointment;

  bool initialized = false;

  final BookingRepo _bookingRepo;
  final OrgState _orgState;
  final RoomState _roomState;

  CalendarViewModel({
    required OrgState orgState,
    required BookingRepo bookingRepo,
    required RoomState roomState,
    CalendarView defaultView = CalendarView.week,
    bool allowAppointmentResize = false,
    bool allowDragAndDrop = false,
    Stream<Appointment?>? newAppointment,
    DateTime? targetDate,
    this.includePrivateBookings = false,
    this.showNavigationArrow = false,
    this.showTodayButton = false,
    this.showDatePickerButton = false,
    this.appendRoomName = false,
    this.showIgnoringOverlaps = false,
    this.allowViewNavigation = false,
    this.onDateTap,
    this.onDragEnd,
    this.onResizeEnd,
    this.onRequestTap,
    this.allowedViews = const [
      CalendarView.day,
      CalendarView.week,
      CalendarView.month,
      CalendarView.schedule,
    ],
  }) : _allowAppointmentResize = allowAppointmentResize,
       _allowDragAndDrop = allowDragAndDrop,
       _bookingRepo = bookingRepo,
       _orgState = orgState,
       _roomState = roomState,
       _newAppointment = (newAppointment ?? Stream.value(null))
           .asBroadcastStream() {
    controller.view = defaultView;
    controller.displayDate = targetDate ?? DateTime.now();
    var currentWindow = VisibleWindow(start: startOfView, end: endOfView);
    _visibleWindowController.add(currentWindow);
    controller.addPropertyChangedListener(_handlePropertyChange);
    _requestIndex.addStream(
      _buildAppointmentStream(bookingRepo, orgState, roomState).map((
        appointmentsToRequests,
      ) {
        Map<String, Request> index = {};
        for (var e in appointmentsToRequests.entries) {
          var appointment = e.key;
          var request = e.value;
          index[_appointmentID(appointment)] = request;
        }
        return index;
      }),
    );
  }

  Stream<CalendarViewState> _viewStateStream(
    BookingRepo bookingRepo,
    OrgState orgState,
    RoomState roomState,
  ) {
    return Rx.combineLatest3(
      _newAppointment.startWith(null),
      _buildAppointmentStream(
        bookingRepo,
        orgState,
        roomState,
      ).startWith(const {}),
      bookingRepo
          .listBlackoutWindows(orgState.org, startOfView, endOfView)
          .startWith(const []),
      (newAppointment, appointments, blackoutWindows) {
        List<Appointment> out = [];
        for (var appointment in appointments.keys) {
          out.add(appointment);
        }
        return CalendarViewState(
          allowAppointmentResize:
              _allowAppointmentResize && newAppointment == null,
          allowDragAndDrop: _allowDragAndDrop && newAppointment == null,
          dataSource: _DataSource(out),
          specialRegions: blackoutWindows.map((w) => w.toTimeRegion()).toList(),
        );
      },
    );
  }

  Stream<Map<Appointment, Request>> _buildAppointmentStream(
    BookingRepo bookingRepo,
    OrgState orgState,
    RoomState roomState,
  ) {
    return Rx.combineLatest2(
      _visibleWindowController,
      _newAppointment.startWith(null),
      (window, newAppointment) => bookingRepo
          .listRequests(
            orgID: orgState.org.id!,
            startTime: window.start,
            endTime: window.end,
            includeStatuses: {RequestStatus.pending, RequestStatus.confirmed},
          )
          .flatMap(
            (requests) => _detailStream(orgState, requests, bookingRepo)
                .startWith([])
                .map(
                  (details) => _convertRequests(
                    requests,
                    details,
                    window,
                    roomState,
                    newAppointment,
                  ),
                ),
          ),
    ).flatMap((s) => s).startWith({});
  }

  Map<Appointment, Request> _convertRequests(
    List<Request> requests,
    List<PrivateRequestDetails> details,
    VisibleWindow window,
    RoomState roomState,
    Appointment? newAppointment,
  ) {
    var detailIndex = _indexDetails(details);
    Map<Appointment, Request> appointments = {};
    for (var request in requests) {
      for (var repeat in request.expand(
        window.start,
        window.end,
        includeRequestDate: true,
      )) {
        /*if (_isSameRequest(requestEditorState.existingRequest, repeat)) {
          // Skip the current request
          continue;
        }*/
        String? subject = repeat.publicName;
        var details = detailIndex[request.id!];
        if (subject == null && details != null) {
          subject = "${details.eventName} (Private)";
        }
        var isPrivateBooking = (subject ?? "") == "";
        if (isPrivateBooking && !includePrivateBookings) {
          continue;
        }
        var appointment = repeat.toAppointment(
          roomState,
          subject: subject,
          diminish: newAppointment != null,
          appendRoomName: appendRoomName,
          showIngnoringOverlaps: showIgnoringOverlaps,
        );
        appointments[appointment] = repeat;
      }
    }
    return appointments;
  }

  static Map<String, PrivateRequestDetails> _indexDetails(
    List<PrivateRequestDetails> details,
  ) {
    var out = <String, PrivateRequestDetails>{};
    for (var d in details) {
      out[d.id!] = d;
    }
    return out;
  }

  Stream<List<PrivateRequestDetails>> _detailStream(
    OrgState orgState,
    List<Request> requests,
    BookingRepo bookingRepo,
  ) {
    if (!orgState.currentUserIsAdmin() || requests.isEmpty) {
      return Stream.value([]);
    }
    var orgID = orgState.org.id!;
    var streams = requests
        .map((r) => bookingRepo.getRequestDetails(orgID, r.id!))
        .toList();
    return Rx.combineLatestList(streams).map((details) {
      var out = <PrivateRequestDetails>[];
      for (var d in details) {
        if (d != null) {
          out.add(d);
        }
      }
      return out;
    });
  }

  void _handlePropertyChange(String property) {
    if (property == "displayDate") {
      // This is a GROSS hack to prevent calling notifyListeners() during
      // initialization.
      if (!initialized &&
          stripTime(controller.displayDate!) == stripTime(DateTime.now())) {
        initialized = true;
        return;
      }
      if (controller.view == CalendarView.schedule) {
        // This prevents the schedule view from glitching out.
        return;
      }
      _visibleWindowController.add(
        VisibleWindow(start: startOfView, end: endOfView),
      );
      return;
    }
    if (property == "calendarView") {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _visibleWindowController.add(
          VisibleWindow(start: startOfView, end: endOfView),
        );
      });
      return;
    }
  }

  Stream<CalendarViewState> calendarViewState() {
    return _viewStateStream(_bookingRepo, _orgState, _roomState);
  }

  // Bizarre things happen when you shink the screen which makes this
  // necessary...
  DateTime? get minDate =>
      controller.view == CalendarView.schedule ? DateTime.now() : null;

  DateTime get startOfView {
    var displayDate = controller.displayDate!;
    switch (controller.view) {
      case CalendarView.schedule:
      case CalendarView.day:
        return displayDate;
      case CalendarView.week:
        var date = displayDate;
        while (getWeekday(date) != Weekday.sunday) {
          date = date.subtract(Duration(days: 1));
        }
        return date;
      case CalendarView.month:
        var startOfMonth = DateTime(displayDate.year, displayDate.month, 1);
        while (getWeekday(startOfMonth) != Weekday.sunday) {
          startOfMonth = startOfMonth.subtract(Duration(days: 1));
        }
        return startOfMonth;
      case CalendarView.timelineDay:
      case CalendarView.timelineWeek:
      case CalendarView.timelineWorkWeek:
      case CalendarView.timelineMonth:
      case CalendarView.workWeek:
      case null:
        throw UnimplementedError();
    }
  }

  DateTime get endOfView {
    var start = controller.displayDate!;
    switch (controller.view) {
      case CalendarView.day:
        return start.add(Duration(days: 1));
      case CalendarView.week:
        return startOfView.add(Duration(days: 7));
      case CalendarView.month:
        var date = DateTime(
          start.year,
          start.month + 1,
          1,
        ).subtract(Duration(days: 1));
        while (getWeekday(date) != Weekday.saturday) {
          date = date.add(Duration(days: 1));
        }
        return date;
      case CalendarView.schedule:
        return start.add(Duration(days: 90));
      case CalendarView.timelineDay:
      case CalendarView.timelineWeek:
      case CalendarView.timelineWorkWeek:
      case CalendarView.timelineMonth:
      case CalendarView.workWeek:
      case null:
        throw UnimplementedError();
    }
  }

  void handleDragEnd(AppointmentDragEndDetails details) {
    if (details.appointment == null || details.droppingTime == null) {
      return;
    }
    var appointment = details.appointment as Appointment?;
    if (appointment == null) {
      return;
    }
    Request? request = _requestIndex.valueOrNull?[_appointmentID(appointment)];
    if (request == null) {
      log("Appointment not found in state, cannot call onAppointmentDragEnd");
      return;
    }
    if (onDragEnd != null) {
      onDragEnd!(
        DragDetails(request: request, dropTime: details.droppingTime!),
      );
    }
  }

  void handleResizeEnd(AppointmentResizeEndDetails details) {
    if (onResizeEnd != null) {
      onResizeEnd!(
        ResizeDetails(
          appointment: details.appointment,
          startTime: details.startTime!,
          endTime: details.endTime!,
        ),
      );
    }
  }

  void handleTap(CalendarTapDetails details) {
    switch (details.targetElement) {
      case CalendarElement.appointment:
        _handleRequestTap(details);
        break;
      case CalendarElement.calendarCell:
        _handleDateTap(details.date);
        break;
      default:
        break;
    }
  }

  static String _appointmentID(Appointment appointment) {
    if (appointment.resourceIds == null || appointment.resourceIds!.isEmpty) {
      throw ArgumentError("Appointment has no resource ID");
    }
    return appointment.resourceIds!.first.toString();
  }

  void _handleRequestTap(CalendarTapDetails details) {
    if (onRequestTap == null) {
      return;
    }
    for (var appointment in details.appointments ?? []) {
      var request = _requestIndex.valueOrNull?[_appointmentID(appointment)];
      if (request == null) {
        log("Appointment not found in state");
        continue;
      }
      onRequestTap!(request);
    }
  }

  void _handleDateTap(DateTime? date) {
    if (date == null) {
      return;
    }
    if (onDateTap != null) {
      onDateTap!(DateTapDetails(date: date, view: controller.view!));
    }
  }
}

class DateTapDetails {
  final DateTime date;
  final CalendarView view;

  DateTapDetails({required this.date, required this.view});
}

class DragDetails {
  final Request request;
  final DateTime dropTime;

  DragDetails({required this.request, required this.dropTime});
}

class ResizeDetails {
  final Appointment appointment;
  final DateTime startTime;
  final DateTime endTime;

  ResizeDetails({
    required this.appointment,
    required this.startTime,
    required this.endTime,
  });
}

class _DataSource extends CalendarDataSource {
  _DataSource(List<Appointment> source) {
    appointments = source;
  }
}

extension on BlackoutWindow {
  TimeRegion toTimeRegion() {
    return TimeRegion(
      startTime: start,
      endTime: end,
      enablePointerInteraction: false,
      text: reason,
      recurrenceRule: recurrenceRule,
      color: Colors.grey.withValues(alpha: 0.2),
    );
  }
}

DateTime stripTime(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

extension on Request {
  Appointment toAppointment(
    RoomState roomState, {
    String? subject,
    bool diminish = false,
    bool appendRoomName = false,
    bool showIngnoringOverlaps = false,
  }) {
    var alphaLevel = diminish || status == RequestStatus.pending ? 128 : 255;
    var color = roomState.color(roomID).withAlpha(alphaLevel);
    var s =
        subject ?? (status == RequestStatus.confirmed ? "Booked" : "Requested");
    if (appendRoomName) {
      var roomName = roomState.getRoom(roomID)?.name ?? "Unknown Room";
      s += " ($roomName)";
    }
    if (ignoreOverlaps && showIngnoringOverlaps) {
      s += "\n(Ignoring Overlaps!)";
    }
    return Appointment(
      subject: s,
      color: color,
      startTime: eventStartTime,
      endTime: eventEndTime,
      resourceIds: [id!],
    );
  }
}
