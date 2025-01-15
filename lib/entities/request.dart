import 'package:json_annotation/json_annotation.dart';
import 'package:room_booker/entities/blackout_window.dart';

part 'request.g.dart';

enum RequestStatus {
  unknown,
  confirmed,
  denied,
  pending,
}

@JsonSerializable(explicitToJson: true)
class Request {
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? id;
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
    this.id,
  });

  Request copyWith({
    String? id,
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
      id: this.id ?? id,
    );
  }

  BlackoutWindow toBlackoutWindow() {
    return BlackoutWindow(
      start: eventStartTime,
      end: eventEndTime,
      reason: "Busy",
    );
  }

  factory Request.fromJson(Map<String, dynamic> json) =>
      _$RequestFromJson(json);
  Map<String, dynamic> toJson() => _$RequestToJson(this);
}
