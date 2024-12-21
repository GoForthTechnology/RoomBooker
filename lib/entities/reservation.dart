import 'package:json_annotation/json_annotation.dart';

part 'reservation.g.dart';

@JsonSerializable(explicitToJson: true)
class Reservation {
  int id;
  String name;
  String email;
  String phone;
  String date;
  String time;
  int people;
  String message;

  Reservation({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.date,
    required this.time,
    required this.people,
    required this.message,
  });

  factory Reservation.fromJson(Map<String, dynamic> data) =>
      _$ReservationFromJson(data);

  Map<String, dynamic> toJson() => _$ReservationToJson(this);
}
