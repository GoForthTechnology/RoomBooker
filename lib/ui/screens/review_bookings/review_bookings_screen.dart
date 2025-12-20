import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/analytics_service.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/ui/widgets/booking_list/confirmed_bookings.dart';
import 'package:room_booker/ui/widgets/booking_list/conflicting_bookings.dart';
import 'package:room_booker/ui/widgets/heading.dart';
import 'package:room_booker/ui/widgets/booking_list/pending_bookings.dart';
import 'package:room_booker/ui/widgets/booking_list/rejected_bookings.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';
import 'package:room_booker/ui/widgets/booking_list/booking_filter_view_model.dart';

@RoutePage()
class ReviewBookingsScreen extends StatefulWidget {
  final String orgID;

  const ReviewBookingsScreen({
    super.key,
    @PathParam("orgID") required this.orgID,
  });

  @override
  State<ReviewBookingsScreen> createState() => _ReviewBookingsScreenState();
}

class _ReviewBookingsScreenState extends State<ReviewBookingsScreen> {
  final TextEditingController searchBarController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Provider.of<AnalyticsService>(context, listen: false).logScreenView(
      screenName: "Review Bookings",
      parameters: {"orgID": widget.orgID},
    );
    var bookingRepo = Provider.of<BookingRepo>(context, listen: false);
    var orgRepo = Provider.of<OrgRepo>(context, listen: false);
    return StreamBuilder(
      stream: orgRepo.getOrg(widget.orgID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          log(snapshot.error.toString(), error: snapshot.error);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: ${snapshot.error}')));
          });
          return const Placeholder();
        }
        if (!snapshot.hasData) {
          return Container();
        }
        var org = snapshot.data;
        return RoomStateProvider(
          enableAllRooms: true,
          org: org!,
          builder: (context, child) => Consumer<RoomState>(
            builder: (context, roomState, child) {
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
                body: ChangeNotifierProvider(
                  create: (context) => BookingFilterViewModel(),
                  child: Consumer<BookingFilterViewModel>(
                    builder: (context, viewModel, child) =>
                        SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SearchBar(
                                leading: Icon(Icons.search),
                                hintText: "Search",
                                controller: searchBarController,
                                onChanged: (v) =>
                                    viewModel.updateSearchQuery(v),
                                trailing: [
                                  IconButton(
                                    icon: Icon(Icons.clear),
                                    onPressed: () {
                                      searchBarController.text = "";
                                      viewModel.updateSearchQuery("");
                                    },
                                  ),
                                ],
                              ),
                              const Heading("Pending"),
                              PendingBookings(
                                repo: bookingRepo,
                                orgID: widget.orgID,
                              ),
                              const Heading("Conflicts"),
                              ConflictingBookings(
                                repo: bookingRepo,
                                orgID: widget.orgID,
                              ),
                              const Heading("Confirmed"),
                              const Subheading("One-offs"),
                              ConfirmedOneOffBookings(
                                repo: bookingRepo,
                                orgID: widget.orgID,
                              ),
                              const Subheading("Recurring"),
                              ConfirmedRepeatingBookings(
                                repo: bookingRepo,
                                orgID: widget.orgID,
                              ),
                              const Heading("Denied"),
                              RejectedBookings(
                                repo: bookingRepo,
                                orgID: widget.orgID,
                              ),
                            ],
                          ),
                        ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

DateTime stripTime(DateTime time) {
  return DateTime(time.year, time.month, time.day);
}
