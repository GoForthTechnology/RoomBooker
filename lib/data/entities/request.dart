import 'dart:developer';

import 'package:json_annotation/json_annotation.dart';
import 'package:room_booker/ui/screens/review_bookings_screen.dart';

part 'request.g.dart';

enum RequestStatus {
  unknown,
  confirmed,
  denied,
  pending,
}

@JsonSerializable(explicitToJson: true)
class PrivateRequestDetails {
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? id;
  final String name;
  final String email;
  final String phone;
  final String message;
  final String eventName;

  PrivateRequestDetails({
    this.message = "",
    this.id,
    required this.eventName,
    required this.name,
    required this.email,
    required this.phone,
  });

  PrivateRequestDetails copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? message,
    String? eventName,
  }) {
    return PrivateRequestDetails(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      message: message ?? this.message,
      eventName: eventName ?? this.eventName,
    );
  }

  factory PrivateRequestDetails.fromJson(Map<String, dynamic> json) =>
      _$PrivateRequestDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$PrivateRequestDetailsToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Request {
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? id;
  final String? publicName;
  final DateTime eventStartTime;
  final DateTime eventEndTime;
  final String roomID;
  final String roomName;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final RequestStatus? status;
  final RecurrancePattern? recurrancePattern;
  final Map<DateTime, Request?>? recurranceOverrides;

  Request({
    this.recurrancePattern,
    required this.eventStartTime,
    required this.eventEndTime,
    required this.roomID,
    required this.roomName,
    this.publicName,
    this.status,
    this.id,
    this.recurranceOverrides,
  }) {
    if (!eventStartTime.isBefore(eventEndTime)) {
      log("Event start time is not before end time",
          name: id ?? "ID MISSING",
          error: "Start time: $eventStartTime, End time: $eventEndTime");
    }
  }

  bool isRepeating() {
    return recurrancePattern != null &&
        recurrancePattern!.frequency != Frequency.never;
  }

  bool hasEndDate() {
    return isRepeating() && recurrancePattern?.end != null;
  }

  Request copyWith({
    String? id,
    DateTime? eventStartTime,
    DateTime? eventEndTime,
    String? roomID,
    String? roomName,
    String? publicName,
    RequestStatus? status,
    RecurrancePattern? recurrancePattern,
    Map<DateTime, Request?>? recurranceOverrides,
  }) {
    return Request(
      eventStartTime: eventStartTime ?? this.eventStartTime,
      eventEndTime: eventEndTime ?? this.eventEndTime,
      roomID: roomID ?? this.roomID,
      roomName: roomName ?? this.roomName,
      publicName: publicName ?? this.publicName,
      status: status ?? this.status,
      id: id ?? this.id,
      recurrancePattern: recurrancePattern ?? this.recurrancePattern,
      recurranceOverrides: recurranceOverrides ?? this.recurranceOverrides,
    );
  }

  @override
  String toString() {
    return """Request{
      id: $id,
      eventStartTime: $eventStartTime,
      eventEndTime: $eventEndTime,
      roomID: $roomID,
      roomName: $roomName,
      status: $status,
      recurrencePattern: $recurrancePattern
    }""";
  }

  Duration eventDuration() {
    return eventEndTime.difference(eventStartTime);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Request &&
        other.id == id &&
        other.eventStartTime == eventStartTime &&
        other.eventEndTime == eventEndTime &&
        other.roomID == roomID &&
        other.roomName == roomName &&
        other.publicName == publicName &&
        other.recurrancePattern == recurrancePattern &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        eventStartTime.hashCode ^
        eventEndTime.hashCode ^
        roomID.hashCode ^
        roomName.hashCode ^
        recurrancePattern.hashCode ^
        publicName.hashCode ^
        status.hashCode;
  }

  List<Request> expand(DateTime windowStart, DateTime windowEnd,
      {bool includeRequestDate = true}) {
    var dates = _generateDates(windowStart, windowEnd);
    var eventDate =
        DateTime(eventStartTime.year, eventStartTime.month, eventStartTime.day);
    return dates
        .where((d) => includeRequestDate || d != eventDate)
        .map((date) {
          if (recurranceOverrides != null &&
              recurranceOverrides!.containsKey(date)) {
            var override = recurranceOverrides![date];
            if (override == null) {
              return null;
            }
            return override.copyWith(id: id);
          }
          return copyWith(
            eventStartTime: DateTime(date.year, date.month, date.day,
                eventStartTime.hour, eventStartTime.minute),
            eventEndTime: DateTime(date.year, date.month, date.day,
                eventEndTime.hour, eventEndTime.minute),
          );
        })
        .where((d) => d != null)
        .map((d) => d!)
        .toList();
  }

  List<DateTime> _generateDates(DateTime windowStart, DateTime windowEnd) {
    var pattern = recurrancePattern;
    if (pattern == null || pattern.frequency == Frequency.never) {
      if (!eventStartTime.isBefore(windowStart) &&
          !eventStartTime.isAfter(windowEnd)) {
        // The event is within the window
        // Using negation to avoid cases where windowStart == eventStartTime
        return [eventStartTime];
      }
      return [];
    }
    // Cap the end date if it is before the window end
    var effectiveEnd = windowEnd.isBefore(pattern.end ?? windowEnd)
        ? windowEnd
        : pattern.end ?? windowEnd;
    if (pattern.end != null) {
      effectiveEnd = min(effectiveEnd, pattern.end!);
    }
    // Ensure the start date is after the window start
    var effectiveStart =
        eventStartTime.isAfter(windowStart) ? eventStartTime : windowStart;
    effectiveStart = stripTime(effectiveStart);
    if (effectiveEnd.isBefore(effectiveStart)) {
      // The series has not started yet
      return [];
    }
    // add one day to make it inclusive
    effectiveEnd = stripTime(effectiveEnd.add(const Duration(days: 1)));
    switch (pattern.frequency) {
      case Frequency.never:
        return [];
      case Frequency.daily:
        return _generateDaily(effectiveStart, effectiveEnd);
      case Frequency.weekly:
        return _generateWeekly(effectiveStart, effectiveEnd);
      case Frequency.monthly:
        return _generateMonthly(effectiveStart, effectiveEnd);
      case Frequency.annually:
      case Frequency.custom:
        // TODO: real implementation
        return [];
    }
  }

  List<DateTime> _generateDaily(DateTime windowStart, DateTime windowEnd) {
    var pattern = recurrancePattern;
    if (pattern == null) {
      return [];
    }
    var dates = <DateTime>[];
    var current = windowStart;
    var periodInHours = pattern.period * 24;
    if (pattern.frequency == Frequency.weekly) {
      periodInHours = periodInHours * 7;
    }
    periodInHours -= 1; // Because daylignt savings time is evil!
    while (current.isBefore(windowEnd)) {
      if (dates.isEmpty ||
          current.difference(dates.last).inHours >= periodInHours) {
        dates.add(current);
      }
      current = advanceOneDay(current);
    }
    return dates;
  }

  List<DateTime> _generateWeekly(DateTime windowStart, DateTime windowEnd) {
    var pattern = recurrancePattern;
    if (pattern == null) {
      return [];
    }
    var effectiveStart = DateTime(eventStartTime.year, eventStartTime.month,
        eventStartTime.day - eventStartTime.weekday);
    var dates = <DateTime>[];
    var current = windowStart;
    while (current.isBefore(windowEnd)) {
      int weeksSinceStart = current.difference(effectiveStart).inDays ~/ 7;
      bool activeWeek = weeksSinceStart % pattern.period == 0;
      if (activeWeek &&
          (pattern.weekday?.contains(getWeekday(current)) ?? false)) {
        dates.add(current);
      }
      current = advanceOneDay(current);
    }
    return dates;
  }

  List<DateTime> _generateMonthly(DateTime windowStart, DateTime windowEnd) {
    var pattern = recurrancePattern;
    if (pattern == null) {
      return [];
    }
    var weekday = pattern.weekday?.first;
    if (weekday == null) {
      return [];
    }
    var offset = pattern.offset;
    if (offset == null) {
      return [];
    }
    int period = pattern.period > 0 ? pattern.period : 1;
    var dates = <DateTime>[];

    // Start from the first month that is >= windowStart
    var year = windowStart.year;
    var month = windowStart.month;

    // Find the first nth weekday of month >= windowStart
    while (true) {
      DateTime nthDate;
      try {
        nthDate = nthWeekdayOfMonth(DateTime(year, month, 1), weekday, offset);
      } catch (_) {
        // Month doesn't have this nth weekday, skip
        nthDate = DateTime(year, month, 1).add(const Duration(days: 32));
        nthDate = DateTime(nthDate.year, nthDate.month, 1);
      }
      if (nthDate.isAfter(windowEnd)) break;
      if (!nthDate.isBefore(windowStart) &&
          nthDate.isBefore(windowEnd) &&
          // Check for cases where it spills to the next month
          nthDate.month == month) {
        dates.add(nthDate);
      }
      // Advance by period months
      month += period;
      while (month > 12) {
        month -= 12;
        year += 1;
      }
    }
    return dates;
  }

  factory Request.fromJson(Map<String, dynamic> json) =>
      _$RequestFromJson(json);
  Map<String, dynamic> toJson() => _$RequestToJson(this);
}

