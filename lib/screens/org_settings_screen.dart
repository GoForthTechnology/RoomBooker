import 'package:auto_route/auto_route.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/organization.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/widgets/heading.dart';
import 'package:room_booker/widgets/simple_text_form_field.dart';

@RoutePage()
class OrgSettingsScreen extends StatelessWidget {
  final String orgID;

  const OrgSettingsScreen({super.key, @PathParam('orgID') required this.orgID});

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.logScreenView(
        screenName: "Org Settings", parameters: {"orgID": orgID});
    return Scaffold(
        appBar: AppBar(
          title: const Text("Organization Settings"),
          leading: BackButton(
            onPressed: () {
              var router = AutoRouter.of(context);
              if (router.canPop()) {
                router.popForced();
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
                    RoomListWidget(org: snapshot.data!, repo: repo),
                    const Divider(),
                    NotificationWidget(org: snapshot.data!, repo: repo),
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

class NotificationWidget extends StatefulWidget {
  final Organization org;
  final OrgRepo repo;

  const NotificationWidget({super.key, required this.org, required this.repo});

  @override
  NotificationWidgetState createState() => NotificationWidgetState();
}

class NotificationWidgetState extends State<NotificationWidget> {
  bool dirty = false;
  final _formKey = GlobalKey<FormState>();
  final controllers = <NotificationEvent, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    var targets = widget.org.notificationSettings?.notificationTargets ?? {};
    for (var event in NotificationEvent.values) {
      var controller = TextEditingController(text: targets[event]);
      controller.addListener(() {
        setState(() {
          dirty = true;
        });
      });
      controllers[event] = controller;
    }
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
        constraints: BoxConstraints.tightFor(width: 400),
        child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Heading("Notifications"),
                const Text(
                    "Please provide the email addresses for notifications"),
                ...NotificationEvent.values.map((e) => SimpleTextFormField(
                      controller: controllers[e]!,
                      readOnly: false,
                      labelText: e.name,
                      clearable: true,
                      validationRegex: RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'),
                      validationMessage: "Please provide a valid email address",
                    )),
                ElevatedButton(
                  onPressed: !dirty
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            widget.repo.updateNotificationSettings(
                                widget.org.id!,
                                NotificationSettings(
                                    notificationTargets: controllers.map(
                                        (key, value) =>
                                            MapEntry(key, value.text))));
                          }
                        },
                  child: Text('Save'),
                ),
              ],
            )));
  }
}

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

class RoomListWidget extends StatelessWidget {
  final Organization org;
  final OrgRepo repo;

  const RoomListWidget({super.key, required this.org, required this.repo});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: repo.listRooms(org.id!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Error loading rooms');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          return _buildRoomList(context, snapshot.data ?? []);
        });
  }

  Widget _buildRoomList(BuildContext context, List<Room> rooms) {
    Widget content;
    if (rooms.isEmpty) {
      content = const Text('No rooms found. Please add one.');
    } else {
      content = ListView.builder(
        shrinkWrap: true,
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          var room = rooms[index];
          return RoomTile(
            room: room,
            onDeleted: () async {
              var confirmed = await confirmRoomDeletion(context);
              if (confirmed == true) {
                await repo.removeRoom(org.id!, room.id!);
              }
            },
          );
        },
      );
    }
    return Column(
      children: [
        const Heading("Rooms"),
        content,
        ActionButton(
          isDangerous: false,
          text: 'Add Room',
          onPressed: () async {
            var repo = Provider.of<OrgRepo>(context, listen: false);
            var roomName = await promptForRoomName(context);
            if (roomName != null) {
              await repo.addRoom(org.id!, Room(name: roomName));
            }
          },
        ),
      ],
    );
  }
}

Future<bool?> confirmRoomDeletion(BuildContext context) {
  return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
            title: const Text('Delete Room?'),
            content: const Text('Are you sure you want to delete this room?'),
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

class RoomTile extends StatelessWidget {
  final Room room;
  final Function() onDeleted;

  const RoomTile({super.key, required this.room, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(room.name),
      deleteIcon: const Icon(Icons.delete),
      onDeleted: onDeleted,
    );
  }
}

Future<String?> promptForRoomName(BuildContext context) {
  var controller = TextEditingController();
  return showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: const Text('Add Room'),
            content: TextFormField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Room Name'),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(null);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(controller.text);
                },
                child: const Text('Add'),
              ),
            ],
          ));
}

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

class ActionButton extends StatelessWidget {
  final String text;
  final bool isDangerous;
  final VoidCallback onPressed;
  final String? tooltip;

  const ActionButton(
      {super.key,
      this.tooltip,
      required this.text,
      required this.onPressed,
      required this.isDangerous});

  @override
  Widget build(BuildContext context) {
    Widget widget = Padding(
        padding: const EdgeInsets.all(8),
        child: ElevatedButton(
          style: ButtonStyle(
            backgroundColor: isDangerous
                ? WidgetStateProperty.all(Colors.red)
                : WidgetStateProperty.all(Colors.blue),
          ),
          onPressed: onPressed,
          child: Text(
            text,
            style: const TextStyle(color: Colors.white),
          ),
        ));
    if (tooltip != null) {
      widget = Tooltip(message: tooltip!, child: widget);
    }
    return widget;
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
