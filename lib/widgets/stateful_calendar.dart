import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/blackout_window.dart';
import 'package:room_booker/entities/request.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarStateProvider extends StatelessWidget {
  final DateTime? focusDate;
  final CalendarView initialView;
  final Widget child;

  const CalendarStateProvider(
      {super.key,
      required this.child,
      this.focusDate,
      required this.initialView});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: CalendarState(initialView, focusDate: focusDate),
      child: child,
    );
  }
}

class CalendarData {
  final List<Request> existingRequests;
  final List<BlackoutWindow> blackoutWindows;
  final List<PrivateRequestDetails>? privateDetails;

  CalendarData(
      {this.privateDetails,
      required this.existingRequests,
      required this.blackoutWindows});
}

class CalendarState extends ChangeNotifier {
  final CalendarController _controller = CalendarController();
  DateTime _windowStartDate = getStartDate(DateTime.now());
  DateTime _windowEndDate = getEndDate(DateTime.now());
  bool initialized = false;

  CalendarState(CalendarView initialView, {DateTime? focusDate}) {
    _controller.displayDate = focusDate;
    _controller.view = initialView;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.addPropertyChangedListener((property) {
        if (property == "displayDate") {
          // This is a GROSS hack to prevent calling notifyListeners() during
          // initialization.
          if (!initialized &&
              stripTime(_controller.displayDate!) ==
                  stripTime(DateTime.now())) {
            initialized = true;
            return;
          }
          _windowStartDate = getStartDate(controller.displayDate!);
          _windowEndDate = getEndDate(controller.displayDate!);
          notifyListeners();
        }
      });
    });
  }

  void focusDay(DateTime date) {
    var displayDate = _controller.displayDate?.stripTime();
    if (displayDate != date.stripTime()) {
      _controller.displayDate = date;
    }
    _controller.view = CalendarView.day;
    notifyListeners();
  }

  void setView(CalendarView view) {
    _controller.view = view;
    notifyListeners();
  }

  get controller => _controller;
  get windowStartDate => _windowStartDate;
  get windowEndDate => _windowEndDate;
}

extension DateTimeExt on DateTime {
  DateTime stripTime() {
    return DateTime(year, month, day);
  }
}

class StatefulCalendar extends StatelessWidget {
  final CalendarView view;
  final bool showNavigationArrow;
  final bool showDatePickerButton;
  final bool showTodayButton;
  final DateTime? selectedDate;
  final DateTime? displayDate;
  final Function(CalendarTapDetails)? onTap;
  final Function(Request)? onTapBooking;

  final bool allowAppointmentResize;
  final Function(ResizeDetails)? onAppointmentResizeEnd;

  final Appointment? newAppointment;
  final Map<Appointment, Request> appointments;
  final List<BlackoutWindow> blackoutWindows;

  const StatefulCalendar({
    super.key,
    required this.view,
    required this.showNavigationArrow,
    required this.showDatePickerButton,
    required this.showTodayButton,
    required this.appointments,
    required this.blackoutWindows,
    this.selectedDate,
    this.displayDate,
    this.onTap,
    this.onTapBooking,
    this.onAppointmentResizeEnd,
    this.allowAppointmentResize = false,
    this.newAppointment,
  });

  @override
  Widget build(BuildContext context) {
    Function(AppointmentResizeEndDetails)? onResizeEnd;
    if (onAppointmentResizeEnd != null) {
      onResizeEnd = (details) {
        onAppointmentResizeEnd!(ResizeDetails(
            appointment: details.appointment,
            startTime: details.startTime!,
            endTime: details.endTime!));
      };
    }
    var dataSource = _DataSource(appointments.keys.toList() +
        [if (newAppointment != null) newAppointment!]);
    var specialRegions = blackoutWindows.map((w) => w.toTimeRegion()).toList();
    var calendarState = Provider.of<CalendarState>(context, listen: false);
    calendarState.controller.view = view;
    return SfCalendar(
      controller: calendarState.controller,
      showNavigationArrow: showNavigationArrow,
      showTodayButton: showTodayButton,
      showDatePickerButton: showDatePickerButton,
      allowAppointmentResize: allowAppointmentResize,
      allowViewNavigation: false,
      allowedViews: [
        CalendarView.day,
        CalendarView.week,
        CalendarView.month,
      ],
      minDate: nowRoundedUpToNearestHour(),
      onAppointmentResizeEnd: onResizeEnd,
      onTap: (details) {
        switch (details.targetElement) {
          case CalendarElement.appointment:
            if (onTapBooking != null) {
              for (var appointment in details.appointments ?? []) {
                var request = appointments[appointment];
                if (request == null) {
                  throw Exception("Appointment not found in state");
                }
                onTapBooking!(request);
              }
            }
            break;
          case CalendarElement.calendarCell:
            if (onTap != null) {
              onTap!(details);
            }
            break;
          default:
            break;
        }
      },
      specialRegions: specialRegions,
      dataSource: dataSource,
    );
  }
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

DateTime stripTime(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime getEndDate(DateTime displayDate) {
  var cleanDate = stripTime(displayDate);
  var daysToAdd = 7 - cleanDate.weekday % 7;
  return displayDate.add(Duration(days: daysToAdd));
}

DateTime getStartDate(DateTime displayDate) {
  var cleanDate = stripTime(displayDate);
  var daysToAdd = cleanDate.weekday % 7;
  return displayDate.subtract(Duration(days: daysToAdd));
}

DateTime nowRoundedUpToNearestHour() {
  var now = DateTime.now();
  return DateTime(now.year, now.month, now.day, now.hour + 1);
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
