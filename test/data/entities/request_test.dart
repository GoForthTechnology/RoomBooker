import 'package:flutter_test/flutter_test.dart';
import 'package:room_booker/data/entities/request.dart';

void main() {
  group('Request Expansion', () {
    test('Monthly expansion with offset', () {
      var now = DateTime(2025, 1, 1, 0, 0, 0);
      Request request = Request(
        id: '123',
        roomID: 'room1',
        eventStartTime: now,
        eventEndTime: now.add(Duration(hours: 1)),
        status: RequestStatus.pending,
        roomName: 'Conference Room A',
        recurrancePattern: RecurrancePattern(
            frequency: Frequency.monthly,
            period: 1,
            offset: 2,
            weekday: {Weekday.thursday}),
      );
      var occurrences = request.expand(now, now.add(Duration(days: 365)));
      expect(occurrences.length, 12);

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
      expect(occurrences.map((e) => e.eventStartTime).toList(),
          expectedStartTimes);
    });
  });
}
