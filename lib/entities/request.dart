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
  final RecurrancePattern? recurrancePattern;

  Request({
    this.recurrancePattern,
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
    RecurrancePattern? recurrancePattern,
  }) {
    return Request(
      eventStartTime: eventStartTime ?? this.eventStartTime,
      eventEndTime: eventEndTime ?? this.eventEndTime,
      roomID: roomID ?? this.roomID,
      roomName: roomName ?? this.roomName,
      status: status ?? this.status,
      id: id ?? this.id,
      recurrancePattern: recurrancePattern ?? this.recurrancePattern,
    );
  }

  @override
  String toString() {
    return """Request{
      id: $id,
      eventStartTime: $eventStartTime,
      eventEndTime: $eventEndTime,
      roomID: $roomID,
      roomName: $roomName,
      status: $status,
      recurrencePattern: $recurrancePattern
    }""";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Request &&
        other.id == id &&
        other.eventStartTime == eventStartTime &&
        other.eventEndTime == eventEndTime &&
        other.roomID == roomID &&
        other.roomName == roomName &&
        other.recurrancePattern == recurrancePattern &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        eventStartTime.hashCode ^
        eventEndTime.hashCode ^
        roomID.hashCode ^
        roomName.hashCode ^
        recurrancePattern.hashCode ^
        status.hashCode;
  }

  factory Request.fromJson(Map<String, dynamic> json) =>
      _$RequestFromJson(json);
  Map<String, dynamic> toJson() => _$RequestToJson(this);
}

enum Frequency { never, daily, weekly, monthly, annually, custom }

enum Weekday { sunday, monday, tuesday, wednesday, thursday, friday, saturday }

@JsonSerializable(explicitToJson: true)
class RecurrancePattern {
  final Frequency frequency;
  final int period;
  final int? offset;
  final Set<Weekday>? weekday;
  final DateTime? end;

  RecurrancePattern({
    required this.frequency,
    required this.period,
    this.offset,
    this.weekday,
    this.end,
  });

  RecurrancePattern copyWith({
    Frequency? frequency,
    Set<Weekday>? weekday,
    int? period,
    int? offset,
    DateTime? end,
  }) {
    return RecurrancePattern(
      frequency: frequency ?? this.frequency,
      weekday: weekday ?? this.weekday,
      period: period ?? this.period,
      offset: offset ?? this.offset,
      end: end ?? this.end,
    );
  }

  factory RecurrancePattern.fromJson(Map<String, dynamic> json) =>
      _$RecurrancePatternFromJson(json);
  Map<String, dynamic> toJson() => _$RecurrancePatternToJson(this);

  static RecurrancePattern never() {
    return RecurrancePattern(frequency: Frequency.never, period: 0);
  }

  static RecurrancePattern every(int n, Frequency frequency,
      {required Weekday on}) {
    return RecurrancePattern(frequency: frequency, weekday: {on}, period: n);
  }

  static RecurrancePattern daily() {
    return RecurrancePattern(frequency: Frequency.daily, period: 1);
  }

  static RecurrancePattern weekly({required Weekday on, int? period}) {
    return RecurrancePattern(
        frequency: Frequency.weekly, weekday: {on}, period: period ?? 1);
  }

  static RecurrancePattern monthlyOnNth(int nth, Weekday on) {
    return RecurrancePattern(
      frequency: Frequency.monthly,
      period: 1,
      weekday: {on},
      offset: nth,
    );
  }

  static RecurrancePattern annually() {
    return RecurrancePattern(frequency: Frequency.annually, period: 1);
  }
}
