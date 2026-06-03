import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roombooker_core/data/entities/organization.dart';
import 'package:roombooker_core/data/repos/prefs_repo.dart';
import 'package:roombooker_portal/router.dart';
import 'package:roombooker_portal/ui/widgets/room_selector.dart';

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
              Center(
                child: Text(
                  "Active Rooms",
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
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
                child: Text("← Back to Org List"),
                onPressed: () {
                  var prefRepo = Provider.of<PreferencesRepo>(
                    context,
                    listen: false,
                  );
                  prefRepo.setLastOpenedOrgId(null);
                  var router = AutoRouter.of(context);
                  router.popUntilRoot();
                  router.replace(const LandingRoute());
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
