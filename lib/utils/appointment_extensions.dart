import 'dart:ui';

import 'package:syncfusion_flutter_calendar/calendar.dart';

extension AppointmentCopyWith on Appointment {
  Appointment copyWith({
    DateTime? startTime,
    DateTime? endTime,
    String? subject,
    Color? color,
  }) {
    return Appointment(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      subject: subject ?? this.subject,
      color: color ?? this.color,
    );
  }
}
