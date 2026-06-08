import 'package:json_annotation/json_annotation.dart';

part 'kiosk_identity.g.dart';

@JsonSerializable(explicitToJson: true)
class KioskIdentity {
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? id;
  final String deviceId;
  final String roomID;
  final String orgID;
  final DateTime lastSeen;

  KioskIdentity({
    this.id,
    required this.deviceId,
    required this.roomID,
    required this.orgID,
    required this.lastSeen,
  });

  factory KioskIdentity.fromJson(Map<String, dynamic> json) =>
      _$KioskIdentityFromJson(json);
  Map<String, dynamic> toJson() => _$KioskIdentityToJson(this);

  KioskIdentity copyWith({
    String? id,
    String? deviceId,
    String? roomID,
    String? orgID,
    DateTime? lastSeen,
  }) {
    return KioskIdentity(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      roomID: roomID ?? this.roomID,
      orgID: orgID ?? this.orgID,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
