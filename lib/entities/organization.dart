import 'package:json_annotation/json_annotation.dart';

part 'organization.g.dart';

@JsonSerializable(explicitToJson: true)
class AdminEntry {
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? id;
  final String email;
  final DateTime lastUpdated;

  AdminEntry({this.id, required this.email, required this.lastUpdated});

  AdminEntry copyWith({String? id}) {
    return AdminEntry(
      email: email,
      lastUpdated: lastUpdated,
      id: this.id ?? id,
    );
  }

  factory AdminEntry.fromJson(Map<String, dynamic> json) =>
      _$AdminEntryFromJson(json);
  Map<String, dynamic> toJson() => _$AdminEntryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Organization {
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? id;
  final String name;
  final String ownerID;
  final List<Room> rooms;
  final bool acceptingAdminRequests;

  Organization({
    required this.name,
    required this.ownerID,
    required this.rooms,
    required this.acceptingAdminRequests,
    this.id,
  });

  Organization copyWith({String? id, bool? acceptingAdminRequests}) {
    return Organization(
      name: name,
      ownerID: ownerID,
      rooms: rooms,
      acceptingAdminRequests:
          acceptingAdminRequests ?? this.acceptingAdminRequests,
      id: this.id ?? id,
    );
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
