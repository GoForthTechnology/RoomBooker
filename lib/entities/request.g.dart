// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Request _$RequestFromJson(Map<String, dynamic> json) => Request(
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      message: json['message'] as String,
      eventName: json['eventName'] as String,
      eventStartTime: DateTime.parse(json['eventStartTime'] as String),
      eventEndTime: DateTime.parse(json['eventEndTime'] as String),
      selectedRoom: json['selectedRoom'] as String,
      status: $enumDecode(_$RequestStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$RequestToJson(Request instance) => <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'message': instance.message,
      'eventName': instance.eventName,
      'eventStartTime': instance.eventStartTime.toIso8601String(),
      'eventEndTime': instance.eventEndTime.toIso8601String(),
      'selectedRoom': instance.selectedRoom,
      'status': _$RequestStatusEnumMap[instance.status]!,
    };

const _$RequestStatusEnumMap = {
  RequestStatus.unknown: 'unknown',
  RequestStatus.confirmed: 'confirmed',
  RequestStatus.denied: 'denied',
  RequestStatus.pending: 'pending',
};
