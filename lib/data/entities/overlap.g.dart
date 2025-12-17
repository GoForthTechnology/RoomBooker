// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overlap.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Overlap _$OverlapFromJson(Map<String, dynamic> json) => Overlap(
  bookingID1: json['bookingID1'] as String,
  bookingID2: json['bookingID2'] as String,
  startTime: DateTime.parse(json['startTime'] as String),
  endTime: DateTime.parse(json['endTime'] as String),
  startTime2: DateTime.parse(json['startTime2'] as String),
  endTime2: DateTime.parse(json['endTime2'] as String),
  roomID: json['roomID'] as String,
);

Map<String, dynamic> _$OverlapToJson(Overlap instance) => <String, dynamic>{
  'bookingID1': instance.bookingID1,
  'bookingID2': instance.bookingID2,
  'startTime': instance.startTime.toIso8601String(),
  'endTime': instance.endTime.toIso8601String(),
  'startTime2': instance.startTime2.toIso8601String(),
  'endTime2': instance.endTime2.toIso8601String(),
  'roomID': instance.roomID,
};
