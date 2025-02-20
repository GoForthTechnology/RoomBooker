import 'package:auto_route/auto_route.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/repos/org_repo.dart';

@RoutePage()
class JoinOrgScreen extends StatelessWidget {
  final String orgID;

  const JoinOrgScreen({super.key, @PathParam('orgID') required this.orgID});

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.logScreenView(
        screenName: "Join Organization", parameters: {"orgID": orgID});
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Organization'),
      ),
      body: Consumer<OrgRepo>(
        builder: (context, repo, child) => StreamBuilder(
          stream: repo.getOrg(orgID),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              FirebaseAnalytics.instance.logEvent(name: "Org Load Error");
              return const Text('Error loading organization');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            var org = snapshot.data!;
            if (!org.acceptingAdminRequests) {
              FirebaseAnalytics.instance
                  .logEvent(name: "Org not accepting new members");
              return const Text(
                  'This organization is not accepting new members');
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Join ${org.name}?'),
                  ElevatedButton(
                    onPressed: () async {
                      var messenger = ScaffoldMessenger.of(context);
                      await repo.addAdminRequestForCurrentUser(orgID);
                      FirebaseAnalytics.instance
                          .logEvent(name: "Join request submitted");
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Request has been submitted'),
                        ),
                      );
                    },
                    child: const Text('Join'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
