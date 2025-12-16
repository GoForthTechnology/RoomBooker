import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/analytics_service.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/data/repos/room_repo.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/ui/widgets/org_settings/app_info.dart';
import 'package:web/web.dart' as web;

import 'package:room_booker/ui/widgets/org_settings/admin_widget.dart';
import 'package:room_booker/ui/widgets/heading.dart';
import 'package:room_booker/ui/widgets/org_settings/notification_widget.dart';
import 'package:room_booker/ui/widgets/request_logs_widget.dart';
import 'package:room_booker/ui/widgets/room_list_widget.dart';
import 'package:room_booker/ui/widgets/org_settings/org_actions.dart';

@RoutePage()
class OrgSettingsScreen extends StatelessWidget {
  final String orgID;

  const OrgSettingsScreen({super.key, @PathParam('orgID') required this.orgID});

  @override
  Widget build(BuildContext context) {
    Provider.of<FirebaseAnalyticsService>(
      context,
      listen: false,
    ).logScreenView(screenName: "Org Settings", parameters: {"orgID": orgID});
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
        actions: [
          if (kIsWeb)
            IconButton(
              onPressed: () {
                web.window.location.reload();
              },
              icon: Icon(Icons.refresh),
            ),
        ],
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
                  LogsWidget(org: snapshot.data!),
                  const Divider(),
                  RoomListWidget(org: snapshot.data!, repo: roomRepo),
                  const Divider(),
                  NotificationWidget(org: snapshot.data!, repo: repo),
                  const Divider(),
                  AdminWidget(org: snapshot.data!, repo: repo),
                  const Divider(),
                  AppInfoWidget(),
                  const Divider(),
                  OrgActions(org: snapshot.data!, repo: repo),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class LogsWidget extends StatelessWidget {
  final Organization org;

  const LogsWidget({super.key, required this.org});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Heading("Request Logs"),
        const Text(
          "This shows the history of admin requests and actions taken on them",
        ),
        Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: RequestLogsWidget(org: org, allowPagination: true),
        ),
      ],
    );
  }
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
          Widget globalBookingWidget;
          if (org.globalRoomID == null) {
            globalBookingWidget = ElevatedButton(
              onPressed: () async {
                var messenger = ScaffoldMessenger.of(context);
                repo
                    .enableGlobalBookings(org.id!)
                    .then((_) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Global booking enabled')),
                      );
                    })
                    .catchError((error) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Error: $error')),
                      );
                    });
              },
              child: Text("Enable Global Booking"),
            );
          } else {
            globalBookingWidget = Text(
              "Global Booking Enabled using ${org.globalRoomID}",
            );
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
