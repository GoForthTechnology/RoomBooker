import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/ui/core/room_selector.dart';

// Assume RoomState and RoomCubit are defined elsewhere
// RoomState has: List<Room> rooms, Set<String> activeRoomIds
// Room has: String id, String name

class MyDrawer extends StatelessWidget {
  final Organization org;

  const MyDrawer({super.key, required this.org});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<RoomState>(
        builder: (context, state, child) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              Text("Active Rooms",
                  style: Theme.of(context).textTheme.headlineSmall),
              ...state.allRooms().map((room) {
                final isActive = state.isEnabled(room.id!);
                return CheckboxListTile(
                  activeColor: room.color,
                  title: Text(room.name),
                  value: isActive,
                  onChanged: (checked) {
                    state.toggleRoom(room);
                  },
                );
              }),
              TextButton(
                child: Text("Edit Rooms"),
                onPressed: () => AutoRouter.of(context)
                    .push(OrgSettingsRoute(orgID: org.id!)),
              ),
            ],
          );
        },
      ),
    );
  }
}
