import 'package:room_booker/entities/request.dart';

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
        throw UnimplementedError();
    }
  }

  List<DateTime> _generateDaily(DateTime windowStart, DateTime windowEnd) {
    var dates = <DateTime>[];
    var current = windowStart;
    while (current.isBefore(windowEnd)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  List<DateTime> _generateWeekly(DateTime windowStart, DateTime windowEnd) {
    var dates = <DateTime>[];
    var current = windowStart;
    while (!(pattern.weekday?.contains(getWeekday(current)) ?? false)) {
      current = current.add(const Duration(days: 1));
    }
    while (current.isBefore(windowEnd)) {
      dates.add(current);
      current = current.add(const Duration(days: 7));
    }
    return dates;
  }

  List<DateTime> _generateMonthly(DateTime windowStart, DateTime windowEnd) {
    var dates = <DateTime>[];
    var currentDate = windowStart;
    var currentMonth = windowStart.month - 1;
    DateTime? nthWeekday;
    while (currentDate.isBefore(windowEnd)) {
      if (currentDate.month != currentMonth) {
        currentMonth = currentDate.month;
        nthWeekday = nthWeekdayOfMonth(
            currentDate, pattern.weekday!.first, pattern.offset!);
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

enum Frequency { never, daily, weekly, monthly, annually }

enum Weekday { sunday, monday, tuesday, wednesday, thursday, friday, saturday }

class RecurrancePattern {
  final Frequency frequency;
  final int period;
  final int? offset;
  final Set<Weekday>? weekday;

  RecurrancePattern({
    required this.frequency,
    required this.period,
    this.offset,
    this.weekday,
  });

  RecurrancePattern copyWith({
    Frequency? frequency,
    Set<Weekday>? weekday,
    int? period,
    int? offset,
  }) {
    return RecurrancePattern(
      frequency: frequency ?? this.frequency,
      weekday: weekday ?? this.weekday,
      period: period ?? this.period,
      offset: offset ?? this.offset,
    );
  }

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
