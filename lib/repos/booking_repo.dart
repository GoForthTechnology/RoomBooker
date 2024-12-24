import 'dart:async';

import 'package:flutter/material.dart';
import 'package:room_booker/entities/booking.dart';

class BookingRepo extends ChangeNotifier {
  final List<Booking> _requests = [
    Booking(
      eventName: 'Meeting',
      eventStartTime: DateTime.now(),
      eventEndTime: DateTime.now().add(const Duration(hours: 1)),
      name: 'Jane Doe',
      email: "jane@gmail.com",
      attendance: 5,
      message: 'Please approve this booking',
      doorUnlockTime: DateTime.now().subtract(const Duration(minutes: 10)),
      doorLockTime: DateTime.now().add(const Duration(hours: 1)),
      selectedRoom: 'Room 1',
      phone: "316-555-0199",
    ),
    Booking(
      eventName: 'Lunch',
      eventStartTime: DateTime.now().add(const Duration(days: 2)),
      eventEndTime: DateTime.now().add(const Duration(days: 3, hours: 1)),
      name: 'Jane Doe',
      email: "jane@gmail.com",
      attendance: 5,
      message: 'Please approve this booking',
      doorUnlockTime: DateTime.now().subtract(const Duration(minutes: 10)),
      doorLockTime: DateTime.now().add(const Duration(hours: 1)),
      selectedRoom: 'Room 1',
      phone: "316-555-0199",
    ),
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
