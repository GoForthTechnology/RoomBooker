import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/blackout_window.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarStateProvider extends StatelessWidget {
  final DateTime focusDate;
  final CalendarView initialView;
  final Widget? child;
  final Widget Function(BuildContext, Widget?)? builder;

  const CalendarStateProvider(
      {super.key,
      this.child,
      required this.focusDate,
      required this.initialView,
      this.builder});

  @override
  Widget build(BuildContext context) {
    if (builder != null) {
      return ChangeNotifierProvider.value(
        value: CalendarState(initialView, focusDate: focusDate),
        builder: builder!,
      );
    }
    if (child != null) {
      return ChangeNotifierProvider.value(
        value: CalendarState(initialView, focusDate: focusDate),
        child: child,
      );
    }
    throw Exception("Must provide either child or builder");
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
          if (_controller.view == CalendarView.schedule) {
            // This prevents the schedule view from glitching out.
            return;
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notifyListeners();
          });
          return;
        }
        if (property == "calendarView") {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notifyListeners();
          });
          return;
        }
      });
    });
  }

  void focusDay(DateTime date) {
    _controller.view = CalendarView.day;
    var displayDate = _controller.displayDate?.stripTime();
    if (displayDate != date.stripTime()) {
      _controller.displayDate = date;
    }
    notifyListeners();
  }

  void setView(CalendarView view) {
    _controller.view = view;
    notifyListeners();
  }

  DateTime startOfView() {
    var displayDate = _controller.displayDate!;
    switch (_controller.view) {
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

  DateTime endOfView() {
    var start = controller.displayDate!;
    switch (_controller.view) {
      case CalendarView.day:
        return start.add(Duration(days: 1));
      case CalendarView.week:
        var date = start;
        while (getWeekday(date) != Weekday.saturday) {
          date = date.add(Duration(days: 1));
        }
        return start.add(Duration(days: 7));
      case CalendarView.month:
        var date = DateTime(start.year, start.month + 1, 1)
            .subtract(Duration(days: 1));
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

  CalendarController get controller => _controller;
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

  final bool allowDragAndDrop;
  final Function(DragDetails)? onAppointmentDragEnd;

  final Appointment? newAppointment;
  final Map<Appointment, Request> appointments;
  final List<BlackoutWindow> blackoutWindows;
  final Map<String, Request> requestIndex;

  final List<CalendarView>? allowedViews;

  StatefulCalendar({
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
    this.allowDragAndDrop = false,
    this.onAppointmentDragEnd,
    this.allowedViews = const [
      CalendarView.day,
      CalendarView.week,
      CalendarView.month,
      CalendarView.schedule,
    ],
  }) : requestIndex =
            appointments.map((key, value) => MapEntry(value.id!, value));

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
    Function(AppointmentDragEndDetails)? onDragEnd;
    if (onAppointmentDragEnd != null) {
      onDragEnd = (details) {
        if (details.appointment == null || details.droppingTime == null) {
          return;
        }
        var appointment = details.appointment as Appointment?;
        Request? request;
        for (var id in appointment?.resourceIds ?? []) {
          request = requestIndex[id];
          if (request != null) {
            break;
          }
        }
        if (request == null) {
          log("Appointment not found in state, cannot call onAppointmentDragEnd");
          return;
        }
        onAppointmentDragEnd!(
            DragDetails(request: request, dropTime: details.droppingTime!));
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
      allowAppointmentResize: allowAppointmentResize && newAppointment != null,
      allowViewNavigation: false,
      cellEndPadding: 20,
      allowedViews: allowedViews,
      onAppointmentResizeEnd: onResizeEnd,
      allowDragAndDrop: allowDragAndDrop && newAppointment != null,
      onDragEnd: onDragEnd,
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
