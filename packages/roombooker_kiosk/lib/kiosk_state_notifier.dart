import 'package:flutter/material.dart';

enum RoomStatus { available, busy, transitioning }

class KioskState {
  final RoomStatus status;
  final String? currentMeetingTitle;
  final DateTime? meetingEndTime;

  KioskState({
    required this.status,
    this.currentMeetingTitle,
    this.meetingEndTime,
  });

  Map<String, dynamic> toJson() => {
    'status': status.index,
    'currentMeetingTitle': currentMeetingTitle,
    'meetingEndTime': meetingEndTime?.millisecondsSinceEpoch,
  };

  factory KioskState.fromJson(Map<String, dynamic> json) => KioskState(
    status: RoomStatus.values[json['status']],
    currentMeetingTitle: json['currentMeetingTitle'],
    meetingEndTime: json['meetingEndTime'] != null 
      ? DateTime.fromMillisecondsSinceEpoch(json['meetingEndTime']) 
      : null,
  );
}

class KioskStateNotifier extends ChangeNotifier {
  KioskState _state = KioskState(status: RoomStatus.available);
  KioskState get state => _state;

  void updateState(KioskState newState) {
    _state = newState;
    notifyListeners();
    // In a real implementation, we would send this data to the secondary display
    // via a platform channel if they were in the same process, but here they are isolates.
  }
}
