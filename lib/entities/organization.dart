import 'package:json_annotation/json_annotation.dart';

part 'organization.g.dart';

@JsonSerializable(explicitToJson: true)
class Organization {
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? id;
  final String name;
  final String ownerID;
  final List<Room> rooms;

  Organization(
      {required this.name,
      required this.ownerID,
      this.id,
      required this.rooms});

  Organization copyWith({String? id}) {
    return Organization(
        name: name, ownerID: ownerID, rooms: rooms, id: this.id ?? id);
  }

  factory Organization.fromJson(Map<String, dynamic> json) =>
      _$OrganizationFromJson(json);
  Map<String, dynamic> toJson() => _$OrganizationToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Room {
  final String name;

  Room({required this.name});

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);
  Map<String, dynamic> toJson() => _$RoomToJson(this);
}
