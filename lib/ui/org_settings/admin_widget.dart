import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/ui/core/heading.dart';

import 'action_button.dart';

class AdminWidget extends StatelessWidget {
  final Organization org;
  final OrgRepo repo;

  const AdminWidget({super.key, required this.org, required this.repo});

  Widget _adminRequests(BuildContext context) {
    return StreamBuilder(
      stream: repo.adminRequests(org.id!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading requests');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        var admins = snapshot.data ?? [];
        if (admins.isEmpty) {
          return const Text('No pending requests');
        }
        return Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: admins.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(admins[index].email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.approval_rounded),
                        onPressed: () async {
                          repo.approveAdminRequest(org.id!, admins[index].id!);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          repo.denyAdminRequest(org.id!, admins[index].id!);
                        },
                      )
                    ],
                  ),
                );
              },
            ));
      },
    );
  }

  Widget _activeAdmins(BuildContext context) {
    return StreamBuilder(
      stream: repo.activeAdmins(org.id!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading admins');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        var admins = snapshot.data ?? [];
        if (admins.isEmpty) {
          return const Text('No active admins');
        }
        return Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: admins.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(admins[index].email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          repo.removeAdmin(org.id!, admins[index].id!);
                        },
                      ),
                    ],
                  ),
                );
              },
            ));
      },
    );
  }

  List<Widget> _sharingWidgets(BuildContext context) {
    List<Widget> contents = [];
    if (org.acceptingAdminRequests) {
      contents.add(const Text('Admin requests are open'));
      contents.add(ActionButton(
        text: "View Join Link",
        tooltip: "This can be shared with others to request admin access",
        onPressed: () async {
          AutoRouter.of(context).push(JoinOrgRoute(orgID: org.id!));
        },
        isDangerous: false,
      ));
    } else {
      contents.add(const Text('Admin requests are closed'));
    }
    return contents;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Heading("Org Adminstrators"),
        const Subheading("Admin Requests"),
        _adminRequests(context),
        const Subheading("Active Admins"),
        _activeAdmins(context),
        const Subheading("Sharing Status"),
        ..._sharingWidgets(context),
      ],
    );
  }
}

class Subheading extends StatelessWidget {
  final String text;
  const Subheading(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
