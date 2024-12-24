import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/repos/booking_repo.dart';
import 'package:room_booker/widgets/review_booking_calendar.dart';

@RoutePage()
class ReviewBookingsScreen extends StatelessWidget {
  const ReviewBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Booking Request'),
      ),
      body: Center(
        child: SingleChildScrollView(
            child: Column(
          children: [
            ReviewBookingsCalendar(
              onAppointmentChanged: (appointment) {},
              bookings: const Stream.empty(),
            )
          ],
        )),
      ),
    );
  }
}
