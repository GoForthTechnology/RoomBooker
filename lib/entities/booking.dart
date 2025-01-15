import 'package:json_annotation/json_annotation.dart';
import 'package:room_booker/entities/request.dart';

part 'booking.g.dart';

@JsonSerializable(explicitToJson: true)
class Booking {
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? id;
  final String requestID;
  final String roomID;
  final DateTime startTime;
  final DateTime endTime;

  Booking({
    required this.requestID,
    required this.roomID,
    required this.startTime,
    required this.endTime,
    this.id,
  }) {
    assert(startTime.isBefore(endTime));
  }

  Booking copyWith({
    String? id,
    String? requestID,
    String? roomID,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return Booking(
      requestID: requestID ?? this.requestID,
      roomID: roomID ?? this.roomID,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      id: this.id ?? id,
    );
  }

  static Booking fromRequest(Request request) {
    return Booking(
      requestID: request.id!,
      endTime: request.eventEndTime,
      startTime: request.eventStartTime,
      roomID: request.selectedRoom,
    );
  }

  factory Booking.fromJson(Map<String, dynamic> json) =>
      _$BookingFromJson(json);
  Map<String, dynamic> toJson() => _$BookingToJson(this);
}
