import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/organization.dart';
import 'package:room_booker/entities/request.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:room_booker/router.dart';
import 'package:rxdart/rxdart.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

@RoutePage()
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.logScreenView(screenName: "Landing");
    return Scaffold(
      appBar: AppBar(
        title: const Text("Room Booker"),
        actions: [
          IconButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                AutoRouter.of(context).replace(LoginRoute());
              },
              icon: const Icon(Icons.logout))
        ],
      ),
      body: const Center(child: OrgList()),
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

class OrgList extends StatelessWidget {
  const OrgList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrgRepo>(
      builder: (context, repo, child) => StreamBuilder(
        stream: repo.getOrgsForCurrentUser(),
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
            itemCount: orgs.length,
            itemBuilder: (context, index) {
              return OrgTile(org: orgs[index]);
            },
          );
        },
      ),
    );
  }
}

class CardState {
  final int numPendingBookings;
  final int numPendingAdminRequests;

  CardState(
      {required this.numPendingBookings,
      required this.numPendingAdminRequests});

  static Stream<CardState> stream(OrgRepo repo, String orgID) {
    return Rx.combineLatest2(
      repo.listRequests(
          orgID: orgID,
          startTime: DateTime.now(),
          endTime: DateTime.now().add(Duration(days: 365)),
          includeStatuses: {RequestStatus.pending}),
      repo.adminRequests(orgID),
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
    return Card(
      elevation: 1,
      child: StreamBuilder(
        stream: CardState.stream(orgRepo, org.id!),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _viewCalendarButton(context),
                _reviewButton(context),
                _scheduleButton(context),
                _settingsButton(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _viewCalendarButton(BuildContext context) {
    return Consumer<OrgRepo>(
      builder: (context, repo, child) => StreamBuilder(
          stream: repo.listRooms(org.id!),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }
            var rooms = snapshot.data!;
            return Tooltip(
              message: "Bookings for this org",
              child: IconButton(
                icon: const Icon(Icons.event),
                onPressed: () {
                  if (rooms.isEmpty) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("No rooms found"),
                        content: const Text(
                            "Please add a room to this organization.\n\nThis can be done in the settings page."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                  AutoRouter.of(context).push(ViewBookingsRoute(
                      orgID: org.id!, view: CalendarView.month.name));
                },
              ),
            );
          }),
    );
  }

  Widget _settingsButton(BuildContext context) {
    return Tooltip(
      message: "Settings for this org",
      child: IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () {
          AutoRouter.of(context).push(OrgSettingsRoute(orgID: org.id!));
        },
      ),
    );
  }

  Widget _scheduleButton(BuildContext context) {
    return Tooltip(
      message: "Schedule for this org",
      child: IconButton(
        icon: const Icon(Icons.view_agenda),
        onPressed: () {
          AutoRouter.of(context).push(ScheduleRoute(orgID: org.id!));
        },
      ),
    );
  }

  Widget _reviewButton(BuildContext context) {
    return Tooltip(
      message: "Review requests for this org",
      child: IconButton(
        icon: const Icon(Icons.approval),
        onPressed: () {
          AutoRouter.of(context).push(ReviewBookingsRoute(orgID: org.id!));
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
