import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/widgets/current_bookings_calendar.dart';

@RoutePage()
class ViewBookingsScreen extends StatelessWidget {
  final String orgID;

  const ViewBookingsScreen(
      {super.key, @PathParam('orgID') required this.orgID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Room Bookings for Church of the Resurrection"),
          actions: _actions(context)),
      body: CurrentBookingsCalendar(orgID: orgID),
    );
  }

  List<Widget> _actions(BuildContext context) {
    if (FirebaseAuth.instance.currentUser != null) {
      return [
        IconButton(
          icon: const Icon(Icons.approval_rounded),
          onPressed: () =>
              AutoRouter.of(context).push(ReviewBookingsRoute(orgID: orgID)),
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
