import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/organization.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:room_booker/widgets/heading.dart';

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
            RoomListWidget(orgID: orgID),
            OrgActions(orgID: orgID),
          ],
        ),
      ),
    );
  }
}

class RoomListWidget extends StatelessWidget {
  final String orgID;

  const RoomListWidget({super.key, required this.orgID});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrgRepo>(
      builder: (context, repo, child) => StreamBuilder(
        stream: repo.getOrg(orgID).map((org) => org?.rooms ?? []),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Error loading rooms');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          var rooms = snapshot.data!;
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
                      await repo.removeRoom(orgID, room.name);
                    }
                  },
                );
              },
            );
          }
          return Column(
            children: [
              const Heading(text: "Rooms"),
              content,
              ActionButton(
                isDangerous: false,
                text: 'Add Room',
                onPressed: () async {
                  var repo = Provider.of<OrgRepo>(context, listen: false);
                  var roomName = await promptForRoomName(context);
                  if (roomName != null) {
                    await repo.addRoom(orgID, roomName);
                  }
                },
              ),
            ],
          );
        },
      ),
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
  final String orgID;

  const OrgActions({super.key, @PathParam('orgID') required this.orgID});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            const Text("Danger zone! These action have consequences."),
            ActionButton(
              isDangerous: true,
              text: 'Remove Organization',
              onPressed: () async {
                var repo = Provider.of<OrgRepo>(context, listen: false);
                var router = AutoRouter.of(context);
                var confirmed = await confirmOrgDeletion(context);
                if (confirmed == true) {
                  await repo.removeOrg(orgID);
                  router.popUntilRoot();
                }
              },
            ),
          ],
        ));
  }
}

class ActionButton extends StatelessWidget {
  final String text;
  final bool isDangerous;
  final VoidCallback onPressed;

  const ActionButton(
      {super.key,
      required this.text,
      required this.onPressed,
      required this.isDangerous});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
