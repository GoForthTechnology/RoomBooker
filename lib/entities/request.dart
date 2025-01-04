import 'package:room_booker/entities/blackout_window.dart';

enum RequestStatus {
  unknown,
  confirmed,
  denied,
  pending,
}

class Request {
  final String name;
  final String email;
  final String phone;
  final int attendance;
  final String message;
  final String eventName;
  final DateTime eventStartTime;
  final DateTime eventEndTime;
  final DateTime doorUnlockTime;
  final DateTime doorLockTime;
  final String selectedRoom;
  final RequestStatus status;

  Request({
    required this.name,
    required this.email,
    required this.phone,
    required this.attendance,
    required this.message,
    required this.eventName,
    required this.eventStartTime,
    required this.eventEndTime,
    required this.doorUnlockTime,
    required this.doorLockTime,
    required this.selectedRoom,
    required this.status,
  });

  Request copyWith({
    String? name,
    String? email,
    String? phone,
    int? attendance,
    String? message,
    String? eventName,
    DateTime? eventStartTime,
    DateTime? eventEndTime,
    DateTime? doorUnlockTime,
    DateTime? doorLockTime,
    String? selectedRoom,
    RequestStatus? status,
  }) {
    return Request(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      attendance: attendance ?? this.attendance,
      message: message ?? this.message,
      eventName: eventName ?? this.eventName,
      eventStartTime: eventStartTime ?? this.eventStartTime,
      eventEndTime: eventEndTime ?? this.eventEndTime,
      doorUnlockTime: doorUnlockTime ?? this.doorUnlockTime,
      doorLockTime: doorLockTime ?? this.doorLockTime,
      selectedRoom: selectedRoom ?? this.selectedRoom,
      status: status ?? this.status,
    );
  }

  BlackoutWindow toBlackoutWindow() {
    return BlackoutWindow(
      start: eventStartTime,
      end: eventEndTime,
      reason: "Busy",
    );
  }
}
