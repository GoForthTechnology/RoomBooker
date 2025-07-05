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
}
