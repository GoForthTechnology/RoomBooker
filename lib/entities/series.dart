import 'package:json_annotation/json_annotation.dart';
import 'package:room_booker/entities/request.dart';

part 'series.g.dart';

class Series {
  final Request request;
  final DateTime? end;
  final RecurrancePattern pattern;

  Series({required this.request, this.end, required this.pattern});

  List<Request> expand(DateTime windowStart, DateTime windowEnd,
      {bool includeRequestDate = true}) {
    var dates = _generateDates(windowStart, windowEnd);
    return dates
        .where((d) => includeRequestDate || d != request.eventStartTime)
        .map((date) {
      return request.copyWith(
        eventStartTime: DateTime(date.year, date.month, date.day,
            request.eventStartTime.hour, request.eventStartTime.minute),
        eventEndTime: DateTime(date.year, date.month, date.day,
            request.eventEndTime.hour, request.eventEndTime.minute),
      );
    }).toList();
  }

  List<DateTime> _generateDates(DateTime windowStart, DateTime windowEnd) {
    // Cap the end date if it is before the window end
    var effectiveEnd =
        windowEnd.isBefore(end ?? windowEnd) ? windowEnd : end ?? windowEnd;
    if (pattern.end != null) {
      effectiveEnd = min(effectiveEnd, pattern.end!);
    }
    // Ensure the start date is after the window start
    var effectiveStart = request.eventStartTime.isAfter(windowStart)
        ? request.eventStartTime
        : windowStart;
    if (effectiveEnd.isBefore(effectiveStart)) {
      // The series has not started yet
      return [];
    }
    // add one day to make it inclusive
    effectiveEnd = effectiveEnd.add(const Duration(days: 1));
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
    var dates = <DateTime>[];
    var current = windowStart;
    var periodInDays = pattern.period;
    if (pattern.frequency == Frequency.weekly) {
      periodInDays = periodInDays * 7;
    }
    while (current.isBefore(windowEnd)) {
      if (dates.isEmpty ||
          current.difference(dates.last).inDays >= periodInDays) {
        dates.add(current);
      }
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  List<DateTime> _generateWeekly(DateTime windowStart, DateTime windowEnd) {
    var effectiveStart = DateTime(
        request.eventStartTime.year,
        request.eventStartTime.month,
        request.eventStartTime.day - request.eventStartTime.weekday);
    var dates = <DateTime>[];
    var current = windowStart;
    while (current.isBefore(windowEnd)) {
      int weeksSinceStart = current.difference(effectiveStart).inDays ~/ 7;
      bool activeWeek = weeksSinceStart % pattern.period == 0;
      if (activeWeek &&
          (pattern.weekday?.contains(getWeekday(current)) ?? false)) {
        dates.add(current);
      }
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  List<DateTime> _generateMonthly(DateTime windowStart, DateTime windowEnd) {
    var weekday = pattern.weekday?.first;
    if (weekday == null) {
      return [];
    }
    var offset = pattern.offset;
    if (offset == null) {
      return [];
    }
    var dates = <DateTime>[];
    var currentDate = windowStart;
    var currentMonth = windowStart.month - 1;
    DateTime? nthWeekday;
    while (currentDate.isBefore(windowEnd)) {
      if (currentDate.month != currentMonth) {
        currentMonth = currentDate.month;
        nthWeekday = nthWeekdayOfMonth(currentDate, weekday, offset);
      }
      if (nthWeekday == currentDate) {
        dates.add(currentDate);
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
    return dates;
  }
}

DateTime nthWeekdayOfMonth(DateTime date, Weekday weekday, int nth) {
  var firstDayOfMonth = DateTime(date.year, date.month, 1);
  var weekdayCount = 0;
  for (var i = 0; i < 31; i++) {
    var currentDay = firstDayOfMonth.add(Duration(days: i));
    if (currentDay.month != date.month) break;
    if (getWeekday(currentDay) == weekday) {
      weekdayCount++;
      if (weekdayCount == nth) {
        return currentDay;
      }
    }
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

enum Frequency { never, daily, weekly, monthly, annually, custom }

enum Weekday { sunday, monday, tuesday, wednesday, thursday, friday, saturday }

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
  });

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

  factory RecurrancePattern.fromJson(Map<String, dynamic> json) =>
      _$RecurrancePatternFromJson(json);
  Map<String, dynamic> toJson() => _$RecurrancePatternToJson(this);

  static RecurrancePattern never() {
    return RecurrancePattern(frequency: Frequency.never, period: 0);
  }

  static RecurrancePattern every(int n, Frequency frequency,
      {required Weekday on}) {
    return RecurrancePattern(frequency: frequency, weekday: {on}, period: n);
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
