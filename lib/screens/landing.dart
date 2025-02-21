import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/organization.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:room_booker/router.dart';

@RoutePage()
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            print(snapshot.error);
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

class OrgTile extends StatelessWidget {
  final Organization org;

  const OrgTile({super.key, required this.org});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: const Icon(Icons.business),
        title: Text(org.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _settingsButton(context),
            _viewCalendarButton(context),
          ],
        ),
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
                  AutoRouter.of(context)
                      .push(ViewBookingsRoute(orgID: org.id!));
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
