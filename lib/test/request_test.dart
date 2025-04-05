import 'package:test/test.dart';
import 'package:room_booker/entities/request.dart';

void main() {
  group('Test Request Expansion', () {
    test('Test recurrence overrides', () {
      var eventStartTime = DateTime(2025, 3, 6, 10);
      var request = Request(
        id: "asdf7asd9f87as0d9f87as",
        eventStartTime: eventStartTime,
        eventEndTime: eventStartTime.add(Duration(hours: 1)),
        roomID: 'roomID',
        roomName: 'roomName',
        status: RequestStatus.confirmed,
        recurrancePattern: RecurrancePattern.daily(),
      );
      request = request.copyWith(recurranceOverrides: {
        DateTime(2025, 3, 8): null,
        DateTime(2025, 3, 9): request.copyWith(
            eventStartTime: DateTime(2025, 3, 9, 12),
            eventEndTime: DateTime(2025, 3, 9, 13)),
      });

      var instances =
          request.expand(DateTime(2025, 3, 6), DateTime(2025, 3, 10));
      expect(instances.length, 4);
      expect(instances[0].eventStartTime, DateTime(2025, 3, 6, 10));
      expect(instances[1].eventStartTime, DateTime(2025, 3, 7, 10));
      expect(instances[2].eventStartTime, DateTime(2025, 3, 9, 12));
      expect(instances[3].eventStartTime, DateTime(2025, 3, 10, 10));

      for (int i = 0; i < instances.length; i++) {
        expect(instances[i].id, request.id);
      }
    });
  });
}

DateTime advanceNDays(DateTime date, int n) {
  for (int i = 0; i < n; i++) {
    date = advanceOneDay(date);
  }
  return date;
}
