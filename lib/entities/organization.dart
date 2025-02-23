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
  final bool acceptingAdminRequests;
  final NotificationSettings? notificationSettings;

  Organization({
    required this.name,
    required this.ownerID,
    required this.acceptingAdminRequests,
    this.id,
    this.notificationSettings,
  });

  String? emailForNotification(NotificationEvent event) {
    if (notificationSettings == null) {
      return null;
    }
    return notificationSettings!.notificationTargets[event];
  }

  Organization copyWith({String? id, bool? acceptingAdminRequests}) {
    return Organization(
        name: name,
        ownerID: ownerID,
        acceptingAdminRequests:
            acceptingAdminRequests ?? this.acceptingAdminRequests,
        id: this.id ?? id,
        notificationSettings: notificationSettings);
  }

  factory Organization.fromJson(Map<String, dynamic> json) =>
      _$OrganizationFromJson(json);
  Map<String, dynamic> toJson() => _$OrganizationToJson(this);
}

enum NotificationEvent {
  bookingCreated,
  bookingApproved,
  bookingRejected,
  adminRequestCreated,
  adminRequestApproved,
  adminRequestRejected,
}

@JsonSerializable(explicitToJson: true)
class NotificationSettings {
  final Map<NotificationEvent, String> notificationTargets;

  NotificationSettings({required this.notificationTargets});

  static NotificationSettings defaultSettings(String defaultEmail) {
    return NotificationSettings(
      notificationTargets: {
        for (var event in NotificationEvent.values) event: defaultEmail,
      },
    );
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationSettingsToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Room {
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? id;
  final String name;

  Room({
    required this.name,
    this.id,
  });

  Room copyWith({String? id}) {
    return Room(
      name: name,
      id: this.id ?? id,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Room && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);
  Map<String, dynamic> toJson() => _$RoomToJson(this);
}
