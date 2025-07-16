import 'package:flutter_test/flutter_test.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';

void main() {
  group("Overlapping Requests", () {
    test("should find overlapping requests correctly", () {
      // Arrange
      var request1 = Request(
        id: "1",
        eventStartTime: DateTime(2023, 1, 1, 10, 0),
        eventEndTime: DateTime(2023, 1, 1, 11, 0),
        roomID: '',
        roomName: '',
      );
      var request2 = Request(
        id: "2",
        eventStartTime: DateTime(2023, 1, 1, 10, 30),
        eventEndTime: DateTime(2023, 1, 1, 11, 30),
        roomID: '',
        roomName: '',
      );
      var request3 = Request(
        id: "3",
        eventStartTime: DateTime(2023, 1, 1, 11, 0),
        eventEndTime: DateTime(2023, 1, 1, 12, 0),
        roomID: '',
        roomName: '',
      );
      var request4 = Request(
        id: "4",
        eventStartTime: DateTime(2023, 1, 1, 12, 0),
        eventEndTime: DateTime(2023, 1, 1, 13, 0),
        roomID: '',
        roomName: '',
      );

      var bookings = [request1, request2, request3, request4];

      // Act
      var overlapping = findOverlaps(bookings);

      // Assert
      expect(overlapping, contains(OverlapPair(request1, request2)));
      expect(overlapping, contains(OverlapPair(request2, request3)));
      expect(overlapping, isNot(contains(OverlapPair(request3, request4))));
    });
  });
}
