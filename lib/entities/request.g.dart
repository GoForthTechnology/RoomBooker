// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrivateRequestDetails _$PrivateRequestDetailsFromJson(
        Map<String, dynamic> json) =>
    PrivateRequestDetails(
      message: json['message'] as String? ?? "",
      eventName: json['eventName'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
    );

Map<String, dynamic> _$PrivateRequestDetailsToJson(
        PrivateRequestDetails instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'message': instance.message,
      'eventName': instance.eventName,
    };

Request _$RequestFromJson(Map<String, dynamic> json) => Request(
      eventStartTime: DateTime.parse(json['eventStartTime'] as String),
      eventEndTime: DateTime.parse(json['eventEndTime'] as String),
      roomID: json['roomID'] as String,
      roomName: json['roomName'] as String,
    );

Map<String, dynamic> _$RequestToJson(Request instance) => <String, dynamic>{
      'eventStartTime': instance.eventStartTime.toIso8601String(),
      'eventEndTime': instance.eventEndTime.toIso8601String(),
      'roomID': instance.roomID,
      'roomName': instance.roomName,
    };
