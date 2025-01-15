import 'package:room_booker/entities/booking.dart';

class BlackoutWindow {
  final DateTime start;
  final DateTime end;
  final String? recurrenceRule;
  final String reason;

  BlackoutWindow(
      {required this.start,
      required this.end,
      this.recurrenceRule,
      required this.reason});

  static BlackoutWindow fromBooking(Booking booking) {
    return BlackoutWindow(
      start: booking.startTime,
      end: booking.endTime,
      reason: 'Busy',
    );
  }
}
