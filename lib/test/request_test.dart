import 'package:test/test.dart';
import 'package:room_booker/entities/request.dart';

void main() {
  group('Test Request Expansion', () {
    test('Test case', () {
      var eventStartTime = DateTime(2025, 3, 6);
      var request = Request(
        eventStartTime: eventStartTime,
        eventEndTime: eventStartTime.add(Duration(hours: 1)),
        roomID: 'roomID',
        roomName: 'roomName',
        status: RequestStatus.confirmed,
        recurrancePattern: RecurrancePattern.monthlyOnNth(1, Weekday.thursday),
      );

      var instances = request.expand(
          eventStartTime, eventStartTime.add(Duration(days: 365)));
      print(instances);
      expect(instances.length, 3);
      expect(instances[0].eventStartTime, eventStartTime);
      expect(
          instances[1].eventStartTime, eventStartTime.add(Duration(days: 28)));
      expect(
          instances[2].eventStartTime, eventStartTime.add(Duration(days: 56)));
      // Add your test case 2 code here
    });
  });
}
