import 'dart:async';

import 'package:flutter/material.dart';
import 'package:room_booker/entities/booking.dart';

class BookingRepo extends ChangeNotifier {
  final List<Booking> _requests = [];
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
