import 'package:json_annotation/json_annotation.dart';

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
  final String roomID;
  final String roomName;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final RequestStatus? status;

  Request({
    required this.eventStartTime,
    required this.eventEndTime,
    required this.roomID,
    required this.roomName,
    this.status,
    this.id,
  }) {
    assert(eventStartTime.isBefore(eventEndTime));
  }

  Request copyWith({
    String? id,
    DateTime? eventStartTime,
    DateTime? eventEndTime,
    String? roomID,
    String? roomName,
    RequestStatus? status,
  }) {
    return Request(
      eventStartTime: eventStartTime ?? this.eventStartTime,
      eventEndTime: eventEndTime ?? this.eventEndTime,
      roomID: roomID ?? this.roomID,
      roomName: roomName ?? this.roomName,
      status: status ?? this.status,
      id: id ?? this.id,
    );
  }

  factory Request.fromJson(Map<String, dynamic> json) =>
      _$RequestFromJson(json);
  Map<String, dynamic> toJson() => _$RequestToJson(this);
}
