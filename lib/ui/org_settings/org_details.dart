import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/repos/org_repo.dart';

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
          Widget globalBookingWidget;
          if (org.globalRoomID == null) {
            globalBookingWidget = ElevatedButton(
              onPressed: () async {
                var messenger = ScaffoldMessenger.of(context);
                repo.enableGlobalBookings(org.id!).then((_) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Global booking enabled')),
                  );
                }).catchError((error) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error: $error')),
                  );
                });
              },
              child: Text("Enable Global Booking"),
            );
          } else {
            globalBookingWidget =
                Text("Global Booking Enabled using ${org.globalRoomID}");
          }
          return Column(
            children: [
              Text('Name: ${org.name}'),
              Text('Owner: ${org.ownerID}'),
              globalBookingWidget,
            ],
          );
        },
      ),
    );
  }
}
