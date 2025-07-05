import 'package:flutter_test/flutter_test.dart';
import 'package:room_booker/data/entities/request.dart';

void main() {
  group('Request Expansion', () {
    var now = DateTime(2025, 1, 1, 0, 0, 0);
    Request baseRequest = Request(
      id: '123',
      roomID: 'room1',
      eventStartTime: now,
      eventEndTime: now.add(Duration(hours: 1)),
      status: RequestStatus.pending,
      roomName: 'Conference Room A',
    );
    test("No expansion", () {
      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern.never(),
      );
      var occurrences = request.expand(now, now.add(Duration(days: 30)));
      expect(occurrences.length, 1);
      expect(occurrences.first.eventStartTime, now);
    });
    test('Monthly expansion with offset', () {
      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.monthly,
          period: 1,
          offset: 2,
          weekday: {Weekday.thursday},
        ),
      );
      var expectedStartTimes = [
        DateTime(2025, 1, 9, 0, 0, 0),
        DateTime(2025, 2, 13, 0, 0, 0),
        DateTime(2025, 3, 13, 0, 0, 0),
        DateTime(2025, 4, 10, 0, 0, 0),
        DateTime(2025, 5, 08, 0, 0, 0),
        DateTime(2025, 6, 12, 0, 0, 0),
        DateTime(2025, 7, 10, 0, 0, 0),
        DateTime(2025, 8, 14, 0, 0, 0),
        DateTime(2025, 9, 11, 0, 0, 0),
        DateTime(2025, 10, 9, 0, 0, 0),
        DateTime(2025, 11, 13, 0, 0, 0),
        DateTime(2025, 12, 11, 0, 0, 0),
      ];
      var occurrences = request.expand(now, now.add(Duration(days: 365)));
      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });
    test("Monthly with period", () {
      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.monthly,
          period: 2,
          offset: 1,
          weekday: {Weekday.thursday},
        ),
      );
      var expectedStartTimes = [
        DateTime(2025, 1, 2, 0, 0, 0),
        DateTime(2025, 3, 6, 0, 0, 0),
        DateTime(2025, 5, 1, 0, 0, 0),
        DateTime(2025, 7, 3, 0, 0, 0),
        DateTime(2025, 9, 4, 0, 0, 0),
        DateTime(2025, 11, 6, 0, 0, 0),
      ];
      var occurrences = request.expand(now, now.add(Duration(days: 364)));
      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });
    test("Weekly expansion", () {
      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.weekly,
          period: 1,
          weekday: {Weekday.monday},
        ),
      );
      var expectedStartTimes = [
        DateTime(2025, 1, 6, 0, 0, 0),
        DateTime(2025, 1, 13, 0, 0, 0),
        DateTime(2025, 1, 20, 0, 0, 0),
        DateTime(2025, 1, 27, 0, 0, 0),
      ];
      var occurrences = request.expand(now, now.add(Duration(days: 30)));
      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });
    test("Weekly expansion with override", () {
      var request = baseRequest.copyWith(
          recurrancePattern: RecurrancePattern(
            frequency: Frequency.weekly,
            period: 1,
            weekday: {Weekday.monday},
          ),
          recurranceOverrides: {
            DateTime(2025, 1, 20): null,
            DateTime(2025, 1, 27): baseRequest.copyWith(
              eventStartTime: DateTime(2025, 1, 27, 10, 0, 0),
              eventEndTime: DateTime(2025, 1, 27, 11, 0, 0),
            ),
          });
      var expectedStartTimes = [
        DateTime(2025, 1, 6, 0, 0, 0),
        DateTime(2025, 1, 13, 0, 0, 0),
        DateTime(2025, 1, 27, 10, 0, 0),
      ];
      var occurrences = request.expand(now, now.add(Duration(days: 30)));
      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });
    test("Daily expansion", () {
      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.daily,
          period: 1,
        ),
      );
      var expectedStartTimes = [
        DateTime(2025, 1, 1, 0, 0, 0),
        DateTime(2025, 1, 2, 0, 0, 0),
        DateTime(2025, 1, 3, 0, 0, 0),
        DateTime(2025, 1, 4, 0, 0, 0),
        DateTime(2025, 1, 5, 0, 0, 0),
      ];
      var occurrences = request.expand(now, now.add(Duration(days: 4)));
      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });
    test("Daily expansion with period", () {
      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.daily,
          period: 2,
        ),
      );
      var expectedStartTimes = [
        DateTime(2025, 1, 1, 0, 0, 0),
        DateTime(2025, 1, 3, 0, 0, 0),
        DateTime(2025, 1, 5, 0, 0, 0),
        DateTime(2025, 1, 7, 0, 0, 0),
      ];
      var occurrences = request.expand(now, now.add(Duration(days: 6)));
      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });
  });

  group('Expansion Window Edge Cases', () {
    var now = DateTime(2025, 1, 1, 10, 0, 0); // Wednesday at 10:00 AM
    Request baseRequest = Request(
      id: '123',
      roomID: 'room1',
      eventStartTime: now,
      eventEndTime: now.add(Duration(hours: 1)),
      status: RequestStatus.pending,
      roomName: 'Conference Room A',
    );

    test('Window that does not include original event date', () {
      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.weekly,
          period: 1,
          weekday: {Weekday.wednesday},
        ),
      );

      // Window starts after the original event
      var windowStart = DateTime(2025, 1, 2, 0, 0, 0);
      var windowEnd = DateTime(2025, 1, 30, 0, 0, 0);

      var occurrences =
          request.expand(windowStart, windowEnd, includeRequestDate: false);

      // Should not include the original event date (Jan 1)
      var expectedStartTimes = [
        DateTime(2025, 1, 8, 10, 0, 0), // Next Wednesday
        DateTime(2025, 1, 15, 10, 0, 0),
        DateTime(2025, 1, 22, 10, 0, 0),
        DateTime(2025, 1, 29, 10, 0, 0),
      ];

      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });

    test('Window that starts after pattern ends', () {
      var endDate = DateTime(2025, 1, 10);
      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.daily,
          period: 1,
          end: endDate,
        ),
      );

      // Window starts after pattern ends
      var windowStart = DateTime(2025, 1, 15, 0, 0, 0);
      var windowEnd = DateTime(2025, 1, 30, 0, 0, 0);

      var occurrences = request.expand(windowStart, windowEnd);

      expect(occurrences.length, 0);
    });

    test('Window that ends before pattern starts', () {
      var futureStart = DateTime(2025, 2, 1, 10, 0, 0);
      var request = baseRequest.copyWith(
        eventStartTime: futureStart,
        eventEndTime: futureStart.add(Duration(hours: 1)),
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.daily,
          period: 1,
        ),
      );

      // Window ends before pattern starts
      var windowStart = DateTime(2025, 1, 1, 0, 0, 0);
      var windowEnd = DateTime(2025, 1, 15, 0, 0, 0);

      var occurrences = request.expand(windowStart, windowEnd);

      expect(occurrences.length, 0);
    });

    test('Very small window - single day', () {
      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.daily,
          period: 1,
        ),
      );

      // Single day window that includes the event
      var windowStart = DateTime(2025, 1, 1, 0, 0, 0);
      var windowEnd = DateTime(2025, 1, 1, 23, 59, 59);

      var occurrences = request.expand(windowStart, windowEnd);

      expect(occurrences.length, 1);
      expect(occurrences.first.eventStartTime, DateTime(2025, 1, 1, 10, 0, 0));
    });

    test('Window starts exactly at event time', () {
      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.daily,
          period: 2,
        ),
      );

      // Window starts exactly at event time
      var windowStart = DateTime(2025, 1, 1, 10, 0, 0);
      var windowEnd = DateTime(2025, 1, 10, 0, 0, 0);

      var occurrences = request.expand(windowStart, windowEnd);

      var expectedStartTimes = [
        DateTime(2025, 1, 1, 10, 0, 0),
        DateTime(2025, 1, 3, 10, 0, 0),
        DateTime(2025, 1, 5, 10, 0, 0),
        DateTime(2025, 1, 7, 10, 0, 0),
        DateTime(2025, 1, 9, 10, 0, 0),
      ];

      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });

    test('Window ends exactly at event time', () {
      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.daily,
          period: 2,
        ),
      );

      // Window ends exactly at next event time
      var windowStart = DateTime(2025, 1, 1, 0, 0, 0);
      var windowEnd = DateTime(2025, 1, 3, 10, 0, 0);

      var occurrences = request.expand(windowStart, windowEnd);

      // Should include the event that ends exactly at window end
      var expectedStartTimes = [
        DateTime(2025, 1, 1, 10, 0, 0),
        DateTime(2025, 1, 3, 10, 0, 0),
      ];

      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });

    test('includeRequestDate parameter - true (default)', () {
      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.daily,
          period: 1,
          weekday: {Weekday.wednesday},
        ),
      );

      var windowStart = DateTime(2025, 1, 1, 0, 0, 0);
      var windowEnd = DateTime(2025, 1, 5, 0, 0, 0);

      var occurrences =
          request.expand(windowStart, windowEnd, includeRequestDate: true);

      // Should include original event date
      var expectedStartTimes = [
        DateTime(2025, 1, 1, 10, 0, 0), // Original event
        DateTime(2025, 1, 2, 10, 0, 0),
        DateTime(2025, 1, 3, 10, 0, 0),
        DateTime(2025, 1, 4, 10, 0, 0),
        DateTime(2025, 1, 5, 10, 0, 0),
      ];

      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });

    test('includeRequestDate parameter - false', () {
      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.weekly,
          period: 1,
          weekday: {Weekday.wednesday},
        ),
      );

      var windowStart = DateTime(2025, 1, 1, 0, 0, 0);
      var windowEnd = DateTime(2025, 1, 15, 0, 0, 0);

      var occurrences =
          request.expand(windowStart, windowEnd, includeRequestDate: false);

      // Should NOT include original event date
      var expectedStartTimes = [
        DateTime(2025, 1, 8, 10, 0, 0), // First recurrence
        DateTime(2025, 1, 15, 10, 0, 0), // Second recurrence
      ];

      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });

    test('Window spans across pattern end date', () {
      var endDate = DateTime(2025, 1, 5);
      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.daily,
          period: 1,
          end: endDate,
        ),
      );

      // Window spans across the pattern end date
      var windowStart = DateTime(2025, 1, 1, 0, 0, 0);
      var windowEnd = DateTime(2025, 1, 10, 0, 0, 0);

      var occurrences = request.expand(windowStart, windowEnd);

      // Should only include events up to the end date
      var expectedStartTimes = [
        DateTime(2025, 1, 1, 10, 0, 0),
        DateTime(2025, 1, 2, 10, 0, 0),
        DateTime(2025, 1, 3, 10, 0, 0),
        DateTime(2025, 1, 4, 10, 0, 0),
        DateTime(2025, 1, 5, 10, 0, 0),
      ];

      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });

    test('Pattern end date is before window start', () {
      var endDate = DateTime(2025, 1, 3);
      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.daily,
          period: 1,
          end: endDate,
        ),
      );

      // Window starts after pattern ends
      var windowStart = DateTime(2025, 1, 5, 0, 0, 0);
      var windowEnd = DateTime(2025, 1, 10, 0, 0, 0);

      var occurrences = request.expand(windowStart, windowEnd);

      expect(occurrences.length, 0);
    });

    test('Non-recurring event with window that excludes it', () {
      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern.never(),
      );

      // Window that doesn't include the event
      var windowStart = DateTime(2025, 1, 2, 0, 0, 0);
      var windowEnd = DateTime(2025, 1, 10, 0, 0, 0);

      var occurrences = request.expand(windowStart, windowEnd);

      expect(occurrences.length, 0);
    });

    test('Non-recurring event with window that includes it', () {
      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern.never(),
      );

      // Window that includes the event
      var windowStart = DateTime(2025, 1, 1, 0, 0, 0);
      var windowEnd = DateTime(2025, 1, 10, 0, 0, 0);

      var occurrences = request.expand(windowStart, windowEnd);

      expect(occurrences.length, 1);
      expect(occurrences.first.eventStartTime, DateTime(2025, 1, 1, 10, 0, 0));
    });
  });

  group('RecurrancePattern Factory Methods', () {
    test('RecurrancePattern.never()', () {
      var pattern = RecurrancePattern.never();

      expect(pattern.frequency, Frequency.never);
      expect(pattern.period, 0);
      expect(pattern.weekday, isNull);
      expect(pattern.offset, isNull);
      expect(pattern.end, isNull);
    });

    test('RecurrancePattern.daily()', () {
      var pattern = RecurrancePattern.daily();

      expect(pattern.frequency, Frequency.daily);
      expect(pattern.period, 1);
      expect(pattern.weekday, isNull);
      expect(pattern.offset, isNull);
      expect(pattern.end, isNull);
    });

    test('RecurrancePattern.weekly() with default period', () {
      var pattern = RecurrancePattern.weekly(on: Weekday.monday);

      expect(pattern.frequency, Frequency.weekly);
      expect(pattern.period, 1);
      expect(pattern.weekday, {Weekday.monday});
      expect(pattern.offset, isNull);
      expect(pattern.end, isNull);
    });

    test('RecurrancePattern.weekly() with custom period', () {
      var pattern = RecurrancePattern.weekly(on: Weekday.friday, period: 3);

      expect(pattern.frequency, Frequency.weekly);
      expect(pattern.period, 3);
      expect(pattern.weekday, {Weekday.friday});
      expect(pattern.offset, isNull);
      expect(pattern.end, isNull);
    });

    test('RecurrancePattern.monthlyOnNth()', () {
      var pattern = RecurrancePattern.monthlyOnNth(2, Weekday.tuesday);

      expect(pattern.frequency, Frequency.monthly);
      expect(pattern.period, 1);
      expect(pattern.weekday, {Weekday.tuesday});
      expect(pattern.offset, 2);
      expect(pattern.end, isNull);
    });

    test('RecurrancePattern.annually()', () {
      var pattern = RecurrancePattern.annually();

      expect(pattern.frequency, Frequency.annually);
      expect(pattern.period, 1);
      expect(pattern.weekday, isNull);
      expect(pattern.offset, isNull);
      expect(pattern.end, isNull);
    });

    test('RecurrancePattern.every() - daily', () {
      var pattern =
          RecurrancePattern.every(3, Frequency.daily, on: Weekday.sunday);

      expect(pattern.frequency, Frequency.daily);
      expect(pattern.period, 3);
      expect(pattern.weekday, {Weekday.sunday});
      expect(pattern.offset, 1);
      expect(pattern.end, isNull);
    });

    test('RecurrancePattern.every() - weekly', () {
      var pattern =
          RecurrancePattern.every(2, Frequency.weekly, on: Weekday.wednesday);

      expect(pattern.frequency, Frequency.weekly);
      expect(pattern.period, 2);
      expect(pattern.weekday, {Weekday.wednesday});
      expect(pattern.offset, 1);
      expect(pattern.end, isNull);
    });

    test('RecurrancePattern.every() - monthly', () {
      var pattern =
          RecurrancePattern.every(4, Frequency.monthly, on: Weekday.saturday);

      expect(pattern.frequency, Frequency.monthly);
      expect(pattern.period, 4);
      expect(pattern.weekday, {Weekday.saturday});
      expect(pattern.offset, 1);
      expect(pattern.end, isNull);
    });

    test('RecurrancePattern copyWith() - change frequency', () {
      var original = RecurrancePattern.weekly(on: Weekday.monday);
      var modified = original.copyWith(frequency: Frequency.daily);

      expect(modified.frequency, Frequency.daily);
      expect(modified.period, 1); // unchanged
      expect(modified.weekday, {Weekday.monday}); // unchanged
      expect(modified.offset, isNull); // unchanged
      expect(modified.end, isNull); // unchanged
    });

    test('RecurrancePattern copyWith() - change multiple properties', () {
      var original = RecurrancePattern.weekly(on: Weekday.tuesday, period: 2);
      var endDate = DateTime(2025, 12, 31);
      var modified = original.copyWith(
        period: 3,
        weekday: {Weekday.friday, Weekday.saturday},
        end: endDate,
      );

      expect(modified.frequency, Frequency.weekly); // unchanged
      expect(modified.period, 3);
      expect(modified.weekday, {Weekday.friday, Weekday.saturday});
      expect(modified.offset, isNull); // unchanged
      expect(modified.end, endDate);
    });

    test('RecurrancePattern copyWith() - no changes', () {
      var original = RecurrancePattern.monthlyOnNth(3, Weekday.thursday);
      var modified = original.copyWith();

      expect(modified.frequency, original.frequency);
      expect(modified.period, original.period);
      expect(modified.weekday, original.weekday);
      expect(modified.offset, original.offset);
      expect(modified.end, original.end);
    });

    test('RecurrancePattern toString() - never', () {
      var pattern = RecurrancePattern.never();
      expect(pattern.toString(), "Never");
    });

    test('RecurrancePattern toString() - daily', () {
      var pattern = RecurrancePattern.daily();
      expect(pattern.toString(), "Daily");
    });

    test('RecurrancePattern toString() - weekly', () {
      var pattern = RecurrancePattern.weekly(on: Weekday.monday);
      expect(pattern.toString(), "Weekly on (Monday)");
    });

    test('RecurrancePattern toString() - weekly with multiple days', () {
      var pattern = RecurrancePattern(
        frequency: Frequency.weekly,
        period: 1,
        weekday: {Weekday.monday, Weekday.wednesday, Weekday.friday},
      );
      var result = pattern.toString();
      expect(result, startsWith("Weekly on "));
      expect(result, contains("Monday"));
      expect(result, contains("Wednesday"));
      expect(result, contains("Friday"));
    });

    test('RecurrancePattern toString() - monthly', () {
      var pattern = RecurrancePattern.monthlyOnNth(2, Weekday.friday);
      expect(pattern.toString(), "Monthly on 2nd (Friday)");
    });

    test('RecurrancePattern toString() - monthly with 1st', () {
      var pattern = RecurrancePattern.monthlyOnNth(1, Weekday.sunday);
      expect(pattern.toString(), "Monthly on 1st (Sunday)");
    });

    test('RecurrancePattern toString() - monthly with 3rd', () {
      var pattern = RecurrancePattern.monthlyOnNth(3, Weekday.tuesday);
      expect(pattern.toString(), "Monthly on 3rd (Tuesday)");
    });

    test('RecurrancePattern toString() - annually', () {
      var pattern = RecurrancePattern.annually();
      expect(pattern.toString(), "Annually");
    });

    test('RecurrancePattern toString() - custom', () {
      var pattern = RecurrancePattern(
        frequency: Frequency.custom,
        period: 1,
      );
      expect(pattern.toString(), "Custom");
    });

    test('Factory methods create patterns that work with Request.expand()', () {
      var now = DateTime(2025, 1, 6, 10, 0, 0); // Monday
      var baseRequest = Request(
        id: 'test',
        roomID: 'room1',
        eventStartTime: now,
        eventEndTime: now.add(Duration(hours: 1)),
        status: RequestStatus.pending,
        roomName: 'Test Room',
      );

      // Test daily pattern
      var dailyRequest = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern.daily(),
      );
      var dailyOccurrences =
          dailyRequest.expand(now, now.add(Duration(days: 3)));
      expect(dailyOccurrences.length, 4); // 4 days including start

      // Test weekly pattern
      var weeklyRequest = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern.weekly(on: Weekday.monday),
      );
      var weeklyOccurrences =
          weeklyRequest.expand(now, now.add(Duration(days: 14)));
      expect(weeklyOccurrences.length, 3); // 3 Mondays

      // Test monthly pattern
      var monthlyRequest = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern.monthlyOnNth(1, Weekday.monday),
      );
      var monthlyOccurrences =
          monthlyRequest.expand(now, now.add(Duration(days: 90)));
      expect(monthlyOccurrences.length, 3); // 3 first Mondays

      // Test never pattern
      var neverRequest = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern.never(),
      );
      var neverOccurrences =
          neverRequest.expand(now, now.add(Duration(days: 30)));
      expect(neverOccurrences.length, 1); // Only original event
    });
  });

  group('Weekly Expansion Edge Cases', () {
    test('Weekly with period > 1 (every 2 weeks)', () {
      var now = DateTime(2025, 1, 6, 10, 0, 0); // Monday
      var baseRequest = Request(
        id: 'test',
        roomID: 'room1',
        eventStartTime: now,
        eventEndTime: now.add(Duration(hours: 1)),
        status: RequestStatus.pending,
        roomName: 'Test Room',
      );

      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.weekly,
          period: 2,
          weekday: {Weekday.monday},
        ),
      );

      var occurrences = request.expand(now, now.add(Duration(days: 42)));
      var expectedStartTimes = [
        DateTime(2025, 1, 6, 10, 0, 0), // Week 0 - Original
        DateTime(2025, 1, 20, 10, 0, 0), // Week 2
        DateTime(2025, 2, 3, 10, 0, 0), // Week 4
        DateTime(2025, 2, 17, 10, 0, 0), // Week 6
      ];

      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });

    test('Weekly with period = 3 (every 3 weeks)', () {
      var now = DateTime(2025, 1, 1, 14, 30, 0); // Wednesday
      var baseRequest = Request(
        id: 'test',
        roomID: 'room1',
        eventStartTime: now,
        eventEndTime: now.add(Duration(hours: 2)),
        status: RequestStatus.pending,
        roomName: 'Test Room',
      );

      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.weekly,
          period: 3,
          weekday: {Weekday.wednesday},
        ),
      );

      var occurrences = request.expand(now, now.add(Duration(days: 70)));
      var expectedStartTimes = [
        DateTime(2025, 1, 1, 14, 30, 0), // Week 0
        DateTime(2025, 1, 22, 14, 30, 0), // Week 3
        DateTime(2025, 2, 12, 14, 30, 0), // Week 6
        DateTime(2025, 3, 5, 14, 30, 0), // Week 9
      ];

      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });

    test('Multiple weekdays in weekly pattern', () {
      var now = DateTime(2025, 1, 6, 9, 0, 0); // Monday
      var baseRequest = Request(
        id: 'test',
        roomID: 'room1',
        eventStartTime: now,
        eventEndTime: now.add(Duration(hours: 1)),
        status: RequestStatus.pending,
        roomName: 'Test Room',
      );

      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.weekly,
          period: 1,
          weekday: {Weekday.monday, Weekday.wednesday, Weekday.friday},
        ),
      );

      var occurrences = request.expand(now, now.add(Duration(days: 14)));
      var expectedStartTimes = [
        DateTime(2025, 1, 6, 9, 0, 0), // Monday
        DateTime(2025, 1, 8, 9, 0, 0), // Wednesday
        DateTime(2025, 1, 10, 9, 0, 0), // Friday
        DateTime(2025, 1, 13, 9, 0, 0), // Monday (next week)
        DateTime(2025, 1, 15, 9, 0, 0), // Wednesday (next week)
        DateTime(2025, 1, 17, 9, 0, 0), // Friday (next week)
        DateTime(2025, 1, 20, 9, 0, 0), // Friday (next week)
      ];

      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });

    test('Weekly pattern starting on different day than event', () {
      var now = DateTime(2025, 1, 7, 11, 0, 0); // Tuesday
      var baseRequest = Request(
        id: 'test',
        roomID: 'room1',
        eventStartTime: now,
        eventEndTime: now.add(Duration(hours: 1)),
        status: RequestStatus.pending,
        roomName: 'Test Room',
      );

      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.weekly,
          period: 1,
          weekday: {Weekday.friday}, // Event on Tuesday, but repeats on Friday
        ),
      );

      var occurrences = request.expand(now, now.add(Duration(days: 21)));
      var expectedStartTimes = [
        DateTime(2025, 1, 10, 11, 0, 0), // First Friday
        DateTime(2025, 1, 17, 11, 0, 0), // Second Friday
        DateTime(2025, 1, 24, 11, 0, 0), // Third Friday
      ];

      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });
  });

  group('Monthly Expansion Edge Cases', () {
    test('Monthly pattern where nth weekday does not exist in some months', () {
      var now =
          DateTime(2025, 1, 30, 10, 0, 0); // Thursday (5th Thursday of January)
      var baseRequest = Request(
        id: 'test',
        roomID: 'room1',
        eventStartTime: now,
        eventEndTime: now.add(Duration(hours: 1)),
        status: RequestStatus.pending,
        roomName: 'Test Room',
      );

      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.monthly,
          period: 1,
          offset: 5, // 5th Thursday - not all months have this
          weekday: {Weekday.thursday},
        ),
      );

      var occurrences = request.expand(now, now.add(Duration(days: 150)));
      var expectedStartTimes = [
        DateTime(2025, 1, 30, 10, 0, 0), // January has 5th Thursday
        DateTime(2025, 5, 29, 10, 0, 0), // May has 5th Thursday
        // February, March, April, June don't have 5th Thursday
      ];

      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });

    test('Monthly with period = 2 (every 2 months)', () {
      var now = DateTime(2025, 1, 6, 14, 0, 0); // First Monday of January
      var baseRequest = Request(
        id: 'test',
        roomID: 'room1',
        eventStartTime: now,
        eventEndTime: now.add(Duration(hours: 1)),
        status: RequestStatus.pending,
        roomName: 'Test Room',
      );

      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.monthly,
          period: 2,
          offset: 1, // First Monday
          weekday: {Weekday.monday},
        ),
      );

      var occurrences = request.expand(now, now.add(Duration(days: 180)));
      var expectedStartTimes = [
        DateTime(2025, 1, 6, 14, 0, 0), // January (1st Monday)
        DateTime(2025, 3, 3, 14, 0, 0), // March (1st Monday)
        DateTime(2025, 5, 5, 14, 0, 0), // May (1st Monday)
      ];

      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });

    test('Monthly with period = 3 (every 3 months)', () {
      var now = DateTime(2025, 1, 10, 9, 30, 0); // Second Friday of January
      var baseRequest = Request(
        id: 'test',
        roomID: 'room1',
        eventStartTime: now,
        eventEndTime: now.add(Duration(hours: 1)),
        status: RequestStatus.pending,
        roomName: 'Test Room',
      );

      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.monthly,
          period: 3,
          offset: 2, // Second Friday
          weekday: {Weekday.friday},
        ),
      );

      var occurrences = request.expand(now, now.add(Duration(days: 300)));
      var expectedStartTimes = [
        DateTime(2025, 1, 10, 9, 30, 0), // January (2nd Friday)
        DateTime(2025, 4, 11, 9, 30, 0), // April (2nd Friday)
        DateTime(2025, 7, 11, 9, 30, 0), // July (2nd Friday)
        DateTime(2025, 10, 10, 9, 30, 0), // October (2nd Friday)
      ];

      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });

    test('Monthly pattern across year boundary', () {
      var now =
          DateTime(2024, 11, 7, 15, 0, 0); // First Thursday of November 2024
      var baseRequest = Request(
        id: 'test',
        roomID: 'room1',
        eventStartTime: now,
        eventEndTime: now.add(Duration(hours: 1)),
        status: RequestStatus.pending,
        roomName: 'Test Room',
      );

      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.monthly,
          period: 1,
          offset: 1, // First Thursday
          weekday: {Weekday.thursday},
        ),
      );

      var occurrences = request.expand(now, DateTime(2025, 3, 1));
      var expectedStartTimes = [
        DateTime(2024, 11, 7, 15, 0, 0), // November 2024
        DateTime(2024, 12, 5, 15, 0, 0), // December 2024
        DateTime(2025, 1, 2, 15, 0, 0), // January 2025
        DateTime(2025, 2, 6, 15, 0, 0), // February 2025
      ];

      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });

    test('Monthly pattern starting mid-month', () {
      var now = DateTime(2025, 1, 21, 12, 0, 0); // Third Tuesday of January
      var baseRequest = Request(
        id: 'test',
        roomID: 'room1',
        eventStartTime: now,
        eventEndTime: now.add(Duration(hours: 1)),
        status: RequestStatus.pending,
        roomName: 'Test Room',
      );

      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.monthly,
          period: 1,
          offset: 3, // Third Tuesday
          weekday: {Weekday.tuesday},
        ),
      );

      var occurrences = request.expand(now, now.add(Duration(days: 90)));
      var expectedStartTimes = [
        DateTime(2025, 1, 21, 12, 0, 0), // January (3rd Tuesday)
        DateTime(2025, 2, 18, 12, 0, 0), // February (3rd Tuesday)
        DateTime(2025, 3, 18, 12, 0, 0), // March (3rd Tuesday)
        DateTime(2025, 4, 15, 12, 0, 0), // April (3rd Tuesday)
      ];

      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });

    test('Monthly pattern edge case - February leap year considerations', () {
      var now = DateTime(
          2024, 2, 26, 10, 0, 0); // 4th Monday of February 2024 (leap year)
      var baseRequest = Request(
        id: 'test',
        roomID: 'room1',
        eventStartTime: now,
        eventEndTime: now.add(Duration(hours: 1)),
        status: RequestStatus.pending,
        roomName: 'Test Room',
      );

      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.monthly,
          period: 1,
          offset: 4, // 4th Monday
          weekday: {Weekday.monday},
        ),
      );

      var occurrences = request.expand(now, DateTime(2024, 6, 1));
      var expectedStartTimes = [
        DateTime(2024, 2, 26, 10, 0, 0), // February 2024 (4th Monday)
        DateTime(2024, 3, 25, 10, 0, 0), // March 2024 (4th Monday)
        DateTime(2024, 4, 22, 10, 0, 0), // April 2024 (4th Monday)
        DateTime(2024, 5, 27, 10, 0, 0), // May 2024 (4th Monday)
      ];

      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });

    test('Monthly pattern with window that starts before first occurrence', () {
      var now = DateTime(2025, 2, 13, 11, 0, 0); // Second Thursday of February
      var baseRequest = Request(
        id: 'test',
        roomID: 'room1',
        eventStartTime: now,
        eventEndTime: now.add(Duration(hours: 1)),
        status: RequestStatus.pending,
        roomName: 'Test Room',
      );

      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.monthly,
          period: 1,
          offset: 2, // Second Thursday
          weekday: {Weekday.thursday},
        ),
      );

      // Window starts in January, before the pattern starts
      var windowStart = DateTime(2025, 1, 1);
      var windowEnd = DateTime(2025, 4, 1);
      var occurrences = request.expand(windowStart, windowEnd);

      var expectedStartTimes = [
        DateTime(2025, 2, 13, 11, 0, 0), // February (2nd Thursday)
        DateTime(2025, 3, 13, 11, 0, 0), // March (2nd Thursday)
      ];

      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });
  });

  group('RecurranceOverrides Testing', () {
    var now = DateTime(2025, 1, 6, 10, 0, 0); // Monday
    Request baseRequest = Request(
      id: 'test-override',
      roomID: 'room1',
      eventStartTime: now,
      eventEndTime: now.add(Duration(hours: 1)),
      status: RequestStatus.pending,
      roomName: 'Test Room',
    );

    test('Single override with modified request', () {
      var overrideDate = DateTime(2025, 1, 13, 0, 0, 0); // Next Monday
      var overrideRequest = baseRequest.copyWith(
        eventStartTime: DateTime(2025, 1, 13, 14, 0, 0), // Different time
        eventEndTime: DateTime(2025, 1, 13, 16, 0, 0), // Different duration
        roomName: 'Override Room',
      );

      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.weekly,
          period: 1,
          weekday: {Weekday.monday},
        ),
        recurranceOverrides: {
          overrideDate: overrideRequest,
        },
      );

      var occurrences = request.expand(now, now.add(Duration(days: 21)));
      var expectedStartTimes = [
        DateTime(2025, 1, 6, 10, 0, 0), // Original
        DateTime(2025, 1, 13, 14, 0, 0), // Override time
        DateTime(2025, 1, 20, 10, 0, 0), // Back to original
        DateTime(2025, 1, 27, 10, 0, 0), // Original
      ];

      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);

      // Check that override has different room name
      var overriddenOccurrence = occurrences[1];
      expect(overriddenOccurrence.roomName, 'Override Room');
      expect(
          overriddenOccurrence.eventEndTime, DateTime(2025, 1, 13, 16, 0, 0));
    });

    test('Override with null (deleted occurrence)', () {
      var deletedDate = DateTime(2025, 1, 13, 0, 0, 0); // Next Monday

      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.weekly,
          period: 1,
          weekday: {Weekday.monday},
        ),
        recurranceOverrides: {
          deletedDate: null, // Delete this occurrence
        },
      );

      var occurrences = request.expand(now, now.add(Duration(days: 21)));
      var expectedStartTimes = [
        DateTime(2025, 1, 6, 10, 0, 0), // Original
        // January 13 is deleted
        DateTime(2025, 1, 20, 10, 0, 0), // Next occurrence
        DateTime(2025, 1, 27, 10, 0, 0), // Following occurrence
      ];

      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
      expect(occurrences.length, 3); // One less than without override
    });

    test('Multiple overrides in a pattern', () {
      var override1Date = DateTime(2025, 1, 13, 0, 0, 0);
      var override2Date = DateTime(2025, 1, 27, 0, 0, 0);

      var override1Request = baseRequest.copyWith(
        eventStartTime: DateTime(2025, 1, 13, 15, 0, 0),
        eventEndTime: DateTime(2025, 1, 13, 17, 0, 0),
        roomName: 'Conference Room B',
      );

      var override2Request = baseRequest.copyWith(
        eventStartTime: DateTime(2025, 1, 27, 8, 0, 0),
        eventEndTime: DateTime(2025, 1, 27, 9, 30, 0),
        roomName: 'Meeting Room C',
      );

      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.weekly,
          period: 1,
          weekday: {Weekday.monday},
        ),
        recurranceOverrides: {
          override1Date: override1Request,
          override2Date: override2Request,
        },
      );

      var occurrences = request.expand(now, now.add(Duration(days: 28)));

      expect(occurrences.length, 5);

      // Check original occurrence
      expect(occurrences[0].eventStartTime, DateTime(2025, 1, 6, 10, 0, 0));
      expect(occurrences[0].roomName, 'Test Room');

      // Check first override
      expect(occurrences[1].eventStartTime, DateTime(2025, 1, 13, 15, 0, 0));
      expect(occurrences[1].roomName, 'Conference Room B');

      // Check normal occurrence
      expect(occurrences[2].eventStartTime, DateTime(2025, 1, 20, 10, 0, 0));
      expect(occurrences[2].roomName, 'Test Room');

      // Check second override
      expect(occurrences[3].eventStartTime, DateTime(2025, 1, 27, 8, 0, 0));
      expect(occurrences[3].roomName, 'Meeting Room C');

      // Check next normal occurrence
      expect(occurrences[4].eventStartTime, DateTime(2025, 2, 3, 10, 0, 0));
      expect(occurrences[4].roomName, 'Test Room');
    });

    test('Mix of modified and deleted overrides', () {
      var modifiedDate = DateTime(2025, 1, 13, 0, 0, 0);
      var deletedDate = DateTime(2025, 1, 20, 0, 0, 0);

      var modifiedRequest = baseRequest.copyWith(
        eventStartTime: DateTime(2025, 1, 13, 16, 0, 0),
        eventEndTime: DateTime(2025, 1, 13, 18, 0, 0),
      );

      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.weekly,
          period: 1,
          weekday: {Weekday.monday},
        ),
        recurranceOverrides: {
          modifiedDate: modifiedRequest,
          deletedDate: null, // Delete this one
        },
      );

      var occurrences = request.expand(now, now.add(Duration(days: 28)));
      var expectedStartTimes = [
        DateTime(2025, 1, 6, 10, 0, 0), // Original
        DateTime(2025, 1, 13, 16, 0, 0), // Modified
        // January 20 is deleted
        DateTime(2025, 1, 27, 10, 0, 0), // Normal
        DateTime(2025, 2, 3, 10, 0, 0), // Normal
      ];

      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
      expect(occurrences.length, 4);
    });

    test('Overrides outside the expansion window', () {
      var outsideOverrideDate =
          DateTime(2025, 2, 10, 0, 0, 0); // Outside window
      var insideOverrideDate = DateTime(2025, 1, 13, 0, 0, 0); // Inside window

      var outsideRequest = baseRequest.copyWith(
        eventStartTime: DateTime(2025, 2, 10, 20, 0, 0),
      );

      var insideRequest = baseRequest.copyWith(
        eventStartTime: DateTime(2025, 1, 13, 12, 0, 0),
      );

      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.weekly,
          period: 1,
          weekday: {Weekday.monday},
        ),
        recurranceOverrides: {
          outsideOverrideDate: outsideRequest, // Should not appear
          insideOverrideDate: insideRequest, // Should appear
        },
      );

      // Window that doesn't include February override
      var occurrences = request.expand(now, DateTime(2025, 1, 28));

      expect(occurrences.length, 4);

      // Check that inside override is applied
      var overriddenOccurrence = occurrences.firstWhere(
        (o) => o.eventStartTime.day == 13,
      );
      expect(
          overriddenOccurrence.eventStartTime, DateTime(2025, 1, 13, 12, 0, 0));

      // Verify outside override is not included
      var februaryOccurrences = occurrences.where(
        (o) => o.eventStartTime.month == 2,
      );
      expect(februaryOccurrences.length, 0);
    });

    test('Override inherits request ID', () {
      var overrideDate = DateTime(2025, 1, 13, 0, 0, 0);
      var overrideRequest = baseRequest.copyWith(
        id: 'different-id', // This should be ignored
        eventStartTime: DateTime(2025, 1, 13, 14, 0, 0),
      );

      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.weekly,
          period: 1,
          weekday: {Weekday.monday},
        ),
        recurranceOverrides: {
          overrideDate: overrideRequest,
        },
      );

      var occurrences = request.expand(now, now.add(Duration(days: 14)));

      // All occurrences should have the same ID as the original request
      for (var occurrence in occurrences) {
        expect(occurrence.id, baseRequest.id);
      }
    });

    test('Monthly pattern with overrides', () {
      var monthlyStart = DateTime(2025, 1, 6, 10, 0, 0); // First Monday
      var monthlyRequest = Request(
        id: 'monthly-test',
        roomID: 'room1',
        eventStartTime: monthlyStart,
        eventEndTime: monthlyStart.add(Duration(hours: 1)),
        status: RequestStatus.pending,
        roomName: 'Monthly Room',
      );

      var overrideDate =
          DateTime(2025, 2, 3, 0, 0, 0); // February's first Monday
      var overrideRequest = monthlyRequest.copyWith(
        eventStartTime: DateTime(2025, 2, 3, 14, 0, 0),
        roomName: 'Override Monthly Room',
      );

      var request = monthlyRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.monthly,
          period: 1,
          offset: 1, // First Monday
          weekday: {Weekday.monday},
        ),
        recurranceOverrides: {
          overrideDate: overrideRequest,
        },
      );

      var occurrences = request.expand(
        monthlyStart,
        DateTime(2025, 4, 1),
      );

      expect(occurrences.length, 3);

      // January - original
      expect(occurrences[0].eventStartTime, DateTime(2025, 1, 6, 10, 0, 0));
      expect(occurrences[0].roomName, 'Monthly Room');

      // February - override
      expect(occurrences[1].eventStartTime, DateTime(2025, 2, 3, 14, 0, 0));
      expect(occurrences[1].roomName, 'Override Monthly Room');

      // March - back to original
      expect(occurrences[2].eventStartTime, DateTime(2025, 3, 3, 10, 0, 0));
      expect(occurrences[2].roomName, 'Monthly Room');
    });

    test('Override with different status and public name', () {
      var overrideDate = DateTime(2025, 1, 13, 0, 0, 0);
      var overrideRequest = baseRequest.copyWith(
        eventStartTime: DateTime(2025, 1, 13, 11, 0, 0),
        status: RequestStatus.confirmed,
        publicName: 'Override Event Name',
      );

      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.weekly,
          period: 1,
          weekday: {Weekday.monday},
        ),
        recurranceOverrides: {
          overrideDate: overrideRequest,
        },
      );

      var occurrences = request.expand(now, now.add(Duration(days: 14)));

      // Check that override has different properties
      var overriddenOccurrence = occurrences[1];
      expect(overriddenOccurrence.status, RequestStatus.confirmed);
      expect(overriddenOccurrence.publicName, 'Override Event Name');

      // Check that other occurrences maintain original properties
      expect(occurrences[0].status, RequestStatus.pending);
      expect(occurrences[0].publicName, isNull);
      expect(occurrences[2].status, RequestStatus.pending);
      expect(occurrences[2].publicName, isNull);
    });

    test('Empty overrides map', () {
      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.weekly,
          period: 1,
          weekday: {Weekday.monday},
        ),
        recurranceOverrides: {}, // Empty map
      );

      var occurrences = request.expand(now, now.add(Duration(days: 14)));

      // Should behave exactly like no overrides
      var expectedStartTimes = [
        DateTime(2025, 1, 6, 10, 0, 0),
        DateTime(2025, 1, 13, 10, 0, 0),
        DateTime(2025, 1, 20, 10, 0, 0),
      ];

      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });

    test('Overrides with includeRequestDate = false', () {
      var originalDate = DateTime(2025, 1, 6, 0, 0, 0); // Original event date
      var overrideDate = DateTime(2025, 1, 13, 0, 0, 0);

      var originalOverride = baseRequest.copyWith(
        eventStartTime: DateTime(2025, 1, 6, 16, 0, 0), // Override original
      );

      var overrideRequest = baseRequest.copyWith(
        eventStartTime: DateTime(2025, 1, 13, 14, 0, 0),
      );

      var request = baseRequest.copyWith(
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.weekly,
          period: 1,
          weekday: {Weekday.monday},
        ),
        recurranceOverrides: {
          originalDate: originalOverride,
          overrideDate: overrideRequest,
        },
      );

      var occurrences = request.expand(
        now,
        now.add(Duration(days: 14)),
        includeRequestDate: false,
      );

      // Should not include original date, but should include other overrides
      var expectedStartTimes = [
        DateTime(2025, 1, 13, 14, 0, 0), // Override
        DateTime(2025, 1, 20, 10, 0, 0), // Normal recurrence
      ];

      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });
  });
}