DateTime advanceOneDay(DateTime date) {
  var newDate = date.add(const Duration(days: 1));
  // Strip off the time to avoid the extra hour from starting DST
  newDate = DateTime(newDate.year, newDate.month, newDate.day);
  if (newDate == date) {
    // Add an extra hour to avoid the extra hour from ending DST
    newDate = newDate.add(const Duration(hours: 1));
  }
  return newDate;
}

enum Frequency { never, daily, weekly, monthly, annually, custom }

enum Weekday { sunday, monday, tuesday, wednesday, thursday, friday, saturday }

extension WeekdayExt on Weekday {
  String get name {
    switch (this) {
      case Weekday.sunday:
        return "Sunday";
      case Weekday.monday:
        return "Monday";
      case Weekday.tuesday:
        return "Tuesday";
      case Weekday.wednesday:
        return "Wednesday";
      case Weekday.thursday:
        return "Thursday";
      case Weekday.friday:
        return "Friday";
      case Weekday.saturday:
        return "Saturday";
    }
  }
}

@JsonSerializable(explicitToJson: true)
class RecurrancePattern {
  final Frequency frequency;
  final int period;
  final int? offset;
  final Set<Weekday>? weekday;
  final DateTime? end;

  RecurrancePattern({
    required this.frequency,
    required this.period,
    this.offset,
    this.weekday,
    this.end,
  }) {
    if (frequency == Frequency.monthly && (offset == null || offset! < 1)) {
      throw ArgumentError(
          "Offset must be greater than 0 for monthly frequency");
    }
    if (frequency == Frequency.monthly && weekday == null) {
      throw ArgumentError("Weekday must be set for monthly frequency");
    }
  }

