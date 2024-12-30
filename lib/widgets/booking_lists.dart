import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/booking.dart';
import 'package:room_booker/repos/booking_repo.dart';
import 'package:rxdart/rxdart.dart';

class ResolvedBookings extends StatelessWidget {
  final Function(Booking) onFocusBooking;

  const ResolvedBookings({super.key, required this.onFocusBooking});

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingRepo>(
      builder: (context, repo, child) => StreamBuilder(
        stream: Rx.combineLatest2(repo.deniedRequests, repo.bookings,
            (denied, confirmed) => denied + confirmed),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }
          List<Booking> bookings = snapshot.data!;
          bookings.sort((a, b) => a.eventStartTime.compareTo(b.eventStartTime));
          return ListView.builder(
            shrinkWrap: true,
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return ResolvedBookingTitle(
                booking: bookings[index],
                onFocusBooking: onFocusBooking,
              );
            },
          );
        },
      ),
    );
  }
}

class ResolvedBookingTitle extends StatelessWidget {
  final Function(Booking) onFocusBooking;
  final Booking booking;

  const ResolvedBookingTitle(
      {super.key, required this.onFocusBooking, required this.booking});

  @override
  Widget build(BuildContext context) {
    bool confirmed = booking.status == BookingStatus.confirmed;
    String trailingText = confirmed ? 'CONFIRMED' : 'DENIED';
    return Card(
        elevation: 1,
        color: confirmed
            ? const Color.fromRGBO(220, 233, 213, 1.0)
            : const Color.fromRGBO(238, 205, 205, 1.0),
        child: ExpansionTile(
          title: Text(bookingTitle(booking)),
          leading: Icon(
            Icons.event,
            color: confirmed
                ? const Color.fromRGBO(120, 166, 90, 1.0)
                : const Color.fromRGBO(187, 39, 26, 1.0),
          ),
          subtitle: Text(bookingSubtitle(booking)),
          trailing: Text(trailingText),
          expandedAlignment: Alignment.topLeft,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<BookingRepo>(
                builder: (context, repo, child) => Row(
                      children: [
                        detailTable(booking),
                        Column(
                          children: [
                            ElevatedButton(
                                onPressed: () => onFocusBooking(booking),
                                child: const Text("Toggle Calendar")),
                            ElevatedButton(
                                onPressed: () => repo.revisitRequest(booking),
                                child: const Text("Revisit")),
                          ],
                        )
                      ],
                    ))
          ],
        ));
  }
}

class PendingBookings extends StatelessWidget {
  final Function(Booking) onFocusBooking;

  const PendingBookings({super.key, required this.onFocusBooking});

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingRepo>(
      builder: (context, repo, child) => StreamBuilder(
        stream: repo.pendingRequests,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }
          List<Booking> bookings = snapshot.data!;
          bookings.sort((a, b) => a.eventStartTime.compareTo(b.eventStartTime));
          return ListView.builder(
            shrinkWrap: true,
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return PendingBookingTile(
                booking: bookings[index],
                onFocusBooking: onFocusBooking,
              );
            },
          );
        },
      ),
    );
  }
}

class PendingBookingTile extends StatelessWidget {
  final Function(Booking) onFocusBooking;
  final Booking booking;

  const PendingBookingTile(
      {super.key, required this.onFocusBooking, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 1,
        child: ExpansionTile(
          leading: const Icon(Icons.event),
          title: Text(bookingTitle(booking)),
          subtitle: Text(bookingSubtitle(booking)),
          trailing: Consumer<BookingRepo>(
              builder: (context, repo, child) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => repo.confirmRequest(booking),
                        child: const Text('Approve'),
                      ),
                      ElevatedButton(
                        onPressed: () => repo.denyRequest(booking),
                        child: const Text('Reject'),
                      )
                    ],
                  )),
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
        ));
  }
}

Widget detailTable(Booking booking) {
  return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Table(
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
      ));
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
