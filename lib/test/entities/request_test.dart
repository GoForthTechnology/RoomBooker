import 'package:test/test.dart';
import 'package:room_booker/entities/request.dart';

void main() {
  group('Test Request Expansion', () {
    var eventStartTime = DateTime(2025, 1, 1);
    var request = Request(
      eventEndTime: eventStartTime,
      eventStartTime: eventStartTime.add(Duration(hours: 1)),
      roomID: 'roomID',
      roomName: 'roomName',
      status: RequestStatus.confirmed,
    );

    test('Test case', () {
      var r = request.copyWith(
          recurrancePattern:
              RecurrancePattern.monthlyOnNth(1, Weekday.saturday));
      var instances =
          r.expand(eventStartTime, eventStartTime.add(Duration(days: 90)));
      expect(instances.length, 4);
      expect(instances[0].eventStartTime, eventStartTime);
      expect(
          instances[1].eventStartTime, eventStartTime.add(Duration(days: 28)));
      expect(
          instances[2].eventStartTime, eventStartTime.add(Duration(days: 56)));
      // Add your test case 2 code here
    });
  });
}
