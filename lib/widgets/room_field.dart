import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/organization.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:room_booker/widgets/room_selector.dart';

class RoomField extends StatelessWidget {
  final String orgID;
  final String initialValue;
  final Function(String) onChanged;

  const RoomField(
      {super.key,
      required this.orgID,
      required this.initialValue,
      required this.onChanged});

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
                return DropdownButtonFormField<String>(
                  value: initialValue,
                  decoration: const InputDecoration(
                    labelText: 'Event Location',
                    border: OutlineInputBorder(),
                  ),
                  items: rooms.map<DropdownMenuItem<String>>((Room value) {
                    return DropdownMenuItem<String>(
                      value: value.name,
                      child: Text(value.name),
                    );
                  }).toList(),
                  onChanged: (value) => onChanged(value!),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a room';
                    }
                    return null;
                  },
                );
              },
            ));
  }
}
