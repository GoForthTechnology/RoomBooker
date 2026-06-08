import 'package:json_annotation/json_annotation.dart';

part 'provisioning_handshake.g.dart';

@JsonSerializable(explicitToJson: true)
class ProvisioningHandshake {
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? id;
  final String code;
  final String roomID;
  final String roomName;
  final String orgID;
  final String orgName;
  final DateTime expiresAt;

  ProvisioningHandshake({
    this.id,
    required this.code,
    required this.roomID,
    required this.roomName,
    required this.orgID,
    required this.orgName,
    required this.expiresAt,
  });

  factory ProvisioningHandshake.fromJson(Map<String, dynamic> json) =>
      _$ProvisioningHandshakeFromJson(json);
  Map<String, dynamic> toJson() => _$ProvisioningHandshakeToJson(this);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
