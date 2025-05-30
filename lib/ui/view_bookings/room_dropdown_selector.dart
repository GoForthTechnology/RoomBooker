import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/room_repo.dart';

class RoomDropdownSelector extends StatelessWidget {
  final String orgID;
  final bool readOnly;
  final String? initialRoomID;
  final Function(Room?) onChanged;

  const RoomDropdownSelector(
      {super.key,
      required this.readOnly,
      required this.orgID,
      this.initialRoomID,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    var roomRepo = Provider.of<RoomRepo>(context, listen: false);
    return StreamBuilder(
      stream: roomRepo.listRooms(orgID),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        var allRooms = snapshot.data as List<Room>;
        return _RoomField(
            rooms: allRooms,
            readOnly: readOnly,
            onChanged: onChanged,
            initialRoomID: initialRoomID);
      },
    );
  }
}

class _RoomField extends StatelessWidget {
  final bool readOnly;
  final List<Room> rooms;
  final String? initialRoomID;
  final Function(Room?) onChanged;

  const _RoomField({
    required this.rooms,
    required this.readOnly,
    this.initialRoomID,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    var selectedRoom = rooms.firstWhere((room) => room.id == initialRoomID,
        orElse: () => rooms.first);
    var field = DropdownButtonFormField<Room>(
      value: selectedRoom,
      decoration: const InputDecoration(
        labelText: 'Room',
        border: OutlineInputBorder(),
      ),
      items: rooms
          .map((room) => DropdownMenuItem(
                value: room,
                child: Text(room.name),
              ))
          .toList(),
      onChanged: readOnly
          ? null
          : (room) {
              onChanged(room);
            },
    );
    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(width: 400),
      child: field,
    );
  }
}
