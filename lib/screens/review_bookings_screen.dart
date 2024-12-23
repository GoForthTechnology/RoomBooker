import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/repos/booking_repo.dart';
import 'package:room_booker/widgets/readonly_calendar_widget.dart';

@RoutePage()
class ReviewBookingsScreen extends StatelessWidget {
  const ReviewBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Booking Request'),
      ),
      body: const Center(
        child: SingleChildScrollView(child: ReviewBookingsCalendar()),
      ),
    );
  }
}

class ReviewBookingsCalendar extends StatelessWidget {
  const ReviewBookingsCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingRepo>(
        builder: (context, repo, child) => SizedBox(
              height: 1100,
              child: Card(
                  child: ReadOnlyCalendarWidget(
                bookings: repo.requests,
                onAppointmentChanged: (a) {},
              )),
            ));
  }
}
