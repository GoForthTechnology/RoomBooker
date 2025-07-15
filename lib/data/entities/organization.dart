import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:room_booker/ui/core/room_colors.dart';

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
  final String? globalRoomID;
  final bool acceptingAdminRequests;
  final bool? publiclyVisible;
  final NotificationSettings? notificationSettings;

  Organization({
    required this.name,
    required this.ownerID,
    required this.acceptingAdminRequests,
    this.globalRoomID,
    this.id,
    this.notificationSettings,
    this.publiclyVisible,
  });

  String? emailForNotification(NotificationEvent event) {
    if (notificationSettings == null) {
      return null;
    }
    return notificationSettings!.notificationTargets[event];
  }

  Organization copyWith({
    String? id,
    bool? acceptingAdminRequests,
    bool? publiclyVisible,
  }) {
    return Organization(
      name: name,
      ownerID: ownerID,
      acceptingAdminRequests:
          acceptingAdminRequests ?? this.acceptingAdminRequests,
      id: this.id ?? id,
      globalRoomID: globalRoomID,
      notificationSettings: notificationSettings,
      publiclyVisible: publiclyVisible ?? this.publiclyVisible,
    );
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
  final String? colorHex;
  final int? orderKey;

  Room({required this.name, this.id, this.colorHex, this.orderKey});

  Color get color {
    return fromHex(colorHex) ?? Colors.black;
  }

  Room copyWith({String? id, String? name, String? colorHex, int? order}) {
    return Room(
        name: name ?? this.name,
        id: id ?? this.id,
        colorHex: colorHex ?? this.colorHex,
        orderKey: order ?? orderKey);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Room &&
        other.id == id &&
        other.name == name &&
        other.colorHex == colorHex;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ colorHex.hashCode;

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);
  Map<String, dynamic> toJson() => _$RoomToJson(this);
}
