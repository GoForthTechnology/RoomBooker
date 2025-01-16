import 'package:flutter/material.dart';
import 'package:room_booker/entities/request.dart';
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

  Request toBooking(RequestStatus status) {
    return Request(
      eventName: subject,
      eventStartTime: startTime,
      eventEndTime: endTime,
      name: '',
      email: '',
      message: '',
      phone: '',
      selectedRoom: '',
      status: status,
    );
  }

  static Appointment fromBooking(Request booking) {
    return Appointment(
      startTime: booking.eventStartTime,
      endTime: booking.eventEndTime,
      subject: booking.eventName,
      color: Colors.blue,
    );
  }
}
