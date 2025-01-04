import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
          actions: _actions(context)),
      body: const CurrentBookingsCalendar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AutoRouter.of(context).push(NewBookingRoute()),
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Widget> _actions(BuildContext context) {
    if (FirebaseAuth.instance.currentUser != null) {
      return [
        IconButton(
          icon: const Icon(Icons.approval_rounded),
          onPressed: () =>
              AutoRouter.of(context).push(const ReviewBookingsRoute()),
        ),
      ];
    }
    return [
      IconButton(
        icon: const Icon(Icons.login),
        onPressed: () => AutoRouter.of(context).push(const LoginRoute()),
      )
    ];
  }
}
