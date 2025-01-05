import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:room_booker/router.dart';

@RoutePage()
class OrgSettingsScreen extends StatelessWidget {
  final String orgID;

  const OrgSettingsScreen({super.key, @PathParam('orgID') required this.orgID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Organization Settings"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            OrgDetails(orgID: orgID),
            OrgActions(orgID: orgID),
          ],
        ),
      ),
    );
  }
}

class OrgActions extends StatelessWidget {
  final String orgID;

  const OrgActions({super.key, @PathParam('orgID') required this.orgID});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            AutoRouter.of(context).push(ViewBookingsRoute(orgID: orgID));
          },
          child: const Text('View Bookings'),
        ),
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.red),
          ),
          onPressed: () async {
            var repo = Provider.of<OrgRepo>(context, listen: false);
            var router = AutoRouter.of(context);
            var confirmed = await confirmOrgDeletion(context);
            if (confirmed == true) {
              await repo.removeOrg(orgID);
              router.popUntilRoot();
            }
          },
          child:
              const Text('Remove Org', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

Future<bool?> confirmOrgDeletion(BuildContext context) {
  return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
            title: const Text('Delete Organization?'),
            content: const Text(
                'Are you sure you want to delete this organization?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text('Delete'),
              ),
            ],
          ));
}

class OrgDetails extends StatelessWidget {
  final String orgID;

  const OrgDetails({super.key, @PathParam('orgID') required this.orgID});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrgRepo>(
      builder: (context, repo, child) => StreamBuilder(
        stream: repo.getOrg(orgID),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Error loading organization');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          var org = snapshot.data;
          if (org == null) {
            return const Text('Organization not found');
          }
          return Column(
            children: [
              Text('Name: ${org.name}'),
              Text('Owner: ${org.ownerID}'),
            ],
          );
        },
      ),
    );
  }
}
