// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminEntry _$AdminEntryFromJson(Map<String, dynamic> json) => AdminEntry(
      email: json['email'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$AdminEntryToJson(AdminEntry instance) =>
    <String, dynamic>{
      'email': instance.email,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };

Organization _$OrganizationFromJson(Map<String, dynamic> json) => Organization(
      name: json['name'] as String,
      ownerID: json['ownerID'] as String,
      acceptingAdminRequests: json['acceptingAdminRequests'] as bool,
      globalRoomID: json['globalRoomID'] as String?,
      notificationSettings: json['notificationSettings'] == null
          ? null
          : NotificationSettings.fromJson(
              json['notificationSettings'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OrganizationToJson(Organization instance) =>
    <String, dynamic>{
      'name': instance.name,
      'ownerID': instance.ownerID,
      'globalRoomID': instance.globalRoomID,
      'acceptingAdminRequests': instance.acceptingAdminRequests,
      'notificationSettings': instance.notificationSettings?.toJson(),
    };

NotificationSettings _$NotificationSettingsFromJson(
        Map<String, dynamic> json) =>
    NotificationSettings(
      notificationTargets:
          (json['notificationTargets'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry($enumDecode(_$NotificationEventEnumMap, k), e as String),
      ),
    );

Map<String, dynamic> _$NotificationSettingsToJson(
        NotificationSettings instance) =>
    <String, dynamic>{
      'notificationTargets': instance.notificationTargets
          .map((k, e) => MapEntry(_$NotificationEventEnumMap[k]!, e)),
    };

const _$NotificationEventEnumMap = {
  NotificationEvent.bookingCreated: 'bookingCreated',
  NotificationEvent.bookingApproved: 'bookingApproved',
  NotificationEvent.bookingRejected: 'bookingRejected',
  NotificationEvent.adminRequestCreated: 'adminRequestCreated',
  NotificationEvent.adminRequestApproved: 'adminRequestApproved',
  NotificationEvent.adminRequestRejected: 'adminRequestRejected',
};

Room _$RoomFromJson(Map<String, dynamic> json) => Room(
      name: json['name'] as String,
      colorHex: json['colorHex'] as String?,
    );

Map<String, dynamic> _$RoomToJson(Room instance) => <String, dynamic>{
      'name': instance.name,
      'colorHex': instance.colorHex,
    };
