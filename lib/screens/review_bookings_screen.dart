import 'package:auto_route/auto_route.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:room_booker/widgets/heading.dart';
import 'package:room_booker/widgets/booking_lists.dart';

@RoutePage()
class ReviewBookingsScreen extends StatelessWidget {
  final String orgID;

  const ReviewBookingsScreen(
      {super.key, @PathParam("orgID") required this.orgID});

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.logScreenView(
        screenName: "Review Bookings", parameters: {"orgID": orgID});
    var repo = Provider.of<OrgRepo>(context, listen: false);
    return Scaffold(
        appBar: AppBar(
          title: const Text('Booking Requests'),
        ),
        body: SingleChildScrollView(
            child: Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
              const Heading("Pending"),
              PendingBookings(
                repo: repo,
                onFocusBooking: (r) {},
                orgID: orgID,
              ),
              const Heading("Confirmed"),
              const Subheading("One-offs"),
              ConfirmedOneOffBookings(
                repo: repo,
                onFocusBooking: (r) {},
                orgID: orgID,
              ),
              const Subheading("Recurring"),
              ConfirmedRepeatingBookings(
                repo: repo,
                onFocusBooking: (r) {},
                orgID: orgID,
              ),
              const Heading("Denied"),
              RejectedBookings(
                repo: repo,
                onFocusBooking: (r) {},
                orgID: orgID,
              ),
            ]))));
  }
}

DateTime stripTime(DateTime time) {
  return DateTime(time.year, time.month, time.day);
}
