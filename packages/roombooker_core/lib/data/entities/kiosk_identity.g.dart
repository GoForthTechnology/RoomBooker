// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kiosk_identity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KioskIdentity _$KioskIdentityFromJson(Map<String, dynamic> json) =>
    KioskIdentity(
      deviceId: json['deviceId'] as String,
      roomID: json['roomID'] as String,
      orgID: json['orgID'] as String,
      lastSeen: DateTime.parse(json['lastSeen'] as String),
    );

Map<String, dynamic> _$KioskIdentityToJson(KioskIdentity instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'roomID': instance.roomID,
      'orgID': instance.orgID,
      'lastSeen': instance.lastSeen.toIso8601String(),
    };
