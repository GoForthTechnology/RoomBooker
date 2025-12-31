import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarUtils {
  /// Returns the date range (start inclusive, end exclusive) for a given [view] and [targetDate].
  static DateTimeRange getVisibleRange(DateTime targetDate, CalendarView view) {
    DateTime start;
    DateTime end;

    if (view == CalendarView.day) {
      start = DateTime(targetDate.year, targetDate.month, targetDate.day);
      end = start.add(const Duration(days: 1));
    } else if (view == CalendarView.week) {
      // Aligning to Sunday start to match previous PrintService logic
      // Note: DateTime.weekday returns 1 for Monday, 7 for Sunday.
      final currentWeekDay = targetDate.weekday;
      // If we want Sunday start:
      final daysToSubtract = currentWeekDay == DateTime.sunday
          ? 0
          : currentWeekDay;
      start = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      ).subtract(Duration(days: daysToSubtract));
      end = start.add(const Duration(days: 7));
    } else if (view == CalendarView.month) {
      start = DateTime(targetDate.year, targetDate.month, 1);
      // Next month's 1st day is the exclusive end
      end = DateTime(targetDate.year, targetDate.month + 1, 1);
    } else if (view == CalendarView.schedule) {
      start = DateTime(targetDate.year, targetDate.month, targetDate.day);
      // Rolling 30 days
      end = start.add(const Duration(days: 30));
    } else {
      // Default fallback
      start = DateTime(targetDate.year, targetDate.month, targetDate.day);
      end = start.add(const Duration(days: 1));
    }

    return DateTimeRange(start: start, end: end);
  }
}
