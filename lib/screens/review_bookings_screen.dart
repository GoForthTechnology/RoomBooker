import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/widgets/pending_bookings.dart';

@RoutePage()
class ReviewBookingsScreen extends StatelessWidget {
  const ReviewBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Bookings to Review'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Expanded(child: PendingBookings(onFocusBooking: (b) {})),
            ],
          ),
        ));
  }
}
