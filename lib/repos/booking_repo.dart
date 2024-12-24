import 'dart:async';

import 'package:flutter/material.dart';
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
  final List<Booking> _requests = [
    fakeBooking(
        'Fake Event #1',
        DateTime.now().subtract(Duration(days: 1, hours: 2)),
        const Duration(hours: 2)),
    fakeBooking('Fake Event #2', DateTime.now(), const Duration(hours: 2)),
    fakeBooking(
        'Fake Event #3',
        DateTime.now().add(Duration(days: 3, hours: 6)),
        const Duration(hours: 1)),
  ];
  final StreamController<List<Booking>> _requestsController =
      StreamController<List<Booking>>.broadcast();

  BookingRepo() {
    _requestsController.add(List.unmodifiable(_requests));
  }

  Stream<List<Booking>> get requests => Stream.value(_requests);

  Future<void> addRequest(Booking request) async {
    _requests.add(request);
    _requestsController
        .add(List.unmodifiable(_requests)); // Emit new notification
    notifyListeners();
  }

  @override
  void dispose() {
    _requestsController.close();
    super.dispose();
  }
}
