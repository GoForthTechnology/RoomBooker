// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Organization _$OrganizationFromJson(Map<String, dynamic> json) => Organization(
      name: json['name'] as String,
      ownerID: json['ownerID'] as String,
    );

Map<String, dynamic> _$OrganizationToJson(Organization instance) =>
    <String, dynamic>{
      'name': instance.name,
      'ownerID': instance.ownerID,
    };
