import 'package:flutter/material.dart';
import 'package:room_booker/entities/booking.dart';
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

  Booking toBooking(BookingStatus status) {
    return Booking(
      eventName: subject,
      eventStartTime: startTime,
      eventEndTime: endTime,
      name: '',
      email: '',
      message: '',
      phone: '',
      attendance: 0,
      doorUnlockTime: startTime,
      doorLockTime: endTime,
      selectedRoom: '',
      status: status,
    );
  }

  static Appointment fromBooking(Booking booking) {
    return Appointment(
      startTime: booking.eventStartTime,
      endTime: booking.eventEndTime,
      subject: booking.eventName,
      color: Colors.blue,
    );
  }
}
