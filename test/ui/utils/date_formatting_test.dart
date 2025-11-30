import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/ui/utils/date_formatting.dart';

void main() {
  group('getFormattedBookingRange', () {
    test('formats same day booking correctly', () {
      final start = DateTime(2023, 10, 27, 10, 0);
      final end = DateTime(2023, 10, 27, 11, 0);
      final request = Request(
        id: '1',
        roomID: 'room1',
        eventStartTime: start,
        eventEndTime: end,
        roomName: 'Room A',
        publicName: 'Meeting',
      );

      final result = getFormattedBookingRange(request);

      expect(result, contains(DateFormat.jm().format(start)));
      expect(result, contains(DateFormat.jm().format(end)));
    });

    test('formats multi-day booking correctly', () {
      final start = DateTime(2023, 10, 27, 10, 0);
      final end = DateTime(2023, 10, 28, 11, 0);
      final request = Request(
        id: '1',
        roomID: 'room1',
        eventStartTime: start,
        eventEndTime: end,
        roomName: 'Room A',
        publicName: 'Meeting',
      );

      final result = getFormattedBookingRange(request);
      expect(result, contains(DateFormat.yMd().format(start)));
      expect(
        result,
        contains(DateFormat.jm().format(start)),
      ); // Check time part separately if needed or combined
      expect(result, contains(DateFormat.yMd().format(end)));
    });
  });
}
