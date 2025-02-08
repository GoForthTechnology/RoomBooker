import 'package:room_booker/entities/request.dart';
import 'package:room_booker/entities/series.dart';
import 'package:test/test.dart';

void main() {
  group('Monthly series tests', () {
    test('Monthly on 1st Monday', () {
      var request = Request(
        eventStartTime: DateTime(2021, 1, 1, 9, 30),
        eventEndTime: DateTime(2021, 1, 1, 10, 30),
        roomID: '1',
        roomName: 'Room 1',
      );
      var series = Series(
        request: request,
        pattern: RecurrancePattern.monthlyOnNth(1, Weekday.tuesday),
      );
      var dates = series.expand(DateTime(2021, 1, 1), DateTime(2021, 2, 28));
      expect(dates, [
        request.copyWith(
          eventStartTime: DateTime(2021, 1, 5, 9, 30),
          eventEndTime: DateTime(2021, 1, 5, 10, 30),
        ),
        request.copyWith(
          eventStartTime: DateTime(2021, 2, 2, 9, 30),
          eventEndTime: DateTime(2021, 2, 2, 10, 30),
        ),
      ]);
    });
  });

  group('Daily series tests', () {
    test('Daily', () {
      var request = Request(
        eventStartTime: DateTime(2021, 1, 1, 9, 30),
        eventEndTime: DateTime(2021, 1, 1, 10, 30),
        roomID: '1',
        roomName: 'Room 1',
      );
      var series = Series(
        request: request,
        pattern: RecurrancePattern.daily(),
      );
      var requests = series.expand(
        DateTime(2021, 1, 1),
        DateTime(2021, 1, 5),
      );
      expect(requests, [
        request.copyWith(
          eventStartTime: DateTime(2021, 1, 1, 9, 30),
          eventEndTime: DateTime(2021, 1, 1, 10, 30),
        ),
        request.copyWith(
          eventStartTime: DateTime(2021, 1, 2, 9, 30),
          eventEndTime: DateTime(2021, 1, 2, 10, 30),
        ),
        request.copyWith(
          eventStartTime: DateTime(2021, 1, 3, 9, 30),
          eventEndTime: DateTime(2021, 1, 3, 10, 30),
        ),
        request.copyWith(
          eventStartTime: DateTime(2021, 1, 4, 9, 30),
          eventEndTime: DateTime(2021, 1, 4, 10, 30),
        ),
        request.copyWith(
          eventStartTime: DateTime(2021, 1, 5, 9, 30),
          eventEndTime: DateTime(2021, 1, 5, 10, 30),
        ),
      ]);
    });
    test('Daily capped by end', () {
      var request = Request(
        eventStartTime: DateTime(2021, 1, 1, 9, 30),
        eventEndTime: DateTime(2021, 1, 1, 10, 30),
        roomID: '1',
        roomName: 'Room 1',
      );
      var series = Series(
        request: request,
        end: DateTime(2021, 1, 3),
        pattern: RecurrancePattern.daily(),
      );
      var dates = series.expand(
        DateTime(2021, 1, 1),
        DateTime(2021, 1, 5),
      );
      expect(dates, [
        request.copyWith(
          eventStartTime: DateTime(2021, 1, 1, 9, 30),
          eventEndTime: DateTime(2021, 1, 1, 10, 30),
        ),
        request.copyWith(
          eventStartTime: DateTime(2021, 1, 2, 9, 30),
          eventEndTime: DateTime(2021, 1, 2, 10, 30),
        ),
        request.copyWith(
          eventStartTime: DateTime(2021, 1, 3, 9, 30),
          eventEndTime: DateTime(2021, 1, 3, 10, 30),
        ),
      ]);
    });
    test('Daily series not yet started', () {
      var request = Request(
        eventStartTime: DateTime(2021, 2, 1, 9, 30),
        eventEndTime: DateTime(2021, 2, 1, 10, 30),
        roomID: '1',
        roomName: 'Room 1',
      );
      var series = Series(
        request: request,
        pattern: RecurrancePattern.daily(),
      );
      var dates = series.expand(
        DateTime(2021, 1, 1),
        DateTime(2021, 1, 5),
      );
      expect(dates, []);
    });
  });
  /*group('Weekly series tests', () {
    test('Weekly on Mondays', () {
      var series = Series(
        start: DateTime(2021, 1, 1),
        pattern: RecurrancePattern.weekly(on: Weekday.monday),
      );
      var dates = series.generateDates(
        DateTime(2021, 1, 1), // A Friday
        DateTime(2021, 1, 31), // A Sunday
      );
      expect(dates, [
        DateTime(2021, 1, 4),
        DateTime(2021, 1, 11),
        DateTime(2021, 1, 18),
        DateTime(2021, 1, 25),
      ]);
    });

    test('Weekly capped by end', () {
      var series = Series(
        start: DateTime(2021, 1, 1),
        end: DateTime(2021, 1, 12),
        pattern: RecurrancePattern.weekly(on: Weekday.monday),
      );
      var dates = series.generateDates(
        DateTime(2021, 1, 1), // A Friday
        DateTime(2021, 1, 31), // A Sunday
      );
      expect(dates, [
        DateTime(2021, 1, 4),
        DateTime(2021, 1, 11),
      ]);
    });

    test('Weekly no instance in window', () {
      var series = Series(
        start: DateTime(2021, 1, 1),
        pattern: RecurrancePattern.weekly(on: Weekday.monday),
      );
      var dates = series.generateDates(
        DateTime(2021, 1, 1), // A Friday
        DateTime(2021, 1, 3), // A Sunday
      );
      expect(dates, []);
    });

    test('Weekly series not yet started', () {
      var series = Series(
        start: DateTime(2021, 2, 1),
        pattern: RecurrancePattern.weekly(on: Weekday.monday),
      );
      var dates = series.generateDates(
        DateTime(2021, 1, 1), // A Friday
        DateTime(2021, 1, 31), // A Sunday
      );
      expect(dates, []);
    });
  });*/
}
