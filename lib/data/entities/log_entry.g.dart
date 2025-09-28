// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestLogEntry _$RequestLogEntryFromJson(Map<String, dynamic> json) =>
    RequestLogEntry(
      requestID: json['requestID'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      action: $enumDecode(_$ActionEnumMap, json['action']),
      adminEmail: json['adminEmail'] as String?,
      before: json['before'] == null
          ? null
          : Request.fromJson(json['before'] as Map<String, dynamic>),
      after: json['after'] == null
          ? null
          : Request.fromJson(json['after'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RequestLogEntryToJson(RequestLogEntry instance) =>
    <String, dynamic>{
      'requestID': instance.requestID,
      'timestamp': instance.timestamp.toIso8601String(),
      'adminEmail': instance.adminEmail,
      'action': _$ActionEnumMap[instance.action]!,
      'before': instance.before?.toJson(),
      'after': instance.after?.toJson(),
    };

const _$ActionEnumMap = {
  Action.create: 'create',
  Action.request: 'request',
  Action.approve: 'approve',
  Action.reject: 'reject',
  Action.revisit: 'revisit',
  Action.endRecurring: 'endRecurring',
  Action.ignoreOverlaps: 'ignoreOverlaps',
  Action.update: 'update',
  Action.delete: 'delete',
};
