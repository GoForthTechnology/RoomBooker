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
  final List<Booking> _requests = [
    fakeBooking("Fake Request #1", DateTime.now().add(const Duration(days: 2)),
        const Duration(hours: 4)),
  ];

  Stream<List<Booking>> get bookings {
    List<Booking> bookings = [];
    bookings.addAll(_bookings.map((b) => b.copyWith(
        confirmation:
            Confirmation(confirmedBy: "parker", confirmedAt: DateTime.now()))));
    bookings.addAll(_requests);

    return Stream.value(bookings);
  }

  Future<void> addRequest(Booking request) async {
    _requests.add(request);
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
}
