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
          return BookingList(
            bookings: snapshot.data!,
            onFocusBooking: onFocusBooking,
          );
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
        final booking = bookings[index];
        return ListTile(
          title: Text(bookingTitle(booking)),
          subtitle: Text(bookingSubtitle(booking)),
          trailing: ElevatedButton(
            onPressed: () => onFocusBooking(booking),
            child: const Text('View'),
          ),
        );
      },
    );
  }
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
