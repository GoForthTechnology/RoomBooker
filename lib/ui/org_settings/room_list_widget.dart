import 'package:flutter/material.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/room_repo.dart';
import 'package:room_booker/ui/core/heading.dart';
import 'action_button.dart';

class RoomListWidget extends StatelessWidget {
  final Organization org;
  final RoomRepo repo;

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
