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
class PrivateRequestDetails {
  final String name;
  final String email;
  final String phone;
  final String message;
  final String eventName;

  PrivateRequestDetails({
    this.message = "",
    required this.eventName,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory PrivateRequestDetails.fromJson(Map<String, dynamic> json) =>
      _$PrivateRequestDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$PrivateRequestDetailsToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Request {
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? id;
  final DateTime eventStartTime;
  final DateTime eventEndTime;
  final String selectedRoom;
  final RequestStatus status;

  Request({
    required this.eventStartTime,
    required this.eventEndTime,
    required this.selectedRoom,
    required this.status,
    this.id,
  }) {
    assert(eventStartTime.isBefore(eventEndTime));
  }

  Request copyWith({
    String? id,
  }) {
    return Request(
      eventStartTime: eventStartTime,
      eventEndTime: eventEndTime,
      selectedRoom: selectedRoom,
      status: status,
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
