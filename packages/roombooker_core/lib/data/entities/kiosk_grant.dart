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
