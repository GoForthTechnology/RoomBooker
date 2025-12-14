import 'package:json_annotation/json_annotation.dart';

part 'overlap.g.dart';

@JsonSerializable()
class Overlap {
  final String bookingID1;
  final String bookingID2;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime startTime2;
  final DateTime endTime2;
  final String roomID;

  Overlap({
    required this.bookingID1,
    required this.bookingID2,
    required this.startTime,
    required this.endTime,
    required this.startTime2,
    required this.endTime2,
    required this.roomID,
  });

  factory Overlap.fromJson(Map<String, dynamic> json) =>
      _$OverlapFromJson(json);
  Map<String, dynamic> toJson() => _$OverlapToJson(this);
}
