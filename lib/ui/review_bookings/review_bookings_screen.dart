import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/ui/core/heading.dart';
import 'package:room_booker/ui/core/room_selector.dart';
import 'package:room_booker/ui/review_bookings/booking_lists.dart';

@RoutePage()
class ReviewBookingsScreen extends StatelessWidget {
  final String orgID;

  const ReviewBookingsScreen(
      {super.key, @PathParam("orgID") required this.orgID});

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.logScreenView(
        screenName: "Review Bookings", parameters: {"orgID": orgID});
    var bookingRepo = Provider.of<BookingRepo>(context, listen: false);
    var orgRepo = Provider.of<OrgRepo>(context, listen: false);
    return StreamBuilder(
      stream: orgRepo.getOrg(orgID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          log(snapshot.error.toString(), error: snapshot.error);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${snapshot.error}')),
            );
          });
          return const Placeholder();
        }
        if (!snapshot.hasData) {
          return Container();
        }
        var org = snapshot.data;
        return RoomStateProvider(
            org: org!,
            builder: (context, child) =>
                Consumer<RoomState>(builder: (context, roomState, child) {
                  roomState.activateAll();
                  return Scaffold(
                    appBar: AppBar(
                      title: Text('Booking Requests for ${org.name}'),
                      leading: BackButton(
                        onPressed: () {
                          var router = AutoRouter.of(context);
                          if (router.canPop()) {
                            router.pop();
                          } else {
                            router.replace(LandingRoute());
                          }
                        },
                      ),
                    ),
                    body: SingleChildScrollView(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                          RoomCardSelector(),
                          const Heading("Pending"),
                          PendingBookings(
                            repo: bookingRepo,
                            onFocusBooking: (r) {},
                            orgID: orgID,
                          ),
                          const Heading("Conflicts"),
                          ConflictingBookings(
                            repo: bookingRepo,
                            onFocusBooking: (r) {},
                            orgID: orgID,
                          ),
                          const Heading("Confirmed"),
                          const Subheading("One-offs"),
                          ConfirmedOneOffBookings(
                            repo: bookingRepo,
                            onFocusBooking: (r) {},
                            orgID: orgID,
                          ),
                          const Subheading("Recurring"),
                          ConfirmedRepeatingBookings(
                            repo: bookingRepo,
                            onFocusBooking: (r) {},
                            orgID: orgID,
                          ),
                          const Heading("Denied"),
                          RejectedBookings(
                            repo: bookingRepo,
                            onFocusBooking: (r) {},
                            orgID: orgID,
                          ),
                        ])),
                  );
                }));
      },
    );
  }
}

DateTime stripTime(DateTime time) {
  return DateTime(time.year, time.month, time.day);
}
