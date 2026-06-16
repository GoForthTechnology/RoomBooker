/// A grant document from `kiosk-grants/{uid}` as read by an admin in the
/// Portal, containing the device's identity and provisioning timestamp.
class KioskGrantRecord {
  final String uid;
  final String? deviceID;
  final DateTime? createdAt;

  KioskGrantRecord({
    required this.uid,
    this.deviceID,
    this.createdAt,
  });
}

/// Result of a successful `claimKioskGrant` call: identifies the org/room
/// this Kiosk device is now authorized to access.
class KioskGrant {
  final String orgID;
  final String orgName;
  final String roomID;
  final String roomName;

  KioskGrant({
    required this.orgID,
    required this.orgName,
    required this.roomID,
    required this.roomName,
  });

  factory KioskGrant.fromJson(Map<String, dynamic> json) => KioskGrant(
        orgID: json['orgID'] as String,
        orgName: json['orgName'] as String,
        roomID: json['roomID'] as String,
        roomName: json['roomName'] as String,
      );
}
