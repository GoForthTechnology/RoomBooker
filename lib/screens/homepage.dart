import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/widgets/current_bookings_calendar.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Room Bookings for Church of the Resurrection"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () =>
                AutoRouter.of(context).push(const NewBookingRoute()),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle),
            onPressed: () =>
                AutoRouter.of(context).push(const ReviewBookingsRoute()),
          ),
        ],
      ),
      body: CurrentBookingsCalendar(),
    );
  }
}
