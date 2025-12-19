import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:room_booker/data/entities/log_entry.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/log_repo.dart';
import 'package:room_booker/data/repos/org_repo.dart';

class MockLogRepo extends Mock implements LogRepo {}

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockLogRepo mockLogRepo;
  late MockFirebaseAnalytics mockAnalytics;
  late BookingRepo bookingRepo;

  setUpAll(() {
    registerFallbackValue(Action.create);
    registerFallbackValue(
      Request(
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now(),
        roomID: 'dummy',
        roomName: 'dummy',
      ),
    );
    registerFallbackValue(
      PrivateRequestDetails(
        eventName: 'dummy',
        name: 'dummy',
        email: 'dummy',
        phone: 'dummy',
      ),
    );
  });

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockLogRepo = MockLogRepo();
    mockAnalytics = MockFirebaseAnalytics();
    bookingRepo = BookingRepo(
      logRepo: mockLogRepo,
      db: fakeFirestore,
      analytics: mockAnalytics,
    );

    // Mock analytics logEvent to do nothing
    when(
      () => mockAnalytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});

    // Mock logRepo addLogEntry to do nothing
    when(
      () => mockLogRepo.addLogEntry(
        orgID: any(named: 'orgID'),
        requestID: any(named: 'requestID'),
        timestamp: any(named: 'timestamp'),
        action: any(named: 'action'),
        before: any(named: 'before'),
        after: any(named: 'after'),
      ),
    ).thenAnswer((_) async {});
  });

  group("BookingRepo", () {
    test("submitBookingRequest adds request to pending", () async {
      var request = Request(
        id: "req1",
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(Duration(hours: 1)),
        roomID: "room1",
        roomName: "Room 1",
      );
      var details = PrivateRequestDetails(
        name: "Test User",
        email: "test@example.com",
        phone: "1234567890",
        eventName: "Test Event",
      );

      await bookingRepo.submitBookingRequest("org1", request, details);

      var pending = await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("pending-requests")
          .get();
      expect(pending.docs.length, 1);
      expect(pending.docs.first.data()['roomID'], "room1");

      var savedDetails = await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("request-details")
          .doc(pending.docs.first.id)
          .get();
      expect(savedDetails.exists, true);
      expect(savedDetails.data()!['name'], "Test User");
    });

    test("addBooking adds request to confirmed", () async {
      var request = Request(
        id: "req1",
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(Duration(hours: 1)),
        roomID: "room1",
        roomName: "Room 1",
        status: RequestStatus.confirmed,
      );
      var details = PrivateRequestDetails(
        name: "Test User",
        email: "test@example.com",
        phone: "1234567890",
        eventName: "Test Event",
      );

      await bookingRepo.addBooking("org1", request, details);

      var confirmed = await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("confirmed-requests")
          .get();
      expect(confirmed.docs.length, 1);
      expect(confirmed.docs.first.data()['roomID'], "room1");
    });

    test("listRequests returns requests in range", () async {
      var startTime = DateTime(2023, 1, 1, 10, 0);
      var endTime = DateTime(2023, 1, 1, 11, 0);

      var request = Request(
        id: "req1",
        eventStartTime: startTime,
        eventEndTime: endTime,
        roomID: "room1",
        roomName: "Room 1",
        status: RequestStatus.confirmed,
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.never,
          period: 1,
        ),
      );

      // Manually add to firestore
      await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("confirmed-requests")
          .doc("req1")
          .set(request.toJson());

      var requests = await bookingRepo
          .listRequests(
            orgID: "org1",
            startTime: startTime.subtract(Duration(hours: 1)),
            endTime: endTime.add(Duration(days: 1)),
          )
          .skip(1)
          .first;

      expect(requests.length, 1);
      expect(requests.first.id, "req1");
    });

    test("confirmRequest moves request from pending to confirmed", () async {
      var request = Request(
        id: "req1",
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(Duration(hours: 1)),
        roomID: "room1",
        roomName: "Room 1",
        status: RequestStatus.pending,
      );

      await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("pending-requests")
          .doc("req1")
          .set(request.toJson());

      await bookingRepo.confirmRequest("org1", "req1");

      var pending = await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("pending-requests")
          .doc("req1")
          .get();
      expect(pending.exists, false);

      var confirmed = await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("confirmed-requests")
          .doc("req1")
          .get();
      expect(confirmed.exists, true);
    });

    test("denyRequest moves request from pending to denied", () async {
      var request = Request(
        id: "req1",
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(Duration(hours: 1)),
        roomID: "room1",
        roomName: "Room 1",
        status: RequestStatus.pending,
      );

      await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("pending-requests")
          .doc("req1")
          .set(request.toJson());

      await bookingRepo.denyRequest("org1", "req1");

      var pending = await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("pending-requests")
          .doc("req1")
          .get();
      expect(pending.exists, false);

      var denied = await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("denied-requests")
          .doc("req1")
          .get();
      expect(denied.exists, true);
    });

    test("deleteBooking removes confirmed request", () async {
      var request = Request(
        id: "req1",
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(Duration(hours: 1)),
        roomID: "room1",
        roomName: "Room 1",
        status: RequestStatus.confirmed,
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.never,
          period: 1,
        ),
      );

      await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("confirmed-requests")
          .doc("req1")
          .set(request.toJson());

      // Also add private details as they are deleted too
      await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("request-details")
          .doc("req1")
          .set({});

      await bookingRepo.deleteBooking(
        "org1",
        request,
        () async => RecurringBookingEditChoice.all,
      );

      var confirmed = await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("confirmed-requests")
          .doc("req1")
          .get();
      expect(confirmed.exists, false);

      var details = await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("request-details")
          .doc("req1")
          .get();
      expect(details.exists, false);
    });

    test("revisitBookingRequest moves confirmed request to pending", () async {
      var request = Request(
        id: "req1",
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(Duration(hours: 1)),
        roomID: "room1",
        roomName: "Room 1",
        status: RequestStatus.confirmed,
      );

      await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("confirmed-requests")
          .doc("req1")
          .set(request.toJson());

      await bookingRepo.revisitBookingRequest("org1", request);

      var confirmed = await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("confirmed-requests")
          .doc("req1")
          .get();
      expect(confirmed.exists, false);

      var pending = await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("pending-requests")
          .doc("req1")
          .get();
      expect(pending.exists, true);
    });

    test("revisitBookingRequest moves denied request to pending", () async {
      var request = Request(
        id: "req1",
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(Duration(hours: 1)),
        roomID: "room1",
        roomName: "Room 1",
        status: RequestStatus.denied,
      );

      await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("denied-requests")
          .doc("req1")
          .set(request.toJson());

      await bookingRepo.revisitBookingRequest("org1", request);

      var denied = await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("denied-requests")
          .doc("req1")
          .get();
      expect(denied.exists, false);

      var pending = await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("pending-requests")
          .doc("req1")
          .get();
      expect(pending.exists, true);
    });

    test("updateBooking updates pending request", () async {
      var originalRequest = Request(
        id: "req1",
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(Duration(hours: 1)),
        roomID: "room1",
        roomName: "Room 1",
        status: RequestStatus.pending,
      );
      var updatedRequest = originalRequest.copyWith(roomName: "Updated Room");
      var details = PrivateRequestDetails(
        name: "Test User",
        email: "test@example.com",
        phone: "1234567890",
        eventName: "Test Event",
      );

      await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("pending-requests")
          .doc("req1")
          .set(originalRequest.toJson());

      await bookingRepo.updateBooking(
        "org1",
        originalRequest,
        updatedRequest,
        details,
        RequestStatus.pending,
        () async => null,
      );

      var pending = await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("pending-requests")
          .doc("req1")
          .get();
      expect(pending.data()!['roomName'], "Updated Room");
    });

    test("updateBooking updates confirmed request (non-recurring)", () async {
      var originalRequest = Request(
        id: "req1",
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(Duration(hours: 1)),
        roomID: "room1",
        roomName: "Room 1",
        status: RequestStatus.confirmed,
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.never,
          period: 1,
        ),
      );
      var updatedRequest = originalRequest.copyWith(roomName: "Updated Room");
      var details = PrivateRequestDetails(
        name: "Test User",
        email: "test@example.com",
        phone: "1234567890",
        eventName: "Test Event",
      );

      await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("confirmed-requests")
          .doc("req1")
          .set(originalRequest.toJson());

      await bookingRepo.updateBooking(
        "org1",
        originalRequest,
        updatedRequest,
        details,
        RequestStatus.confirmed,
        () async => null,
      );

      var confirmed = await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("confirmed-requests")
          .doc("req1")
          .get();
      expect(confirmed.data()!['roomName'], "Updated Room");
    });

    test("updateBooking updates recurring request (this instance)", () async {
      var startTime = DateTime(2023, 1, 1, 10, 0);
      var originalRequest = Request(
        id: "req1",
        eventStartTime: startTime,
        eventEndTime: startTime.add(Duration(hours: 1)),
        roomID: "room1",
        roomName: "Room 1",
        status: RequestStatus.confirmed,
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.daily,
          period: 1,
        ),
      );

      // The updated request is for a specific instance
      var updatedRequest = originalRequest.copyWith(roomName: "Updated Room");
      var details = PrivateRequestDetails(
        name: "Test User",
        email: "test@example.com",
        phone: "1234567890",
        eventName: "Test Event",
      );

      await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("confirmed-requests")
          .doc("req1")
          .set(originalRequest.toJson());

      await bookingRepo.updateBooking(
        "org1",
        originalRequest,
        updatedRequest,
        details,
        RequestStatus.confirmed,
        () async => RecurringBookingEditChoice.thisInstance,
      );

      var confirmed = await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("confirmed-requests")
          .doc("req1")
          .get();

      var data = confirmed.data()!;
      // The main request should still have the old room name
      expect(data['roomName'], "Room 1");

      // But it should have an override
      var overrides = data['recurranceOverrides'] as Map<String, dynamic>;
      expect(overrides.isNotEmpty, true);

      // The key is the date string
      var key = DateTime(
        startTime.year,
        startTime.month,
        startTime.day,
      ).toIso8601String();
      expect(overrides.containsKey(key), true);
      expect(overrides[key]['roomName'], "Updated Room");
    });

    test("updateBooking updates recurring request (all instances)", () async {
      var startTime = DateTime(2023, 1, 1, 10, 0);
      var originalRequest = Request(
        id: "req1",
        eventStartTime: startTime,
        eventEndTime: startTime.add(Duration(hours: 1)),
        roomID: "room1",
        roomName: "Room 1",
        status: RequestStatus.confirmed,
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.daily,
          period: 1,
        ),
      );

      var updatedRequest = originalRequest.copyWith(roomName: "Updated Room");
      var details = PrivateRequestDetails(
        name: "Test User",
        email: "test@example.com",
        phone: "1234567890",
        eventName: "Test Event",
      );

      await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("confirmed-requests")
          .doc("req1")
          .set(originalRequest.toJson());

      await bookingRepo.updateBooking(
        "org1",
        originalRequest,
        updatedRequest,
        details,
        RequestStatus.confirmed,
        () async => RecurringBookingEditChoice.all,
      );

      var confirmed = await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("confirmed-requests")
          .doc("req1")
          .get();

      expect(confirmed.data()!['roomName'], "Updated Room");
    });

    test("updateBooking updates recurring request (this and future)", () async {
      var startTime = DateTime(2023, 1, 1, 10, 0);
      var originalRequest = Request(
        id: "req1",
        eventStartTime: startTime,
        eventEndTime: startTime.add(Duration(hours: 1)),
        roomID: "room1",
        roomName: "Room 1",
        status: RequestStatus.confirmed,
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.daily,
          period: 1,
        ),
      );

      // Update starting from the next day
      var updateStartTime = startTime.add(Duration(days: 1));
      var updatedRequest = originalRequest.copyWith(
        eventStartTime: updateStartTime,
        eventEndTime: updateStartTime.add(Duration(hours: 1)),
        roomName: "Updated Room",
      );
      var details = PrivateRequestDetails(
        name: "Test User",
        email: "test@example.com",
        phone: "1234567890",
        eventName: "Test Event",
      );

      await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("confirmed-requests")
          .doc("req1")
          .set(originalRequest.toJson());

      // Add details for the original request so they can be copied
      await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("request-details")
          .doc("req1")
          .set(details.toJson());

      await bookingRepo.updateBooking(
        "org1",
        originalRequest,
        updatedRequest,
        details,
        RequestStatus.confirmed,
        () async => RecurringBookingEditChoice.thisAndFuture,
      );

      // 1. Check original request is capped
      var originalDoc = await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("confirmed-requests")
          .doc("req1")
          .get();
      var originalData = originalDoc.data()!;
      var pattern = RecurrancePattern.fromJson(
        originalData['recurrancePattern'],
      );
      expect(pattern.end, isNotNull);
      // Should end the day before the update
      expect(pattern.end!.isBefore(updateStartTime), true);

      // 2. Check new request is created
      var confirmed = await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("confirmed-requests")
          .get();

      // Should have 2 docs now: original (capped) and new (started)
      expect(confirmed.docs.length, 2);

      var newDoc = confirmed.docs.firstWhere((d) => d.id != "req1");
      expect(newDoc.data()['roomName'], "Updated Room");
      expect(
        newDoc.data()['eventStartTime'],
        updatedRequest.eventStartTime.toIso8601String(),
      );
    });

    test("deleteBooking deletes recurring request (this instance)", () async {
      var startTime = DateTime(2023, 1, 1, 10, 0);
      var request = Request(
        id: "req1",
        eventStartTime: startTime,
        eventEndTime: startTime.add(Duration(hours: 1)),
        roomID: "room1",
        roomName: "Room 1",
        status: RequestStatus.confirmed,
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.daily,
          period: 1,
        ),
      );

      await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("confirmed-requests")
          .doc("req1")
          .set(request.toJson());

      // Delete specific instance
      var instanceToDelete = request.copyWith(
        eventStartTime: startTime.add(Duration(days: 1)),
        eventEndTime: startTime.add(Duration(days: 1, hours: 1)),
      );

      await bookingRepo.deleteBooking(
        "org1",
        instanceToDelete,
        () async => RecurringBookingEditChoice.thisInstance,
      );

      var doc = await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("confirmed-requests")
          .doc("req1")
          .get();

      var overrides =
          doc.data()!['recurranceOverrides'] as Map<String, dynamic>;
      var key = DateTime(
        2023,
        1,
        2,
      ).toIso8601String(); // The date of the deleted instance
      expect(overrides.containsKey(key), true);
      expect(overrides[key], null); // Null means deleted/cancelled
    });

    test("deleteBooking deletes recurring request (this and future)", () async {
      var startTime = DateTime(2023, 1, 1, 10, 0);
      var request = Request(
        id: "req1",
        eventStartTime: startTime,
        eventEndTime: startTime.add(Duration(hours: 1)),
        roomID: "room1",
        roomName: "Room 1",
        status: RequestStatus.confirmed,
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.daily,
          period: 1,
        ),
      );

      await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("confirmed-requests")
          .doc("req1")
          .set(request.toJson());

      // Delete from this instance onwards
      var splitDate = startTime.add(Duration(days: 5));
      var instanceToDelete = request.copyWith(
        eventStartTime: splitDate,
        eventEndTime: splitDate.add(Duration(hours: 1)),
      );

      await bookingRepo.deleteBooking(
        "org1",
        instanceToDelete,
        () async => RecurringBookingEditChoice.thisAndFuture,
      );

      var doc = await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("confirmed-requests")
          .doc("req1")
          .get();

      var pattern = RecurrancePattern.fromJson(
        doc.data()!['recurrancePattern'],
      );
      expect(pattern.end, isNotNull);
      // Should end at the split date (technically the day starts at 00:00)
      expect(pattern.end!.year, splitDate.year);
      expect(pattern.end!.month, splitDate.month);
      expect(pattern.end!.day, splitDate.day);
    });

    test("listRequests includes recurring requests starting in past", () async {
      var startTime = DateTime(2023, 1, 1, 10, 0);
      // Recurring daily forever
      var request = Request(
        id: "req1",
        eventStartTime: startTime,
        eventEndTime: startTime.add(Duration(hours: 1)),
        roomID: "room1",
        roomName: "Room 1",
        status: RequestStatus.confirmed,
        recurrancePattern: RecurrancePattern(
          frequency: Frequency.daily,
          period: 1,
        ),
      );

      await fakeFirestore
          .collection("orgs")
          .doc("org1")
          .collection("confirmed-requests")
          .doc("req1")
          .set(request.toJson());

      // Query for a window a month later
      var queryStart = DateTime(2023, 2, 1, 0, 0);
      var queryEnd = DateTime(2023, 2, 2, 0, 0);

      var requests = await bookingRepo
          .listRequests(orgID: "org1", startTime: queryStart, endTime: queryEnd)
          .skip(1)
          .first;

      expect(requests.length, 1);
      expect(requests.first.id, "req1");
    });
  });

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