  RecurrancePattern copyWith({
    Frequency? frequency,
    Set<Weekday>? weekday,
    int? period,
    int? offset,
    DateTime? end,
  }) {
    return RecurrancePattern(
      frequency: frequency ?? this.frequency,
      weekday: weekday ?? this.weekday,
      period: period ?? this.period,
      offset: offset ?? this.offset,
      end: end ?? this.end,
    );
  }

  @override
  String toString() {
    switch (frequency) {
      case Frequency.never:
        return "Never";
      case Frequency.daily:
        return "Daily";
      case Frequency.weekly:
        return "Weekly on ${weekday?.map((w) => w.name)}";
      case Frequency.monthly:
        return "Monthly on $offset${numberSuffix(offset!)} ${weekday?.map((e) => e.name)}";
      case Frequency.annually:
        return "Annually";
      case Frequency.custom:
        return "Custom";
    }
  }

  factory RecurrancePattern.fromJson(Map<String, dynamic> json) =>
      _$RecurrancePatternFromJson(json);
  Map<String, dynamic> toJson() => _$RecurrancePatternToJson(this);

  static RecurrancePattern never() {
    return RecurrancePattern(frequency: Frequency.never, period: 0);
  }

  static RecurrancePattern every(int n, Frequency frequency,
      {required Weekday on}) {
    return RecurrancePattern(
        frequency: frequency, weekday: {on}, period: n, offset: 1);
  }

  static RecurrancePattern daily() {
    return RecurrancePattern(frequency: Frequency.daily, period: 1);
  }

  static RecurrancePattern weekly({required Weekday on, int? period}) {
    return RecurrancePattern(
        frequency: Frequency.weekly, weekday: {on}, period: period ?? 1);
  }

  static RecurrancePattern monthlyOnNth(int nth, Weekday on) {
    return RecurrancePattern(
      frequency: Frequency.monthly,
      period: 1,
      weekday: {on},
      offset: nth,
    );
  }

  static RecurrancePattern annually() {
    return RecurrancePattern(frequency: Frequency.annually, period: 1);
  }
}

DateTime nthWeekdayOfMonth(DateTime date, Weekday weekday, int nth) {
  var firstDayOfMonth = DateTime(date.year, date.month, 1);
  var weekdayCount = 0;
  var currentDay = firstDayOfMonth;
  for (var i = 0; i < 31; i++) {
    if (currentDay.month != date.month) break;
    if (getWeekday(currentDay) == weekday) {
      weekdayCount++;
      if (weekdayCount == nth) {
        return currentDay;
      }
    }
    currentDay = advanceOneDay(currentDay);
  }
  throw Exception("The month does not have $nth $weekday");
}

DateTime min(DateTime a, DateTime b) {
  return a.isBefore(b) ? a : b;
}

Weekday getWeekday(DateTime date) {
  switch (date.weekday) {
    case DateTime.sunday:
      return Weekday.sunday;
    case DateTime.monday:
      return Weekday.monday;
    case DateTime.tuesday:
      return Weekday.tuesday;
    case DateTime.wednesday:
      return Weekday.wednesday;
    case DateTime.thursday:
      return Weekday.thursday;
    case DateTime.friday:
      return Weekday.friday;
    case DateTime.saturday:
      return Weekday.saturday;
  }
  throw Exception("Invalid weekday");
}

String numberSuffix(int i) {
  switch (i) {
    case 1:
    case 21:
    case 31:
      return "st";
    case 2:
    case 22:
      return "nd";
    case 3:
    case 23:
      return "rd";
    default:
      return "th";
  }
}
