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
      rooms: (json['rooms'] as List<dynamic>)
          .map((e) => Room.fromJson(e as Map<String, dynamic>))
          .toList(),
      acceptingAdminRequests: json['acceptingAdminRequests'] as bool,
    );

Map<String, dynamic> _$OrganizationToJson(Organization instance) =>
    <String, dynamic>{
      'name': instance.name,
      'ownerID': instance.ownerID,
      'rooms': instance.rooms.map((e) => e.toJson()).toList(),
      'acceptingAdminRequests': instance.acceptingAdminRequests,
    };

Room _$RoomFromJson(Map<String, dynamic> json) => Room(
      name: json['name'] as String,
    );

Map<String, dynamic> _$RoomToJson(Room instance) => <String, dynamic>{
      'name': instance.name,
    };
