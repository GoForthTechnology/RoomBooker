import 'package:room_booker/entities/blackout_window.dart';

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
  final Confirmation? confirmation;

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
    this.confirmation,
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
      confirmation: confirmation ?? this.confirmation,
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

  Confirmation({required this.confirmedBy, required this.confirmedAt});
}
