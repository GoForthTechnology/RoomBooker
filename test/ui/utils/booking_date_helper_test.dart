import 'package:flutter_test/flutter_test.dart';
import 'package:room_booker/ui/utils/booking_date_helper.dart';

void main() {
  group('BookingDateHelper', () {
    test('getFirstDate returns first day of the month', () {
      final focusDate = DateTime(2023, 10, 27);
      final result = BookingDateHelper.getFirstDate(focusDate);
      expect(result, DateTime(2023, 10, 1));
    });

    test('getLastDate returns date 365 days later', () {
      final firstDate = DateTime(2023, 10, 1);
      final result = BookingDateHelper.getLastDate(firstDate);
      expect(result, firstDate.add(const Duration(days: 365)));
    });
  });
}
