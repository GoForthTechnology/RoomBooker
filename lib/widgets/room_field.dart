import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/organization.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:room_booker/widgets/room_selector.dart';

class RoomField extends StatelessWidget {
  final String orgID;
  final String initialRoomID;
  final bool readOnly;
  final Function(Room) onChanged;

  const RoomField(
      {super.key,
      required this.orgID,
      required this.initialRoomID,
      required this.onChanged,
      required this.readOnly});

  @override
  Widget build(BuildContext context) {
    return Consumer2<OrgRepo, RoomState>(
        builder: (context, repo, roomState, child) => StreamBuilder(
              stream: repo.listRooms(orgID),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                List<Room> rooms = snapshot.data!;
                Room initialValue = rooms.firstWhere(
                    (element) => element.id == initialRoomID,
                    orElse: () => rooms.first);
                return DropdownButtonFormField<Room>(
                  value: initialValue,
                  decoration: const InputDecoration(
                    labelText: 'Event Location',
                    border: OutlineInputBorder(),
                  ),
                  items: rooms.map<DropdownMenuItem<Room>>((Room value) {
                    return DropdownMenuItem<Room>(
                      value: value,
                      child: Text(value.name),
                    );
                  }).toList(),
                  onChanged: readOnly ? null : (value) => onChanged(value!),
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a room';
                    }
                    return null;
                  },
                );
              },
            ));
  }
}
