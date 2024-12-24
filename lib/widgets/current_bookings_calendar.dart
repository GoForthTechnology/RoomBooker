import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/booking.dart';
import 'package:room_booker/repos/booking_repo.dart';
import 'package:room_booker/widgets/readonly_calendar.dart';

class CurrentBookingsCalendar extends StatelessWidget {
  const CurrentBookingsCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingRepo>(
      builder: (context, repo, child) => ReadonlyCalendar(
        bookings: repo.requests,
        onTapBooking: (booking) {
          _showBookingSummaryDialog(context, booking);
        },
      ),
    );
  }

  void _showBookingSummaryDialog(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Booking Summary'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Name: ${booking.name}'),
                Text('Email: ${booking.email}'),
                Text('Phone: ${booking.phone}'),
                Text('Event Name: ${booking.eventName}'),
                Text('Event Start Time: ${booking.eventStartTime}'),
                Text('Event End Time: ${booking.eventEndTime}'),
                Text('Event Attendance: ${booking.attendance}'),
                Text('Event Location: ${booking.selectedRoom}'),
                Text('Notes: ${booking.message}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
