import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/organization.dart';
import 'package:room_booker/repos/org_repo.dart';

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
    return Consumer<OrgRepo>(
      builder: (context, orgRepo, child) => StreamBuilder(
        stream: orgRepo.listRooms(orgID),
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
      ),
    );
  }
}

class _RoomField extends StatefulWidget {
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
  State<_RoomField> createState() => _RoomFieldState();
}

class _RoomFieldState extends State<_RoomField> {
  Room? selectedRoom;

  @override
  void initState() {
    super.initState();
    if (widget.initialRoomID != null) {
      for (var room in widget.rooms) {
        if (room.id == widget.initialRoomID) {
          selectedRoom = room;
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var field = DropdownButtonFormField<Room>(
      value: selectedRoom,
      decoration: const InputDecoration(
        labelText: 'Room',
        border: OutlineInputBorder(),
      ),
      items: widget.rooms
          .map((room) => DropdownMenuItem(
                value: room,
                child: Text(room.name),
              ))
          .toList(),
      onChanged: widget.readOnly
          ? null
          : (room) {
              setState(() {
                selectedRoom = room;
                widget.onChanged(room);
              });
            },
    );
    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(width: 400),
      child: field,
    );
  }
}
