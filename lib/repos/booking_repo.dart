import 'dart:async';

import 'package:flutter/material.dart';
import 'package:room_booker/entities/blackout_window.dart';
import 'package:room_booker/entities/booking.dart';

Booking fakeBooking(String name, DateTime start, Duration duration) {
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
    selectedRoom: 'Room 1',
    phone: "316-555-0199",
  );
}

class BookingRepo extends ChangeNotifier {
  final List<Booking> _bookings = [
    fakeBooking(
        'Fake Event #1',
        DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        const Duration(hours: 2)),
    fakeBooking('Fake Event #2', DateTime.now(), const Duration(hours: 2)),
    fakeBooking(
        'Fake Event #3',
        DateTime.now().add(const Duration(days: 3, hours: 6)),
        const Duration(hours: 1)),
  ];
  final List<Booking> _pendingRequests = [
    fakeBooking("Fake Request #1", DateTime.now().add(const Duration(hours: 2)),
        const Duration(hours: 3)),
    fakeBooking("Fake Request #2", DateTime.now().add(const Duration(days: 2)),
        const Duration(hours: 4)),
  ];
  final List<Booking> _deniedRequests = [];

  Stream<List<Booking>> get bookings {
    List<Booking> bookings = [];
    bookings.addAll(_bookings.map((b) => b.copyWith(
        confirmation: Confirmation(
            confirmedBy: "parker",
            confirmedAt: DateTime.now(),
            status: BookingStatus.confirmed))));

    return Stream.value(bookings);
  }

  Stream<List<Booking>> get pendingRequests => Stream.value(_pendingRequests);
  Stream<List<Booking>> get deniedRequests => Stream.value(_deniedRequests);

  Future<void> confirmRequest(Booking request) async {
    _pendingRequests.remove(request);
    _bookings.add(request.copyWith(
        confirmation: Confirmation(
      confirmedBy: "parker",
      confirmedAt: DateTime.now(),
      status: BookingStatus.confirmed,
    )));
    notifyListeners();
  }

  Future<void> denyRequest(Booking request) async {
    _pendingRequests.remove(request);
    _deniedRequests.add(request.copyWith(
        confirmation: Confirmation(
      confirmedBy: "parker",
      confirmedAt: DateTime.now(),
      status: BookingStatus.denied,
    )));
    notifyListeners();
  }

  Future<void> revisitRequest(Booking request) async {
    _deniedRequests.remove(request);
    _bookings.remove(request);
    _pendingRequests.add(request.copyWith(confirmation: null));
    notifyListeners();
  }

  Future<void> addRequest(Booking request) async {
    _pendingRequests.add(request);
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
