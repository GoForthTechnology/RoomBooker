import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/booking.dart';
import 'package:room_booker/repos/booking_repo.dart';

class PendingBookings extends StatelessWidget {
  final Function(Booking) onFocusBooking;

  const PendingBookings({super.key, required this.onFocusBooking});

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingRepo>(
      builder: (context, repo, child) => StreamBuilder(
        stream: repo.requests,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }
          return Expanded(
              child: BookingList(
            bookings: snapshot.data!,
            onFocusBooking: onFocusBooking,
          ));
        },
      ),
    );
  }
}

class BookingList extends StatelessWidget {
  final Function(Booking) onFocusBooking;
  final List<Booking> bookings;

  const BookingList(
      {super.key, required this.bookings, required this.onFocusBooking});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return BookingTile(
          booking: bookings[index],
          onFocusBooking: onFocusBooking,
        );
      },
    );
  }
}

class BookingTile extends StatelessWidget {
  final Function(Booking) onFocusBooking;
  final Booking booking;

  const BookingTile(
      {super.key, required this.onFocusBooking, required this.booking});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(bookingTitle(booking)),
      subtitle: Text(bookingSubtitle(booking)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => onFocusBooking(booking),
            child: const Text('Approve'),
          ),
          ElevatedButton(
            onPressed: () => onFocusBooking(booking),
            child: const Text('Reject'),
          )
        ],
      ),
      expandedAlignment: Alignment.topLeft,
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            detailTable(booking),
            Column(
              children: [
                ElevatedButton(
                    onPressed: () => onFocusBooking(booking),
                    child: const Text("Toggle Calendar")),
              ],
            )
          ],
        )
      ],
    );
  }
}

Table detailTable(Booking booking) {
  return Table(
    defaultColumnWidth: const FixedColumnWidth(200),
    children: [
      bookingField('Attendance', booking.attendance.toString()),
      bookingField('Phone', booking.phone),
      bookingField('Email', booking.email),
      bookingField('Start Time',
          "${formatDate(booking.eventStartTime)} ${formatTime(booking.eventStartTime)}"),
      bookingField('End Time',
          "${formatDate(booking.eventEndTime)} ${formatTime(booking.eventEndTime)}"),
    ],
  );
}

TableRow bookingField(String label, String value) {
  return TableRow(children: [
    TableCell(
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    ),
    TableCell(
      child: Text(value),
    ),
  ]);
}

String bookingTitle(Booking booking) {
  return '${booking.eventName} for ${booking.name}';
}

String bookingSubtitle(Booking booking) {
  return '${booking.selectedRoom} on ${formatDate(booking.eventStartTime)} from ${formatTime(booking.eventStartTime)} to ${formatTime(booking.eventEndTime)}';
}

String formatDate(DateTime dateTime) {
  return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
}

String formatTime(DateTime dateTime) {
  return '${dateTime.hour}:${dateTime.minute}';
}
