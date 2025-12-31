import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/services/booking_service.dart';

class MockBookingRepo extends Mock implements BookingRepo {}

void main() {
  late MockBookingRepo mockBookingRepo;
  late BookingService bookingService;

  setUp(() {
    mockBookingRepo = MockBookingRepo();
    bookingService = BookingService(bookingRepo: mockBookingRepo);

    registerFallbackValue(RequestStatus.confirmed);
  });

  group("BookingService", () {
    group("Validation", () {
      test("validateRequest throws if end is before start", () {
        var request = Request(
          eventStartTime: DateTime(2023, 1, 1, 10, 0),
          eventEndTime: DateTime(2023, 1, 1, 9, 0), // End before start
          roomID: "room1",
          roomName: "Room 1",
        );

        expect(
          () => bookingService.validateRequest(request),
          throwsA(isA<ArgumentError>()),
        );
      });

      test("validateRequest passes if times are valid", () {
        var request = Request(
          eventStartTime: DateTime(2023, 1, 1, 10, 0),
          eventEndTime: DateTime(2023, 1, 1, 11, 0),
          roomID: "room1",
          roomName: "Room 1",
        );

        expect(() => bookingService.validateRequest(request), returnsNormally);
      });
    });

    group("Overlapping Bookings", () {
      test("findOverlappingBookings identifies overlaps correctly", () {
        var startWindow = DateTime(2023, 1, 1, 0, 0);
        var endWindow = DateTime(2023, 1, 2, 0, 0);

        var request1 = Request(
          id: "1",
          eventStartTime: DateTime(2023, 1, 1, 10, 0),
          eventEndTime: DateTime(2023, 1, 1, 11, 0),
          roomID: 'room1',
          roomName: 'Room 1',
        );
        var request2 = Request(
          id: "2",
          eventStartTime: DateTime(2023, 1, 1, 10, 30),
          eventEndTime: DateTime(2023, 1, 1, 11, 30),
          roomID: 'room1',
          roomName: 'Room 1',
        );
        var request3 = Request(
          id: "3",
          eventStartTime: DateTime(2023, 1, 1, 11, 0),
          eventEndTime: DateTime(2023, 1, 1, 12, 0),
          roomID: 'room1',
          roomName: 'Room 1',
        );
        var request4 = Request(
          id: "4",
          eventStartTime: DateTime(2023, 1, 1, 12, 0),
          eventEndTime: DateTime(2023, 1, 1, 13, 0),
          roomID: 'room1',
          roomName: 'Room 1',
        );

        // Mock listRequests to return these requests
        // Note: BookingService.findOverlappingBookings calls getRequestsStream
        // getRequestsStream calls listRequests
        when(
          () => mockBookingRepo.listRequests(
            orgID: any(named: 'orgID'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            includeStatuses: any(named: 'includeStatuses'),
            includeRoomIDs: any(named: 'includeRoomIDs'),
          ),
        ).thenAnswer(
          (_) => Stream.value([request1, request2, request3, request4]),
        );

        when(
          () => mockBookingRepo.getRequestDetails(any(), any()),
        ).thenAnswer((_) => Stream.value(null));

        var overlapsStream = bookingService.findOverlappingBookings(
          orgID: "org1",
          startTime: startWindow,
          endTime: endWindow,
        );

        expect(
          overlapsStream,
          emits(
            allOf(
              contains(OverlapPair(request1, request2)),
              contains(OverlapPair(request2, request3)),
              isNot(contains(OverlapPair(request3, request4))),
            ),
          ),
        );
      });
    });
  });
}
