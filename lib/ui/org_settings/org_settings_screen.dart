import 'package:auto_route/auto_route.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/data/repos/room_repo.dart';
import 'package:room_booker/router.dart';

import 'admin_widget.dart';
import 'notification_widget.dart';
import 'request_logs_widget.dart';
import 'room_list_widget.dart';
import 'org_actions.dart';
import 'org_details.dart';

@RoutePage()
class OrgSettingsScreen extends StatelessWidget {
  final String orgID;

  const OrgSettingsScreen({super.key, @PathParam('orgID') required this.orgID});

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.logScreenView(
        screenName: "Org Settings", parameters: {"orgID": orgID});
    var roomRepo = Provider.of<RoomRepo>(context, listen: false);
    return Scaffold(
        appBar: AppBar(
          title: const Text("Organization Settings"),
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
        body: Consumer<OrgRepo>(
          builder: (context, repo, child) => StreamBuilder(
            stream: repo.getOrg(orgID),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }
              return SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    OrgDetails(orgID: orgID),
                    const Divider(),
                    RoomListWidget(org: snapshot.data!, repo: roomRepo),
                    const Divider(),
                    NotificationWidget(org: snapshot.data!, repo: repo),
                    const Divider(),
                    RequestLogsWidget(org: snapshot.data!),
                    const Divider(),
                    AdminWidget(org: snapshot.data!, repo: repo),
                    const Divider(),
                    OrgActions(org: snapshot.data!, repo: repo),
                  ],
                ),
              );
            },
          ),
        ));
  }
}
