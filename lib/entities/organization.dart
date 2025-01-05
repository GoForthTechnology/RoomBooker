import 'package:json_annotation/json_annotation.dart';

part 'organization.g.dart';

@JsonSerializable(explicitToJson: true)
class Organization {
  final String name;
  final String ownerID;

  Organization(this.ownerID, {required this.name});

  factory Organization.fromJson(Map<String, dynamic> json) =>
      _$OrganizationFromJson(json);
  Map<String, dynamic> toJson() => _$OrganizationToJson(this);
}
