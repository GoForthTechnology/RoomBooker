import 'package:room_booker/data/entities/request.dart';

class BlackoutWindow {
  final DateTime start;
  final DateTime end;
  final String? recurrenceRule;
  final String reason;

  const BlackoutWindow(
      {required this.start,
      required this.end,
      this.recurrenceRule,
      required this.reason});

  static BlackoutWindow fromRequest(Request request) {
    return BlackoutWindow(
      start: request.eventStartTime,
      end: request.eventEndTime,
      reason: request.publicName ?? "Blackout Window",
    );
  }
}
