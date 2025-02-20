import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/organization.dart';
import 'package:room_booker/repos/org_repo.dart';

List<Color> roomColors = [
  Colors.blueAccent,
  Colors.redAccent,
  Colors.greenAccent,
  Colors.purpleAccent,
  Colors.orangeAccent,
  Colors.yellowAccent,
];

class RoomState extends ChangeNotifier {
  Room _activeRoom;
  final Map<Room, Color> _colorMap;

  RoomState(this._activeRoom, this._colorMap);

  Color color(String roomID) {
    return _colorMap[getRoom(roomID)] ?? Colors.black;
  }

  Room? getRoom(String roomID) {
    return _colorMap.keys.firstWhereOrNull((r) => r.id == roomID);
  }

  List<Room> allRooms() {
    return _colorMap.keys.toList();
  }

  Room enabledValue() {
    return _activeRoom;
  }

  bool isEnabled(String roomID) {
    return _activeRoom.id == roomID;
  }

  void setActiveRoom(Room room) {
    if (!_colorMap.containsKey(room)) {
      throw ArgumentError("Room $room not found in ${_colorMap.keys}");
    }
    _activeRoom = room;
    notifyListeners();
  }
}

class RoomStateProvider extends StatelessWidget {
  final String orgID;
  final Widget Function(BuildContext, RoomState) builder;

  const RoomStateProvider(
      {super.key, required this.orgID, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrgRepo>(
        builder: (context, repo, child) => FutureBuilder(
            future: repo.listRooms(orgID).first,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }
              var rooms = snapshot.data!;
              Map<Room, Color> initialValues = {};
              for (int i = 0; i < rooms.length; i++) {
                initialValues[rooms[i]] = roomColors[i];
              }
              return builder(context, RoomState(rooms.first, initialValues));
            }));
  }
}

class RoomSelector extends StatelessWidget {
  const RoomSelector({super.key});

  @override
  Widget build(BuildContext context) {
    var field = Consumer<RoomState>(
      builder: (context, state, child) => DropdownButtonFormField<Room>(
        value: state.enabledValue(),
        decoration: const InputDecoration(
          labelText: 'Room',
          border: OutlineInputBorder(),
        ),
        items: state
            .allRooms()
            .map((r) => DropdownMenuItem(
                  value: r,
                  child: Text(r.name),
                ))
            .toList(),
        onChanged: (room) {
          state.setActiveRoom(room!);
        },
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints.tightFor(width: 400),
        child: field,
      ),
    );
  }
}

class RoomCard extends StatelessWidget {
  final Color color;
  final Room room;
  final Function(Room) onClick;

  const RoomCard(
      {super.key,
      required this.color,
      required this.room,
      required this.onClick});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "Show/hide this room",
      child: GestureDetector(
        onTap: () => onClick(room),
        child: Card(
          color: color,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(room.name, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
