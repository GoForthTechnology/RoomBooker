import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/router.dart';
import 'package:rxdart/rxdart.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

@RoutePage()
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.logScreenView(screenName: "Landing");
    var orgRepo = Provider.of<OrgRepo>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Room Booker"),
        actions: [
          AuthAction(isSignedIn: FirebaseAuth.instance.currentUser != null),
        ],
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            YourOrgs(
                orgRepo: orgRepo,
                isLoggedIn: FirebaseAuth.instance.currentUser != null),
            Heading("All Organizations"),
            OrgList(orgStream: orgRepo.getOrgs(excludeOwned: true)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var repo = Provider.of<OrgRepo>(context, listen: false);
          var name = await promptForOrgName(context);
          if (name != null) {
            await repo.addOrgForCurrentUser(name);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class YourOrgs extends StatelessWidget {
  final OrgRepo orgRepo;
  final bool isLoggedIn;

  const YourOrgs({super.key, required this.orgRepo, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return Container();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Heading("Your Organizations"),
        OrgList(
          orgStream: orgRepo.getOrgsForCurrentUser(),
        ),
      ],
    );
  }
}

class Heading extends StatelessWidget {
  final String text;

  const Heading(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 16, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class AuthAction extends StatelessWidget {
  final bool isSignedIn;

  const AuthAction({super.key, required this.isSignedIn});

  @override
  Widget build(BuildContext context) {
    if (isSignedIn) {
      return Tooltip(
        message: "Sign out",
        child: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            FirebaseAuth.instance.signOut();
            AutoRouter.of(context).replace(LoginRoute());
          },
        ),
      );
    } else {
      return Tooltip(
        message: "Sign in",
        child: IconButton(
          icon: const Icon(Icons.login),
          onPressed: () {
            AutoRouter.of(context).replace(LoginRoute());
          },
        ),
      );
    }
  }
}

class OrgList extends StatelessWidget {
  final Stream<List<Organization>> orgStream;
  const OrgList({super.key, required this.orgStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: orgStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          log(snapshot.error.toString(), error: snapshot.error);
          return const Text('Error loading organizations');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        var orgs = snapshot.data!;
        if (orgs.isEmpty) {
          return const Text('No organizations found. Please add one.');
        }
        return ListView.builder(
          shrinkWrap: true,
          itemCount: orgs.length,
          itemBuilder: (context, index) {
            return OrgTile(org: orgs[index]);
          },
        );
      },
    );
  }
}

class CardState {
  final int numPendingBookings;
  final int numPendingAdminRequests;

  CardState(
      {required this.numPendingBookings,
      required this.numPendingAdminRequests});

  static Stream<CardState> stream(
      BookingRepo bookingRepo, OrgRepo orgRepo, String orgID) {
    return Rx.combineLatest2(
      bookingRepo.listRequests(
          orgID: orgID,
          startTime: DateTime.now(),
          endTime: DateTime.now().add(Duration(days: 365)),
          includeStatuses: {RequestStatus.pending}),
      orgRepo.adminRequests(orgID),
      (pendingRequests, adminRequests) => CardState(
          numPendingBookings: pendingRequests.length,
          numPendingAdminRequests: adminRequests.length),
    );
  }
}

class OrgTile extends StatelessWidget {
  final Organization org;

  const OrgTile({super.key, required this.org});

  @override
  Widget build(BuildContext context) {
    var orgRepo = Provider.of<OrgRepo>(context, listen: false);
    var bookingRepo = Provider.of<BookingRepo>(context, listen: false);
    return Card(
      elevation: 1,
      child: StreamBuilder(
        stream: CardState.stream(bookingRepo, orgRepo, org.id!),
        builder: (context, snapshot) {
          String? subtitle;
          if (snapshot.hasData) {
            var state = snapshot.data!;
            subtitle = "${state.numPendingBookings} pending bookings";
            if (state.numPendingAdminRequests > 0) {
              subtitle += ", ${state.numPendingAdminRequests} admin requests";
            }
          }
          return ListTile(
            leading: const Icon(Icons.business),
            title: Text(org.name),
            subtitle: subtitle != null ? Text(subtitle) : null,
            onTap: () => AutoRouter.of(context).push(ViewBookingsRoute(
                orgID: org.id!, view: CalendarView.month.name)),
          );
        },
      ),
    );
  }
}

Future<String?> promptForOrgName(BuildContext context) async {
  var controller = TextEditingController();
  var name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
            title: const Text('Create New Organization'),
            content: TextFormField(
              autofocus: true,
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter the name of your organization',
              ),
              onFieldSubmitted: (value) {
                Navigator.of(context).pop(value);
              },
              textInputAction: TextInputAction.search,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: const Text('OK'),
              ),
            ],
          ));
  return name;
}
