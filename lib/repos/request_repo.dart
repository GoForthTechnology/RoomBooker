import 'dart:async';

import 'package:flutter/material.dart';
import 'package:room_booker/entities/blackout_window.dart';
import 'package:room_booker/entities/request.dart';

Request fakeRequest(
    String name, DateTime start, Duration duration, RequestStatus status,
    {String room = "Room 1"}) {
  return Request(
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

class RequestRepo extends ChangeNotifier {
  final List<Request> _requests = [
    fakeRequest(
        'Fake Event #1',
        DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        const Duration(hours: 2),
        RequestStatus.confirmed),
    fakeRequest('Fake Event #2', DateTime.now(), const Duration(hours: 2),
        RequestStatus.confirmed),
    fakeRequest(
        'Fake Event #3',
        DateTime.now().add(const Duration(days: 3, hours: 6)),
        const Duration(hours: 1),
        RequestStatus.confirmed),
    fakeRequest(
      'Fake Event #4',
      DateTime.now().copyWith(hour: 6, minute: 0),
      const Duration(hours: 12),
      RequestStatus.confirmed,
      room: "Room 2",
    ),
    fakeRequest("Fake Request #1", DateTime.now().add(const Duration(hours: 2)),
        const Duration(hours: 3), RequestStatus.pending),
    fakeRequest("Fake Request #2", DateTime.now().add(const Duration(days: 2)),
        const Duration(hours: 4), RequestStatus.pending),
  ];

  Stream<List<Request>> bookings({Set<String>? roomID}) =>
      getWhere(roomID: roomID, status: RequestStatus.confirmed);

  Stream<List<Request>> pendingRequests({Set<String>? roomID}) =>
      getWhere(roomID: roomID, status: RequestStatus.pending);

  Stream<List<Request>> deniedRequests({Set<String>? roomID}) =>
      getWhere(roomID: roomID, status: RequestStatus.denied);

  Stream<List<Request>> getWhere({Set<String>? roomID, RequestStatus? status}) {
    List<bool Function(Request)> criteria = [];
    if (roomID != null) {
      criteria.add((b) => roomID.contains(b.selectedRoom));
    }
    if (status != null) {
      criteria.add((b) => b.status == status);
    }
    condition(Request b) {
      for (var criterion in criteria) {
        if (!criterion(b)) {
          return false;
        }
      }
      return true;
    }

    return Stream.value(_requests.where(condition).toList());
  }

  Future<void> confirmRequest(Request request) async {
    _requests.remove(request);
    _requests.add(request.copyWith(
      status: RequestStatus.confirmed,
    ));
    notifyListeners();
  }

  Future<void> denyRequest(Request request) async {
    _requests.remove(request);
    _requests.add(request.copyWith(
      status: RequestStatus.denied,
    ));
    notifyListeners();
  }

  Future<void> revisitRequest(Request request) async {
    _requests.remove(request);
    await addRequest(request);
    notifyListeners();
  }

  Future<void> addRequest(Request request) async {
    _requests.add(request.copyWith(status: RequestStatus.pending));
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
