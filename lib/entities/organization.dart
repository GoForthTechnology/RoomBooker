import 'package:json_annotation/json_annotation.dart';

part 'organization.g.dart';

@JsonSerializable(explicitToJson: true)
class Organization {
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? id;
  final String name;
  final String ownerID;

  Organization({required this.name, required this.ownerID, this.id});

  Organization copyWith({String? id}) {
    return Organization(name: name, ownerID: ownerID, id: this.id ?? id);
  }

  factory Organization.fromJson(Map<String, dynamic> json) =>
      _$OrganizationFromJson(json);
  Map<String, dynamic> toJson() => _$OrganizationToJson(this);
}
