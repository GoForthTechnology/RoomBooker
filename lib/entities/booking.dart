import 'package:room_booker/entities/blackout_window.dart';

enum BookingStatus {
  unknown,
  confirmed,
  denied,
  pending,
}

class Booking {
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
  final BookingStatus status;

  Booking({
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

  Booking copyWith({
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
    Confirmation? confirmation,
    BookingStatus? status,
  }) {
    return Booking(
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
      reason: eventName,
    );
  }
}

class Confirmation {
  final String confirmedBy;
  final DateTime confirmedAt;
  final BookingStatus status;

  Confirmation(
      {required this.status,
      required this.confirmedBy,
      required this.confirmedAt});
}
