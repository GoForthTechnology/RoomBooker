import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/ui/core/heading.dart';

import 'action_button.dart';

class OrgActions extends StatelessWidget {
  final Organization org;
  final OrgRepo repo;

  const OrgActions({super.key, required this.org, required this.repo});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            const Heading('Danger Zone'),
            const Text("These action have consequences!"),
            _adminRegistrationButton(context),
            _removeOrgButton(context)
          ],
        ));
  }

  Widget _adminRegistrationButton(BuildContext context) {
    if (org.acceptingAdminRequests) {
      return ActionButton(
        tooltip: 'This will stop accepting admin requests',
        isDangerous: false,
        text: 'Stop Admin Requests',
        onPressed: () async {
          await repo.disableAdminRequests(org.id!);
        },
      );
    }
    return ActionButton(
      tooltip: 'This will allow others to request to join your org as an admin',
      isDangerous: true,
      text: 'Share Organization',
      onPressed: () async {
        await repo.enableAdminRequests(org.id!);
      },
    );
  }

  Widget _removeOrgButton(BuildContext context) {
    return ActionButton(
      tooltip: 'This action will permanently delete the organization',
      isDangerous: true,
      text: 'Remove Organization',
      onPressed: () async {
        var repo = Provider.of<OrgRepo>(context, listen: false);
        var router = AutoRouter.of(context);
        var confirmed = await confirmOrgDeletion(context);
        if (confirmed == true) {
          await repo.removeOrg(org.id!);
          router.popUntilRoot();
        }
      },
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
