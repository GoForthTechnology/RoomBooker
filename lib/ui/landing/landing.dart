import 'dart:async';
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
import 'package:room_booker/data/repos/prefs_repo.dart';
import 'package:room_booker/router.dart';
import 'package:rxdart/rxdart.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

@RoutePage()
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
  StreamSubscription<User?>? subscription;

  @override
  initState() {
    subscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        isLoggedIn = user != null;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.logScreenView(screenName: "Landing");
    var orgRepo = Provider.of<OrgRepo>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Room Booker"),
        actions: [SettingsAction(), AuthAction(isSignedIn: isLoggedIn)],
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            YourOrgs(orgRepo: orgRepo, isLoggedIn: isLoggedIn),
            Heading("All Organizations"),
            Consumer<PreferencesRepo>(
              builder: (context, settingsProvider, child) => OrgList(
                orgStream: orgRepo.getOrgs(excludeOwned: true),
                defaultCalendarView: settingsProvider.defaultCalendarView,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isLoggedIn
          ? FloatingActionButton(
              onPressed: () async {
                var repo = Provider.of<OrgRepo>(context, listen: false);
                var name = await promptForOrgName(context);
                if (name != null) {
                  await repo.addOrgForCurrentUser(name);
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class SettingsAction extends StatelessWidget {
  const SettingsAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "Settings",
      child: IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () => _showSettingsDialog(context),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Consumer<PreferencesRepo>(
            builder: (context, prefsRepo, child) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Default Calendar View:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...CalendarView.values
                        .where((view) => _isValidCalendarView(view))
                        .map((view) => RadioListTile<CalendarView>(
                              title: Text(_getCalendarViewDisplayName(view)),
                              value: view,
                              groupValue: prefsRepo.defaultCalendarView,
                              onChanged: (CalendarView? value) {
                                if (value != null) {
                                  prefsRepo.setDefaultCalendarView(value);
                                }
                              },
                            )),
                  ],
                )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  bool _isValidCalendarView(CalendarView view) {
    // Filter to only show commonly used calendar views
    return [
      CalendarView.month,
      CalendarView.week,
      CalendarView.day,
      CalendarView.schedule,
    ].contains(view);
  }

  String _getCalendarViewDisplayName(CalendarView view) {
    switch (view) {
      case CalendarView.month:
        return 'Month';
      case CalendarView.week:
        return 'Week';
      case CalendarView.day:
        return 'Day';
      case CalendarView.schedule:
        return 'Schedule';
      default:
        return view.name;
    }
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
        Consumer<PreferencesRepo>(
          builder: (context, prefsRepo, child) => OrgList(
            orgStream: orgRepo.getOrgsForCurrentUser(),
            defaultCalendarView: prefsRepo.defaultCalendarView,
          ),
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
          },
        ),
      );
    } else {
      return Tooltip(
        message: "Sign in",
        child: IconButton(
          icon: const Icon(Icons.login),
          onPressed: () {
            AutoRouter.of(context).push(LoginRoute());
          },
        ),
      );
    }
  }
}

class OrgList extends StatelessWidget {
  final Stream<List<Organization>> orgStream;
  final CalendarView defaultCalendarView;
  const OrgList(
      {super.key, required this.orgStream, required this.defaultCalendarView});

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
            return OrgTile(
                org: orgs[index], defaultCalendarView: defaultCalendarView);
          },
        );
      },
    );
  }
}

class CardState {
  final int numPendingBookings;
  final int numPendingAdminRequests;
  final int numOverlappingBookings;

  CardState(
      {required this.numPendingBookings,
      required this.numPendingAdminRequests,
      required this.numOverlappingBookings});

  static Stream<CardState> stream(
      BookingRepo bookingRepo, OrgRepo orgRepo, String orgID) {
    return Rx.combineLatest3(
      bookingRepo.listRequests(
          orgID: orgID,
          startTime: DateTime.now(),
          endTime: DateTime.now().add(Duration(days: 365)),
          includeStatuses: {RequestStatus.pending}),
      orgRepo.adminRequests(orgID),
      bookingRepo.findOverlappingBookings(
          orgID, DateTime.now(), DateTime.now().add(Duration(days: 365))),
      (pendingRequests, adminRequests, overlaps) => CardState(
          numPendingBookings: pendingRequests.length,
          numPendingAdminRequests: adminRequests.length,
          numOverlappingBookings: overlaps.length),
    );
  }
}

class OrgTile extends StatelessWidget {
  final Organization org;
  final CalendarView defaultCalendarView;

  const OrgTile(
      {super.key, required this.org, required this.defaultCalendarView});

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
            if (state.numOverlappingBookings > 0) {
              subtitle +=
                  ", ${state.numOverlappingBookings} overlapping bookings";
            }
          }
          return ListTile(
            leading: const Icon(Icons.business),
            title: Text(org.name),
            subtitle: subtitle != null ? Text(subtitle) : null,
            onTap: () => AutoRouter.of(context).replace(ViewBookingsRoute(
                orgID: org.id!, view: defaultCalendarView.name)),
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
