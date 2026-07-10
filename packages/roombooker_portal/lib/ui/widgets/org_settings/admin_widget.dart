import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:roombooker_core/data/entities/organization.dart';
import 'package:roombooker_core/data/repos/org_repo.dart';
import 'package:roombooker_portal/router.dart';
import 'package:roombooker_portal/ui/widgets/heading.dart';

import '../action_button.dart';

class AdminWidget extends StatefulWidget {
  final Organization org;
  final OrgRepo repo;

  const AdminWidget({super.key, required this.org, required this.repo});

  @override
  State<AdminWidget> createState() => _AdminWidgetState();
}

class _AdminWidgetState extends State<AdminWidget> {
  final _inviteController = TextEditingController();
  String? _inviteError;

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  Widget _adminRequests(BuildContext context) {
    return StreamBuilder(
      stream: widget.repo.adminRequests(widget.org.id!),
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
                        widget.repo.approveAdminRequest(
                          widget.org.id!,
                          admins[index].id!,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        widget.repo.denyAdminRequest(
                          widget.org.id!,
                          admins[index].id!,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _activeAdmins(BuildContext context) {
    return StreamBuilder(
      stream: widget.repo.activeAdmins(widget.org.id!),
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
                        widget.repo.removeAdmin(
                          widget.org.id!,
                          admins[index].id!,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _pendingInvites(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: widget.repo.pendingInvites(widget.org.id!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading invites');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        final emails = snapshot.data ?? [];
        if (emails.isEmpty) {
          return const Text('No pending invites');
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
            itemCount: emails.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(emails[index]),
                trailing: IconButton(
                  icon: const Icon(Icons.cancel),
                  tooltip: 'Cancel invite',
                  onPressed: () async {
                    await widget.repo.cancelAdminInvite(
                      widget.org.id!,
                      emails[index],
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _inviteByEmail(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _inviteController,
              decoration: InputDecoration(
                hintText: 'Email address',
                errorText: _inviteError,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            child: const Text('Invite'),
            onPressed: () async {
              final email = _inviteController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                setState(() => _inviteError = 'Enter a valid email address');
                return;
              }
              setState(() => _inviteError = null);
              await widget.repo.addAdminInvite(widget.org.id!, email);
              _inviteController.clear();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Invite sent to $email')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _sharingWidgets(BuildContext context) {
    List<Widget> contents = [];
    if (widget.org.acceptingAdminRequests) {
      contents.add(const Text('Admin requests are open'));
      contents.add(
        ActionButton(
          text: "View Join Link",
          tooltip: "This can be shared with others to request admin access",
          onPressed: () async {
            AutoRouter.of(context).push(JoinOrgRoute(orgID: widget.org.id!));
          },
          isDangerous: false,
        ),
      );
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
        const Subheading("Pending Invites"),
        _pendingInvites(context),
        const Subheading("Invite by Email"),
        _inviteByEmail(context),
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
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
