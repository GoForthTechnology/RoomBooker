import 'package:flutter/services.dart';

class MeetingOrchestrator {
  static const platform = MethodChannel('org.goforthtech.roombooker_kiosk/automation');

  Future<void> launchMeetingOnStage(String url, int? displayId) async {
    await platform.invokeMethod('launchMeeting', {
      'url': url,
      'displayId': displayId,
    });
  }
}
