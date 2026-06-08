// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provisioning_handshake.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProvisioningHandshake _$ProvisioningHandshakeFromJson(
  Map<String, dynamic> json,
) => ProvisioningHandshake(
  code: json['code'] as String,
  roomID: json['roomID'] as String,
  roomName: json['roomName'] as String,
  orgID: json['orgID'] as String,
  orgName: json['orgName'] as String,
  expiresAt: DateTime.parse(json['expiresAt'] as String),
);

Map<String, dynamic> _$ProvisioningHandshakeToJson(
  ProvisioningHandshake instance,
) => <String, dynamic>{
  'code': instance.code,
  'roomID': instance.roomID,
  'roomName': instance.roomName,
  'orgID': instance.orgID,
  'orgName': instance.orgName,
  'expiresAt': instance.expiresAt.toIso8601String(),
};
