import 'dart:async';

import 'package:flutter/material.dart';
import 'package:room_booker/entities/blackout_window.dart';
import 'package:room_booker/entities/booking.dart';

Booking fakeBooking(
    String name, DateTime start, Duration duration, BookingStatus status,
    {String room = "Room 1"}) {
  return Booking(
    eventName: name,
    eventStartTime: start,
    eventEndTime: start.add(duration),
    name: 'Jane Doe',
    email: "jane@gmail.com",
    attendance: 5,
    message: 'Please approve this booking',
    doorUnlockTime: start,
    doorLockTime: start.add(duration),
    selectedRoom: room,
    phone: "316-555-0199",
    status: status,
  );
}

class BookingRepo extends ChangeNotifier {
  final List<Booking> _requests = [
    fakeBooking(
        'Fake Event #1',
        DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        const Duration(hours: 2),
        BookingStatus.confirmed),
    fakeBooking('Fake Event #2', DateTime.now(), const Duration(hours: 2),
        BookingStatus.confirmed),
    fakeBooking(
        'Fake Event #3',
        DateTime.now().add(const Duration(days: 3, hours: 6)),
        const Duration(hours: 1),
        BookingStatus.confirmed),
    fakeBooking(
      'Fake Event #4',
      DateTime.now().copyWith(hour: 6, minute: 0),
      const Duration(hours: 12),
      BookingStatus.confirmed,
      room: "Room 2",
    ),
    fakeBooking("Fake Request #1", DateTime.now().add(const Duration(hours: 2)),
        const Duration(hours: 3), BookingStatus.pending),
    fakeBooking("Fake Request #2", DateTime.now().add(const Duration(days: 2)),
        const Duration(hours: 4), BookingStatus.pending),
  ];

  Stream<List<Booking>> bookings({String? roomID}) =>
      getWhere(roomID: roomID, status: BookingStatus.confirmed);

  Stream<List<Booking>> pendingRequests({String? roomID}) =>
      getWhere(roomID: roomID, status: BookingStatus.pending);

  Stream<List<Booking>> deniedRequests({String? roomID}) =>
      getWhere(roomID: roomID, status: BookingStatus.denied);

  Stream<List<Booking>> getWhere({String? roomID, BookingStatus? status}) {
    List<bool Function(Booking)> criteria = [];
    if (roomID != null) {
      criteria.add((b) => b.selectedRoom == roomID);
    }
    if (status != null) {
      criteria.add((b) => b.status == status);
    }
    condition(Booking b) {
      for (var criterion in criteria) {
        if (!criterion(b)) {
          return false;
        }
      }
      return true;
    }

    return Stream.value(_requests.where(condition).toList());
  }

  Future<void> confirmRequest(Booking request) async {
    _requests.remove(request);
    _requests.add(request.copyWith(
      status: BookingStatus.confirmed,
    ));
    notifyListeners();
  }

  Future<void> denyRequest(Booking request) async {
    _requests.remove(request);
    _requests.add(request.copyWith(
      status: BookingStatus.denied,
    ));
    notifyListeners();
  }

  Future<void> revisitRequest(Booking request) async {
    _requests.remove(request);
    await addRequest(request);
    notifyListeners();
  }

  Future<void> addRequest(Booking request) async {
    _requests.add(request.copyWith(status: BookingStatus.pending));
    notifyListeners();
  }

  Future<List<BlackoutWindow>> get blackoutWindows => Future.value([
        BlackoutWindow(
          start: DateTime(2023, 1, 1, 0, 0),
          end: DateTime(2023, 1, 1, 5, 59),
          recurrenceRule: 'FREQ=DAILY',
          reason: "Too Early",
        ),
        BlackoutWindow(
          start: DateTime(2023, 1, 1, 22, 0),
          end: DateTime(2023, 1, 1, 23, 59),
          recurrenceRule: 'FREQ=DAILY',
          reason: "Too Late",
        ),
      ]);

  Stream<List<String>> get rooms => Stream.value(['Room 1', 'Room 2']);
}
