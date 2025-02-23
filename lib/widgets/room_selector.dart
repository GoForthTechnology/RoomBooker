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
  final Map<String, Room> _rooms;
  final Set<String> _activeIDs;
  final Map<String, Color> _colorMap;

  RoomState(List<Room> rooms, Set<Room> activeRooms)
      : _rooms = Map.fromEntries(rooms.map((r) => MapEntry(r.id!, r))),
        _activeIDs = activeRooms.map((r) => r.id!).toSet(),
        _colorMap =
            Map.fromEntries(rooms.map((r) => MapEntry(r.id!, Colors.black))) {
    for (int i = 0; i < rooms.length; i++) {
      var room = rooms[i];
      _colorMap[room.id!] = roomColors[i];
    }
  }

  Color color(String roomID) {
    var color = _colorMap[roomID];
    return color ?? Colors.black;
  }

  Room? getRoom(String roomID) {
    return _rooms[roomID];
  }

  List<Room> allRooms() {
    return _rooms.values.toList();
  }

  Room? enabledValue() {
    return _activeIDs.map((id) => _rooms[id]).first;
  }

  Set<Room> enabledValues() {
    return _activeIDs.map((id) => _rooms[id]!).toSet();
  }

  bool isEnabled(String roomID) {
    return _activeIDs.contains(roomID);
  }

  void setActiveRoom(Room room) {
    if (!_rooms.containsKey(room.id!)) {
      throw ArgumentError("Room $room not found in ${_rooms.keys}");
    }
    _activeIDs.clear();
    _activeIDs.add(room.id!);
    notifyListeners();
  }
}

class RoomStateProvider extends StatelessWidget {
  final String orgID;
  final bool enableAllRooms;
  final Widget Function(BuildContext, RoomState) builder;

  const RoomStateProvider(
      {super.key,
      required this.orgID,
      required this.builder,
      this.enableAllRooms = false});

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
              var activeRooms = enableAllRooms ? rooms.toSet() : {rooms.first};
              var roomState = RoomState(rooms, activeRooms);
              return builder(context, roomState);
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
